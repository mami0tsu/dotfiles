{ config, pkgs, ... }:
let
  legacyPlugins = import ./legacy-plugins.nix { inherit pkgs; };
in
{
  programs.nixvim = {
    extraPlugins = (with pkgs.vimPlugins; [
      auto-pairs
      denops-vim
      ddc-vim
      ddc-ui-native
      ddc-ui-pum
      ddc-source-around
      ddc-source-file
      ddc-source-lsp
      ddc-filter-matcher_head
      ddc-filter-sorter_rank
      pum-vim
      tcomment_vim
      vim-prettier
      vim-terraform
    ]) ++ (with legacyPlugins; [
      previm
      ddc-ui-inline
      ddc-buffer
      ddc-source-shell_native
      ddc-source-input
      ddc-source-rg
      ddc-source-line
      ddc-source-cmdline
      ddc-source-cmdline-history
      ddc-filter-matcher_length
      ddc-filter-matcher_prefix
      ddc-filter-matcher_vimregexp
      ddc-filter-sorter_head
      ddc-filter-converter_remove_overlap
      ddc-filter-converter_truncate_abbr
      ddu-vim
      ddu-commands-vim
      ddu-ui-ff
      ddu-ui-filer
      ddu-source-buffer
      ddu-source-file
      ddu-source-file_rec
      ddu-source-line
      ddu-source-rg
      ddu-kind-file
      ddu-kind-word
      ddu-filter-matcher_files
      ddu-filter-matcher_relative
      ddu-filter-matcher_substring
      ddu-filter-sorter_alpha
      ddu-column-filename
      deol-nvim
      vim-goimports
      moody-nvim
    ]);

    extraConfigVim = ''
      autocmd BufWritePre *.md PrettierAsync

      let g:previm_open_cmd = 'open -a Google\ Chrome'
      let g:deol#external_history_path = '${config.xdg.stateHome}/zsh_history'
      let g:deol#prompt_pattern = '\w*>'

      let g:terraform_fmt_on_save = 1
    '';

    diagnostic.settings = {
      update_in_insert = false;
      virtual_text = {
        format.__raw = ''
          function(diagnostic)
            return string.format(
              '%s (%s: %s)',
              diagnostic.message,
              diagnostic.source,
              diagnostic.code
            )
          end
        '';
      };
    };

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;
        show_end_of_buffer = true;
        color_overrides.mocha = {
          base = "#000000";
          mantle = "#000000";
          crust = "#000000";
        };
        term_colors = true;
        integrations = {
          gitsigns = true;
          markdown = true;
          mason = true;
          notify = true;
          treesitter = true;
        };
      };
    };

    plugins = {
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          gopls.enable = true;
          html.enable = true;
          jsonls = {
            enable = true;
            settings = {
              json = {
                format.enable = true;
                validate.enable = true;
              };
            };
          };
          lua_ls = {
            enable = true;
            settings = {
              Lua = {
                diagnostics.globals = [
                  "vim"
                ];
                telemetry.enable = false;
                workspace.checkThirdParty = false;
              };
            };
          };
          cssls.enable = true;
          terraformls.enable = true;
          ts_ls.enable = true;
          yamlls = {
            enable = true;
            settings = {
              yaml = {
                completion = true;
                hover = true;
                validate = true;
                schemaStore = {
                  enable = true;
                  url = "https://www.schemastore.org/api/json/catalog.json";
                };
              };
            };
          };
        };
      };

      web-devicons.enable = true;

      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add.text = "│";
            change.text = "│";
            delete.text = "_";
            topdelete.text = "‾";
            changedelete.text = "~";
            untracked.text = "┆";
          };
          signcolumn = true;
          numhl = true;
        };
      };

      notify = {
        enable = true;
        settings = {
          render = "compact";
          stages = "static";
          timeout = 1000;
        };
      };

      treesitter = {
        enable = true;
        grammarPackages =
          with config.programs.nixvim.plugins.treesitter.package.builtGrammars;
          [
            bash
            dockerfile
            go
            gomod
            gosum
            gowork
            javascript
            json
            lua
            markdown
            markdown_inline
            nix
            terraform
            toml
            tsx
            typescript
            vim
            vimdoc
            yaml
          ];
        highlight.enable = true;
        indent.enable = true;
      };

      render-markdown = {
        enable = true;
        settings = {
          enabled = true;
          max_file_size = 1.5;
          markdown_query = ''
            (atx_heading [
                (atx_h1_marker)
                (atx_h2_marker)
                (atx_h3_marker)
                (atx_h4_marker)
                (atx_h5_marker)
                (atx_h6_marker)
            ] @heading)

            (thematic_break) @dash

            (fenced_code_block) @code

            [
                (list_marker_plus)
                (list_marker_minus)
                (list_marker_star)
            ] @list_marker

            (task_list_marker_unchecked) @checkbox_unchecked
            (task_list_marker_checked) @checkbox_checked

            (block_quote) @quote

            (pipe_table) @table
          '';
          markdown_quote_query = ''
            [
                (block_quote_marker)
                (block_continuation)
            ] @quote_marker
          '';
          inline_query = ''
            (code_span) @code

            (shortcut_link) @callout

            [(inline_link) (image)] @link
          '';
          inline_link_query = "[(inline_link) (image)] @link";
          log_level = "error";
          file_types = [ "markdown" ];
          render_modes = [
            "n"
            "c"
          ];
          exclude.buftypes = [ ];
        };
      };

      lualine = {
        enable = true;
        luaConfig.pre = ''
          local function dotfiles_lualine_diff_source()
            local gitsigns = vim.b.gitsigns_status_dict
            if gitsigns then
              return {
                added = gitsigns.added,
                modified = gitsigns.changed,
                removed = gitsigns.removed
              }
            end
          end
        '';
        settings = {
          options = {
            icons_enabled = true;
            theme = "auto";
            component_separators = {
              left = "|";
              right = "|";
            };
            section_separators = {
              left = "";
              right = "";
            };
            disabled_filetypes = {
              statusline = [ ];
              winbar = [ ];
            };
            ignore_focus = [ ];
            always_divide_middle = true;
            globalstatus = true;
            refresh = {
              statusline = 1000;
              tabline = 1000;
              winbar = 1000;
            };
          };
          sections = {
            lualine_a = [ "mode" ];
            lualine_b = [
              "branch"
              {
                __unkeyed-1 = "diff";
                source.__raw = "dotfiles_lualine_diff_source";
              }
              "diagnostics"
            ];
            lualine_c = [
              {
                __unkeyed-1 = "filename";
                path = 3;
              }
            ];
            lualine_x = [
              "encoding"
              "fileformat"
              {
                __unkeyed-1 = "filetype";
                colored = false;
              }
            ];
            lualine_y = [ "progress" ];
            lualine_z = [ "location" ];
          };
          inactive_sections = {
            lualine_a = [ ];
            lualine_b = [ ];
            lualine_c = [ "filename" ];
            lualine_x = [ "location" ];
            lualine_y = [ ];
            lualine_z = [ ];
          };
          tabline = { };
          winbar = { };
          inactive_winbar = { };
          extensions = [ ];
        };
      };
    };
  };
}
