{
  fetchurl,
  lib,
  mkGithubReleaseBinary,
}:

mkGithubReleaseBinary rec {
  pname = "gh-stack";
  # renovate: datasource=github-releases depName=github/gh-stack extractVersion=^v(?<version>.+)$
  version = "0.1.0";
  assetName = "darwin-arm64";

  src = fetchurl {
    url = "https://github.com/github/gh-stack/releases/download/v${version}/${assetName}";
    hash = "sha256-XKmCQaJl1t4BgJXNrl88QNpcp4JFDuwOqRqo4+sYMQM=";
  };

  executable = "gh-stack";

  passthru.release = {
    owner = "github";
    repo = "gh-stack";
    tag = "v${version}";
    asset = assetName;
  };

  meta = {
    description = "GitHub CLI extension for managing stacked branches and pull requests";
    homepage = "https://github.com/github/gh-stack";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "gh-stack";
  };
}
