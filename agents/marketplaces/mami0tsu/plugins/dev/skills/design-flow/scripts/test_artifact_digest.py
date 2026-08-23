import hashlib
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("artifact_digest.py")
SPEC = importlib.util.spec_from_file_location("artifact_digest", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ArtifactDigestTest(unittest.TestCase):
    def test_digest_excludes_mutable_canonical_identity(self) -> None:
        artifact = {
            "canonical": {
                "kind": "linear",
                "url": None,
                "revision": None,
                "content_sha256": hashlib.sha256(b"design\n").hexdigest(),
            },
            "artifact_sha256": "ignored",
            "summary": "example",
        }
        first = MODULE.artifact_digest(artifact)
        artifact["canonical"]["url"] = "https://linear.example/issue/TEST-1"
        artifact["canonical"]["revision"] = "revision-1"
        artifact["artifact_sha256"] = first
        self.assertEqual(first, MODULE.artifact_digest(artifact))

    def test_digest_binds_canonical_content_digest(self) -> None:
        artifact = {
            "canonical": {
                "content_sha256": hashlib.sha256(b"first\n").hexdigest(),
            },
            "summary": "example",
        }
        first = MODULE.artifact_digest(artifact)
        artifact["canonical"]["content_sha256"] = hashlib.sha256(b"second\n").hexdigest()
        self.assertNotEqual(first, MODULE.artifact_digest(artifact))

    def test_cli_accepts_matching_content_digest(self) -> None:
        content = b"design\n"
        artifact = {
            "canonical": {},
            "summary": "example",
        }
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifact_path = root / "artifact.json"
            content_path = root / "design.md"
            artifact_path.write_text(json.dumps(artifact), encoding="utf-8")
            content_path.write_bytes(content)
            computed = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    str(artifact_path),
                    "--content",
                    str(content_path),
                    "--compute",
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            computed_output = json.loads(computed.stdout)
            artifact["canonical"]["content_sha256"] = computed_output["contentSha256"]
            artifact["artifact_sha256"] = computed_output["artifactSha256"]
            artifact_path.write_text(json.dumps(artifact), encoding="utf-8")
            verified = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    str(artifact_path),
                    "--content",
                    str(content_path),
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            output = json.loads(verified.stdout)
            self.assertEqual(hashlib.sha256(content).hexdigest(), output["contentSha256"])

    def test_cli_rejects_missing_artifact_digest(self) -> None:
        content = b"design\n"
        artifact = {
            "canonical": {"content_sha256": hashlib.sha256(content).hexdigest()},
            "summary": "example",
        }
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifact_path = root / "artifact.json"
            content_path = root / "design.md"
            artifact_path.write_text(json.dumps(artifact), encoding="utf-8")
            content_path.write_bytes(content)
            result = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    str(artifact_path),
                    "--content",
                    str(content_path),
                ],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(0, result.returncode)
            self.assertIn("must be present", result.stderr)

    def test_cli_rejects_mismatched_artifact_digest(self) -> None:
        content = b"design\n"
        artifact = {
            "canonical": {"content_sha256": hashlib.sha256(content).hexdigest()},
            "artifact_sha256": "wrong",
            "summary": "example",
        }
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifact_path = root / "artifact.json"
            content_path = root / "design.md"
            artifact_path.write_text(json.dumps(artifact), encoding="utf-8")
            content_path.write_bytes(content)
            result = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    str(artifact_path),
                    "--content",
                    str(content_path),
                ],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(0, result.returncode)
            self.assertIn("does not match artifact", result.stderr)

    def test_cli_rejects_mismatched_content_digest(self) -> None:
        artifact = {"canonical": {"content_sha256": "wrong"}, "summary": "example"}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifact_path = root / "artifact.json"
            content_path = root / "design.md"
            artifact_path.write_text(json.dumps(artifact), encoding="utf-8")
            content_path.write_bytes(b"design\n")
            result = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    str(artifact_path),
                    "--content",
                    str(content_path),
                ],
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(0, result.returncode)
            self.assertIn("does not match content", result.stderr)


if __name__ == "__main__":
    unittest.main()
