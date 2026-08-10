{
  fetchurl,
  lib,
  mkGithubReleaseBinary,
}:

mkGithubReleaseBinary rec {
  pname = "ax";
  # renovate: datasource=github-releases depName=yusukebe/ax extractVersion=^v(?<version>.+)$
  version = "0.1.23";
  assetName = "ax-darwin-arm64";

  src = fetchurl {
    url = "https://github.com/yusukebe/ax/releases/download/v${version}/${assetName}";
    hash = "sha256-FCCrnigkNiCtCHsuzpskyZaxfJGGUdltOMu2A+WKvOk=";
  };

  executable = "ax";

  passthru.release = {
    owner = "yusukebe";
    repo = "ax";
    tag = "v${version}";
    asset = assetName;
  };

  meta = {
    description = "AI-era curl: fetch, discover, extract";
    homepage = "https://github.com/yusukebe/ax";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "ax";
  };
}
