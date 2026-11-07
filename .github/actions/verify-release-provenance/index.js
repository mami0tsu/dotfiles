const { execFileSync } = require('node:child_process');
const { createHash } = require('node:crypto');
const { mkdtempSync, readFileSync, rmSync, writeFileSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { basename, join } = require('node:path');

function run(command, args) {
  return execFileSync(command, args, {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    maxBuffer: 16 * 1024 * 1024,
  });
}

// リリース情報を持つパッケージを Nix 定義から取得し、対象一覧の重複管理を避ける
function discoverReleases(execute = run) {
  const expression = `packages: builtins.listToAttrs (builtins.concatMap
    (name: let package = packages.\${name}; in
      if package ? passthru.release then [{ inherit name; value = package.passthru.release; }] else [])
    (builtins.attrNames packages))`;
  return JSON.parse(execute('nix', [
    'eval', '--json', '.#packages.aarch64-darwin', '--apply', expression,
  ]));
}

function selectReleases(releases, changedFiles) {
  // 共通処理の変更は個別パッケージの変更と同時でも全件検証する
  const sharedChange = changedFiles.some((file) =>
    file.startsWith('.github/actions/verify-release-provenance/')
    || file === '.github/workflows/nix-package-provenance.yaml'
    || file === 'nix/packages/default.nix'
    || file.startsWith('nix/packages/lib/'));
  const changedNames = new Set(changedFiles
    .filter((file) => /^nix\/packages\/[^/]+\.nix$/.test(file))
    .map((file) => basename(file, '.nix')));
  const entries = Object.entries(releases);
  const changed = entries.filter(([name]) => changedNames.has(name));
  return sharedChange || changed.length === 0 ? entries : changed;
}

function getAttestations(owner, repo, digest, execute = run) {
  try {
    const response = JSON.parse(execute('gh', ['api', `repos/${owner}/${repo}/attestations/${digest}`]));
    if (!Array.isArray(response.attestations)) throw new Error('Invalid attestation response');
    return response.attestations;
  } catch (error) {
    // 証明が未提供の場合だけスキップし、認証エラーや通信障害は失敗させる
    if (error.status && /HTTP 404\b/.test(String(error.stderr))) return [];
    throw error;
  }
}

function verifyRelease(name, release, execute = run) {
  const { owner, repo, tag, asset } = release;
  for (const [key, value] of Object.entries({ owner, repo, tag, asset })) {
    if (typeof value !== 'string' || !value) throw new Error(`Invalid ${key} for ${name}`);
  }
  if (asset !== basename(asset) || asset === '.' || asset === '..') {
    throw new Error(`Invalid asset filename for ${name}`);
  }
  const directory = mkdtempSync(join(tmpdir(), 'release-provenance-'));
  try {
    console.log(`Verifying ${name}: ${owner}/${repo} ${tag}`);
    execute('gh', ['release', 'download', tag, '--repo', `${owner}/${repo}`, '--pattern', asset, '--dir', directory]);
    const assetPath = join(directory, asset);
    const digest = `sha256:${createHash('sha256').update(readFileSync(assetPath)).digest('hex')}`;
    const attestations = getAttestations(owner, repo, digest, execute);
    if (attestations.length === 0) {
      console.log(`Skipping ${name}: no attestations available`);
      return;
    }
    const bundlePath = join(directory, 'attestations.jsonl');
    writeFileSync(bundlePath, attestations.map(({ bundle }) => JSON.stringify(bundle)).join('\n') + '\n');
    const predicateTypes = new Set(attestations.map(({ bundle }) => {
      const payload = Buffer.from(bundle.dsseEnvelope.payload, 'base64').toString('utf8');
      return JSON.parse(payload).predicateType;
    }));
    // 暗号学的な検証は GitHub CLI に任せ、独自実装しない
    for (const predicateType of predicateTypes) {
      if (typeof predicateType !== 'string') throw new Error('Invalid attestation predicate type');
      if (predicateType.startsWith('https://in-toto.io/attestation/release/')) {
        const output = execute('gh', ['release', 'verify-asset', tag, assetPath, '--repo', `${owner}/${repo}`]);
        console.log(output);
      } else if (predicateType === 'https://slsa.dev/provenance/v1') {
        const output = execute('gh', [
          'attestation', 'verify', assetPath, '--bundle', bundlePath,
          '--repo', `${owner}/${repo}`, '--predicate-type', predicateType,
          '--source-ref', `refs/tags/${tag}`,
        ]);
        console.log(output);
      }
    }
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

function main() {
  const base = process.env['INPUT_BASE-SHA'];
  const head = process.env['INPUT_HEAD-SHA'];
  if (!base || !head) throw new Error('base-sha and head-sha are required');
  const changedFiles = run('git', ['diff', '--name-only', '-z', base, head, '--']).split('\0').filter(Boolean);
  for (const [name, release] of selectReleases(discoverReleases(), changedFiles)) {
    verifyRelease(name, release);
  }
}

module.exports = { discoverReleases, selectReleases, getAttestations, verifyRelease };

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(error.stderr ? String(error.stderr) : error.message);
    process.exitCode = 1;
  }
}
