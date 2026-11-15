from common import load_config, run, stop
from runtime import locked_runtime, owned_entry


def main(payload):
    load_config(payload)
    with locked_runtime(payload) as state:
        entry = owned_entry(state, payload)
        if entry["phase"] not in ("reserved", "running", "unknown"):
            stop("claim does not need reconciliation")
        if entry["child"] != payload.get("child") or payload.get("childTerminated") is not True:
            stop("native child termination is unconfirmed")
        checks = payload.get("writeChecks", {})
        if not isinstance(checks, dict):
            stop("writeChecks must be an object", "error")
        unresolved = [k for k in entry["unknownWrites"] if checks.get(k) not in ("observed", "not-written")]
        if unresolved:
            stop("unknown writes require adapter reconciliation: " + ", ".join(unresolved))
        if entry["phase"] == "reserved" and payload.get("launchAbsent") is not True:
            stop("reservation requires confirmed absent native launch")
        entry.update(phase="stopped", unknownWrites=[])
    return {"claim": payload["claim"], "phase": "stopped"}


if __name__ == "__main__":
    run(main)
