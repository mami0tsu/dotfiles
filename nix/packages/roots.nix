{
  fetchurl,
  lib,
  mkGithubReleaseArchive,
  unzip,
}:

mkGithubReleaseArchive rec {
  pname = "roots";
  # renovate: datasource=github-releases depName=k1LoW/roots extractVersion=^v(?<version>.+)$
  version = "0.4.1";

  assetName = "roots_v${version}_darwin_arm64";
  archiveName = "${assetName}.zip";

  src = fetchurl {
    url = "https://github.com/k1LoW/roots/releases/download/v${version}/${archiveName}";
    hash = "sha256-fWWMN1y8Mx0HWxj8qxXPJBRwRrnIjVWHiG9uLlRbiyo=";
  };

  binaryPath = "roots";
  nativeBuildInputs = [ unzip ];

  passthru.release = {
    owner = "k1LoW";
    repo = "roots";
    tag = "v${version}";
    asset = archiveName;
  };

  meta = {
    description = "A CLI tool for managing project roots";
    homepage = "https://github.com/k1LoW/roots";
    license = lib.licenses.mit;
    mainProgram = "roots";
  };
}
