import secrets
from common import load_config, require_ref, run, stable_key, stop, worker_input
from runtime import active, locked_runtime


def main(payload):
    config = load_config(payload)
    skill = payload.get("skill")
    if skill not in config["loop"]["skills"]:
        stop("unknown worker", "error")
    target = require_ref(payload.get("target"), revision=False)
    step = payload.get("step")
    if not isinstance(step, str) or not step:
        stop("step is required", "error")
    supplied, refs = payload.get("input", {}), payload.get("refs", {})
    if not isinstance(supplied, dict) or not isinstance(refs, dict):
        stop("worker input and refs must be objects", "error")
    inputs = worker_input(payload, supplied)
    identity = stable_key(target["url"])
    claim = stable_key(skill, target["url"], target.get("revision"), step)
    with locked_runtime(payload) as state:
        entries = state["entries"]
        current = [e for e in entries.values() if active(e)]
        if any(e["identity"] == identity for e in current):
            stop("target is already active")
        if len(current) >= config["loop"]["concurrency"]:
            stop("global concurrency limit reached")
        if sum(e["skill"] == skill for e in current) >= config["loop"]["skills"][skill]["concurrency"]:
            stop("worker concurrency limit reached")
        if claim in entries and entries[claim]["phase"] == "done":
            stop("this target revision and step are already complete")
        entry = {"skill": skill, "target": target, "step": step, "identity": identity,
                 "input": inputs, "refs": refs,
                 "token": secrets.token_hex(16), "phase": "reserved", "child": None,
                 "unknownWrites": []}
        entries[claim] = entry
    return {"claim": claim, "token": entry["token"], "skill": skill, "target": target,
            "step": step, "input": entry["input"], "refs": entry["refs"]}


if __name__ == "__main__":
    run(main)
