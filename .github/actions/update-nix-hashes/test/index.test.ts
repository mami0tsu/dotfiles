import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { test, type TestContext } from "node:test";

const entry = fileURLToPath(new URL("../dist/index.js", import.meta.url));
const oldHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
const newHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBA=";
const revision = "1".repeat(40);
const newRevision = "2".repeat(40);
const pluginFile = "nix/home-manager/nixvim/legacy-plugins.nix";
const flakeCheck = ["flake", "check", "--no-build", "--no-update-lock-file"];
const source = (rev: string) => `owner = "example";\nrepo = "source";\nrev = "${rev}";\nhash = "${oldHash}";\n`;
const plugin = (rev: string) => "# renovate: datasource=git-refs packageName=https://github.com/example/plugin currentValue=main\n"
  + `rev = "${rev}";\nhash = "${oldHash}";\n`;

function fixture(t: TestContext) {
  const root = mkdtempSync(join(tmpdir(), "nix-hash-action-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const log = join(root, "calls.jsonl");
  const env: NodeJS.ProcessEnv = { ...process.env, NIX_TEST_LOG: log, NIX_TEST_HASH: newHash, PATH: `${root}/bin:${process.env.PATH}` };
  delete env.INPUT_MODE;
  const write = (name: string, content: string) => {
    const path = join(root, name);
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, content);
    return path;
  };
  write("bin/nix", `#!${process.execPath}\n` + String.raw`
const assert = require("node:assert/strict");
const { appendFileSync } = require("node:fs");
const args = process.argv.slice(2);
assert.deepEqual(args.splice(0, 2), ["--extra-experimental-features", "nix-command flakes"]);
appendFileSync(process.env.NIX_TEST_LOG, JSON.stringify(args) + "\n");
if (args[0] === "store") {
  assert.deepEqual(args.slice(0, 5), ["store", "prefetch-file", "--json", "--hash-type", "sha256"]);
  assert.equal(args.length, args.includes("--unpack") ? 7 : 6);
  if (process.env.NIX_TEST_FAIL) process.exit(1);
  console.log(JSON.stringify({ hash: process.env.NIX_TEST_HASH, storePath: "/unused" }));
} else if (args[0] === "eval") {
  process.stdout.write("https://example.invalid/tool.tar.gz");
} else if (args[0] === "flake") {
  assert.deepEqual(args, ["flake", "check", "--no-build", "--no-update-lock-file"]);
} else if (args[0] === "hash") {
  assert.deepEqual(args, ["hash", "convert", "--hash-algo", "sha256", "--to", "sri", "0".repeat(52)]);
  console.log("sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=");
} else {
  assert.deepEqual(args.slice(0, 2), ["run", "nixpkgs#nix-update"]);
}
`);
  chmodSync(join(root, "bin/nix"), 0o755);
  for (const command of ["nix-prefetch-url", "jq"]) {
    chmodSync(write(`bin/${command}`, "#!/bin/sh\necho 'unexpected legacy dependency' >&2\nexit 99\n"), 0o755);
  }
  write("nix/packages/codex.nix", `version = "1.0.0";\nhash = "${oldHash}";\n`);
  write("nix/packages/git-open-src.nix", source(revision));
  write(pluginFile, plugin(revision));
  write(".github/textlint/pnpm-lock.yaml", "lockfileVersion: '9.0'\n");
  const git = (...args: string[]) => execFileSync("git", args, { cwd: root, env, encoding: "utf8", stdio: "pipe" });
  git("init", "--quiet");
  git("add", "--", "nix", ".github");
  git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "fixture");
  const run = (args: string[] = [], success = true) => {
    const result = spawnSync(process.execPath, [entry, ...args], { cwd: root, env, encoding: "utf8" });
    if (success) assert.equal(result.status, 0, result.stderr);
    else assert.notEqual(result.status, 0, result.stderr);
    return result;
  };
  const read = (file: string) => readFileSync(join(root, file), "utf8");
  const calls = (): string[][] => existsSync(log) ? readFileSync(log, "utf8").trim().split("\n").map((line) => JSON.parse(line)) : [];
  return { root, env, write, git, run, read, calls };
}

test("release hash uses flat SRI and preserves file mode", (t) => {
  const f = fixture(t);
  const path = f.write("nix/packages/codex.nix", `version = "2.0.0";\nhash = "${oldHash}";\n`);
  chmodSync(path, 0o640);
  f.run();
  assert.match(f.read("nix/packages/codex.nix"), new RegExp(newHash));
  assert.equal(statSync(path).mode & 0o777, 0o640);
  assert.ok(f.calls().some((args) => args[0] === "store" && !args.includes("--unpack") && args.at(-1) === "https://example.invalid/tool.tar.gz"));
});

