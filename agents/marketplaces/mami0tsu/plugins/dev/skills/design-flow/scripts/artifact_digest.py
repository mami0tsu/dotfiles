#!/usr/bin/env python3
import argparse
import copy
import hashlib
import json
from pathlib import Path


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def artifact_digest(artifact: dict) -> str:
    projected = copy.deepcopy(artifact)
    projected.pop("artifact_sha256", None)
    canonical = projected.get("canonical")
    if isinstance(canonical, dict):
        canonical.pop("url", None)
        canonical.pop("revision", None)
    encoded = json.dumps(
        projected,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8") + b"\n"
    return sha256(encoded)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--content", type=Path, required=True)
    args = parser.parse_args()

    artifact = json.loads(args.artifact.read_text(encoding="utf-8"))
    content_digest = sha256(args.content.read_bytes())
    canonical = artifact.get("canonical")
    if not isinstance(canonical, dict):
        parser.error("artifact canonical must be an object")
    if canonical.get("content_sha256") != content_digest:
        parser.error("canonical.content_sha256 does not match content")
    result = {
        "artifactSha256": artifact_digest(artifact),
        "contentSha256": content_digest,
    }
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
