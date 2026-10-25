#!/usr/bin/env python3
"""Exercise the Renovate hook without network access or legacy Nix commands."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "renovate-update-nix-hashes.sh"
OLD_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
NEW_HASH = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBA="
REVISION = "1" * 40
NEW_REVISION = "2" * 40
RELEASE_URL = "https://example.invalid/tool.tar.gz"


class HashUpdateTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.log = self.root / "calls.jsonl"
        self.env = dict(os.environ, NIX_TEST_LOG=str(self.log))
        self.env["PATH"] = f"{self.root / 'bin'}:{os.environ['PATH']}"
        self.write("bin/nix", f"#!{sys.executable}\n" + '''
import json
import os
import sys

args = sys.argv[1:]
assert args[:2] == ["--extra-experimental-features", "nix-command flakes"], args
args = args[2:]
with open(os.environ["NIX_TEST_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")
if args[:3] == ["store", "prefetch-file", "--json"]:
    assert args[3:5] == ["--hash-type", "sha256"], args
    assert len(args[5:]) == (2 if "--unpack" in args else 1), args
    if os.environ.get("NIX_TEST_FAIL"):
        sys.exit(1)
    print(json.dumps({"hash": os.environ.get("NIX_TEST_HASH"), "storePath": "/unused"}))
elif args[:2] == ["eval", "--raw"]:
    print("https://example.invalid/tool.tar.gz", end="")
elif args == ["flake", "check", "--no-build", "--no-update-lock-file"]:
    pass
elif args[:2] == ["run", "nixpkgs#nix-update"]:
    pass
else:
    raise AssertionError(args)
''')
        self.env["NIX_TEST_HASH"] = NEW_HASH
        (self.root / "bin/nix").chmod(0o755)
        self.write("bin/nix-prefetch-url", "#!/bin/sh\necho 'legacy command used' >&2\nexit 99\n")
        (self.root / "bin/nix-prefetch-url").chmod(0o755)
        self.write("nix/packages/codex.nix", f'version = "1.0.0";\nhash = "{OLD_HASH}";\n')
        self.write("nix/packages/git-open-src.nix", self.source(REVISION))
        self.write("nix/home-manager/nixvim/legacy-plugins.nix", self.plugin(REVISION))
        self.write(".github/textlint/pnpm-lock.yaml", "lockfileVersion: '9.0'\n")
        self.git("init", "--quiet")
        self.git("add", "--", "nix", ".github")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "fixture")

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, env=self.env,
                              check=True, capture_output=True, text=True)

    @staticmethod
    def source(revision):
        return f'owner = "example";\nrepo = "source";\nrev = "{revision}";\nhash = "{OLD_HASH}";\n'

    @staticmethod
    def plugin(revision):
        return ("# renovate: datasource=git-refs packageName=https://github.com/example/plugin currentValue=main\n"
                f'rev = "{revision}";\nhash = "{OLD_HASH}";\n')

    def run_hook(self, *args, success=True):
        result = subprocess.run(["bash", str(SCRIPT), *args], cwd=self.root,
                                env=self.env, capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stderr)
        return result

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_release_hash_is_flat_sri_and_preserves_file_mode(self):
        path = self.write("nix/packages/codex.nix", f'version = "2.0.0";\nhash = "{OLD_HASH}";\n')
        path.chmod(0o640)
        self.run_hook()
        self.assertIn(NEW_HASH, path.read_text())
        self.assertEqual(path.stat().st_mode & 0o777, 0o640)
        self.assertIn(["store", "prefetch-file", "--json", "--hash-type", "sha256", RELEASE_URL], self.calls())

    def test_source_and_changed_plugin_are_unpacked(self):
        source = self.write("nix/packages/git-open-src.nix", self.source(NEW_REVISION))
        plugin = self.write("nix/home-manager/nixvim/legacy-plugins.nix", self.plugin(NEW_REVISION))
        self.run_hook()
        for path, repo in [(source, "source"), (plugin, "plugin")]:
            self.assertIn(NEW_HASH, path.read_text())
            self.assertIn(["store", "prefetch-file", "--json", "--hash-type", "sha256", "--unpack",
                           f"https://github.com/example/{repo}/archive/{NEW_REVISION}.tar.gz"], self.calls())

    def test_unchanged_packages_are_not_prefetched(self):
        self.run_hook()
        self.assertEqual(self.calls(), [["flake", "check", "--no-build", "--no-update-lock-file"]])

    def test_check_rejects_stale_hash_without_modifying_file(self):
        path = self.root / "nix/home-manager/nixvim/legacy-plugins.nix"
        original = path.read_bytes()
        result = self.run_hook("--check", success=False)
        self.assertIn("stale hash", result.stderr)
        self.assertEqual(path.read_bytes(), original)

    def test_check_accepts_matching_hash_without_modifying_file(self):
        self.env["NIX_TEST_HASH"] = OLD_HASH
        self.run_hook("--check")
        self.assertEqual(self.git("diff", "--exit-code").returncode, 0)

    def test_all_updates_unchanged_plugin_hashes(self):
        self.run_hook("--all")
        self.assertIn(NEW_HASH, (self.root / "nix/home-manager/nixvim/legacy-plugins.nix").read_text())

    def test_prefetch_failure_or_missing_hash_leaves_release_unchanged(self):
        path = self.write("nix/packages/codex.nix", f'version = "2.0.0";\nhash = "{OLD_HASH}";\n')
        original = path.read_bytes()
        for fail in [True, False]:
            with self.subTest(download_failure=fail):
                if fail:
                    self.env["NIX_TEST_FAIL"] = "1"
                else:
                    self.env.pop("NIX_TEST_FAIL")
                    self.env.pop("NIX_TEST_HASH")
                self.run_hook(success=False)
                self.assertEqual(path.read_bytes(), original)
                self.assertNotIn(["flake", "check", "--no-build", "--no-update-lock-file"], self.calls())

    def test_textlint_lockfile_update_runs_nix_update(self):
        self.write(".github/textlint/pnpm-lock.yaml", "lockfileVersion: '9.0'\n# updated\n")
        self.run_hook()
        self.assertIn(["run", "nixpkgs#nix-update", "--", "--flake", "--system",
                       "aarch64-darwin", "--version=skip", "textlint"], self.calls())


if __name__ == "__main__":
    if not shutil.which("jq"):
        sys.exit("jq is required")
    unittest.main()
