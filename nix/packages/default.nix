{ callPackage, pkgs }:

let
  # リポジトリ共通の指定から Node.js のメジャーバージョンを選ぶ
  packageJson = builtins.fromJSON (builtins.readFile ../../package.json);
  nodejs = pkgs."nodejs_${pkgs.lib.versions.major packageJson.engines.node}";
  mkGithubReleaseBinary = callPackage ./lib/mk-github-release-binary.nix { };
  mkGithubReleaseArchive = callPackage ./lib/mk-github-release-archive.nix { };
in
{
  apm = callPackage ./apm.nix { inherit mkGithubReleaseArchive; };
  ax = callPackage ./ax.nix { inherit mkGithubReleaseBinary; };
  claude-code = callPackage ./claude-code.nix { inherit mkGithubReleaseArchive; };
  claude-desktop = callPackage ./claude-desktop.nix { };
  codex = callPackage ./codex.nix { inherit mkGithubReleaseArchive; };
  codex-desktop = callPackage ./codex-desktop.nix { };
  difit = callPackage ./difit.nix { inherit nodejs; };
  gh-aw = callPackage ./gh-aw.nix { inherit mkGithubReleaseBinary; };
  gh-stack = callPackage ./gh-stack.nix { inherit mkGithubReleaseBinary; };
  git-open-src = callPackage ./git-open-src.nix { };
  git-wt = callPackage ./git-wt.nix { inherit mkGithubReleaseArchive; };
  jactionlint = callPackage ./jactionlint.nix { };
  roots = callPackage ./roots.nix { inherit mkGithubReleaseArchive; };
  textlint = callPackage ./textlint.nix { inherit nodejs; };
  zsh-defer-src = callPackage ./zsh-defer-src.nix { };
}
