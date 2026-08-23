#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("workflow_state.py")


class WorkflowStateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name) / "repository"
        self.root.mkdir()
        subprocess.run(["git", "init", "-q", "-b", "main"], cwd=self.root, check=True)
        subprocess.run(["git", "config", "user.name", "State Test"], cwd=self.root, check=True)
        subprocess.run(["git", "config", "user.email", "state@example.invalid"], cwd=self.root, check=True)
        (self.root / "tracked.txt").write_text("initial\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "tracked.txt"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "initial"], cwd=self.root, check=True)
        self.commit = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=self.root, text=True, check=True, stdout=subprocess.PIPE
        ).stdout.strip()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def run_state(self, *arguments: str, cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [sys.executable, str(SCRIPT), *arguments],
            cwd=cwd or self.root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if check and result.returncode != 0:
            self.fail(f"workflow_state.py failed:\n{result.stdout}\n{result.stderr}")
        return result

    def initialize(self) -> dict[str, object]:
        return json.loads(self.run_state(
            "init", "--workflow-id", "linear-P-92", "--workflow", "dev-flow",
            "--subject-kind", "ticket", "--subject", "https://linear.example/P-92",
        ).stdout)

    def test_initialize_verify_and_complete(self) -> None:
        initialized = self.initialize()
        state = Path(str(initialized["state"]))
        self.assertEqual(state.parent.name, "agent-workflows")
        self.assertEqual(state.stat().st_mode & 0o777, 0o600)
        self.run_state(
            "verify", "--workflow-id", "linear-P-92", "--workflow", "dev-flow",
            "--subject-kind", "ticket", "--subject", "https://linear.example/P-92",
            "--branch", "main", "--start-commit", self.commit,
        )
        self.run_state("complete", "--workflow-id", "linear-P-92")
        self.assertFalse(state.exists())

    def test_linked_worktree_reads_the_same_state(self) -> None:
        initialized = self.initialize()
        linked = Path(self.temporary.name) / "linked"
        subprocess.run(["git", "worktree", "add", "-q", "-b", "linked", str(linked), "HEAD"], cwd=self.root, check=True)
        value_file = Path(self.temporary.name) / "value.json"
        value_file.write_text('{"phase":"waiting","ticketId":"P-92"}\n', encoding="utf-8")
        value_file.chmod(0o600)
        self.run_state(
            "put", "--workflow-id", "linear-P-92", "--namespace", "impl-flow",
            "--value-file", str(value_file), cwd=linked,
        )
        self.run_state(
            "verify", "--workflow-id", "linear-P-92", "--workflow", "dev-flow",
            "--subject-kind", "ticket", "--subject", "https://linear.example/P-92",
            "--branch", "main", "--start-commit", self.commit, cwd=linked,
        )
        read = json.loads(self.run_state(
            "get", "--workflow-id", "linear-P-92", "--namespace", "impl-flow", cwd=self.root,
        ).stdout)
        self.assertEqual(read, {"phase": "waiting", "ticketId": "P-92"})
        self.assertEqual(Path(str(initialized["state"])), Path(subprocess.run(
            ["git", "rev-parse", "--git-common-dir"], cwd=linked, text=True, check=True,
            stdout=subprocess.PIPE,
        ).stdout.strip()).resolve() / "agent-workflows" / "linear-P-92.json")

    def test_show_omits_namespace_content(self) -> None:
        self.initialize()
        value_file = Path(self.temporary.name) / "value.json"
        value_file.write_text('{"phase":"waiting","ticketId":"P-92"}\n', encoding="utf-8")
        value_file.chmod(0o600)
        self.run_state(
            "put", "--workflow-id", "linear-P-92", "--namespace", "impl-flow",
            "--value-file", str(value_file),
        )
        shown = json.loads(self.run_state("show", "--workflow-id", "linear-P-92").stdout)
        self.assertEqual(shown["namespaces"], ["impl-flow"])
        self.assertNotIn("phase", json.dumps(shown))

    def test_rejects_dirty_init_and_identity_mismatch(self) -> None:
        (self.root / "untracked.txt").write_text("dirty\n", encoding="utf-8")
        dirty = self.run_state(
            "init", "--workflow-id", "dirty", "--workflow", "dev-flow",
            "--subject-kind", "ticket", "--subject", "https://linear.example/P-92", check=False,
        )
        self.assertNotEqual(dirty.returncode, 0)
        (self.root / "untracked.txt").unlink()
        self.initialize()
        mismatch = self.run_state(
            "verify", "--workflow-id", "linear-P-92", "--workflow", "dev-flow",
            "--subject-kind", "ticket", "--subject", "https://linear.example/P-999",
            "--branch", "main", "--start-commit", self.commit, check=False,
        )
        self.assertNotEqual(mismatch.returncode, 0)
        self.assertIn("does not match", mismatch.stderr)

    def test_rejects_public_or_sensitive_namespace_values(self) -> None:
        self.initialize()
        value_file = Path(self.temporary.name) / "value.json"
        value_file.write_text('{"phase":"waiting"}\n', encoding="utf-8")
        value_file.chmod(0o644)
        public = self.run_state(
            "put", "--workflow-id", "linear-P-92", "--namespace", "dev-flow",
            "--value-file", str(value_file), check=False,
        )
        self.assertNotEqual(public.returncode, 0)
        value_file.write_text('{"accessToken":"hidden"}\n', encoding="utf-8")
        value_file.chmod(0o600)
        sensitive = self.run_state(
            "put", "--workflow-id", "linear-P-92", "--namespace", "dev-flow",
            "--value-file", str(value_file), check=False,
        )
        self.assertNotEqual(sensitive.returncode, 0)
        self.assertIn("forbidden field", sensitive.stderr)

        for field in ("apiKey", "authorization", "review.body", "comment", "review"):
            value_file.write_text(json.dumps({field: "sensitive"}), encoding="utf-8")
            rejected = self.run_state(
                "put", "--workflow-id", "linear-P-92", "--namespace", "dev-flow",
                "--value-file", str(value_file), check=False,
            )
            self.assertNotEqual(rejected.returncode, 0, field)

        value_file.write_text(json.dumps({
            "commentId": "RC_1",
            "commentUrl": "https://example.invalid/comment/1",
            "messageId": "M_1",
            "contentOid": "abc123",
            "somebodyApproved": True,
        }), encoding="utf-8")
        accepted = self.run_state(
            "put", "--workflow-id", "linear-P-92", "--namespace", "dev-flow",
            "--value-file", str(value_file), check=False,
        )
        self.assertEqual(accepted.returncode, 0, accepted.stderr)


if __name__ == "__main__":
    unittest.main()
