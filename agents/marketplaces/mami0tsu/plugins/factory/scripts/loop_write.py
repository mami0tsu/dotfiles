from common import load_config, run, stop
from runtime import locked_runtime, owned_entry


def main(payload):
    load_config(payload)
    key = payload.get("key")
    if not isinstance(key, str) or not key:
        stop("stable write key is required", "error")
    operation = payload.get("operation")
    if operation not in ("begin", "observed", "not-written"):
        stop("invalid write observation", "error")
    with locked_runtime(payload) as state:
        entry = owned_entry(state, payload)
        if entry["phase"] != "running" or entry["child"] != payload.get("child"):
            stop("write requires the active native child")
        pending = set(entry["unknownWrites"])
        if operation == "begin":
            if key in pending:
                stop("write outcome is unknown; reconcile before retry")
            pending.add(key)
        else:
            if key not in pending:
                stop("write intent is absent", "error")
            pending.remove(key)
        entry["unknownWrites"] = sorted(pending)
    return {"key": key, "operation": operation}


if __name__ == "__main__":
    run(main)
