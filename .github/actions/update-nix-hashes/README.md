# Update Nix hashes

This repository-local Node.js 24 action updates hashes after Renovate changes Nix
packages or textlint dependencies. It requires Git and Nix with flake support.
The committed `dist/index.js` runs without installing dependencies.

After checking out the repository and installing Nix, call it from a workflow:

```yaml
- uses: ./.github/actions/update-nix-hashes
  with:
    mode: changed
```

| Mode | Behavior |
| --- | --- |
| `changed` (default) | Update packages, textlint dependencies, and plugin revisions modified relative to `HEAD`. |
| `all` | Refresh every legacy Neovim plugin hash. |
| `check` | Verify every legacy Neovim plugin hash without modifying files. |

Every successful invocation ends with `nix flake check --no-build --no-update-lock-file`.

Renovate's `postUpgradeTasks` executes commands before committing its changes.
It calls the same entry point inside the Renovate container:

```sh
node .github/actions/update-nix-hashes/dist/index.js
```

For local verification, pass `--changed`, `--all`, or `--check` to that command.
CLI arguments take precedence over the action's `INPUT_MODE` environment variable.

To change the implementation:

```sh
cd .github/actions/update-nix-hashes
pnpm install --frozen-lockfile --ignore-scripts
pnpm run typecheck
pnpm run build
pnpm test
```

Commit the regenerated `dist/index.js` with the TypeScript source. CI rebuilds
the action, checks for differences, runs its tests, and invokes it as a local action.
Renovate also rebuilds this file when it updates the action's dependencies.
