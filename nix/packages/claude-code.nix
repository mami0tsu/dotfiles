{
  fetchurl,
  lib,
  mkGithubReleaseArchive,
}:

mkGithubReleaseArchive rec {
  pname = "claude-code";
  # renovate: datasource=github-releases depName=anthropics/claude-code extractVersion=^v(?<version>.+)$
  version = "2.1.233";

  archiveName = "claude-darwin-arm64.tar.gz";

  src = fetchurl {
    url = "https://github.com/anthropics/claude-code/releases/download/v${version}/${archiveName}";
    hash = "sha256-Xc6SzNkxc/6tAY8qgmIYnaiMfW//uqZmt6gaawX3Kv4=";
  };

  sourceRoot = ".";

  binaryPath = "claude";

  passthru.release = {
    owner = "anthropics";
    repo = "claude-code";
    tag = "v${version}";
    asset = archiveName;
  };

  meta = {
    description = "Agentic coding tool that lives in your terminal";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "claude";
  };
}
