import { execFileSync, spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdtempSync, readFileSync, renameSync, rmSync, statSync, writeFileSync } from "node:fs";
import { basename, dirname, join } from "node:path";
const pluginFile = "nix/home-manager/nixvim/legacy-plugins.nix";
const sourcePackages = new Set(["git-open-src", "zsh-defer-src"]);
const releasePackages = new Set(["apm", "ax", "claude-code", "codex", "gh-aw", "gh-stack", "git-wt", "roots"]);
const hashLine = /^([\t ]*)hash[\t ]*=[\t ]*"([^"\r\n]+)";[\t ]*$/gm;
function run(command, args) {
    return execFileSync(command, args, {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "inherit"],
        maxBuffer: 16 * 1024 * 1024,
    });
}
function nix(...args) {
    return run("nix", ["--extra-experimental-features", "nix-command flakes", ...args]);
}
function prefetchHash(url, unpack = false) {
    const result = JSON.parse(nix("store", "prefetch-file", "--json", "--hash-type", "sha256", ...(unpack ? ["--unpack"] : []), url));
    if (typeof result !== "object" || result === null || !("hash" in result)
        || typeof result.hash !== "string" || !/^sha256-[A-Za-z0-9+/]{43}=$/.test(result.hash)) {
        throw new Error(`Invalid SHA-256 prefetch result for ${url}`);
    }
    return result.hash;
}
function writeAtomically(file, content) {
    const directory = mkdtempSync(join(dirname(file), ".nix-hash-"));
    try {
        const temporary = join(directory, basename(file));
        const mode = statSync(file).mode & 0o777;
        writeFileSync(temporary, content, { mode });
        chmodSync(temporary, mode);
        renameSync(temporary, file);
    }
    finally {
        rmSync(directory, { recursive: true, force: true });
    }
}
function replaceSingleHash(file, hash) {
    let count = 0;
    const content = readFileSync(file, "utf8").replace(hashLine, (_line, indent) => {
        count += 1;
        return `${indent}hash = "${hash}";`;
    });
    if (count !== 1) {
        throw new Error(`Expected one hash in ${file}, found ${count}`);
    }
    writeAtomically(file, content);
}
function updateSourcePackage(file) {
    const content = readFileSync(file, "utf8");
    const owner = content.match(/^\s*owner\s*=\s*"([^"\r\n]+)";\s*$/m)?.[1];
    const repo = content.match(/^\s*repo\s*=\s*"([^"\r\n]+)";\s*$/m)?.[1];
    const revision = content.match(/^\s*rev\s*=\s*"([a-f0-9]{40})";\s*$/m)?.[1];
    if (!owner || !repo || !revision) {
        throw new Error(`Incomplete GitHub source metadata in ${file}`);
    }
    replaceSingleHash(file, prefetchHash(`https://github.com/${owner}/${repo}/archive/${revision}.tar.gz`, true));
}
function updateWithNixUpdate(packageName) {
    nix("run", "nixpkgs#nix-update", "--", "--flake", "--system", "aarch64-darwin", "--version=skip", packageName);
}
function updateChangedPackages() {
    const changedFiles = run("git", ["diff", "--name-only", "-z", "HEAD", "--", "nix/packages"]).split("\0");
    for (const file of changedFiles) {
        if (dirname(file) !== "nix/packages" || !file.endsWith(".nix") || file === "nix/packages/default.nix") {
            continue;
        }
        const packageName = basename(file, ".nix");
        if (sourcePackages.has(packageName)) {
            updateSourcePackage(file);
        }
        else if (releasePackages.has(packageName)) {
            const url = nix("eval", "--raw", `.#packages.aarch64-darwin.${packageName}.src.url`).trim();
            replaceSingleHash(file, prefetchHash(url));
        }
        else {
            updateWithNixUpdate(packageName);
        }
    }
    const result = spawnSync("git", [
        "diff", "--quiet", "HEAD", "--", ".github/textlint/package.json", ".github/textlint/pnpm-lock.yaml",
    ], { stdio: "inherit" });
    if (result.error)
        throw result.error;
    if (result.status === 1) {
        updateWithNixUpdate("textlint");
    }
    else if (result.status !== 0) {
        throw new Error(`git diff failed with status ${result.status}`);
    }
}
function updatePluginHashes(mode) {
    if (!existsSync(pluginFile))
        return;
    const changedRevisions = new Set();
    if (mode === "changed") {
        const diff = run("git", ["diff", "--no-ext-diff", "--unified=0", "HEAD", "--", pluginFile]);
        for (const match of diff.matchAll(/^\+[\t ]*rev = "([a-f0-9]{40})";$/gm)) {
            changedRevisions.add(match[1]);
        }
        if (changedRevisions.size === 0)
            return;
    }
    const matchedRevisions = new Set();
    let source;
    const lines = readFileSync(pluginFile, "utf8").split("\n").map((line) => {
        const metadata = line.match(/^\s*# renovate: datasource=git-refs packageName=https:\/\/github\.com\/([^/\s]+)\/([^\s]+) currentValue=\S+\s*$/);
        const revision = line.match(/^\s*rev = "([a-f0-9]{40})";$/);
        const hash = line.match(/^([\t ]*)hash = "([^"\r\n]+)";$/);
        if (metadata) {
            if (source)
                throw new Error(`Incomplete Renovate metadata in ${pluginFile}`);
            source = { owner: metadata[1], repo: metadata[2] };
        }
        else if (source && revision) {
            source.revision = revision[1];
        }
        else if (source?.revision && hash) {
            if (mode !== "changed" || changedRevisions.has(source.revision)) {
                matchedRevisions.add(source.revision);
                const actualHash = prefetchHash(`https://github.com/${source.owner}/${source.repo}/archive/${source.revision}.tar.gz`, true);
                if (mode === "check") {
                    const existingHash = hash[2].startsWith("sha256-")
                        ? hash[2]
                        : nix("hash", "convert", "--hash-algo", "sha256", "--to", "sri", hash[2]).trim();
                    if (actualHash !== existingHash) {
                        throw new Error(`Stale hash for ${source.owner}/${source.repo} at ${source.revision}`);
                    }
                }
                else {
                    line = `${hash[1]}hash = "${actualHash}";`;
                }
            }
            source = undefined;
        }
        return line;
    });
    if (source)
        throw new Error(`Incomplete Renovate metadata in ${pluginFile}`);
    if (mode === "check")
        return;
    for (const revision of changedRevisions) {
        if (!matchedRevisions.has(revision)) {
            throw new Error(`Changed revision ${revision} was not matched by Renovate metadata in ${pluginFile}`);
        }
    }
    writeAtomically(pluginFile, lines.join("\n"));
}
function main() {
    const args = process.argv.slice(2);
    if (args.length === 1 && ["-h", "--help"].includes(args[0])) {
        console.log("Usage: node dist/index.js [--changed | --all | --check]");
        return;
    }
    const mode = args.length ? args[0].replace(/^--/, "") : (process.env.INPUT_MODE || "changed");
    if (args.length > 1 || (args.length === 1 && !args[0].startsWith("--"))
        || !["changed", "all", "check"].includes(mode)) {
        throw new Error(`Invalid mode: ${args.join(" ") || mode}. Expected changed, all, or check.`);
    }
    if (mode === "changed")
        updateChangedPackages();
    updatePluginHashes(mode);
    nix("flake", "check", "--no-build", "--no-update-lock-file");
}
try {
    main();
}
catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
}
