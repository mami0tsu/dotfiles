{
  fetchurl,
  lib,
  mkGithubReleaseArchive,
  unzip,
}:

mkGithubReleaseArchive rec {
  pname = "git-wt";
  # renovate: datasource=github-releases depName=k1LoW/git-wt extractVersion=^v(?<version>.+)$
  version = "0.30.0";

  assetName = "git-wt_v${version}_darwin_arm64";
  archiveName = "${assetName}.zip";

  src = fetchurl {
    url = "https://github.com/k1LoW/git-wt/releases/download/v${version}/${archiveName}";
    hash = "sha256-DDPlQlDr/dhJdfKZIzKZ09XdLmHKpUFmN/u/NNqrW6s=";
  };

  binaryPath = "git-wt";
  nativeBuildInputs = [ unzip ];

  passthru.release = {
    owner = "k1LoW";
    repo = "git-wt";
    tag = "v${version}";
    asset = archiveName;
  };

  meta = {
    description = "A CLI tool for managing git worktrees";
    homepage = "https://github.com/k1LoW/git-wt";
    license = lib.licenses.mit;
    mainProgram = "git-wt";
  };
}
