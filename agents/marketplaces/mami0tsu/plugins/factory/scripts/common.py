import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

SCHEMA = Path(__file__).resolve().parents[1] / "skills/init/assets/config.cue"


class Stop(Exception):
    def __init__(self, reason, status):
        super().__init__(reason)
        self.status = status


def stop(reason, status="wait"):
    raise Stop(reason, status)


def run(fn):
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    args = parser.parse_args()
    try:
        payload = json.loads(args.input.read_text() if args.input else sys.stdin.read())
        if not isinstance(payload, dict):
            stop("input must be a JSON object", "error")
        result = {"status": "success", **fn(payload)}
    except Stop as exc:
        result = {"status": exc.status, "reason": str(exc)}
    except (OSError, ValueError, KeyError, TypeError) as exc:
        result = {"status": "error", "reason": str(exc)}
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


def config_path(payload):
    value = payload.get("config")
    if not isinstance(value, str) or not Path(value).is_absolute():
        stop("config must be an absolute path", "error")
    return Path(value).resolve()


def worker_input(payload, supplied=None):
    path = config_path(payload)
    result = dict(payload if supplied is None else supplied)
    if result.get("config") is not None and config_path(result) != path:
        stop("worker configuration differs from loop configuration", "error")
    result["config"] = str(path)
    journal = path.with_name("." + path.name + ".writes.json")
    if result.get("journal") is not None:
        value = result["journal"]
        if not isinstance(value, str) or not Path(value).is_absolute():
            stop("journal must be an absolute path", "error")
        if supplied is not None and Path(value).resolve() != journal:
            stop("loop worker journal differs from canonical journal", "error")
    if supplied is not None or result.get("journal") is None:
        result["journal"] = str(journal)
    return result


def cue_export(path, incomplete_wait=False):
    cue = shutil.which(os.environ.get("FACTORY_CUE", "cue"))
    if not cue:
        stop("CUE is unavailable")
    result = subprocess.run(
        [cue, "export", str(SCHEMA), "json:", str(path), "--out", "json"],
        capture_output=True, text=True, check=False,
    )
    if result.returncode:
        incomplete = "incomplete" in result.stderr or "non-concrete" in result.stderr
        stop(result.stderr.strip(), "wait" if incomplete_wait and incomplete else "error")
    return json.loads(result.stdout)


def load_config(payload):
    path = config_path(payload)
    if not path.exists():
        stop(f"configuration is absent: {path}")
    return cue_export(path)


def resolve_binding(config, role, output=None, expected=None):
    if role not in ("ideas", "tasks", "staging", "artifacts", "changes"):
        stop("unknown binding role", "error")
    if role in ("ideas", "tasks"):
        binding = config["roles"][role]
        output = None
    else:
        if not isinstance(output, str) or output not in config["outputs"]:
            stop("one known output is required")
        binding = config["outputs"][output]
    result = {"adapter": binding["adapter"], "definition": config["adapters"][binding["adapter"]],
              "target": binding["target"], "output": output, "role": role}
    if expected is not None:
        if not isinstance(expected, dict) or any(result.get(k) != v for k, v in expected.items()):
            stop("recorded binding differs from configuration")
    return result


def stable_key(*parts):
    encoded = json.dumps(parts, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(encoded.encode()).hexdigest()


def require_ref(ref, revision=True):
    fields = ("id", "url", "revision") if revision else ("id", "url")
    if not isinstance(ref, dict) or any(not isinstance(ref.get(k), str) or not ref[k] for k in fields):
        stop("reference is incomplete: " + ", ".join(fields))
    return ref
