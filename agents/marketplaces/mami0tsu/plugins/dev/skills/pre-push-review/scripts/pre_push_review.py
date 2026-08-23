#!/usr/bin/env python3
"""Keep pre-push difit checkpoints and classify review messages."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from typing import Any
import urllib.error
import urllib.parse
import urllib.request


STATE_NAME = "pre-push-review-state.json"
SCHEMA_VERSION = 1
REPLY_RE = re.compile(r"^Reply ([1-9][0-9]*) \((.*)\)$")
EMPTY_COMMENTS_OUTPUT = (
    "\n📝 Comments from review session:\n"
    + "=" * 50
    + "\n\n"
    + "=" * 50
    + "\nTotal comments: 0\n"
)


class ReviewError(RuntimeError):
    pass


class CommentsCollectionError(ReviewError):
    def __init__(self, message: str, partial: str) -> None:
        super().__init__(message)
        self.partial = partial


def git(*args: str, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if check and result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise ReviewError(f"git {' '.join(args)} failed: {detail}")
    return result.stdout.strip()


def git_raw(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise ReviewError(f"git {' '.join(args)} failed: {detail}")
    return result.stdout


def repository_root() -> Path:
    return Path(git("rev-parse", "--show-toplevel"))


def state_path() -> Path:
    value = git("rev-parse", "--git-path", STATE_NAME)
    path = Path(value)
    if not path.is_absolute():
        path = repository_root() / path
    return path.resolve()


def legacy_state_path() -> Path:
    value = git("rev-parse", "--git-path", "review-state.json")
    path = Path(value)
    if not path.is_absolute():
        path = repository_root() / path
    return path.resolve()


def require_no_legacy_state() -> None:
    path = legacy_state_path()
    if path.exists():
        raise ReviewError(
            f"legacy review state exists; migrate or complete it before continuing: {path}"
        )


def require_clean() -> None:
    status = git("status", "--porcelain=v1", "--untracked-files=all")
    if status:
        raise ReviewError("worktree is not clean, including untracked files")


def resolve_commit(value: str) -> str:
    return git("rev-parse", "--verify", f"{value}^{{commit}}")


def checkpoint(value: str) -> dict[str, str]:
    commit = resolve_commit(value)
    return {
        "commit": commit,
        "title": git("show", "-s", "--format=%s", commit),
        "tree": git("rev-parse", f"{commit}^{{tree}}"),
    }


def validate_checkpoint(value: dict[str, Any]) -> None:
    commit = value.get("commit")
    tree = value.get("tree")
    if not isinstance(commit, str) or not isinstance(tree, str):
        raise ReviewError("invalid checkpoint in review state")
    if resolve_commit(commit) != commit:
        raise ReviewError(f"checkpoint commit changed unexpectedly: {commit}")
    resolved_tree = git("rev-parse", "--verify", f"{tree}^{{tree}}")
    if resolved_tree != tree:
        raise ReviewError(f"checkpoint tree changed unexpectedly: {tree}")
    if git("rev-parse", f"{commit}^{{tree}}") != tree:
        raise ReviewError(f"checkpoint commit and tree do not match: {commit}")


def read_state() -> dict[str, Any]:
    require_no_legacy_state()
    path = state_path()
    if not path.exists():
        raise ReviewError("review state does not exist; run init first")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReviewError(f"cannot read review state: {error}") from error
    if not isinstance(value, dict) or value.get("schemaVersion") != SCHEMA_VERSION:
        raise ReviewError("unsupported review state schema")
    return value


def write_private_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, stat.S_IRUSR | stat.S_IWUSR)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(value, handle, ensure_ascii=False, indent=2, sort_keys=True)
            handle.write("\n")
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def write_state(value: dict[str, Any]) -> None:
    write_private_json(state_path(), value)


def command_init(args: argparse.Namespace) -> None:
    repository_root()
    require_clean()
    require_no_legacy_state()
    path = state_path()
    base = checkpoint(args.base)
    target = checkpoint(args.target)
    if args.base != base["commit"]:
        raise ReviewError("base must be a full commit OID")
    if args.target != target["commit"]:
        raise ReviewError("target must be a full commit OID")
    if base["commit"] == target["commit"]:
        raise ReviewError("base and target must differ")
    if path.exists():
        state = read_state()
        stored_base = state.get("base")
        stored_target = state.get("initialTarget")
        if (
            not isinstance(stored_base, dict)
            or not isinstance(stored_target, dict)
            or stored_base.get("commit") != base["commit"]
            or stored_target.get("commit") != target["commit"]
        ):
            raise ReviewError("existing review state does not match base and target identity")
        last_review = state.get("lastReview")
        if isinstance(last_review, dict):
            validate_checkpoint(last_review)
            if checkpoint("HEAD")["tree"] != last_review["tree"]:
                next_selection(state)
        else:
            next_selection(state)
        print(
            json.dumps(
                {"state": str(path), "base": base, "target": target, "resumed": True},
                ensure_ascii=False,
            )
        )
        return
    if target["commit"] != resolve_commit("HEAD"):
        raise ReviewError("target must match the current HEAD commit")
    write_state(
        {
            "schemaVersion": SCHEMA_VERSION,
            "base": base,
            "initialTarget": target,
            "lastReview": None,
            "active": None,
            "comparisons": [],
            "commentThreads": {},
            "agentMessages": {},
            "validations": {},
            "processedSignatures": [],
            "lastExtract": None,
        }
    )
    print(
        json.dumps(
            {"state": str(path), "base": base, "target": target},
            ensure_ascii=False,
        )
    )


def next_selection(state: dict[str, Any]) -> dict[str, Any]:
    base_checkpoint = state.get("lastReview") or state.get("base")
    if not isinstance(base_checkpoint, dict):
        raise ReviewError("review state has no base checkpoint")
    validate_checkpoint(base_checkpoint)
    if state.get("lastReview") is None:
        initial_target = state.get("initialTarget")
        if not isinstance(initial_target, dict):
            raise ReviewError("review state has no initial target checkpoint")
        validate_checkpoint(initial_target)
        target_checkpoint = checkpoint("HEAD")
        if initial_target["tree"] != target_checkpoint["tree"]:
            raise ReviewError("initial target tree no longer matches the current HEAD tree")
    else:
        target_checkpoint = checkpoint("HEAD")
    key = f"{base_checkpoint['tree']}:{target_checkpoint['tree']}"
    if base_checkpoint["tree"] == target_checkpoint["tree"]:
        raise ReviewError("next review range is empty; reopen the active range or complete it")
    comparisons = state.get("comparisons", [])
    if not isinstance(comparisons, list):
        raise ReviewError("invalid comparisons in review state")
    return {
        "base": base_checkpoint["tree"],
        "target": target_checkpoint["tree"],
        "baseCommit": base_checkpoint["commit"],
        "targetCommit": target_checkpoint["commit"],
        "baseTitle": base_checkpoint["title"],
        "targetTitle": target_checkpoint["title"],
        "clean": key not in comparisons,
        "key": key,
    }


def command_next(_args: argparse.Namespace) -> None:
    require_clean()
    print(json.dumps(next_selection(read_state()), ensure_ascii=False))


def command_retarget(args: argparse.Namespace) -> None:
    require_clean()
    state = read_state()
    if state.get("lastReview") is not None:
        raise ReviewError("review already advanced; use next with the current HEAD")
    current = state.get("currentTranscript")
    if isinstance(current, dict) and not current.get("deleted"):
        raise ReviewError("extract or explicitly discard the current transcript before retargeting")
    target = checkpoint(args.target)
    if args.target != target["commit"]:
        raise ReviewError("retarget target must be a full commit OID")
    if target["commit"] != resolve_commit("HEAD"):
        raise ReviewError("retarget target must match the current HEAD commit")
    base = state.get("base")
    if not isinstance(base, dict) or base.get("tree") == target["tree"]:
        raise ReviewError("retarget range must contain a committed tree change")
    state["initialTarget"] = target
    state["active"] = None
    state["activeComments"] = []
    state["activeAgentMessages"] = []
    state["currentTranscript"] = None
    state["lastExtract"] = None
    write_state(state)
    print(json.dumps({"target": target, "retargeted": True}, ensure_ascii=False))


def command_validated(args: argparse.Namespace) -> None:
    require_clean()
    state = read_state()
    base = checkpoint(args.base)
    target = checkpoint(args.target)
    if args.base != base["commit"]:
        raise ReviewError("validated base must be a full commit OID")
    if args.target != target["commit"]:
        raise ReviewError("validated target must be a full commit OID")
    if target["commit"] != resolve_commit("HEAD"):
        raise ReviewError("validated target must match the current HEAD commit")
    selection = next_selection(state)
    if base["tree"] != selection["base"] or target["tree"] != selection["target"]:
        raise ReviewError("validated comparison does not match the next review range")
    checks = [value.strip() for value in args.normal_check if value.strip()]
    subagents = sorted(set(value.strip() for value in args.subagent if value.strip()))
    if len(checks) != len(args.normal_check):
        raise ReviewError("normal check labels must not be empty")
    required = 1 if args.risk == "normal" else 2
    maximum = 1 if args.risk == "normal" else 3
    if not required <= len(subagents) <= maximum:
        raise ReviewError(
            f"{args.risk} risk requires {required} to {maximum} distinct subagents"
        )
    validations = state.get("validations")
    if not isinstance(validations, dict):
        raise ReviewError("invalid validations in review state")
    validations[selection["key"]] = {
        "baseCommit": base["commit"],
        "targetCommit": target["commit"],
        "normalChecks": checks,
        "risk": args.risk,
        "subagents": subagents,
    }
    write_state(state)


def validate_difit() -> str:
    executable = shutil.which("difit")
    if executable is None:
        raise ReviewError("difit was not found; install the managed local command")
    version_result = subprocess.run(
        [executable, "--version"], capture_output=True, text=True, check=False
    )
    if version_result.returncode != 0:
        raise ReviewError("difit --version failed")
    version = version_result.stdout.strip()
    if version != "4.0.5":
        raise ReviewError(f"pre-push-review requires difit 4.0.5, found {version}")
    return executable


def load_comments(path: Path) -> list[dict[str, Any]]:
    try:
        metadata = path.stat()
    except OSError as error:
        raise ReviewError(f"cannot stat comments JSON: {error}") from error
    if not stat.S_ISREG(metadata.st_mode):
        raise ReviewError("comments JSON must be a regular file")
    if metadata.st_uid != os.getuid():
        raise ReviewError("comments JSON must be owned by the current user")
    if stat.S_IMODE(metadata.st_mode) & 0o077:
        raise ReviewError("comments JSON permissions must not allow group or other access")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReviewError(f"cannot read comments JSON: {error}") from error
    if not isinstance(value, list):
        raise ReviewError("comments JSON must be an array")
    output: list[dict[str, Any]] = []
    displayed_positions: set[str] = set()
    for index, item in enumerate(value):
        if not isinstance(item, dict):
            raise ReviewError(f"comment {index} must be an object")
        if item.get("type") not in ("thread", "reply"):
            raise ReviewError(f"comment {index} has an invalid type")
        body = item.get("body")
        if not isinstance(body, str) or not body.strip():
            raise ReviewError(f"comment {index} has an empty body")
        file_path = item.get("filePath")
        position = item.get("position")
        if not isinstance(file_path, str) or not file_path or not isinstance(position, dict):
            raise ReviewError(f"comment {index} has no diff position")
        candidate_path = Path(file_path)
        if candidate_path.is_absolute() or ".." in candidate_path.parts:
            raise ReviewError(f"comment {index} filePath must be a repository-relative path")
        if position.get("side") not in ("old", "new"):
            raise ReviewError(f"comment {index} position has an invalid side")
        line = position.get("line")
        valid_line = isinstance(line, int) and not isinstance(line, bool) and line > 0
        if isinstance(line, dict):
            start = line.get("start")
            end = line.get("end")
            valid_line = (
                isinstance(start, int)
                and not isinstance(start, bool)
                and isinstance(end, int)
                and not isinstance(end, bool)
                and 0 < start <= end
            )
        if not valid_line:
            raise ReviewError(f"comment {index} position has an invalid line")
        copy = dict(item)
        clean_body = body.rstrip()
        copy["body"] = clean_body
        copy["author"] = "agent"
        line = copy["position"].get("line")
        if isinstance(line, dict):
            line_label = f"L{line.get('start')}-L{line.get('end')}"
        else:
            line_label = f"L{line}"
        displayed = f"{copy['filePath']}:{line_label}"
        if copy["type"] == "thread" and displayed in displayed_positions:
            raise ReviewError("difit cannot safely distinguish multiple threads at one displayed position")
        if copy["type"] == "thread":
            displayed_positions.add(displayed)
            copy["id"] = "agent-" + hashlib.sha256(
                json.dumps(
                    {"filePath": copy["filePath"], "position": copy["position"], "body": clean_body},
                    ensure_ascii=False,
                    sort_keys=True,
                ).encode("utf-8")
            ).hexdigest()[:24]
        output.append(copy)
    return output


def validate_comments_for_range(
    comments: list[dict[str, Any]], state: dict[str, Any], key: str, base: str, target: str
) -> None:
    changed_paths = {
        value
        for value in git_raw(
            "diff", "--no-ext-diff", "--no-textconv", "--name-only", "-z", base, target
        ).split("\0")
        if value
    }
    thread_sets = state.get("commentThreads", {})
    if not isinstance(thread_sets, dict):
        raise ReviewError("invalid comment threads in review state")
    known_threads = thread_sets.get(key, [])
    if not isinstance(known_threads, list):
        raise ReviewError("invalid comparison comment threads in review state")
    for index, item in enumerate(comments):
        if item["filePath"] not in changed_paths:
            raise ReviewError(f"comment {index} filePath is not part of the comparison")
        diff_text = git(
            "diff",
            "--no-ext-diff",
            "--no-textconv",
            "--unified=0",
            base,
            target,
            "--",
            item["filePath"],
        )
        valid_lines: dict[str, set[int]] = {"old": set(), "new": set()}
        for match in re.finditer(
            r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@",
            diff_text,
            re.MULTILINE,
        ):
            old_start, old_count, new_start, new_count = match.groups()
            old_size = int(old_count) if old_count is not None else 1
            new_size = int(new_count) if new_count is not None else 1
            valid_lines["old"].update(range(int(old_start), int(old_start) + old_size))
            valid_lines["new"].update(range(int(new_start), int(new_start) + new_size))
        line = item["position"]["line"]
        requested_lines = (
            range(line["start"], line["end"] + 1)
            if isinstance(line, dict)
            else (line,)
        )
        if not all(value in valid_lines[item["position"]["side"]] for value in requested_lines):
            raise ReviewError(f"comment {index} position is outside a changed diff hunk")
        if item["type"] != "reply":
            continue
        matches = [
            thread
            for thread in known_threads
            if isinstance(thread, dict)
            and thread.get("filePath") == item["filePath"]
            and thread.get("position") == item["position"]
        ]
        if len(matches) != 1:
            raise ReviewError(f"comment {index} reply target is not a unique Agent thread")


def new_transcript_path() -> Path:
    descriptor, name = tempfile.mkstemp(prefix="difit-review-", suffix=".log")
    os.fchmod(descriptor, stat.S_IRUSR | stat.S_IWUSR)
    os.close(descriptor)
    return Path(name)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def fetch_comments_output(server_url: str) -> str:
    try:
        parsed = urllib.parse.urlsplit(server_url)
        port = parsed.port
    except ValueError as error:
        raise ReviewError(f"invalid difit server URL: {error}") from error
    if (
        parsed.scheme != "http"
        or parsed.hostname != "localhost"
        or port is None
        or parsed.path not in ("", "/")
        or parsed.query
        or parsed.fragment
        or parsed.username is not None
        or parsed.password is not None
    ):
        raise ReviewError("invalid difit server URL")
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    try:
        with opener.open(f"{server_url}/api/comments-output", timeout=5) as response:
            if response.status != 200:
                raise ReviewError(f"difit comments endpoint returned HTTP {response.status}")
            value = response.read().decode("utf-8")
    except (OSError, UnicodeDecodeError, urllib.error.URLError) as error:
        raise ReviewError(f"cannot fetch difit comments output: {error}") from error
    return value


def collect_comments_output(server_url: str) -> str:
    deadline = time.monotonic() + 1.0
    latest = fetch_comments_output(server_url)
    try:
        while time.monotonic() < deadline:
            time.sleep(0.1)
            latest = fetch_comments_output(server_url)
    except BaseException as error:
        raise CommentsCollectionError(str(error), latest) from error
    return latest or EMPTY_COMMENTS_OUTPUT


def command_run(args: argparse.Namespace) -> None:
    require_clean()
    state = read_state()
    current_transcript = state.get("currentTranscript")
    if isinstance(current_transcript, dict) and not current_transcript.get("deleted"):
        raise ReviewError("extract and discard the current transcript before another run")
    active = state.get("active")
    allowed_active = (
        isinstance(active, dict)
        and args.target == active.get("target")
        and args.base == active.get("base")
    )
    if allowed_active:
        if checkpoint("HEAD")["tree"] != args.target:
            raise ReviewError("HEAD tree no longer matches the active review target")
        expected_clean = False
    else:
        selection = next_selection(state)
        if args.target != selection["target"] or args.base != selection["base"]:
            raise ReviewError("requested comparison does not match next or active review range")
        expected_clean = selection["clean"]
    if args.clean != expected_clean:
        raise ReviewError(f"--clean must be {'present' if expected_clean else 'absent'} for this range")

    validations = state.get("validations")
    validation_key = f"{args.base}:{args.target}"
    validation = validations.get(validation_key) if isinstance(validations, dict) else None
    if not isinstance(validation, dict):
        raise ReviewError("comparison has no completed validation record")

    comments = load_comments(args.comments)
    validate_comments_for_range(comments, state, validation_key, args.base, args.target)
    executable = validate_difit()
    transcript = new_transcript_path()
    command = [executable, args.target, args.base]
    command.append("--keep-alive")
    if args.clean:
        command.append("--clean")
    if comments:
        command.extend(["--comment", json.dumps(comments, ensure_ascii=False, separators=(",", ":"))])

    key = f"{args.base}:{args.target}"
    comparisons = state.setdefault("comparisons", [])
    state["currentTranscript"] = {
        "path": str(transcript.resolve()),
        "sha256": hashlib.sha256(b"").hexdigest(),
        "base": args.base,
        "target": args.target,
        "status": "running",
        "processGroup": None,
        "extracted": False,
        "empty": False,
        "deleted": False,
    }
    state["lastExtract"] = None
    write_state(state)

    return_code: int | None = None
    process: subprocess.Popen[str] | None = None
    disconnect_handled = False
    controlled_shutdown = False
    server_url: str | None = None
    try:
        with transcript.open("w", encoding="utf-8") as output:
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                start_new_session=True,
            )
            state["currentTranscript"]["processGroup"] = process.pid
            write_state(state)
            assert process.stdout is not None
            for line in process.stdout:
                sys.stdout.write(line)
                sys.stdout.flush()
                output.write(line)
                output.flush()
                url_match = re.search(r"difit server started on (http://localhost:[0-9]+)", line)
                if url_match:
                    server_url = url_match.group(1)
                if (
                    not disconnect_handled
                    and "Client disconnected, but server is staying alive" in line
                ):
                    disconnect_handled = True
                    if server_url is None:
                        raise ReviewError("difit disconnect occurred before the server URL was known")
                    try:
                        comments_output = collect_comments_output(server_url)
                    except CommentsCollectionError as error:
                        if error.partial:
                            output.write(error.partial)
                            output.flush()
                        raise
                    output.write(comments_output)
                    output.flush()
                    sys.stdout.write(comments_output)
                    sys.stdout.flush()
                    controlled_shutdown = True
                    os.killpg(process.pid, 15)
                    break
            process.stdout.close()
            try:
                return_code = process.wait(timeout=5 if controlled_shutdown else None)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, 9)
                return_code = process.wait()
            if controlled_shutdown:
                try:
                    os.killpg(process.pid, 9)
                except ProcessLookupError:
                    pass
    except BaseException as error:
        if process is not None and process.poll() is None:
            try:
                os.killpg(process.pid, 15)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(process.pid, 9)
                except ProcessLookupError:
                    pass
                process.wait()
        if process is not None:
            try:
                os.killpg(process.pid, 9)
            except ProcessLookupError:
                pass
        if process is not None and process.stdout is not None:
            process.stdout.close()
        transcript_text = transcript.read_text(encoding="utf-8")
        state["currentTranscript"]["sha256"] = hashlib.sha256(
            transcript_text.encode("utf-8")
        ).hexdigest()
        state["currentTranscript"]["status"] = "interrupted"
        write_state(state)
        raise ReviewError(f"difit interrupted: {error}; transcript: {transcript}") from error
    transcript_text = transcript.read_text(encoding="utf-8")
    state["currentTranscript"]["sha256"] = hashlib.sha256(
        transcript_text.encode("utf-8")
    ).hexdigest()
    if controlled_shutdown and return_code == -15:
        return_code = 0
    state["currentTranscript"]["status"] = "completed" if return_code == 0 else "failed"
    if return_code != 0:
        write_state(state)
        raise ReviewError(f"difit exited with status {return_code}; transcript: {transcript}")
    state["active"] = {"base": args.base, "target": args.target, "key": key}
    thread_sets = state.setdefault("commentThreads", {})
    if not isinstance(thread_sets, dict):
        raise ReviewError("invalid comment threads in review state")
    known_threads = thread_sets.setdefault(key, [])
    if not isinstance(known_threads, list):
        raise ReviewError("invalid comparison comment threads in review state")
    known_ids = {item.get("id") for item in known_threads if isinstance(item, dict)}
    for item in comments:
        if item["type"] == "thread" and item.get("id") not in known_ids:
            known_threads.append(item)
            known_ids.add(item.get("id"))
    state["activeComments"] = known_threads
    message_sets = state.setdefault("agentMessages", {})
    if not isinstance(message_sets, dict):
        raise ReviewError("invalid agent messages in review state")
    known_messages = message_sets.setdefault(key, [])
    if not isinstance(known_messages, list):
        raise ReviewError("invalid comparison agent messages in review state")
    known_message_keys = {
        json.dumps(item, ensure_ascii=False, sort_keys=True)
        for item in known_messages
        if isinstance(item, dict)
    }
    for item in comments:
        message = {
            "commentedBy": "agent",
            "type": item["type"],
            "filePath": item["filePath"],
            "position": item["position"],
            "body": item["body"],
        }
        message_key = json.dumps(message, ensure_ascii=False, sort_keys=True)
        if message_key not in known_message_keys:
            known_messages.append(message)
            known_message_keys.add(message_key)
    state["activeAgentMessages"] = known_messages
    if key not in comparisons:
        comparisons.append(key)
    write_state(state)
    print(json.dumps({"transcript": str(transcript), "base": args.base, "target": args.target}, ensure_ascii=False))


def review_section(text: str) -> str:
    header = "📝 Comments from review session:"
    if text.count(header) > 1:
        raise ReviewError("difit transcript contains an ambiguous review header")
    start = text.find(header)
    if start < 0:
        raise ReviewError("difit transcript has no review comment section")
    section = text[start + len(header) :]
    border = "=" * 50
    if section.count(border) != 2:
        raise ReviewError("difit transcript contains ambiguous comment boundaries")
    first = section.find(border)
    last = section.rfind(border)
    if first < 0 or last <= first:
        raise ReviewError("cannot locate difit comment boundaries")
    content = section[first + len(border) : last].strip("\n")
    footer = section[last + len(border) :]
    totals = re.findall(r"(?:^|\n)Total comments: ([0-9]+)(?:\n|$)", footer)
    if len(totals) != 1:
        raise ReviewError("difit transcript has no unique comment count")
    blocks = [] if not content else content.split("\n=====\n")
    if int(totals[0]) != len(blocks):
        raise ReviewError("difit transcript comment count does not match its thread blocks")
    return content


def split_messages(block: str) -> list[tuple[int, str | None, str]]:
    lines = block.splitlines()
    if len(lines) < 2:
        return []
    messages: list[tuple[int, str | None, list[str]]] = [(0, None, [])]
    for line in lines[1:]:
        match = REPLY_RE.match(line)
        if match:
            messages.append((int(match.group(1)), match.group(2), []))
        else:
            messages[-1][2].append(line)
    return [
        (index, author, "\n".join(body).strip())
        for index, author, body in messages
        if "\n".join(body).strip()
    ]


def signature(comparison_key: str, position: str, message_index: int, body: str) -> str:
    payload = json.dumps(
        {
            "comparisonKey": comparison_key,
            "position": position,
            "messageIndex": message_index,
            "body": body,
        },
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def extract_candidates(
    text: str,
    processed: set[str],
    active_comments: list[dict[str, Any]],
    agent_messages: list[dict[str, Any]],
    comparison_key: str,
) -> list[dict[str, Any]]:
    section = review_section(text)
    if not section:
        return []
    candidates: list[dict[str, Any]] = []
    blocks = section.split("\n=====\n")
    labels = [block.splitlines()[0].strip() for block in blocks if block.splitlines()]
    if len(labels) != len(set(labels)):
        raise ReviewError("difit output has multiple threads at one displayed position")
    known_by_label: dict[str, dict[str, Any]] = {}
    for item in active_comments:
        line = item["position"]["line"]
        line_label = f"L{line['start']}-L{line['end']}" if isinstance(line, dict) else f"L{line}"
        known_by_label[f"{item['filePath']}:{line_label}"] = item
    agent_root_bodies_by_label: dict[str, set[str]] = {}
    agent_reply_bodies_by_label: dict[str, set[str]] = {}
    for item in agent_messages:
        line = item["position"]["line"]
        line_label = f"L{line['start']}-L{line['end']}" if isinstance(line, dict) else f"L{line}"
        label = f"{item['filePath']}:{line_label}"
        if item.get("type") == "thread":
            agent_root_bodies_by_label.setdefault(label, set()).add(item["body"])
        elif item.get("type") == "reply":
            agent_reply_bodies_by_label.setdefault(label, set()).add(item["body"])
    for block in blocks:
        lines = block.splitlines()
        if not lines:
            continue
        position = lines[0].strip()
        known = known_by_label.get(position)
        identity = position
        reply_position = None
        if known is not None:
            reply_position = known["position"]
            identity = json.dumps(
                {"filePath": known["filePath"], "position": reply_position, "threadId": known.get("id")},
                sort_keys=True,
                separators=(",", ":"),
            )
        for message_index, author, body in split_messages(block):
            known_agent_root = (
                message_index == 0
                and body in agent_root_bodies_by_label.get(position, set())
            )
            known_agent_reply = (
                message_index > 0
                and author == "agent"
                and body in agent_reply_bodies_by_label.get(position, set())
            )
            if known_agent_root or known_agent_reply:
                continue
            value = signature(comparison_key, identity, message_index, body)
            if value in processed:
                continue
            candidates.append(
                {
                    "position": position,
                    "filePath": known["filePath"] if known is not None else None,
                    "replyPosition": reply_position,
                    "threadId": known.get("id") if known is not None else None,
                    "messageIndex": message_index,
                    "body": body,
                    "signature": value,
                }
            )
    return candidates


def command_extract(args: argparse.Namespace) -> None:
    state = read_state()
    current = state.get("currentTranscript")
    if not isinstance(current, dict) or current.get("deleted"):
        raise ReviewError("there is no current difit transcript to extract")
    if current.get("status") != "completed":
        raise ReviewError("incomplete difit transcript must be inspected and explicitly discarded")
    if args.transcript.resolve() != Path(str(current.get("path"))).resolve():
        raise ReviewError("transcript does not match the current difit run")
    try:
        text = args.transcript.read_text(encoding="utf-8")
    except OSError as error:
        raise ReviewError(f"cannot read transcript: {error}") from error
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    if digest != current.get("sha256"):
        current["status"] = "unreadable"
        write_state(state)
        raise ReviewError("current difit transcript content changed")
    processed_value = state.get("processedSignatures", [])
    if not isinstance(processed_value, list):
        raise ReviewError("invalid processed signatures in review state")
    active_comments = state.get("activeComments", [])
    if not isinstance(active_comments, list):
        raise ReviewError("invalid active comments in review state")
    agent_messages = state.get("activeAgentMessages", [])
    if not isinstance(agent_messages, list):
        raise ReviewError("invalid active agent messages in review state")
    try:
        candidates = extract_candidates(
            text,
            set(processed_value),
            active_comments,
            agent_messages,
            f"{current.get('base')}:{current.get('target')}",
        )
    except ReviewError:
        current["status"] = "unreadable"
        write_state(state)
        raise
    state["lastExtract"] = {
        "transcriptSha256": digest,
        "candidateSignatures": [item["signature"] for item in candidates],
    }
    current["extracted"] = True
    current["empty"] = candidates == []
    write_state(state)
    print(json.dumps({"candidates": candidates}, ensure_ascii=False, indent=2))


def command_acknowledge(args: argparse.Namespace) -> None:
    state = read_state()
    last_extract = state.get("lastExtract")
    if not isinstance(last_extract, dict):
        raise ReviewError("extract the current transcript before acknowledging messages")
    candidates = last_extract.get("candidateSignatures")
    if not isinstance(candidates, list):
        raise ReviewError("invalid extracted candidate signatures in review state")
    processed = state.setdefault("processedSignatures", [])
    if not isinstance(processed, list):
        raise ReviewError("invalid processed signatures in review state")
    for value in args.signatures:
        if not re.fullmatch(r"[0-9a-f]{64}", value):
            raise ReviewError(f"invalid signature: {value}")
        if value not in candidates:
            raise ReviewError(f"signature is not in the current extraction: {value}")
        if value not in processed:
            processed.append(value)
    write_state(state)


def command_reviewed(_args: argparse.Namespace) -> None:
    require_clean()
    state = read_state()
    active = state.get("active")
    if not isinstance(active, dict) or not isinstance(active.get("target"), str):
        raise ReviewError("there is no active review range")
    transcript = state.get("currentTranscript")
    if (
        not isinstance(transcript, dict)
        or transcript.get("deleted")
        or not transcript.get("extracted")
        or transcript.get("base") != active.get("base")
        or transcript.get("target") != active.get("target")
    ):
        raise ReviewError("extract the active transcript before marking it reviewed")
    path = Path(str(transcript.get("path")))
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as error:
        raise ReviewError(f"cannot read transcript before marking reviewed: {error}") from error
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    last_extract = state.get("lastExtract")
    if (
        digest != transcript.get("sha256")
        or not isinstance(last_extract, dict)
        or last_extract.get("transcriptSha256") != digest
    ):
        transcript["status"] = "unreadable"
        write_state(state)
        raise ReviewError("active transcript extraction is stale or changed")
    current = checkpoint("HEAD")
    if current["tree"] != active["target"]:
        raise ReviewError("HEAD tree no longer matches the active review target")
    state["lastReview"] = current
    state["active"]["reviewed"] = True
    write_state(state)


def command_discard_transcript(args: argparse.Namespace) -> None:
    state = read_state()
    path = args.transcript.resolve()
    temporary_root = Path(tempfile.gettempdir()).resolve()
    if path.parent != temporary_root or not path.name.startswith("difit-review-"):
        raise ReviewError("refusing to delete a transcript outside the managed temporary path")
    current = state.get("currentTranscript")
    if not isinstance(current, dict) or path != Path(str(current.get("path"))).resolve():
        raise ReviewError("transcript does not match the current difit run")
    incomplete = current.get("status") != "completed"
    if incomplete and not args.allow_incomplete:
        raise ReviewError("inspect the incomplete transcript and pass --allow-incomplete to discard it")
    if current.get("status") == "running":
        process_group = current.get("processGroup")
        if not isinstance(process_group, int) or process_group <= 0:
            raise ReviewError("running transcript has no verifiable process group; stop for human recovery")
        try:
            os.killpg(process_group, 0)
        except ProcessLookupError:
            pass
        except PermissionError as error:
            raise ReviewError("cannot verify the running difit process group") from error
        else:
            raise ReviewError("difit process group is still running; stop it before discarding")
    if not incomplete and not current.get("extracted"):
        raise ReviewError("extract the current transcript before discarding it")
    if not incomplete:
        last_extract = state.get("lastExtract")
        processed = state.get("processedSignatures", [])
        if not isinstance(last_extract, dict) or not isinstance(processed, list):
            raise ReviewError("invalid extracted message state")
        pending = set(last_extract.get("candidateSignatures", [])) - set(processed)
        if pending:
            raise ReviewError("acknowledge every extracted human message before discarding")
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as error:
        raise ReviewError(f"cannot read transcript before deletion: {error}") from error
    if (
        current.get("status") not in ("running", "unreadable")
        and hashlib.sha256(text.encode("utf-8")).hexdigest() != current.get("sha256")
    ):
        raise ReviewError("current difit transcript content changed")
    path.unlink()
    current["deleted"] = True
    write_state(state)


def command_complete(_args: argparse.Namespace) -> None:
    require_clean()
    state = read_state()
    last_extract = state.get("lastExtract")
    if not isinstance(last_extract, dict) or last_extract.get("candidateSignatures") != []:
        raise ReviewError("the latest extraction must contain zero new human messages")
    active = state.get("active")
    if not isinstance(active, dict) or not active.get("reviewed"):
        raise ReviewError("the active difit range has not been marked reviewed")
    current = state.get("currentTranscript")
    if not isinstance(current, dict) or not current.get("empty") or not current.get("deleted"):
        raise ReviewError("the current empty transcript must be extracted and deleted")
    if current.get("base") != active.get("base") or current.get("target") != active.get("target"):
        raise ReviewError("the current transcript does not match the active difit range")
    if checkpoint("HEAD")["tree"] != active.get("target"):
        raise ReviewError("HEAD tree no longer matches the reviewed target")
    state_path().unlink()


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(description=__doc__)
    commands = value.add_subparsers(dest="command", required=True)

    init = commands.add_parser("init")
    init.add_argument("--base", required=True)
    init.add_argument("--target", required=True)
    init.set_defaults(handler=command_init)

    next_command = commands.add_parser("next")
    next_command.set_defaults(handler=command_next)

    retarget = commands.add_parser("retarget")
    retarget.add_argument("--target", required=True)
    retarget.set_defaults(handler=command_retarget)

    validated = commands.add_parser("validated")
    validated.add_argument("--base", required=True)
    validated.add_argument("--target", required=True)
    validated.add_argument("--risk", choices=("normal", "high"), required=True)
    validated.add_argument("--normal-check", action="append", required=True)
    validated.add_argument("--subagent", action="append", required=True)
    validated.set_defaults(handler=command_validated)

    run = commands.add_parser("run")
    run.add_argument("--target", required=True)
    run.add_argument("--base", required=True)
    run.add_argument("--comments", type=Path, required=True)
    run.add_argument("--clean", action="store_true")
    run.set_defaults(handler=command_run)

    extract = commands.add_parser("extract")
    extract.add_argument("--transcript", type=Path, required=True)
    extract.set_defaults(handler=command_extract)

    acknowledge = commands.add_parser("acknowledge")
    acknowledge.add_argument("signatures", nargs="+")
    acknowledge.set_defaults(handler=command_acknowledge)

    reviewed = commands.add_parser("reviewed")
    reviewed.set_defaults(handler=command_reviewed)

    discard = commands.add_parser("discard-transcript")
    discard.add_argument("--transcript", type=Path, required=True)
    discard.add_argument("--allow-incomplete", action="store_true")
    discard.set_defaults(handler=command_discard_transcript)

    complete = commands.add_parser("complete")
    complete.set_defaults(handler=command_complete)
    return value


def main() -> int:
    try:
        arguments = parser().parse_args()
        arguments.handler(arguments)
    except ReviewError as error:
        print(f"review: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
