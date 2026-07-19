{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "ax";
  # renovate: datasource=github-releases depName=yusukebe/ax extractVersion=^v(?<version>.+)$
  version = "0.1.10";
  assetName = "ax-darwin-arm64";

  src = fetchurl {
    url = "https://github.com/yusukebe/ax/releases/download/v${version}/${assetName}";
    hash = "sha256-FCCrnigkNiCtCHsuzpskyZaxfJGGUdltOMu2A+WKvOk=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m 0755 "$src" "$out/bin/ax"

    runHook postInstall
  '';

  meta = {
    description = "AI-era curl: fetch, discover, extract";
    homepage = "https://github.com/yusukebe/ax";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "ax";
  };
}
