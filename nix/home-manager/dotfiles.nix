{
  self,
  ...
}:
let
  agentInstructions = builtins.readFile "${self}/agents/AGENTS.md";
in
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
    ".codex/AGENTS.md".source = "${self}/agents/AGENTS.md";
    ".claude/CLAUDE.md".text = agentInstructions;
  };
}
