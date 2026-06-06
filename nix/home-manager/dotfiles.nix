{
  self,
  ...
}:
{
  xdg.enable = true;

  xdg.configFile = {
    "espanso".source = "${self}/espanso";
    "ghostty".source = "${self}/ghostty";
    "starship".source = "${self}/starship";
    "zellij".source = "${self}/zellij";
  };

  home.file = {
    ".editorconfig".source = "${self}/.editorconfig";
  };
}
