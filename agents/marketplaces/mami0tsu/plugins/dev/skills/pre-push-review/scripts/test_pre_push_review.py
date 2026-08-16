#!/usr/bin/env python3

from __future__ import annotations

import json
import importlib.util
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("pre_push_review.py")
SPEC = importlib.util.spec_from_file_location("pre_push_review_skill_helper", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
REVIEW_MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(REVIEW_MODULE)


class PrePushReviewScriptTest(unittest.TestCase):
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
        self.fake_difit = fake

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
            timeout=15,
        )
        if check and result.returncode != 0:
            self.fail(
                f"pre_push_review.py {' '.join(arguments)} failed with {result.returncode}:\n"
                f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            )
        return result

    def commit_change(self) -> None:
        (self.root / "document.md").write_text("after\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "document.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "change document"], cwd=self.root, check=True)

    def commit_oid(self, value: str = "HEAD") -> str:
        return subprocess.run(
            ["git", "rev-parse", value],
            cwd=self.root,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        ).stdout.strip()

    def initialize_committed_change(self) -> dict[str, object]:
        base = self.commit_oid()
        self.commit_change()
        target = self.commit_oid()
        return json.loads(
            self.run_review(
                "init", "--base", base, "--target", target
            ).stdout
        )

    def record_validation(self, *, risk: str = "normal", subagents: tuple[str, ...] = ("agent-1",)) -> None:
        selection = json.loads(self.run_review("next").stdout)
        arguments = [
            "validated",
            "--base",
            selection["baseCommit"],
            "--target",
            selection["targetCommit"],
            "--risk",
            risk,
            "--normal-check",
            "unit tests",
        ]
        for subagent in subagents:
            arguments.extend(["--subagent", subagent])
        self.run_review(*arguments)

    def test_init_rejects_dirty_worktree(self) -> None:
        (self.root / "untracked.txt").write_text("dirty\n", encoding="utf-8")
        oid = self.commit_oid()
        result = self.run_review(
            "init", "--base", oid, "--target", oid, check=False
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("worktree is not clean", result.stderr)

    def test_init_requires_explicit_base_and_target(self) -> None:
        result = self.run_review("init", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--base", result.stderr)
        self.assertIn("--target", result.stderr)

    def test_init_rejects_short_oid(self) -> None:
        base = self.commit_oid()
        self.commit_change()
        result = self.run_review(
            "init",
            "--base",
            base[:8],
            "--target",
            self.commit_oid(),
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("base must be a full commit OID", result.stderr)

    def test_init_rejects_target_other_than_head(self) -> None:
        old = self.commit_oid()
        self.commit_change()
        head = self.commit_oid()
        result = self.run_review(
            "init", "--base", head, "--target", old, check=False
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("target must match", result.stderr)

    def test_next_rejects_head_changed_after_init(self) -> None:
        self.initialize_committed_change()
        (self.root / "second.md").write_text("second\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "second.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "second change"], cwd=self.root, check=True)
        result = self.run_review("next", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("initial target tree no longer matches", result.stderr)

    def test_init_resumes_only_matching_identity(self) -> None:
        initialized = self.initialize_committed_change()
        matching = self.run_review(
            "init",
            "--base",
            initialized["base"]["commit"],
            "--target",
            initialized["target"]["commit"],
        )
        self.assertTrue(json.loads(matching.stdout)["resumed"])

        (self.root / "second.md").write_text("second\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "second.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "second change"], cwd=self.root, check=True)
        mismatch = self.run_review(
            "init",
            "--base",
            initialized["target"]["commit"],
            "--target",
            self.commit_oid(),
            check=False,
        )
        self.assertNotEqual(mismatch.returncode, 0)
        self.assertIn("does not match", mismatch.stderr)

    def test_init_resumes_after_reviewed_target_and_new_commit(self) -> None:
        initialized = self.initialize_committed_change()
        state_path = Path(initialized["state"])
        state = json.loads(state_path.read_text(encoding="utf-8"))
        state["lastReview"] = state["initialTarget"]
        state_path.write_text(json.dumps(state), encoding="utf-8")
        (self.root / "second.md").write_text("second\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "second.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "second change"], cwd=self.root, check=True)

        resumed = self.run_review(
            "init",
            "--base",
            initialized["base"]["commit"],
            "--target",
            initialized["target"]["commit"],
        )
        self.assertTrue(json.loads(resumed.stdout)["resumed"])
        selection = json.loads(self.run_review("next").stdout)
        self.assertEqual(selection["baseCommit"], initialized["target"]["commit"])
        self.assertEqual(selection["targetCommit"], self.commit_oid())

    def test_init_rejects_legacy_review_state(self) -> None:
        git_path = subprocess.run(
            ["git", "rev-parse", "--git-path", "review-state.json"],
            cwd=self.root,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        ).stdout.strip()
        legacy = Path(git_path)
        if not legacy.is_absolute():
            legacy = self.root / legacy
        legacy.write_text("{}\n", encoding="utf-8")
        base = self.commit_oid()
        self.commit_change()
        result = self.run_review(
            "init", "--base", base, "--target", self.commit_oid(), check=False
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("legacy review state exists", result.stderr)

    def test_review_round_marks_agent_comments_and_tracks_human_reply(self) -> None:
        initialized = self.initialize_committed_change()
        self.assertEqual(initialized["base"]["title"], "initial")
        state_path = Path(initialized["state"])
        self.assertEqual(state_path.stat().st_mode & 0o777, 0o600)

        selection = json.loads(self.run_review("next").stdout)
        self.assertTrue(selection["clean"])
        self.record_validation()

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
        self.assertIn("--keep-alive", arguments)
        self.assertIn("--clean", arguments)
        comment_value = json.loads(arguments[arguments.index("--comment") + 1])
        self.assertEqual(comment_value[0]["body"], "実装の意図")
        state = json.loads(state_path.read_text(encoding="utf-8"))
        self.assertEqual(state["activeAgentMessages"][0]["commentedBy"], "agent")

        extracted = json.loads(
            self.run_review("extract", "--transcript", str(transcript)).stdout
        )
        self.assertEqual(len(extracted["candidates"]), 2)
        candidate = next(
            item for item in extracted["candidates"] if item["body"] == "実装の意図"
        )
        self.assertEqual(candidate["messageIndex"], 1)
        self.assertEqual(candidate["body"], "実装の意図")
        self.run_review(
            "acknowledge", *(item["signature"] for item in extracted["candidates"])
        )
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
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
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
        transcript = Path(json.loads(result.stdout.splitlines()[-1])["transcript"])
        extracted = json.loads(
            self.run_review("extract", "--transcript", str(transcript)).stdout
        )
        self.run_review("reviewed")
        self.run_review(
            "acknowledge", *(item["signature"] for item in extracted["candidates"])
        )
        self.run_review("discard-transcript", "--transcript", str(transcript))

        (self.root / "document.md").write_text("second change\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "document.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "second change"], cwd=self.root, check=True)
        next_selection = json.loads(self.run_review("next").stdout)
        self.assertEqual(next_selection["base"], selection["target"])
        self.assertNotEqual(next_selection["target"], selection["target"])

    def test_rejects_public_comments_file(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
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

    def test_run_rejects_target_without_validation_record(self) -> None:
        self.initialize_committed_change()
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
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no completed validation", result.stderr)

    def test_run_rejects_validation_from_a_different_base(self) -> None:
        initialized = self.initialize_committed_change()
        original = json.loads(self.run_review("next").stdout)
        self.record_validation()
        original_target = self.commit_oid()
        (self.root / "alternate.md").write_text("alternate\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "alternate.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "alternate base"], cwd=self.root, check=True)
        alternate_commit = self.commit_oid()
        alternate_tree = subprocess.run(
            ["git", "rev-parse", f"{alternate_commit}^{{tree}}"],
            cwd=self.root,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        ).stdout.strip()
        subprocess.run(["git", "reset", "--hard", "-q", original_target], cwd=self.root, check=True)
        state_path = Path(initialized["state"])
        state = json.loads(state_path.read_text(encoding="utf-8"))
        state["lastReview"] = {
            "commit": alternate_commit,
            "title": "alternate base",
            "tree": alternate_tree,
        }
        state_path.write_text(json.dumps(state), encoding="utf-8")
        selection = json.loads(self.run_review("next").stdout)
        self.assertNotEqual(selection["key"], original["key"])
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
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("comparison has no completed validation", result.stderr)

    def test_reviewed_rejects_unextracted_transcript(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
            "--clean",
        )
        result = self.run_review("reviewed", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("extract the active transcript", result.stderr)

    def test_discard_requires_all_current_candidates_to_be_acknowledged(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        run = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
            "--clean",
        )
        transcript = Path(json.loads(run.stdout.splitlines()[-1])["transcript"])
        extracted = json.loads(
            self.run_review("extract", "--transcript", str(transcript)).stdout
        )
        unknown = "0" * 64
        rejected_ack = self.run_review("acknowledge", unknown, check=False)
        self.assertNotEqual(rejected_ack.returncode, 0)
        self.assertIn("not in the current extraction", rejected_ack.stderr)
        rejected_discard = self.run_review(
            "discard-transcript", "--transcript", str(transcript), check=False
        )
        self.assertNotEqual(rejected_discard.returncode, 0)
        self.assertIn("acknowledge every", rejected_discard.stderr)
        self.run_review(
            "acknowledge", *(item["signature"] for item in extracted["candidates"])
        )
        self.run_review("discard-transcript", "--transcript", str(transcript))

    def test_failed_difit_persists_transcript_until_explicit_discard(self) -> None:
        initialized = self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        self.fake_difit.write_text(
            "#!/bin/sh\n"
            "if [ \"$1\" = \"--version\" ]; then echo 4.0.5; exit 0; fi\n"
            "echo 'partial transcript'\n"
            "exit 7\n",
            encoding="utf-8",
        )
        self.fake_difit.chmod(0o755)
        comments = self.temporary_root / "comments.json"
        comments.write_text(
            json.dumps(
                [{"type": "thread", "filePath": "document.md", "position": {"side": "new", "line": 1}, "body": "failed Agent thread"}]
            ),
            encoding="utf-8",
        )
        comments.chmod(0o600)
        failed = self.run_review(
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
        self.assertNotEqual(failed.returncode, 0)
        state = json.loads(Path(initialized["state"]).read_text(encoding="utf-8"))
        current = state["currentTranscript"]
        self.assertEqual(current["status"], "failed")
        transcript = Path(current["path"])
        self.assertTrue(transcript.exists())
        blocked = self.run_review(
            "discard-transcript", "--transcript", str(transcript), check=False
        )
        self.assertNotEqual(blocked.returncode, 0)
        self.assertIn("--allow-incomplete", blocked.stderr)
        self.run_review(
            "discard-transcript",
            "--transcript",
            str(transcript),
            "--allow-incomplete",
        )
        self.assertFalse(transcript.exists())
        state = json.loads(Path(initialized["state"]).read_text(encoding="utf-8"))
        self.assertEqual(state["commentThreads"], {})
        reply = self.temporary_root / "reply-after-failure.json"
        reply.write_text(
            json.dumps(
                [{"type": "reply", "filePath": "document.md", "position": {"side": "new", "line": 1}, "body": "must not attach"}]
            ),
            encoding="utf-8",
        )
        reply.chmod(0o600)
        rejected = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(reply),
            "--clean",
            check=False,
        )
        self.assertNotEqual(rejected.returncode, 0)
        self.assertIn("not a unique Agent thread", rejected.stderr)

    def test_unreadable_completed_transcript_can_be_explicitly_discarded(self) -> None:
        initialized = self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        self.fake_difit.write_text(
            "#!/bin/sh\n"
            "if [ \"$1\" = \"--version\" ]; then echo 4.0.5; exit 0; fi\n"
            "echo 'server stopped without comments output'\n",
            encoding="utf-8",
        )
        self.fake_difit.chmod(0o755)
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        run = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
            "--clean",
        )
        transcript = Path(json.loads(run.stdout.splitlines()[-1])["transcript"])
        extract = self.run_review(
            "extract", "--transcript", str(transcript), check=False
        )
        self.assertNotEqual(extract.returncode, 0)
        state = json.loads(Path(initialized["state"]).read_text(encoding="utf-8"))
        self.assertEqual(state["currentTranscript"]["status"], "unreadable")
        self.run_review(
            "discard-transcript",
            "--transcript",
            str(transcript),
            "--allow-incomplete",
        )

    def test_changed_transcript_becomes_unreadable_before_extract(self) -> None:
        initialized = self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        run = self.run_review(
            "run", "--target", selection["target"], "--base", selection["base"],
            "--comments", str(comments), "--clean",
        )
        transcript = Path(json.loads(run.stdout.splitlines()[-1])["transcript"])
        transcript.write_text(transcript.read_text(encoding="utf-8") + "\n", encoding="utf-8")
        extract = self.run_review("extract", "--transcript", str(transcript), check=False)
        self.assertNotEqual(extract.returncode, 0)
        state = json.loads(Path(initialized["state"]).read_text(encoding="utf-8"))
        self.assertEqual(state["currentTranscript"]["status"], "unreadable")
        self.run_review(
            "discard-transcript", "--transcript", str(transcript), "--allow-incomplete"
        )

    def test_changed_transcript_becomes_unreadable_after_extract(self) -> None:
        initialized = self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        run = self.run_review(
            "run", "--target", selection["target"], "--base", selection["base"],
            "--comments", str(comments), "--clean",
        )
        transcript = Path(json.loads(run.stdout.splitlines()[-1])["transcript"])
        self.run_review("extract", "--transcript", str(transcript))
        transcript.write_text(transcript.read_text(encoding="utf-8") + "\n", encoding="utf-8")
        reviewed = self.run_review("reviewed", check=False)
        self.assertNotEqual(reviewed.returncode, 0)
        state = json.loads(Path(initialized["state"]).read_text(encoding="utf-8"))
        self.assertEqual(state["currentTranscript"]["status"], "unreadable")
        self.run_review(
            "discard-transcript", "--transcript", str(transcript), "--allow-incomplete"
        )

    def test_keep_alive_disconnect_collects_comments_via_sigint(self) -> None:
        initialized = self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        self.fake_difit.write_text(
            "#!/bin/sh\n"
            "if [ \"$1\" = \"--version\" ]; then echo 4.0.5; exit 0; fi\n"
            "trap 'printf \"\\n📝 Comments from review session:\\n==================================================\\n==================================================\\nTotal comments: 0\\n\"; exit 0' INT\n"
            "echo 'Client disconnected, but server is staying alive (--keep-alive)'\n"
            "while :; do sleep 1; done\n",
            encoding="utf-8",
        )
        self.fake_difit.chmod(0o755)
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        run = self.run_review(
            "run", "--target", selection["target"], "--base", selection["base"],
            "--comments", str(comments), "--clean",
        )
        transcript = Path(json.loads(run.stdout.splitlines()[-1])["transcript"])
        state = json.loads(Path(initialized["state"]).read_text(encoding="utf-8"))
        self.assertEqual(state["currentTranscript"]["status"], "completed")
        extracted = json.loads(
            self.run_review("extract", "--transcript", str(transcript)).stdout
        )
        self.assertEqual(extracted["candidates"], [])

    def test_matching_init_resumes_before_reopening_a_reviewed_range(self) -> None:
        initialized = self.initialize_committed_change()
        state_path = Path(initialized["state"])
        state = json.loads(state_path.read_text(encoding="utf-8"))
        state["lastReview"] = state["initialTarget"]
        state["active"] = {
            "base": state["base"]["tree"],
            "target": state["initialTarget"]["tree"],
            "key": f"{state['base']['tree']}:{state['initialTarget']['tree']}",
            "reviewed": True,
        }
        state_path.write_text(json.dumps(state), encoding="utf-8")
        resumed = self.run_review(
            "init",
            "--base",
            initialized["base"]["commit"],
            "--target",
            initialized["target"]["commit"],
        )
        self.assertTrue(json.loads(resumed.stdout)["resumed"])

    def test_running_transcript_from_terminated_helper_can_be_discarded(self) -> None:
        initialized = self.initialize_committed_change()
        descriptor, transcript_name = tempfile.mkstemp(prefix="difit-review-", suffix=".log")
        os.close(descriptor)
        transcript = Path(transcript_name)
        transcript.write_text("output written after the initial state\n", encoding="utf-8")
        state_path = Path(initialized["state"])
        state = json.loads(state_path.read_text(encoding="utf-8"))
        state["currentTranscript"] = {
            "path": str(transcript.resolve()),
            "sha256": hashlib.sha256(b"").hexdigest(),
            "base": state["base"]["tree"],
            "target": state["initialTarget"]["tree"],
            "status": "running",
            "processGroup": 99999999,
            "extracted": False,
            "empty": False,
            "deleted": False,
        }
        state_path.write_text(json.dumps(state), encoding="utf-8")
        self.run_review(
            "discard-transcript",
            "--transcript",
            str(transcript),
            "--allow-incomplete",
        )
        self.assertFalse(transcript.exists())

    def test_run_rejects_invalid_position_and_unknown_reply_target(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        for name, item, expected in (
            (
                "invalid-line",
                {"type": "thread", "filePath": "document.md", "position": {"side": "new", "line": 0}, "body": "x"},
                "invalid line",
            ),
            (
                "outside-diff",
                {"type": "thread", "filePath": "other.md", "position": {"side": "new", "line": 1}, "body": "x"},
                "not part of the comparison",
            ),
            (
                "outside-hunk",
                {"type": "thread", "filePath": "document.md", "position": {"side": "new", "line": 999999}, "body": "x"},
                "outside a changed diff hunk",
            ),
            (
                "unknown-reply",
                {"type": "reply", "filePath": "document.md", "position": {"side": "new", "line": 1}, "body": "x"},
                "not a unique Agent thread",
            ),
        ):
            with self.subTest(name=name):
                comments = self.temporary_root / f"{name}.json"
                comments.write_text(json.dumps([item]), encoding="utf-8")
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
                    check=False,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected, result.stderr)

    def test_run_accepts_changed_paths_without_text_normalization(self) -> None:
        base = self.commit_oid()
        changed_names = ("日本語.md", " leading-space.md", "\nleading-newline.md")
        for name in changed_names:
            (self.root / name).write_text("変更\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", *changed_names], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "add non-ASCII path"], cwd=self.root, check=True)
        self.run_review("init", "--base", base, "--target", self.commit_oid())
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        comments = self.temporary_root / "comments.json"
        comments.write_text(
            json.dumps(
                [
                    {"type": "thread", "filePath": name, "position": {"side": "new", "line": 1}, "body": "追加理由"}
                    for name in changed_names
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
        self.assertEqual(result.returncode, 0)

    def test_reviewed_range_can_be_reopened_for_an_answer(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        first = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
            "--clean",
        )
        transcript = Path(json.loads(first.stdout.splitlines()[-1])["transcript"])
        extracted = json.loads(
            self.run_review("extract", "--transcript", str(transcript)).stdout
        )
        self.run_review("reviewed")
        self.run_review(
            "acknowledge", *(item["signature"] for item in extracted["candidates"])
        )
        self.run_review("discard-transcript", "--transcript", str(transcript))
        reopened = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
        )
        self.assertEqual(reopened.returncode, 0)

    def test_run_rejects_missing_difit(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        self.fake_difit.unlink()
        git_executable = shutil.which("git")
        assert git_executable is not None
        (self.bin_dir / "git").symlink_to(git_executable)
        self.environment["PATH"] = str(self.bin_dir)
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
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("difit was not found", result.stderr)

    def test_run_rejects_difit_without_required_options(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        self.fake_difit.write_text(
            "#!/bin/sh\nif [ \"$1\" = \"--version\" ]; then echo 4.0.6; fi\n",
            encoding="utf-8",
        )
        self.fake_difit.chmod(0o755)
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
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires difit 4.0.5", result.stderr)

    def test_complete_rejects_head_after_reviewed_target(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        self.record_validation()
        self.fake_difit.write_text(
            "#!/bin/sh\n"
            "if [ \"$1\" = \"--version\" ]; then echo 4.0.5; exit 0; fi\n"
            "cat <<'OUTPUT'\n"
            "📝 Comments from review session:\n"
            "==================================================\n"
            "==================================================\n"
            "Total comments: 0\n"
            "OUTPUT\n",
            encoding="utf-8",
        )
        self.fake_difit.chmod(0o755)
        comments = self.temporary_root / "comments.json"
        comments.write_text("[]\n", encoding="utf-8")
        comments.chmod(0o600)
        run = self.run_review(
            "run",
            "--target",
            selection["target"],
            "--base",
            selection["base"],
            "--comments",
            str(comments),
            "--clean",
        )
        transcript = Path(json.loads(run.stdout.splitlines()[-1])["transcript"])
        self.run_review("extract", "--transcript", str(transcript))
        self.run_review("reviewed")
        self.run_review("discard-transcript", "--transcript", str(transcript))
        (self.root / "second.md").write_text("second\n", encoding="utf-8")
        subprocess.run(["git", "add", "--", "second.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-qm", "second change"], cwd=self.root, check=True)
        result = self.run_review("complete", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("HEAD tree no longer matches", result.stderr)

    def test_high_risk_requires_two_subagents(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        result = self.run_review(
            "validated",
            "--base",
            selection["baseCommit"],
            "--target",
            selection["targetCommit"],
            "--risk",
            "high",
            "--normal-check",
            "unit tests",
            "--subagent",
            "agent-1",
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires 2 to 3 distinct subagents", result.stderr)

    def test_validated_rejects_empty_check_and_extra_normal_subagent(self) -> None:
        self.initialize_committed_change()
        selection = json.loads(self.run_review("next").stdout)
        empty = self.run_review(
            "validated",
            "--base",
            selection["baseCommit"],
            "--target",
            selection["targetCommit"],
            "--risk",
            "normal",
            "--normal-check",
            " ",
            "--subagent",
            "agent-1",
            check=False,
        )
        self.assertNotEqual(empty.returncode, 0)
        self.assertIn("must not be empty", empty.stderr)
        extra = self.run_review(
            "validated",
            "--base",
            selection["baseCommit"],
            "--target",
            selection["targetCommit"],
            "--risk",
            "normal",
            "--normal-check",
            "unit tests",
            "--subagent",
            "agent-1",
            "--subagent",
            "agent-2",
            check=False,
        )
        self.assertNotEqual(extra.returncode, 0)
        self.assertIn("requires 1 to 1 distinct subagents", extra.stderr)

    def test_complete_requires_current_reviewed_deleted_empty_transcript(self) -> None:
        initialized = self.initialize_committed_change()
        empty = self.temporary_root / "empty.log"
        empty.write_text("", encoding="utf-8")
        extract = self.run_review("extract", "--transcript", str(empty), check=False)
        self.assertNotEqual(extract.returncode, 0)
        complete = self.run_review("complete", check=False)
        self.assertNotEqual(complete.returncode, 0)
        self.assertTrue(Path(initialized["state"]).exists())

    def test_same_trees_keep_the_same_comparison_after_amend(self) -> None:
        self.initialize_committed_change()
        first = json.loads(self.run_review("next").stdout)
        subprocess.run(
            ["git", "commit", "--amend", "-qm", "renamed change"],
            cwd=self.root,
            check=True,
        )
        second = json.loads(self.run_review("next").stdout)
        self.assertEqual(first["target"], second["target"])
        self.assertNotEqual(first["targetCommit"], second["targetCommit"])
        self.assertEqual(second["targetCommit"], self.commit_oid())

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
            transcript, set(), [thread], messages, "base-a:target-a"
        )
        self.assertEqual(len(candidates), 1)
        self.assertEqual(candidates[0]["body"], "人間が作り直したコメント")

    def test_human_reply_with_agent_author_text_is_not_hidden(self) -> None:
        transcript = """📝 Comments from review session:
==================================================
document.md:L1
Reply 1 (agent)
人間が入力した本文
==================================================
Total comments: 1
"""
        thread = {
            "id": "agent-thread",
            "filePath": "document.md",
            "position": {"side": "new", "line": 1},
            "body": "実装の意図",
        }
        candidates = REVIEW_MODULE.extract_candidates(
            transcript, set(), [thread], [], "base-a:target-a"
        )
        self.assertEqual(len(candidates), 1)
        self.assertEqual(candidates[0]["body"], "人間が入力した本文")

    def test_duplicate_review_header_is_rejected(self) -> None:
        transcript = """📝 Comments from review session:
==================================================
document.md:L1
人間の本文
📝 Comments from review session:
==================================================
Total comments: 1
"""
        with self.assertRaises(REVIEW_MODULE.ReviewError):
            REVIEW_MODULE.extract_candidates(transcript, set(), [], [], "base-a:target-a")

    def test_current_transcript_without_comment_header_is_rejected(self) -> None:
        with self.assertRaises(REVIEW_MODULE.ReviewError):
            REVIEW_MODULE.extract_candidates(
                "server stopped\n", set(), [], [], "base-a:target-a"
            )

    def test_processed_signature_is_scoped_to_the_comparison(self) -> None:
        transcript = """📝 Comments from review session:
==================================================
document.md:L1
同じ指摘
==================================================
Total comments: 1
"""
        first = REVIEW_MODULE.extract_candidates(
            transcript, set(), [], [], "base-a:target-a"
        )
        processed = {first[0]["signature"]}
        repeated = REVIEW_MODULE.extract_candidates(
            transcript, processed, [], [], "base-a:target-a"
        )
        different = REVIEW_MODULE.extract_candidates(
            transcript, processed, [], [], "base-b:target-b"
        )
        self.assertEqual(repeated, [])
        self.assertEqual(len(different), 1)

if __name__ == "__main__":
    unittest.main()
