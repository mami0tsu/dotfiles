{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "claude-desktop";
  version = "2.2553.1";

  src = fetchurl {
    url = "https://downloads.claude.ai/releases/darwin/universal/${version}/Claude-c38127e27202ddc1c8c187102f7798a93b1b8ede.zip";
    hash = "sha256-GMWR59il2fdnwjiNBO7lGyKtkiLFhyxtKoCh4b/g3dk=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";
  dontFixup = true;

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
