{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "apm";
  # renovate: datasource=github-releases depName=microsoft/apm extractVersion=^v(?<version>.+)$
  version = "0.26.0";
  assetName = "apm-darwin-arm64";
  archiveName = "${assetName}.tar.gz";

  src = fetchurl {
    url = "https://github.com/microsoft/apm/releases/download/v${version}/${archiveName}";
    sha256 = "1psl0qr5xwxpfsvmx4z0sn14989pd5sfs27726sffjzbic5dvggy";
  };

  sourceRoot = assetName;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/apm" "$out/bin"
    cp -R . "$out/libexec/apm/"
    ln -s "$out/libexec/apm/apm" "$out/bin/apm"

    runHook postInstall
  '';

  meta = {
    description = "Agent Package Manager";
    homepage = "https://github.com/microsoft/apm";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "apm";
  };
}
