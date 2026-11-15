import json
import os
import tempfile
from common import config_path, cue_export, run, stop


def main(payload):
    path = config_path(payload)
    if path.exists():
        return {"config": str(path), "created": False, "value": cue_export(path)}
    if "answers" not in payload:
        stop("configuration answers are required")
    if not isinstance(payload["answers"], dict):
        stop("answers must be an object", "error")
    if not path.parent.is_dir():
        stop("configuration parent directory is absent")
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", dir=path.parent, delete=False) as f:
            temporary = f.name
            json.dump(payload["answers"], f)
        value = cue_export(temporary, incomplete_wait=True)
        with open(temporary, "w") as f:
            json.dump(value, f, ensure_ascii=False, indent=2)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        try:
            os.link(temporary, path)
        except FileExistsError:
            return {"config": str(path), "created": False, "value": cue_export(path)}
        return {"config": str(path), "created": True, "value": value}
    finally:
        if temporary:
            os.unlink(temporary)


if __name__ == "__main__":
    run(main)
