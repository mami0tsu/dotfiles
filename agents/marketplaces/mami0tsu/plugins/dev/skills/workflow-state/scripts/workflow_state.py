#!/usr/bin/env python3
"""Persist one resumable workflow state in a repository's common Git directory."""

from __future__ import annotations

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import time
from typing import Any, Iterator
from contextlib import contextmanager


SCHEMA_VERSION = 1
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")
NAMESPACE_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
FORBIDDEN_SECRET_KEY_PARTS = (
    "token",
    "secret",
    "password",
    "credential",
    "apikey",
    "authorization",
    "authheader",
)
FORBIDDEN_TEXT_KEYS = (
    "body",
    "comment",
    "message",
    "content",
    "review",
    "text",
    "reviewbody",
    "commentbody",
    "reviewtext",
    "commenttext",
)
LOCK_TIMEOUT_SECONDS = 10.0
LOCK_RETRY_SECONDS = 0.05


class WorkflowStateError(RuntimeError):
    pass


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise WorkflowStateError(f"git {' '.join(args)} failed: {detail}")
    return result.stdout.strip()


def repository_identity() -> dict[str, str]:
    root = Path(git("rev-parse", "--show-toplevel")).resolve()
    common = Path(git("rev-parse", "--git-common-dir"))
    if not common.is_absolute():
        common = root / common
    common = common.resolve()
    return {"commonDir": str(common)}


def state_directory() -> Path:
    return Path(repository_identity()["commonDir"]) / "agent-workflows"


def validate_identifier(value: str) -> str:
    if not ID_RE.fullmatch(value):
        raise WorkflowStateError("workflow ID must contain only letters, digits, dot, underscore, or hyphen")
    return value


def state_path(workflow_id: str) -> Path:
    return state_directory() / f"{validate_identifier(workflow_id)}.json"


def lock_path(workflow_id: str) -> Path:
    return state_directory() / f"{validate_identifier(workflow_id)}.lock"


@contextmanager
def locked(workflow_id: str) -> Iterator[None]:
    directory = state_directory()
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(directory, 0o700)
    descriptor = os.open(lock_path(workflow_id), os.O_RDWR | os.O_CREAT, 0o600)
    try:
        deadline = time.monotonic() + LOCK_TIMEOUT_SECONDS
        while True:
            try:
                fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise WorkflowStateError("workflow state lock timed out")
                time.sleep(LOCK_RETRY_SECONDS)
        yield
    finally:
        fcntl.flock(descriptor, fcntl.LOCK_UN)
        os.close(descriptor)


def atomic_write(path: Path, value: dict[str, Any]) -> None:
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, stat.S_IRUSR | stat.S_IWUSR)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(value, handle, ensure_ascii=False, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
        directory_descriptor = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_descriptor)
        finally:
            os.close(directory_descriptor)
    finally:
        if temporary.exists():
            temporary.unlink()


