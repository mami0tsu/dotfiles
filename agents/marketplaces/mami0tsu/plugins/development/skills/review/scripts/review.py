#!/usr/bin/env python3
"""Keep local difit review checkpoints and classify review messages."""

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
from typing import Any


STATE_NAME = "review-state.json"
SCHEMA_VERSION = 1
REPLY_RE = re.compile(r"^Reply ([1-9][0-9]*) \((.*)\)$")


class ReviewError(RuntimeError):
    pass


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


def repository_root() -> Path:
    return Path(git("rev-parse", "--show-toplevel"))


def state_path() -> Path:
    value = git("rev-parse", "--git-path", STATE_NAME)
    path = Path(value)
    if not path.is_absolute():
        path = repository_root() / path
    return path.resolve()


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
    path = state_path()
    if path.exists():
        raise ReviewError(f"review state already exists: {path}")
    base = checkpoint(args.base or "HEAD")
    write_state(
        {
            "schemaVersion": SCHEMA_VERSION,
            "base": base,
            "lastReview": None,
            "active": None,
            "comparisons": [],
            "commentThreads": {},
            "agentMessages": {},
            "processedSignatures": [],
            "lastExtract": None,
        }
    )
    print(json.dumps({"state": str(path), "base": base}, ensure_ascii=False))


def next_selection(state: dict[str, Any]) -> dict[str, Any]:
    base_checkpoint = state.get("lastReview") or state.get("base")
    if not isinstance(base_checkpoint, dict):
        raise ReviewError("review state has no base checkpoint")
    validate_checkpoint(base_checkpoint)
    target_checkpoint = checkpoint("HEAD")
    key = f"{base_checkpoint['tree']}:{target_checkpoint['tree']}"
    comparisons = state.get("comparisons", [])
    if not isinstance(comparisons, list):
        raise ReviewError("invalid comparisons in review state")
    return {
        "base": base_checkpoint["tree"],
        "target": target_checkpoint["tree"],
        "baseTitle": base_checkpoint["title"],
        "targetTitle": target_checkpoint["title"],
        "clean": key not in comparisons,
        "key": key,
    }


def command_next(_args: argparse.Namespace) -> None:
    require_clean()
    print(json.dumps(next_selection(read_state()), ensure_ascii=False))


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
        help_result = subprocess.run(
            [executable, "--help"], capture_output=True, text=True, check=False
        )
        required = ("--comment", "--clean")
        if help_result.returncode != 0 or any(item not in help_result.stdout for item in required):
            raise ReviewError(f"difit {version} does not expose required options")
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
        if not isinstance(item.get("filePath"), str) or not isinstance(item.get("position"), dict):
            raise ReviewError(f"comment {index} has no diff position")
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
            copy.setdefault("id", "agent-" + hashlib.sha256(
                json.dumps(
                    {"filePath": copy["filePath"], "position": copy["position"], "body": clean_body},
                    ensure_ascii=False,
                    sort_keys=True,
                ).encode("utf-8")
            ).hexdigest()[:24])
        output.append(copy)
    return output


def new_transcript_path() -> Path:
    descriptor, name = tempfile.mkstemp(prefix="difit-review-", suffix=".log")
    os.fchmod(descriptor, stat.S_IRUSR | stat.S_IWUSR)
    os.close(descriptor)
    return Path(name)


