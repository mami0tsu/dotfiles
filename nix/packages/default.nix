{ callPackage }:

let
  mkGithubReleaseBinary = callPackage ./lib/mk-github-release-binary.nix { };
  mkGithubReleaseArchive = callPackage ./lib/mk-github-release-archive.nix { };
in
{
  apm = callPackage ./apm.nix { inherit mkGithubReleaseArchive; };
  ax = callPackage ./ax.nix { inherit mkGithubReleaseBinary; };
  codex = callPackage ./codex.nix { inherit mkGithubReleaseArchive; };
  difit = callPackage ./difit.nix { };
  gh-aw = callPackage ./gh-aw.nix { inherit mkGithubReleaseBinary; };
  gh-stack = callPackage ./gh-stack.nix { inherit mkGithubReleaseBinary; };
  git-open-src = callPackage ./git-open-src.nix { };
  git-wt = callPackage ./git-wt.nix { inherit mkGithubReleaseArchive; };
  roots = callPackage ./roots.nix { inherit mkGithubReleaseArchive; };
  zsh-defer-src = callPackage ./zsh-defer-src.nix { };
}