def read_state_unlocked(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise WorkflowStateError(f"workflow state does not exist: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise WorkflowStateError(f"cannot read workflow state: {error}") from error
    if not isinstance(value, dict) or value.get("schemaVersion") != SCHEMA_VERSION:
        raise WorkflowStateError("unsupported workflow state schema")
    return value


def ensure_clean() -> None:
    if git("status", "--porcelain=v1", "--untracked-files=all"):
        raise WorkflowStateError("worktree is not clean, including untracked files")


def current_branch() -> str:
    branch = git("symbolic-ref", "--quiet", "--short", "HEAD")
    if not branch:
        raise WorkflowStateError("detached HEAD cannot initialize a workflow")
    return branch


def resolve_commit(value: str) -> str:
    return git("rev-parse", "--verify", f"{value}^{{commit}}")


def forbidden_path(value: Any, path: tuple[str, ...] = ()) -> str | None:
    if isinstance(value, dict):
        for key, child in value.items():
            if not isinstance(key, str):
                return ".".join((*path, "<non-string>"))
            normalized = re.sub(r"[^a-z0-9]", "", key.lower())
            if (
                any(part in normalized for part in FORBIDDEN_SECRET_KEY_PARTS)
                or normalized in FORBIDDEN_TEXT_KEYS
            ):
                return ".".join((*path, key))
            found = forbidden_path(child, (*path, key))
            if found:
                return found
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found = forbidden_path(child, (*path, str(index)))
            if found:
                return found
    return None


def command_init(args: argparse.Namespace) -> None:
    ensure_clean()
    repository = repository_identity()
    branch = current_branch()
    start_commit = resolve_commit(args.start_commit or "HEAD")
    path = state_path(args.workflow_id)
    with locked(args.workflow_id):
        if path.exists():
            raise WorkflowStateError(f"workflow state already exists: {path}")
        value = {
            "schemaVersion": SCHEMA_VERSION,
            "identity": {
                "repository": repository,
                "workflow": args.workflow,
                "subjectKind": args.subject_kind,
                "subject": args.subject,
                "branch": branch,
                "startCommit": start_commit,
            },
            "namespaces": {},
        }
        atomic_write(path, value)
    print(json.dumps({"state": str(path), "identity": value["identity"]}, ensure_ascii=False))


def command_verify(args: argparse.Namespace) -> None:
    path = state_path(args.workflow_id)
    with locked(args.workflow_id):
        value = read_state_unlocked(path)
    identity = value.get("identity")
    expected = {
        "repository": repository_identity(),
        "workflow": args.workflow,
        "subjectKind": args.subject_kind,
        "subject": args.subject,
        "branch": args.branch,
        "startCommit": resolve_commit(args.start_commit),
    }
    if identity != expected:
        raise WorkflowStateError("workflow identity does not match the repository or requested work")
    print(json.dumps({"state": str(path), "identity": identity}, ensure_ascii=False))


def command_show(args: argparse.Namespace) -> None:
    path = state_path(args.workflow_id)
    with locked(args.workflow_id):
        value = read_state_unlocked(path)
    namespaces = value.get("namespaces")
    if not isinstance(namespaces, dict):
        raise WorkflowStateError("workflow state has invalid namespaces")
    print(json.dumps(
        {"state": str(path), "identity": value.get("identity"), "namespaces": sorted(namespaces)},
        ensure_ascii=False,
    ))


def read_private_object(path: Path) -> dict[str, Any]:
    metadata = path.stat()
    if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid():
        raise WorkflowStateError("value file must be a regular file owned by the current user")
    if stat.S_IMODE(metadata.st_mode) & 0o077:
        raise WorkflowStateError("value file permissions must not allow group or other access")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise WorkflowStateError(f"cannot read value file: {error}") from error
    if not isinstance(value, dict):
        raise WorkflowStateError("namespace value must be a JSON object")
    found = forbidden_path(value)
    if found:
        raise WorkflowStateError(f"namespace contains a forbidden field: {found}")
    return value


def validate_namespace(value: str) -> str:
    if not NAMESPACE_RE.fullmatch(value):
        raise WorkflowStateError("namespace must use lowercase letters, digits, and hyphens")
    return value


def command_put(args: argparse.Namespace) -> None:
    namespace = validate_namespace(args.namespace)
    content = read_private_object(Path(args.value_file))
    path = state_path(args.workflow_id)
    with locked(args.workflow_id):
        state = read_state_unlocked(path)
        namespaces = state.get("namespaces")
        if not isinstance(namespaces, dict):
            raise WorkflowStateError("workflow state has invalid namespaces")
        namespaces[namespace] = content
        atomic_write(path, state)
    print(json.dumps({"state": str(path), "namespace": namespace}, ensure_ascii=False))


def command_get(args: argparse.Namespace) -> None:
    namespace = validate_namespace(args.namespace)
    path = state_path(args.workflow_id)
    with locked(args.workflow_id):
        state = read_state_unlocked(path)
    namespaces = state.get("namespaces")
    if not isinstance(namespaces, dict) or namespace not in namespaces:
        raise WorkflowStateError(f"namespace does not exist: {namespace}")
    print(json.dumps(namespaces[namespace], ensure_ascii=False, sort_keys=True))


def command_complete(args: argparse.Namespace) -> None:
    path = state_path(args.workflow_id)
    with locked(args.workflow_id):
        read_state_unlocked(path)
        path.unlink()
    print(json.dumps({"completed": args.workflow_id}, ensure_ascii=False))


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="command", required=True)

    initialize = subparsers.add_parser("init")
    initialize.add_argument("--workflow-id", required=True)
    initialize.add_argument("--workflow", required=True)
    initialize.add_argument("--subject-kind", choices=("ticket", "pr"), required=True)
    initialize.add_argument("--subject", required=True)
    initialize.add_argument("--start-commit")
    initialize.set_defaults(handler=command_init)

    verify = subparsers.add_parser("verify")
    verify.add_argument("--workflow-id", required=True)
    verify.add_argument("--workflow", required=True)
    verify.add_argument("--subject-kind", choices=("ticket", "pr"), required=True)
    verify.add_argument("--subject", required=True)
    verify.add_argument("--branch", required=True)
    verify.add_argument("--start-commit", required=True)
    verify.set_defaults(handler=command_verify)

    show = subparsers.add_parser("show")
    show.add_argument("--workflow-id", required=True)
    show.set_defaults(handler=command_show)

    put = subparsers.add_parser("put")
    put.add_argument("--workflow-id", required=True)
    put.add_argument("--namespace", required=True)
    put.add_argument("--value-file", required=True)
    put.set_defaults(handler=command_put)

    get = subparsers.add_parser("get")
    get.add_argument("--workflow-id", required=True)
    get.add_argument("--namespace", required=True)
    get.set_defaults(handler=command_get)

    complete = subparsers.add_parser("complete")
    complete.add_argument("--workflow-id", required=True)
    complete.set_defaults(handler=command_complete)
    return result


def main() -> int:
    try:
        args = parser().parse_args()
        args.handler(args)
    except (WorkflowStateError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
