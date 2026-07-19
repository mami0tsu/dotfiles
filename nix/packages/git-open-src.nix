{
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "git-open-src";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "paulirish";
    repo = "git-open";
    # renovate: datasource=git-refs packageName=https://github.com/paulirish/git-open currentValue=master
    rev = "63c0e77aaf18b72c839b1113c1e2f9514413643b";
    hash = "sha256-E93A/KBEGlPDm98p1ClvWxzjK2ylv3BrVaEvBcuD6c4=";
  };

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    cp -R "$src" "$out"

    runHook postInstall
  '';
}
