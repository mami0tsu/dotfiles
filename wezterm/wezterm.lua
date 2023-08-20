local wezterm = require 'wezterm';
local act = wezterm.action

local config = {}

config.adjust_window_size_when_changing_font_size = false
config.color_scheme = 'Wombat'
config.font = wezterm.font('FirgeNerd Console', { weight = 'Regular', stretch = 'Normal', style = 'Normal'})
config.font_dirs = { 'fonts' }
config.font_size = 16.0
config.hide_tab_bar_if_only_one_tab = true
config.leader = { key = 't', mods = 'CTRL', timeout_milliseconds = 1000 }
config.use_ime = true

-- config.keys = {
--   {
--     key = 'c',
--     mods = 'LEADER',
--     action = act.SpawnTab 'CurrentPaneDomain',
--   },
--   {
--     key = 'w',
--     mods = 'LEADER',
--     action = wezterm.action.CloseCurrentTab {
--       confirm = true
--     },
--   },
--   {
--     key = 'f',
--     mods = 'LEADER',
--     action = act.ActivateTabRelative(1),
--   },
--   {
--     key = 'b',
--     mods = 'LEADER',
--     action = act.ActivateTabRelative(-1),
--   },
--   {
--     key = '|',
--     mods = 'LEADER',
--     action = act.SplitPane {
--       direction = 'Right',
--       size = {
--         Percent = 50
--       },
--     },
--   },
--   {
--     key = '-',
--     mods = 'LEADER',
--     action = act.SplitPane {
--       direction = 'Down',
--       size = {
--         Percent = 50
--       },
--     },
--   },
--   {
--     key = 'x',
--     mods = 'LEADER',
--     action = act.CloseCurrentPane {
--       confirm = true,
--     },
--   },
--   {
--     key = 'l',
--     mods = 'LEADER',
--     action = act.ActivatePaneDirection 'Right'
--   },
--   {
--     key = 'j',
--     mods = 'LEADER',
--     action = act.ActivatePaneDirection 'Down'
--   },
--   {
--     key = 'k',
--     mods = 'LEADER',
--     action = act.ActivatePaneDirection 'Up'
--   },
--   {
--     key = 'h',
--     mods = 'LEADER',
--     action = act.ActivatePaneDirection 'Left'
--   },
--   {
--     key = 'L',
--     mods = 'LEADER',
--     action = act.AdjustPaneSize {'Right', 5 },
--   },
--   {
--     key = 'J',
--     mods = 'LEADER',
--     action = act.AdjustPaneSize {'Down', 5 },
--   },
--   {
--     key = 'K',
--     mods = 'LEADER',
--     action = act.AdjustPaneSize {'Up', 5 },
--   },
--   {
--     key = 'H',
--     mods = 'LEADER',
--     action = act.AdjustPaneSize {'Left', 5 },
--   },
-- }

return config
