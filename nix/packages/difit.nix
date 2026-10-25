{
  stdenvNoCC,
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  nodejs_26,
  pnpm,
  pnpmConfigHook,
}:

stdenvNoCC.mkDerivation rec {
  pname = "difit";
  # renovate: datasource=github-releases depName=yoshiko-pg/difit extractVersion=^v(?<version>.+)$
  version = "5.0.12";

  src = fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    tag = "v${version}";
    hash = "sha256-1EoC5t+8KjNmwKg5lFLig26tzCnp2byhkeGjctVdRls=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs_26
    pnpm
    pnpmConfigHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    inherit pnpm;
    hash = "sha256-vuQxZ8U0PQ+f6o1DMmKii+Bs4XHML6N2ZlB5C3JKxqo=";
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

    makeWrapper ${nodejs_26}/bin/node "$out/bin/difit" \
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
