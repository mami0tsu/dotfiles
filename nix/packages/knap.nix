{
  fetchurl,
  lib,
  makeWrapper,
  nodejs,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "knap";
  # renovate: datasource=npm depName=knap extractVersion=^(?<version>.+)$
  version = "0.6.0";
  dayjsVersion = "1.11.23";

  src = fetchurl {
    url = "https://registry.npmjs.org/knap/-/knap-${version}.tgz";
    hash = "sha512-FpuNFQ67rrgbZu3prheLA05/ND0gdHchRBC43Abn5CmROwn8XdYdar5+fRcylN/jrDnSNKj3aFdg92qvQJbYZA==";
  };

  dayjs = fetchurl {
    url = "https://registry.npmjs.org/dayjs/-/dayjs-${dayjsVersion}.tgz";
    hash = "sha512-QDTCU0M0MxR3hQfnlDJfwekQiaanm1ubOD231u73WBckQ/fsamwRLiE2GBz6D3a/xF1NgfiDLJjXBa1hYOYTtQ==";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    ${nodejs}/bin/node -e 'const deps = require("./package.json").dependencies; if (Object.keys(deps).length !== 1 || deps.dayjs !== "^${dayjsVersion}") process.exit(1)'
    package_dir="$out/lib/node_modules/knap"
    mkdir -p "$package_dir/node_modules/dayjs" "$out/bin"
    cp -R . "$package_dir/"
    tar -xzf "$dayjs" --strip-components=1 -C "$package_dir/node_modules/dayjs"
    makeWrapper ${nodejs}/bin/node "$out/bin/knap" \
      --add-flags "$package_dir/dist/cli.js"

    runHook postInstall
  '';

  meta = {
    description = "Template language for generating Markdown";
    homepage = "https://knap.md/";
    license = lib.licenses.mit;
    mainProgram = "knap";
    platforms = lib.platforms.unix;
  };
}
