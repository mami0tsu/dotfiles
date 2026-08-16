{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    clearDefaultKeybinds = true;

    settings = {
      background = "000000";
      background-blur = 20;
      background-opacity = 0.8;
      font-family = "FirgeNerd Console";
      font-size = 16;
      font-style = "Normal";

      theme = "Catppuccin Mocha";

      cursor-color = "ffffff";
      cursor-click-to-move = false;
      cursor-opacity = 0.7;
      cursor-style = "block";
      cursor-style-blink = false;

      macos-titlebar-style = "tabs";
      macos-window-buttons = "hidden";

      mouse-hide-while-typing = true;

      split-divider-color = "313244";

      window-title-font-family = "FirgeNerd Console";
      window-padding-x = 20;

      keybind = [
        "global:ctrl+g=toggle_visibility"

        "ctrl+t>u=undo"
        "ctrl+t>shift+u=redo"

        "ctrl+t>y=copy_to_clipboard"
        "ctrl+t>p=paste_from_clipboard"

        "ctrl+t>n=new_window"
        "ctrl+t>w=close_surface"
        "ctrl+t>q=quit"

        "ctrl+t>plus=increase_font_size:1"
        "ctrl+t>minus=decrease_font_size:1"
        "ctrl+t>zero=reset_font_size"

        "ctrl+t>c=new_tab"
        "ctrl+t>x=close_surface"

        "ctrl+t>l=next_tab"
        "ctrl+t>h=previous_tab"
        "ctrl+t>n=next_tab"
        "ctrl+t>b=previous_tab"

        "ctrl+t>s=new_split:right"
        "ctrl+t>shift+s=new_split:down"

        "ctrl+t>left_bracket=goto_split:previous"
        "ctrl+t>right_bracket=goto_split:next"

        "ctrl+t>comma=open_config"
        "ctrl+t>shift+comma=reload_config"
      ];
    };
  };
}
