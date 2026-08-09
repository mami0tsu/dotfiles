{
  fetchPnpmDeps,
  lib,
  makeWrapper,
  nodejs_24,
  pnpm,
  pnpmConfigHook,
  stdenvNoCC,
}:

let
  packageJson = builtins.fromJSON (builtins.readFile ../../.github/textlint/package.json);
in
stdenvNoCC.mkDerivation {
  pname = "textlint";
  version = packageJson.dependencies.textlint;

  src = ../../.github/textlint;

  nativeBuildInputs = [
    makeWrapper
    nodejs_24
    pnpm
    pnpmConfigHook
  ];

  pnpmDeps = fetchPnpmDeps {
    pname = "textlint";
    version = packageJson.dependencies.textlint;
    src = ../../.github/textlint;
    fetcherVersion = 4;
    inherit pnpm;
    hash = "sha256-tvH6BdGBUEulWZhGZrd37cbsdFQgd4Gtrge5TVXKwAs=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    package_dir="$out/lib/node_modules/textlint"
    mkdir -p "$package_dir" "$out/bin"
    cp -R node_modules package.json "$package_dir/"

    makeWrapper ${nodejs_24}/bin/node "$out/bin/textlint" \
      --add-flags "$package_dir/node_modules/textlint/bin/textlint.js" \
      --prefix NODE_PATH : "$package_dir/node_modules"

    runHook postInstall
  '';

  meta = {
    description = "Pluggable natural language linter with the dotfiles rule set";
    homepage = "https://textlint.org/";
    license = lib.licenses.mit;
    mainProgram = "textlint";
    platforms = lib.platforms.unix;
  };
}
