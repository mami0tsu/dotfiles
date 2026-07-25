{
  self,
  ...
}:
{
  xdg.enable = true;

  xdg.configFile = {
    "espanso".source = "${self}/espanso";
    "ghostty".source = "${self}/ghostty";
    "zellij".source = "${self}/zellij";
  };

  home.file = {
    ".editorconfig".source = "${self}/.editorconfig";
    ".codex/AGENTS.md".source = "${self}/AGENTS.md";
    ".claude/CLAUDE.md".source = "${self}/CLAUDE.md";
  };
}
