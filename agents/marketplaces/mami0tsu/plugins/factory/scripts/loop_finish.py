import time
from common import load_config, run, stop
from runtime import locked_runtime, owned_entry


def main(payload):
    load_config(payload)
    result = payload.get("result", {})
    if not isinstance(result, dict) or result.get("status") not in ("success", "wait", "error"):
        stop("worker result is required", "error")
    writes = payload.get("unknownWrites", [])
    if not isinstance(writes, list) or any(not isinstance(k, str) or not k for k in writes):
        stop("unknownWrites must contain stable write keys", "error")
    with locked_runtime(payload) as state:
        entry = owned_entry(state, payload)
        if entry["phase"] not in ("running", "unknown") or not entry["child"]:
            stop("claim is already closed")
        if entry["child"] != payload.get("child"):
            stop("native child does not match", "error")
        entry["unknownWrites"] = sorted(set(entry["unknownWrites"] + writes))
        entry["result"] = result
        confirmed = payload.get("childTerminated") is True
        if not confirmed or entry["unknownWrites"]:
            entry["phase"] = "unknown"
        elif result["status"] == "wait" and payload.get("humanWait") is True:
            entry["phase"] = "waiting"
        elif result["status"] == "success":
            entry["phase"] = "done"
        else:
            entry["phase"] = "stopped"
        if entry["phase"] == "done":
            entry["finishedAt"] = time.time()
        phase = entry["phase"]
    return {"claim": payload["claim"], "phase": phase, "status": "wait" if phase == "unknown" else "success"}


if __name__ == "__main__":
    run(main)