test("source and changed plugin hashes use unpacked sources", (t) => {
  const f = fixture(t);
  f.write("nix/packages/git-open-src.nix", source(newRevision));
  f.write(pluginFile, plugin(newRevision));
  f.run();
  for (const [file, repo] of [["nix/packages/git-open-src.nix", "source"], [pluginFile, "plugin"]]) {
    assert.ok(f.read(file).includes(newHash));
    assert.ok(f.calls().some((args) => args.includes("--unpack") && args.at(-1) === `https://github.com/example/${repo}/archive/${newRevision}.tar.gz`));
  }
});

test("unchanged packages are not prefetched", (t) => {
  const f = fixture(t);
  f.run();
  assert.deepEqual(f.calls(), [flakeCheck]);
});

test("check rejects stale hashes without modifying the file", (t) => {
  const f = fixture(t);
  assert.match(f.run(["--check"], false).stderr, /Stale hash/);
  assert.equal(f.read(pluginFile), plugin(revision));
});

test("check accepts matching hashes without modifying the file", (t) => {
  const f = fixture(t);
  f.env.NIX_TEST_HASH = oldHash;
  f.run(["--check"]);
  assert.equal(f.git("diff", "--exit-code"), "");
});

test("all updates unchanged plugin hashes", (t) => {
  const f = fixture(t);
  f.run(["--all"]);
  assert.ok(f.read(pluginFile).includes(newHash));
});

test("check accepts equivalent Nix base32 hashes without rewriting them", (t) => {
  const f = fixture(t);
  const content = plugin(revision).replace(oldHash, "0".repeat(52));
  f.write(pluginFile, content);
  f.env.NIX_TEST_HASH = oldHash;
  f.run(["--check"]);
  assert.equal(f.read(pluginFile), content);
});

test("failed or invalid prefetch results leave the release unchanged", (t) => {
  const f = fixture(t);
  const original = `version = "2.0.0";\nhash = "${oldHash}";\n`;
  f.write("nix/packages/codex.nix", original);
  for (const hash of [undefined, "not-an-sri-hash", newHash]) {
    delete f.env.NIX_TEST_FAIL;
    if (hash === undefined) delete f.env.NIX_TEST_HASH;
    else f.env.NIX_TEST_HASH = hash;
    if (hash === newHash) f.env.NIX_TEST_FAIL = "1";
    f.run([], false);
    assert.equal(f.read("nix/packages/codex.nix"), original);
    assert.ok(!f.calls().some((args) => args[0] === "flake"));
  }
});

test("textlint lockfile changes run nix-update", (t) => {
  const f = fixture(t);
  f.write(".github/textlint/pnpm-lock.yaml", "lockfileVersion: '9.0'\n# updated\n");
  f.run();
  assert.deepEqual(f.calls()[0], ["run", "nixpkgs#nix-update", "--", "--flake", "--system", "aarch64-darwin", "--version=skip", "textlint"]);
});

test("GitHub Actions mode input is honored and CLI mode takes precedence", (t) => {
  const f = fixture(t);
  f.env.INPUT_MODE = "check";
  assert.match(f.run([], false).stderr, /Stale hash/);
  f.run(["--all"]);
  assert.ok(f.read(pluginFile).includes(newHash));
});

test("invalid arguments fail before running tools", (t) => {
  const f = fixture(t);
  for (const args of [["changed"], ["--invalid"], ["--all", "--check"]]) f.run(args, false);
  f.env.INPUT_MODE = "invalid";
  f.run([], false);
  assert.deepEqual(f.calls(), []);
});

test("multiple hashes are rejected without modifying the package", (t) => {
  const f = fixture(t);
  const content = `version = "2.0.0";\nhash = "${oldHash}";\nhash = "${oldHash}";\n`;
  f.write("nix/packages/codex.nix", content);
  assert.match(f.run([], false).stderr, /Expected one hash/);
  assert.equal(f.read("nix/packages/codex.nix"), content);
});

test("incomplete plugin metadata is rejected before writing", (t) => {
  const f = fixture(t);
  const content = plugin(revision) + "# renovate: datasource=git-refs packageName=https://github.com/example/broken currentValue=main\n";
  f.write(pluginFile, content);
  assert.match(f.run(["--all"], false).stderr, /Incomplete Renovate metadata/);
  assert.equal(f.read(pluginFile), content);
});

test("changed revisions without metadata are rejected", (t) => {
  const f = fixture(t);
  const content = plugin(revision) + `rev = "${newRevision}";\n`;
  f.write(pluginFile, content);
  assert.match(f.run([], false).stderr, /not matched by Renovate metadata/);
  assert.equal(f.read(pluginFile), content);
});
