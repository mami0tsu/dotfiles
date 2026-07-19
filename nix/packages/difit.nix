{
  stdenvNoCC,
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
}:

stdenvNoCC.mkDerivation rec {
  pname = "difit";
  # renovate: datasource=github-releases depName=yoshiko-pg/difit extractVersion=^v(?<version>.+)$
  version = "4.0.5";

  src = fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    tag = "v${version}";
    hash = "sha256-01x0CfNNgg7BGQrQ+fTUSZYE+3lVgWG+2W0FbxiYJPc=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpm_10
    pnpmConfigHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    pnpm = pnpm_10;
    hash = "sha256-fh7YhyOIZvaFoWxgazn464bZ7VeWBlFs1Iow/6TSkpg=";
  };

  buildPhase = ''
    runHook preBuild

    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    package_dir="$out/lib/node_modules/${pname}"
    mkdir -p "$package_dir" "$out/bin"
    cp -R dist node_modules package.json README.md "$package_dir/"
    find "$package_dir/node_modules" -xtype l -delete

    makeWrapper ${nodejs}/bin/node "$out/bin/difit" \
      --add-flags "$package_dir/dist/cli/index.js"

    runHook postInstall
  '';

  meta = {
    description = "GitHub-like diff viewer for local code review";
    homepage = "https://github.com/yoshiko-pg/difit";
    license = lib.licenses.mit;
    mainProgram = "difit";
  };
}
