{
  self,
  ...
}:
{
  xdg.enable = true;

  xdg.configFile = {
    "ghostty".source = "${self}/ghostty";
    "starship".source = "${self}/starship";
    "zellij".source = "${self}/zellij";
  };

  home.file = {
    ".editorconfig".source = "${self}/.editorconfig";
    ".codex/AGENTS.md".source = "${self}/AGENTS.md";
    ".claude/CLAUDE.md".source = "${self}/CLAUDE.md";
  };
}
