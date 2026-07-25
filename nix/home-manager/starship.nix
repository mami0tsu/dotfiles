{
  ...
}:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      scan_timeout = 10;

      battery.disabled = true;
      cmd_duration.show_milliseconds = true;

      character = {
        error_symbol = "[>](bold red)";
        format = "$symbol";
        success_symbol = "[>](bold green)";
      };

      directory.format = "[$path]($style) ";

      git_status = {
        ahead = "\${count}↑";
        behind = "\${count}↓";
        conflicted = "\${count}=";
        deleted = "\${count}x";
        diverged = "\${count}⇕";
        modified = "\${count}!";
        renamed = "\${count}»";
        staged = "[++\\($count\\)](green)";
        stashed = "\${count}*";
        untracked = "\${count}?";
      };
    };
  };
}
