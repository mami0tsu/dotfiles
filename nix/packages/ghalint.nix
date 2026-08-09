{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule rec {
  pname = "ghalint";
  # renovate: datasource=github-releases depName=suzuki-shunsuke/ghalint extractVersion=^v(?<version>.+)$
  version = "1.5.6";

  src = fetchFromGitHub {
    owner = "suzuki-shunsuke";
    repo = "ghalint";
    tag = "v${version}";
    hash = "sha256-u85vX9lg5JKUvRjFloE4KZUm/qs8RmjoY/hybtJk/kc=";
  };

  vendorHash = "sha256-n++Rq79KHyRVhIXIdN9IOADTGEG73Wl2SUq/YEo++WM=";

  subPackages = [ "cmd/ghalint" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = {
    description = "GitHub Actions policy checker";
    homepage = "https://github.com/suzuki-shunsuke/ghalint";
    license = lib.licenses.mit;
  };
}
