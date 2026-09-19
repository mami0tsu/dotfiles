{
  fetchurl,
  lib,
  stdenvNoCC,
  undmg,
}:

stdenvNoCC.mkDerivation rec {
  pname = "codex-desktop";
  version = "26.915.31945";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg";
    hash = "sha256-9LyOlfkh9Fw/HRiR6tIer9vo5AYS6zTPC+FzmIwZlt0=";
  };

  nativeBuildInputs = [ undmg ];

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
    platforms = lib.platforms.darwin;
  };
}
