const assert = require('node:assert/strict');
const { existsSync, readFileSync, writeFileSync } = require('node:fs');
const { join } = require('node:path');
const { test } = require('node:test');
const { discoverReleases, selectReleases, getAttestations, verifyRelease } = require('../index.js');

const release = { owner: 'owner', repo: 'repo', tag: 'v1', asset: 'binary.tar.gz' };
const releases = { 'new-tool': release, 'another-tool': release };

function apiError(status) {
  return Object.assign(new Error('API request failed'), { status: 1, stderr: `gh: HTTP ${status}` });
}

function attestation(predicateType) {
  return { bundle: { dsseEnvelope: { payload: Buffer.from(JSON.stringify({ predicateType })).toString('base64') } } };
}

test('discovers release metadata through Nix evaluation', () => {
  assert.deepEqual(discoverReleases((command, args) => {
    assert.equal(command, 'nix');
    assert.ok(args.includes('.#packages.aarch64-darwin'));
    assert.match(args.at(-1), /package \? passthru\.release/);
    return JSON.stringify(releases);
  }), releases);
});

test('selects a newly added tool without an action-side allowlist', () => {
  assert.deepEqual(selectReleases(releases, ['nix/packages/new-tool.nix']), [['new-tool', release]]);
});

test('shared changes and changes with no matching release select all packages', () => {
  for (const files of [
    ['nix/packages/new-tool.nix', 'nix/packages/lib/helper.nix'],
    ['nix/packages/new-tool.nix', 'nix/packages/default.nix'],
    ['.github/actions/verify-release-provenance/index.js'],
    ['nix/packages/non-release.nix'],
  ]) assert.deepEqual(selectReleases(releases, files), Object.entries(releases));
});

test('only missing attestations are skipped', () => {
  assert.deepEqual(getAttestations('owner', 'repo', 'sha256:abc', () => { throw apiError(404); }), []);
  assert.deepEqual(getAttestations('owner', 'repo', 'sha256:abc', () => '{"attestations":[]}'), []);
  for (const status of [401, 403, 500]) {
    assert.throws(() => getAttestations('owner', 'repo', 'sha256:abc', () => { throw apiError(status); }));
  }
  assert.throws(() => getAttestations('owner', 'repo', 'sha256:abc', () => '{}'));
});

test('verifies release and SLSA predicates against the repository and tag', () => {
  let directory;
  const calls = [];
  const attestations = [
    attestation('https://in-toto.io/attestation/release/v1'),
    attestation('https://slsa.dev/provenance/v1'),
    attestation('https://slsa.dev/provenance/v1'),
    attestation('https://example.com/unsupported'),
  ];
  verifyRelease('new-tool', release, (command, args) => {
    assert.equal(command, 'gh');
    calls.push(args);
    if (args[1] === 'download') {
      directory = args[args.indexOf('--dir') + 1];
      writeFileSync(join(directory, release.asset), 'artifact');
    } else if (args[0] === 'api') {
      assert.match(args[1], /^repos\/owner\/repo\/attestations\/sha256:[a-f0-9]{64}$/);
      return JSON.stringify({ attestations });
    } else if (args[0] === 'attestation') {
      assert.equal(args[args.indexOf('--repo') + 1], 'owner/repo');
      assert.equal(args[args.indexOf('--source-ref') + 1], 'refs/tags/v1');
      const bundlePath = args[args.indexOf('--bundle') + 1];
      assert.equal(readFileSync(bundlePath, 'utf8').trim().split('\n').length, 4);
    }
    return '';
  });
  assert.equal(calls.filter((args) => args[1] === 'verify-asset').length, 1);
  assert.equal(calls.filter((args) => args[0] === 'attestation').length, 1);
  assert.equal(existsSync(directory), false);
});

test('propagates verification failures and cleans downloaded artifacts', () => {
  let directory;
  assert.throws(() => verifyRelease('new-tool', release, (_command, args) => {
    if (args[1] === 'download') {
      directory = args[args.indexOf('--dir') + 1];
      writeFileSync(join(directory, release.asset), 'artifact');
      return '';
    }
    if (args[0] === 'api') return JSON.stringify({ attestations: [attestation('https://slsa.dev/provenance/v1')] });
    throw new Error('Invalid signature');
  }), /Invalid signature/);
  assert.equal(existsSync(directory), false);
});
