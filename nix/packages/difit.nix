{
  stdenvNoCC,
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  nodejs,
  pnpm_10,
  pnpmBuildHook,
  pnpmConfigHook,
}:

stdenvNoCC.mkDerivation rec {
  pname = "difit";
  version = "4.0.5";

  src = fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    tag = "v${version}";
    sha256 = "1xr4k0c6y1bdv6z630amg7xh95j9sksgkl0a370hx0jdyc4p8p6k";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpm_10
    pnpmConfigHook
    pnpmBuildHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    pnpm = pnpm_10;
    hash = "sha256-fh7YhyOIZvaFoWxgazn464bZ7VeWBlFs1Iow/6TSkpg=";
  };

  installPhase = ''
    runHook preInstall

    package_dir="$out/lib/node_modules/difit"
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
