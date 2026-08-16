{
  fetchurl,
  lib,
  mkGithubReleaseArchive,
}:

mkGithubReleaseArchive rec {
  pname = "codex";
  # renovate: datasource=github-releases depName=openai/codex extractVersion=^rust-v(?<version>.+)$
  version = "0.147.0";

  assetName = "codex-package-aarch64-apple-darwin";
  archiveName = "${assetName}.tar.gz";

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/${archiveName}";
    hash = "sha256-F7KYTrIrYH49DCVyglL8kPUQ5Ha605ptn0XNsapoVDI=";
  };

  sourceRoot = ".";

  binaryPath = "bin/codex";

  postInstall = ''
    ln -s \
      "$out/libexec/${pname}/bin/codex-code-mode-host" \
      "$out/bin/codex-code-mode-host"
  '';

  passthru.release = {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${version}";
    asset = archiveName;
  };

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "codex";
  };
}
