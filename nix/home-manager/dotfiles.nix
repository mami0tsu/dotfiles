{
  self,
  lib,
  ...
}:
let
  allowedCommands = [
    [ "ax" ]
    [ "difit" ]
    [ "gh" "pr" "view" ]
    [ "git" "add" ]
    [ "git" "fetch" ]
    [ "git" "ls-remote" ]
    [ "git" "remote" "show" ]
    [ "git" "worktree" "add" ]
    [ "git" "wt" ]
    [ "nix" "build" "--dry-run" "--no-write-lock-file" ]
    [ "nix" "build" "--no-link" "--no-write-lock-file" ]
    [ "nix" "build" "--no-write-lock-file" "--dry-run" ]
    [ "nix" "build" "--no-write-lock-file" "--no-link" ]
    [ "nix" "eval" ]
    [ "nix" "fmt" ]
  ];

  tomlArray = values:
    "[${lib.concatMapStringsSep ", " builtins.toJSON values}]";

  claudeAnyArguments = "*";

  codexPermissions = lib.concatLines (map (pattern:
    "prefix_rule(pattern=${tomlArray pattern}, decision=\"allow\")"
  ) allowedCommands);

  claudePermissions = lib.concatLines [ (builtins.toJSON {
    permissions.allow = map (pattern:
      "Bash(${lib.concatStringsSep " " pattern} ${claudeAnyArguments})"
    ) allowedCommands;
  }) ];
in
{
  xdg.enable = true;

  home.file = {
    ".editorconfig".source = "${self}/.editorconfig";
    ".codex/AGENTS.md".source = "${self}/AGENTS.md";
    ".codex/rules/default.rules".text = codexPermissions;
    ".claude/CLAUDE.md".source = "${self}/CLAUDE.md";
    ".claude/permissions.json".text = claudePermissions;
  };
}
