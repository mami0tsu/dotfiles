{ config, ... }:
{
  programs.nixvim = {
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
