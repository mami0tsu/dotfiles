{
  fetchurl,
  git,
  lib,
  makeWrapper,
  mkGithubReleaseArchive,
}:

mkGithubReleaseArchive rec {
  pname = "apm";
  # renovate: datasource=github-releases depName=microsoft/apm extractVersion=^v(?<version>.+)$
  version = "0.26.0";
  assetName = "apm-darwin-arm64";
  archiveName = "${assetName}.tar.gz";

  src = fetchurl {
    url = "https://github.com/microsoft/apm/releases/download/v${version}/${archiveName}";
    hash = "sha256-/r3dCovrS+e0EecI7XRpN6FEgtXgk163drfzXjIGVN8=";
  };

  sourceRoot = assetName;

  binaryPath = "apm";
  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/apm" --prefix PATH : ${lib.makeBinPath [ git ]}
  '';

  passthru.release = {
    owner = "microsoft";
    repo = "apm";
    tag = "v${version}";
    asset = archiveName;
  };

  meta = {
    description = "Agent Package Manager";
    homepage = "https://github.com/microsoft/apm";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "apm";
  };
}
