{
  pkgs,
  self,
  ...
}:
let
  localPackages = self.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.gh = {
    enable = true;
    extensions = [ localPackages.gh-stack ];
  };
}
