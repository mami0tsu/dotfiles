{
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "zsh-defer-src";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "romkatv";
    repo = "zsh-defer";
    # renovate: datasource=git-refs packageName=https://github.com/romkatv/zsh-defer currentValue=master
    rev = "53a26e287fbbe2dcebb3aa1801546c6de32416fa";
    hash = "sha256-MFlvAnPCknSgkW3RFA8pfxMZZS/JbyF3aMsJj9uHHVU=";
  };

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    cp -R "$src" "$out"

    runHook postInstall
  '';
}
