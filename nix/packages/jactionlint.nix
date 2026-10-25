{
  buildGo127Module,
  fetchFromGitHub,
  lib,
}:

buildGo127Module rec {
  pname = "jactionlint";
  # renovate: datasource=github-releases depName=jdx/jactionlint extractVersion=^v(?<version>.+)$
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "jdx";
    repo = "jactionlint";
    tag = "v${version}";
    hash = "sha256-oCfz/PVcEPsol8OsvVDTWsgDx+/0V9dqdlUZkn4Irmc=";
  };

  vendorHash = "sha256-SnP9Siop3zgGrVMuHU2IOqDkPKnfyJZVxUB/iBV8hIA=";

  subPackages = [ "cmd/jactionlint" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/jdx/jactionlint/v2.version=${version}"
  ];

  meta = {
    description = "Static checker for GitHub Actions workflows";
    homepage = "https://github.com/jdx/jactionlint";
    license = lib.licenses.mit;
    mainProgram = "jactionlint";
  };
}
