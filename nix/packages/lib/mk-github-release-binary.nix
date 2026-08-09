{ stdenvNoCC }:

{
  pname,
  version,
  src,
  executable,
  meta,
  passthru ? { },
  ...
}:

stdenvNoCC.mkDerivation {
  inherit
    pname
    version
    src
    meta
    passthru
    ;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/${executable}"

    runHook postInstall
  '';
}
