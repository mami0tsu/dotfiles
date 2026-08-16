{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "ghostty";
  version = "tip-9009122";
  assetName = "ghostty-macos-universal.zip";
  assetId = "516114575";

  src = fetchurl {
    url = "https://api.github.com/repos/ghostty-org/ghostty/releases/assets/${assetId}";
    hash = "sha256-tQXAlyWjn/XhS/54DdTN6+++vnNO3qV+naiLUwy6gNk=";
    name = assetName;
    curlOptsList = [
      "-H"
      "Accept: application/octet-stream"
    ];
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -d "$out/Applications" "$out/bin" "$out/share/man/man1" "$out/share/man/man5"
    cp -R Ghostty.app "$out/Applications/"
    ln -s "$out/Applications/Ghostty.app/Contents/MacOS/ghostty" "$out/bin/ghostty"
    ln -s "$out/Applications/Ghostty.app/Contents/Resources/man/man1/ghostty.1" "$out/share/man/man1/ghostty.1"
    ln -s "$out/Applications/Ghostty.app/Contents/Resources/man/man5/ghostty.5" "$out/share/man/man5/ghostty.5"

    runHook postInstall
  '';

  passthru.release = {
    owner = "ghostty-org";
    repo = "ghostty";
    tag = "tip";
    asset = assetName;
    inherit assetId;
    revision = "9009122953f59d4900143aad587202a70c2136f4";
  };

  meta = {
    description = "Fast, feature-rich terminal emulator";
    homepage = "https://ghostty.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "ghostty";
  };
}
