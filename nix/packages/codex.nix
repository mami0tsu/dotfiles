{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "codex";
  # renovate: datasource=github-releases depName=openai/codex extractVersion=^rust-v(?<version>.+)$
  version = "0.142.3";
  assetName = "codex-aarch64-apple-darwin";
  archiveName = "${assetName}.tar.gz";

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/${archiveName}";
    hash = "sha256-wwMVy0HWbQAPya1mc19CiNn/DH/nSPaPcautcC1y+DI=";
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m 0755 "${assetName}" "$out/bin/codex"

    runHook postInstall
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "codex";
  };
}
