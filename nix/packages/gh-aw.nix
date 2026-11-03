{
  fetchurl,
  lib,
  mkGithubReleaseBinary,
}:

mkGithubReleaseBinary rec {
  pname = "gh-aw";
  # renovate: datasource=github-releases depName=github/gh-aw extractVersion=^v(?<version>.+)$
  version = "0.93.5";
  assetName = "darwin-arm64";

  src = fetchurl {
    url = "https://github.com/github/gh-aw/releases/download/v${version}/${assetName}";
    hash = "sha256-8HC/MixtqZCsr9gwCT1uezNqX+ZpDBlVAFVUmWM/o+c=";
  };

  executable = "gh-aw";

  passthru.release = {
    owner = "github";
    repo = "gh-aw";
    tag = "v${version}";
    asset = assetName;
  };

  meta = {
    description = "GitHub CLI extension for GitHub Agentic Workflows";
    homepage = "https://github.github.com/gh-aw/";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "gh-aw";
  };
}
