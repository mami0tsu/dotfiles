import time
from common import config_path, load_config, require_ref, run, stable_key, stop
from runtime import active, locked_runtime


def main(payload):
    config = load_config(payload)
    candidates = payload.get("manual", [])
    results = payload.get("results", [])
    if not isinstance(candidates, list) or not isinstance(results, list):
        stop("manual and results must be arrays", "error")
    candidates = [{**c, "explicit": True} if isinstance(c, dict) else c for c in candidates]
    for result in results:
        if not isinstance(result, dict):
            stop("worker result must be an object", "error")
        if result.get("status") == "success" and result.get("next") not in (None, "none", "human"):
            candidates.append({"skill": result["next"], "target": result.get("target"),
                               "step": result.get("step", result["next"]), "explicit": True,
                               "input": result.get("nextInput", result.get("input", {})),
                               "refs": result.get("nextRefs", result.get("refs", {}))})
    with locked_runtime(payload) as state:
        entries = state["entries"]
        for entry in entries.values():
            result = entry.get("result", {})
            if entry["phase"] == "done" and result.get("next") not in (None, "none", "human"):
                candidates.append({"skill": result["next"], "target": result.get("target"),
                                   "step": result.get("step", result["next"]),
                                   "input": result.get("nextInput", result.get("input", entry.get("input", {}))),
                                   "refs": result.get("nextRefs", result.get("refs", entry.get("refs", {})))})
        latest = max((e.get("finishedAt", 0) for e in entries.values()
                      if e["skill"] == "research" and e["phase"] == "done"
                      and e.get("input", {}).get("case") == "periodic"), default=0)
        now = time.time()
        if config["repositories"] and now - latest >= config["research"]["intervalSeconds"]:
            cycle = stable_key(str(config_path(payload)), latest)
            candidates.append({"skill": "research", "step": "periodic-research",
                               "target": {"id": "periodic-research", "url": config_path(payload).as_uri(),
                                          "revision": cycle},
                               "input": {"config": str(config_path(payload)), "case": "periodic",
                                         "now": now, "completedAt": latest, "cycle": cycle}})
        selected = []
        seen = set()
        for candidate in candidates:
            if not isinstance(candidate, dict) or candidate.get("skill") not in config["loop"]["skills"]:
                stop("candidate names an unknown worker", "error")
            target = require_ref(candidate.get("target"), revision=False)
            step = candidate.get("step")
            if not isinstance(step, str) or not step:
                stop("candidate step is required", "error")
            identity = stable_key(target["url"])
            claim = stable_key(candidate["skill"], target["url"], target.get("revision"), step)
            if identity in seen or any(active(e) and e["identity"] == identity for e in entries.values()):
                continue
            if entries.get(claim, {}).get("phase") == "done":
                continue
            if entries.get(claim, {}).get("phase") in ("waiting", "stopped") and not candidate.get("explicit"):
                continue
            seen.add(identity)
            worker_input, refs = candidate.get("input", {}), candidate.get("refs", {})
            if not isinstance(worker_input, dict) or not isinstance(refs, dict):
                stop("worker input and refs must be objects", "error")
            selected.append({"skill": candidate["skill"], "target": target, "step": step,
                             "input": worker_input, "refs": refs})
    return {"candidates": selected}


if __name__ == "__main__":
    run(main)
