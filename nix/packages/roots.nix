{
  buildGoModule,
  fetchFromGitHub,
  git,
  lib,
}:

buildGoModule rec {
  pname = "roots";
  # renovate: datasource=github-tags depName=k1LoW/roots extractVersion=^v(?<version>.+)$
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "k1LoW";
    repo = "roots";
    tag = "v${version}";
    hash = "sha256-ACMRfWY/lhc3C/KVhuUyS1rgkSHGWPxZrmYt+pXupJI=";
  };

  vendorHash = "sha256-uxcT5VzlTCxxnx09p13mot0wVbbas/otoHdg7QSDt4E=";

  nativeCheckInputs = [ git ];

  meta = {
    description = "A CLI tool for managing project roots";
    homepage = "https://github.com/k1LoW/roots";
    license = lib.licenses.mit;
  };
}
