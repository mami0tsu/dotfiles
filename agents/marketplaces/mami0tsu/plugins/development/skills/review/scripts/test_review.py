#!/usr/bin/env python3

from __future__ import annotations

import json
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("review.py")
SPEC = importlib.util.spec_from_file_location("review_skill_helper", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
REVIEW_MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(REVIEW_MODULE)


class ReviewScriptTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.temporary_root = Path(self.temporary.name)
        self.root = self.temporary_root / "repository"
        self.root.mkdir()
        subprocess.run(["git", "init", "-q", "-b", "main"], cwd=self.root, check=True)
        subprocess.run(["git", "config", "user.name", "Review Test"], cwd=self.root, check=True)
        subprocess.run(["git", "config", "user.email", "review@example.invalid"], cwd=self.root, check=True)
        (self.root / "document.md").write_text("before\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "document.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "initial"], cwd=self.root, check=True)

        self.bin_dir = self.temporary_root / "bin"
        self.bin_dir.mkdir()
        self.arguments_path = self.temporary_root / "difit-arguments.json"
        fake = self.bin_dir / "difit"
        fake.write_text(
            """#!/bin/sh
if [ "$1" = "--version" ]; then
  echo 4.0.5
  exit 0
fi
python3 -c 'import json, os, sys; open(os.environ["DIFIT_ARGUMENTS"], "w").write(json.dumps(sys.argv[1:]))' "$@"
cat <<'OUTPUT'
📝 Comments from review session:
==================================================
document.md:L1
実装の意図

Reply 1 (Unknown)
実装の意図
Reply 2 (agent)
修正方針への回答
==================================================
Total comments: 1
OUTPUT
""",
            encoding="utf-8",
        )
        fake.chmod(0o755)
        self.environment = os.environ.copy()
        self.environment["PATH"] = f"{self.bin_dir}{os.pathsep}{self.environment['PATH']}"
        self.environment["DIFIT_ARGUMENTS"] = str(self.arguments_path)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def run_review(self, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [sys.executable, str(SCRIPT), *arguments],
            cwd=self.root,
            env=self.environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if check and result.returncode != 0:
            self.fail(
                f"review.py {' '.join(arguments)} failed with {result.returncode}:\n"
                f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            )
        return result

    def commit_change(self) -> None:
        (self.root / "document.md").write_text("after\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "document.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "change document"], cwd=self.root, check=True)

    def test_init_rejects_dirty_worktree(self) -> None:
        (self.root / "untracked.txt").write_text("dirty\n", encoding="utf-8")
        result = self.run_review("init", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("worktree is not clean", result.stderr)

    def test_review_round_marks_agent_comments_and_tracks_human_reply(self) -> None:
        initialized = json.loads(self.run_review("init").stdout)
        self.assertEqual(initialized["base"]["title"], "initial")
        state_path = Path(initialized["state"])
        self.assertEqual(state_path.stat().st_mode & 0o777, 0o600)

        self.commit_change()
        selection = json.loads(self.run_review("next").stdout)
        self.assertTrue(selection["clean"])

        comments = self.temporary_root / "comments.json"
        comments.write_text(
            json.dumps(
                [
                    {
                        "type": "thread",
                        "filePath": "document.md",
                        "position": {"side": "new", "line": 1},
                        "body": "実装の意図",
                    }
                ],
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        comments.chmod(0o600)
        result = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
            "--clean",
        )
        summary = json.loads(result.stdout.splitlines()[-1])
        transcript = Path(summary["transcript"])
        self.assertEqual(transcript.stat().st_mode & 0o777, 0o600)

        arguments = json.loads(self.arguments_path.read_text(encoding="utf-8"))
        self.assertEqual(arguments[0:2], [selection["target"], selection["base"]])
        self.assertIn("--clean", arguments)
        comment_value = json.loads(arguments[arguments.index("--comment") + 1])
        self.assertEqual(comment_value[0]["body"], "実装の意図")
        state = json.loads(state_path.read_text(encoding="utf-8"))
        self.assertEqual(state["activeAgentMessages"][0]["commentedBy"], "agent")

        extracted = json.loads(
            self.run_review("extract", "--transcript", str(transcript)).stdout
        )
        self.assertEqual(len(extracted["candidates"]), 1)
        candidate = extracted["candidates"][0]
        self.assertEqual(candidate["messageIndex"], 1)
        self.assertEqual(candidate["body"], "実装の意図")
        self.run_review("acknowledge", candidate["signature"])
        self.run_review("discard-transcript", "--transcript", str(transcript))

        reply_comments = self.temporary_root / "reply-comments.json"
        reply_comments.write_text(
            json.dumps(
                [
                    {
                        "type": "reply",
                        "filePath": "document.md",
                        "position": {"side": "new", "line": 1},
                        "body": "修正方針への回答",
                    }
                ],
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        reply_comments.chmod(0o600)
        repeated = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(reply_comments),
        )
        repeated_transcript = Path(json.loads(repeated.stdout.splitlines()[-1])["transcript"])
        repeated_extract = json.loads(
            self.run_review("extract", "--transcript", str(repeated_transcript)).stdout
        )
        self.assertEqual(repeated_extract["candidates"], [])
        state = json.loads(state_path.read_text(encoding="utf-8"))
        self.assertEqual(len(state["activeComments"]), 1)
        self.assertEqual(state["activeComments"][0]["position"], {"side": "new", "line": 1})
        self.run_review("reviewed")
        self.run_review("discard-transcript", "--transcript", str(repeated_transcript))
        self.run_review("complete")
        self.assertFalse(state_path.exists())

    def test_reviewed_advances_the_next_base(self) -> None:
        self.run_review("init")
        self.commit_change()
        selection = json.loads(self.run_review("next").stdout)
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        result = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
            "--clean",
        )
        self.run_review("reviewed")
        transcript = Path(json.loads(result.stdout.splitlines()[-1])["transcript"])
        self.run_review("extract", "--transcript", str(transcript))
        self.run_review("discard-transcript", "--transcript", str(transcript))

        (self.root / "document.md").write_text("second change\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "document.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "second change"], cwd=self.root, check=True)
        next_selection = json.loads(self.run_review("next").stdout)
        self.assertEqual(next_selection["base"], selection["target"])
        self.assertNotEqual(next_selection["target"], selection["target"])

    def test_rejects_public_comments_file(self) -> None:
        self.run_review("init")
        self.commit_change()
        selection = json.loads(self.run_review("next").stdout)
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o644)
        result = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
            "--clean",
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("permissions", result.stderr)

    def test_complete_requires_current_reviewed_deleted_empty_transcript(self) -> None:
        initialized = json.loads(self.run_review("init").stdout)
        empty = self.temporary_root / "empty.log"
        empty.write_text("", encoding="utf-8")
        extract = self.run_review("extract", "--transcript", str(empty), check=False)
        self.assertNotEqual(extract.returncode, 0)
        complete = self.run_review("complete", check=False)
        self.assertNotEqual(complete.returncode, 0)
        self.assertTrue(Path(initialized["state"]).exists())

    def test_same_trees_keep_the_same_comparison_after_amend(self) -> None:
        self.run_review("init")
        self.commit_change()
        first = json.loads(self.run_review("next").stdout)
        subprocess.run(
            ["git", "commit", "--amend", "-qm", "renamed change"],
            cwd=self.root,
            check=True,
        )
        second = json.loads(self.run_review("next").stdout)
        self.assertEqual(first["target"], second["target"])

    def test_different_human_root_at_known_position_is_not_hidden(self) -> None:
        transcript = """📝 Comments from review session:
==================================================
document.md:L1
人間が作り直したコメント
==================================================
Total comments: 1
"""
        thread = {
            "id": "agent-thread",
            "filePath": "document.md",
            "position": {"side": "new", "line": 1},
            "body": "実装の意図",
        }
        messages = [
            {
                "commentedBy": "agent",
                "type": "thread",
                "filePath": "document.md",
                "position": {"side": "new", "line": 1},
                "body": "実装の意図",
            }
        ]
        candidates = REVIEW_MODULE.extract_candidates(
            transcript, set(), [thread], messages
        )
        self.assertEqual(len(candidates), 1)
        self.assertEqual(candidates[0]["body"], "人間が作り直したコメント")

if __name__ == "__main__":
    unittest.main()
