{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "claude-desktop";
  version = "1.40609.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/releases/darwin/universal/${version}/Claude-f65e386db0db64c8f8b39950e25adb11f5f5e3f3.zip";
    hash = "sha256-Xf7Nm0av6DkLnQwUPFa92CbW1QHCaG/rlOGgkyKW1Eo=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Claude.app "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Anthropic's official Claude AI desktop app";
    homepage = "https://claude.com/download";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
  };
}
