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
  version = "0.35.1";
  assetName = "apm-darwin-arm64";
  archiveName = "${assetName}.tar.gz";

  src = fetchurl {
    url = "https://github.com/microsoft/apm/releases/download/v${version}/${archiveName}";
    hash = "sha256-gEfyRDaZy3/ZBPaR88l9gnZgYL9wpLho5/mU5E8HxHs=";
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
