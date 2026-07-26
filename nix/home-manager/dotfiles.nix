{
  self,
  ...
}:
{
  xdg.enable = true;

  home.file = {
    ".editorconfig".source = "${self}/.editorconfig";
    ".codex/AGENTS.md".source = "${self}/AGENTS.md";
    ".claude/CLAUDE.md".source = "${self}/CLAUDE.md";
  };
}
