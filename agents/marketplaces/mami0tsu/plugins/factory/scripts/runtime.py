from contextlib import contextmanager
import fcntl
import json
import os
import tempfile
from common import config_path, stop


@contextmanager
def locked_runtime(payload):
    config = config_path(payload)
    path = config.with_name("." + config.name + ".runtime.json")
    with open(str(path) + ".lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = json.loads(path.read_text()) if path.exists() else {"entries": {}}
        if not isinstance(state, dict) or not isinstance(state.get("entries"), dict):
            stop("invalid runtime record", "error")
        yield state
        name = None
        try:
            with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as tmp:
                name = tmp.name
                json.dump(state, tmp, sort_keys=True, ensure_ascii=False)
                tmp.write("\n")
                tmp.flush()
                os.fsync(tmp.fileno())
            os.replace(name, path)
            name = None
            directory = os.open(path.parent, os.O_DIRECTORY)
            try:
                os.fsync(directory)
            finally:
                os.close(directory)
        finally:
            if name:
                os.unlink(name)


def owned_entry(state, payload):
    entry = state["entries"].get(payload.get("claim"))
    if not entry or entry["token"] != payload.get("token"):
        stop("claim ownership does not match", "error")
    return entry


def active(entry):
    return entry["phase"] in ("reserved", "running", "unknown")
