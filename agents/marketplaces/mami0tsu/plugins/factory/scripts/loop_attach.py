from common import load_config, run, stop
from runtime import locked_runtime, owned_entry


def main(payload):
    load_config(payload)
    child = payload.get("child")
    if not isinstance(child, str) or not child:
        stop("native child ID is required", "error")
    with locked_runtime(payload) as state:
        entry = owned_entry(state, payload)
        if entry["phase"] != "reserved" or entry["child"] is not None:
            stop("reservation already has a child")
        entry.update(child=child, phase="running")
    return {"claim": payload["claim"], "child": child}


if __name__ == "__main__":
    run(main)
