{
  config,
  ...
}:
{
  xdg.stateFile."nvim/undo/.keep".text = "";

  programs.nixvim = {
    globals = {
      mapleader = " ";
    };

    opts = {
      undodir = "${config.xdg.stateHome}/nvim/undo";
      undofile = true;
      undolevels = 1000;

      encoding = "UTF-8";
      cmdheight = 0;
      laststatus = 2;
      number = true;
      showmatch = true;
      ruler = true;
      incsearch = true;
      hlsearch = true;
      hidden = true;
      swapfile = false;
      clipboard = "unnamedplus";
      signcolumn = "yes";
      termguicolors = true;
      showmode = false;

      expandtab = true;
      smartindent = true;
      wildmenu = true;
      wildmode = "full";
      tabstop = 4;
      shiftwidth = 4;
      softtabstop = 0;
      virtualedit = "block";
    };

    extraConfigLuaPre = ''
      vim.opt.shortmess:append("c")
    '';

    userCommands = {
      T = {
        command = "split | wincmd j | resize 20 | terminal <args>";
        nargs = "*";
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<Leader>w";
        action = ":w<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "U";
        action = "<C-r>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "ws";
        action = ":split<CR><C-w>w";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "wv";
        action = ":vsplit<CR><C-w>w";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "ww";
        action = "<C-w>w";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "wh";
        action = "<C-w>h";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "wk";
        action = "<C-w>k";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "wj";
        action = "<C-w>j";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "wl";
        action = "<C-w>l";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<C-w><Left>";
        action = "<C-w><";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<C-w><Right>";
        action = "<C-w>>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<C-w><Up>";
        action = "<C-w>+";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<C-w><Down>";
        action = "<C-w>-";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<Left>";
        action = ":bp<CR>";
        options = {
          noremap = true;
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<Right>";
        action = ":bn<CR>";
        options = {
          noremap = true;
          silent = true;
        };
      }
      {
        mode = "n";
        key = "gk";
        action = ":tabedit<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "gj";
        action = ":tabclose<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "gh";
        action = "gT";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "gl";
        action = "gt";
        options.noremap = true;
      }
      {
        mode = "i";
        key = "<C-[>";
        action = "<Esc>";
        options = {
          noremap = true;
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<C-[>";
        action = "<Esc>";
        options = {
          noremap = true;
          silent = true;
        };
      }
      {
        mode = "t";
        key = "<C-[>";
        action = "<C-\\><C-n>";
        options = {
          noremap = true;
          silent = true;
        };
      }
    ];

    autoCmd = [
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.go";
        command = "set filetype=go";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.lua";
        command = "set filetype=lua";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.md";
        command = "set filetype=markdown";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.tf";
        command = "set filetype=terraform";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.ts";
        command = "set filetype=typescript";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.tsx";
        command = "set filetype=typescript";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.yml";
        command = "set filetype=yaml";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.yaml";
        command = "set filetype=yaml";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.toml";
        command = "set filetype=toml";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "*.vim";
        command = "set filetype=vim";
      }
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = "Dockerfile*";
        command = "set filetype=dockerfile";
      }
      {
        event = "FileType";
        pattern = "go";
        command = "setlocal ts=4 sts=4 sw=4";
      }
      {
        event = "FileType";
        pattern = "lua";
        command = "setlocal ts=2 sts=2 sw=2";
      }
      {
        event = "FileType";
        pattern = "terraform";
        command = "setlocal ts=2 sts=2 sw=2";
      }
      {
        event = "FileType";
        pattern = "typescript";
        command = "setlocal ts=2 sts=2 sw=2";
      }
      {
        event = "FileType";
        pattern = "toml";
        command = "setlocal ts=2 sts=2 sw=2";
      }
      {
        event = "FileType";
        pattern = "yaml";
        command = "setlocal ts=2 sts=2 sw=2 et";
      }
      {
        event = "FileType";
        pattern = "vim";
        command = "setlocal ts=4 sts=4 sw=4";
      }
      {
        event = "TermOpen";
        pattern = "*";
        command = "startinsert";
      }
    ];
  };
}
