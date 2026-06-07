{ pkgs, ... }:

let
  roots = pkgs.buildGoModule rec {
    pname = "roots";
    version = "0.4.1";

    src = pkgs.fetchFromGitHub {
      owner = "k1LoW";
      repo = "roots";
      rev = "0fa24290d16582550c7156d92a6a040ef79f617d"; # v0.4.1
      sha256 = "14m4xsazlbb6mrczqn66468y0njb6bjqd5gj1cvig5izcryi28q0";
    };

    vendorHash = "sha256-uxcT5VzlTCxxnx09p13mot0wVbbas/otoHdg7QSDt4E=";

    nativeCheckInputs = [ pkgs.git ];

    meta = with pkgs.lib; {
      description = "A CLI tool for managing project roots";
      homepage = "https://github.com/k1LoW/roots";
      license = licenses.mit;
    };
  };

  git-wt = pkgs.buildGoModule rec {
    pname = "git-wt";
    version = "0.27.0";

    src = pkgs.fetchFromGitHub {
      owner = "k1LoW";
      repo = "git-wt";
      rev = "93bab0c27d305f7bfbfa218a4118077d3d77786d"; # v0.27.0
      sha256 = "0b0fnwbary83jw482325nliv25m0dajjazys3d41kzlgraw3srm0";
    };

    vendorHash = "sha256-4ak2Gx/i/yvj/tAoDJjsfpBUKJI5iDyKIuv7R7Pzz/w=";

    nativeCheckInputs = [ pkgs.git ];

    meta = with pkgs.lib; {
      description = "A CLI tool for managing git worktrees";
      homepage = "https://github.com/k1LoW/git-wt";
      license = licenses.mit;
    };
  };
in
{
  home.packages = [
    # vim-goimports が呼ぶ goimports 本体を供給する
    pkgs.gotools
    roots
    git-wt
  ];
}
