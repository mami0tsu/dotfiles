{
  config,
  useremail,
  username,
  ...
}:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = username;
        email = useremail;
      };

      alias = {
        a = "add";
        b = "branch";
        c = "commit --message";
        d = "diff";
        f = "fetch";
        h = "!git config --get-regexp alias | sed 's/^alias.//g' | sed 's/ / = /1' | sort";
        l = "log --oneline -n 10";
        m = "merge @{-1}";
        r = "restore";
        s = "status --short --branch";
        save = "stash save --include-untracked --message";
        sw = "switch";
        swc = "switch --create";
      };

      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        pager = "delta";
      };
      commit.verbose = true;
      merge.conflictStyle = "diff3";
      push.autoSetupRemote = true;
      interactive.diffFilter = "delta --color-only";
      delta = {
        line-numbers = true;
        navigate = true;
        side-by-side = true;
      };
      diff.colorMoved = "default";
      ghq.root = "~/src";
      secrets = {
        providers = "git secrets --aws-provider";
        patterns = [
          "(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}"
          "(\"|')?(AWS|aws|Aws)?_?(SECRET|secret|Secret)?_?(ACCESS|access|Access)?_?(KEY|key|Key)(\"|')?\\\\s*(:|=>|=)\\\\s*(\"|')?[A-Za-z0-9/\\\\+=]{40}(\"|')?"
          "(\"|')?(AWS|aws|Aws)?_?(ACCOUNT|account|Account)_?(ID|id|Id)?(\"|')?\\\\s*(:|=>|=)\\\\s*(\"|')?[0-9]{4}\\\\-?[0-9]{4}\\\\-?[0-9]{4}(\"|')?"
        ];
      };
    };

    ignores = [ ".DS_Store" ];
  };
}