def command_run(args: argparse.Namespace) -> None:
    require_clean()
    state = read_state()
    current_transcript = state.get("currentTranscript")
    if isinstance(current_transcript, dict) and not current_transcript.get("deleted"):
        raise ReviewError("extract and discard the current transcript before another run")
    selection = next_selection(state)
    if args.target != selection["target"] or args.base != selection["base"]:
        active = state.get("active")
        allowed_active = (
            isinstance(active, dict)
            and args.target == active.get("target")
            and args.base == active.get("base")
        )
        if not allowed_active:
            raise ReviewError("requested comparison does not match next or active review range")
    expected_clean = selection["clean"] if args.target == selection["target"] and args.base == selection["base"] else False
    if args.clean != expected_clean:
        raise ReviewError(f"--clean must be {'present' if expected_clean else 'absent'} for this range")

    comments = load_comments(args.comments)
    executable = validate_difit()
    transcript = new_transcript_path()
    command = [executable, args.target, args.base]
    if args.clean:
        command.append("--clean")
    if comments:
        command.extend(["--comment", json.dumps(comments, ensure_ascii=False, separators=(",", ":"))])

    with transcript.open("w", encoding="utf-8") as output:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        assert process.stdout is not None
        for line in process.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()
            output.write(line)
            output.flush()
        return_code = process.wait()
    if return_code != 0:
        raise ReviewError(f"difit exited with status {return_code}; transcript: {transcript}")

    key = f"{args.base}:{args.target}"
    comparisons = state.setdefault("comparisons", [])
    if key not in comparisons:
        comparisons.append(key)
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
    transcript_text = transcript.read_text(encoding="utf-8")
    state["currentTranscript"] = {
        "path": str(transcript.resolve()),
        "sha256": hashlib.sha256(transcript_text.encode("utf-8")).hexdigest(),
        "base": args.base,
        "target": args.target,
        "extracted": False,
        "empty": False,
        "deleted": False,
    }
    state["lastExtract"] = None
    write_state(state)
    print(json.dumps({"transcript": str(transcript), "base": args.base, "target": args.target}, ensure_ascii=False))


def review_section(text: str) -> str:
    header = "📝 Comments from review session:"
    start = text.rfind(header)
    if start < 0:
        raise ReviewError("difit review header is missing from the current transcript")
    section = text[start + len(header) :]
    border = "=" * 50
    first = section.find(border)
    last = section.rfind(border)
    if first < 0 or last <= first:
        raise ReviewError("cannot locate difit comment boundaries")
    return section[first + len(border) : last].strip("\n")


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


def signature(position: str, message_index: int, body: str) -> str:
    payload = json.dumps(
        {"position": position, "messageIndex": message_index, "body": body},
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
    for item in agent_messages:
        if item.get("type") != "thread":
            continue
        line = item["position"]["line"]
        line_label = f"L{line['start']}-L{line['end']}" if isinstance(line, dict) else f"L{line}"
        label = f"{item['filePath']}:{line_label}"
        agent_root_bodies_by_label.setdefault(label, set()).add(item["body"])
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
            if known_agent_root or author == "agent":
                continue
            value = signature(identity, message_index, body)
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
    if args.transcript.resolve() != Path(str(current.get("path"))).resolve():
        raise ReviewError("transcript does not match the current difit run")
    try:
        text = args.transcript.read_text(encoding="utf-8")
    except OSError as error:
        raise ReviewError(f"cannot read transcript: {error}") from error
    processed_value = state.get("processedSignatures", [])
    if not isinstance(processed_value, list):
        raise ReviewError("invalid processed signatures in review state")
    active_comments = state.get("activeComments", [])
    if not isinstance(active_comments, list):
        raise ReviewError("invalid active comments in review state")
    agent_messages = state.get("activeAgentMessages", [])
    if not isinstance(agent_messages, list):
        raise ReviewError("invalid active agent messages in review state")
    candidates = extract_candidates(
        text, set(processed_value), active_comments, agent_messages
    )
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    if digest != current.get("sha256"):
        raise ReviewError("current difit transcript content changed")
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
    processed = state.setdefault("processedSignatures", [])
    if not isinstance(processed, list):
        raise ReviewError("invalid processed signatures in review state")
    for value in args.signatures:
        if not re.fullmatch(r"[0-9a-f]{64}", value):
            raise ReviewError(f"invalid signature: {value}")
        if value not in processed:
            processed.append(value)
    write_state(state)


def command_reviewed(_args: argparse.Namespace) -> None:
    require_clean()
    state = read_state()
    active = state.get("active")
    if not isinstance(active, dict) or not isinstance(active.get("target"), str):
        raise ReviewError("there is no active review range")
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
    if not current.get("extracted"):
        raise ReviewError("extract the current transcript before discarding it")
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as error:
        raise ReviewError(f"cannot read transcript before deletion: {error}") from error
    if hashlib.sha256(text.encode("utf-8")).hexdigest() != current.get("sha256"):
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
    state_path().unlink()


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(description=__doc__)
    commands = value.add_subparsers(dest="command", required=True)

    init = commands.add_parser("init")
    init.add_argument("--base")
    init.set_defaults(handler=command_init)

    next_command = commands.add_parser("next")
    next_command.set_defaults(handler=command_next)

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
