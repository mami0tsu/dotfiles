{
  self,
  ...
}:
{
  xdg.enable = true;

  home.file = {
    ".editorconfig".source = "${self}/.editorconfig";
    ".codex/AGENTS.md".source = "${self}/AGENTS.md";
    ".codex/rules/default.rules".source = "${self}/agents/permissions/codex/default.rules";
    ".claude/CLAUDE.md".source = "${self}/CLAUDE.md";
    ".claude/permissions.json".source = "${self}/agents/permissions/claude/settings.json";
  };
}
