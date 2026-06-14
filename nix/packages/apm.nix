{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "apm";
  version = "0.20.0";

  src = fetchurl {
    url = "https://github.com/microsoft/apm/releases/download/v${version}/apm-darwin-arm64.tar.gz";
    sha256 = "1zdy26r2h9r95hdr2d4f37z6r8lwahb01n6kgkp429gkszrrzpcr";
  };

  sourceRoot = "apm-darwin-arm64";

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
