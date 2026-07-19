{
  buildGoModule,
  fetchFromGitHub,
  git,
  lib,
}:

buildGoModule rec {
  pname = "git-wt";
  # renovate: datasource=github-tags depName=k1LoW/git-wt extractVersion=^v(?<version>.+)$
  version = "0.27.0";

  src = fetchFromGitHub {
    owner = "k1LoW";
    repo = "git-wt";
    tag = "v${version}";
    hash = "sha256-oGY9uMqP/hlIG9p/JaVqoBaxI7VFDIEIlwP5rBa3Diw=";
  };

  vendorHash = "sha256-4ak2Gx/i/yvj/tAoDJjsfpBUKJI5iDyKIuv7R7Pzz/w=";

  nativeCheckInputs = [ git ];

  meta = {
    description = "A CLI tool for managing git worktrees";
    homepage = "https://github.com/k1LoW/git-wt";
    license = lib.licenses.mit;
  };
}
