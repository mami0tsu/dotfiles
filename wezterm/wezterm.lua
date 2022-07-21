local wezterm = require 'wezterm';

return {
	use_ime = true,
    font_dirs = {"fonts"},
	font = wezterm.font("FirgeNerd Console", {weight="Regular", stretch="Normal", style="Normal"}),
 	font_size = 16.0,
	color_scheme = "Wombat",
	hide_tab_bar_if_only_one_tab = true,
	adjust_window_size_when_changing_font_size = false,
}
