{ pkgs, self, ... }:

let
  localPackages = self.packages.${pkgs.system};
in
{
  home.packages = [
    # vim-goimports が呼ぶ goimports 本体を供給する
    pkgs.gotools
    localPackages.roots
    localPackages.git-wt
  ];
}
