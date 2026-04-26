{
  self,
  ...
}:
{
  xdg.enable = true;

  xdg.configFile = {
    "espanso".source = "${self}/espanso";
    "ghostty".source = "${self}/ghostty";
    "mise".source = "${self}/mise";
    "nvim".source = "${self}/nvim";
    "starship".source = "${self}/starship";
    "zellij".source = "${self}/zellij";
  };

  home.file = {
    ".brewfile".source = "${self}/brew/.brewfile";
    ".editorconfig".source = "${self}/.editorconfig";
  };
}
