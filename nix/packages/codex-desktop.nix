{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "codex-desktop";
  version = "26.1021.31345";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-arm64-${version}.zip";
    hash = "sha256-KvzVjgSEp2R5zKIxdOCFEnqdnmNGa3VznraCWl/2E/Q=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R ChatGPT.app "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "OpenAI's official ChatGPT desktop app with Codex";
    homepage = "https://chatgpt.com/features/codex";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-darwin" ];
  };
}
