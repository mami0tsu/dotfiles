{
  buildGo127Module,
  fetchFromGitHub,
  lib,
}:

buildGo127Module rec {
  pname = "jactionlint";
  # renovate: datasource=github-releases depName=jdx/jactionlint extractVersion=^v(?<version>.+)$
  version = "2.5.0";

  src = fetchFromGitHub {
    owner = "jdx";
    repo = "jactionlint";
    tag = "v${version}";
    hash = "sha256-u9qyLHqiccAzLKOS8MPA0Nq/CWLu2GGYConX5xUFXks=";
  };

  vendorHash = "sha256-jf7hKPnaSl4iTYT0mtRRAEmgLKAA/lj0vSVoO9+iOvw=";

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
