{
  inputs,
  ...
}:
{
  imports = [
    ./nixvim/core.nix
    ./nixvim/plugins.nix
  ];

  programs.nixvim = {
    enable = true;
    enableMan = false;
    nixpkgs.source = inputs.nixpkgs;

    extraConfigLua = builtins.readFile ../../nvim/init.lua;

    extraFiles = {
      "ddc.toml".source = ../../nvim/ddc.toml;
      "ddc.vim".source = ../../nvim/ddc.vim;
      "ddu.toml".source = ../../nvim/ddu.toml;
      "ddu.vim".source = ../../nvim/ddu.vim;
      "ddu-ui-ff.vim".source = ../../nvim/ddu-ui-ff.vim;
      "ddu-ui-filer.vim".source = ../../nvim/ddu-ui-filer.vim;
      "dein.toml".source = ../../nvim/dein.toml;
      "dein_lazy.toml".source = ../../nvim/dein_lazy.toml;
      "neovim.toml".source = ../../nvim/neovim.toml;
    };
  };
}
