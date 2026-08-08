{ stdenvNoCC }:

{
  pname,
  version,
  src,
  sourceRoot ? ".",
  binaryPath,
  meta,
  nativeBuildInputs ? [ ],
  passthru ? { },
  postInstall ? "",
  ...
}:

stdenvNoCC.mkDerivation {
  inherit
    pname
    version
    src
    sourceRoot
    meta
    nativeBuildInputs
    passthru
    postInstall
    ;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -d "$out/libexec/${pname}" "$out/bin"
    cp -R . "$out/libexec/${pname}/"
    ln -s "$out/libexec/${pname}/${binaryPath}" "$out/bin/${meta.mainProgram}"

    runHook postInstall
  '';
}
