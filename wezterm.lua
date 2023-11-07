-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- Handle for actions available in WexTerm
local act = wezterm.action

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'Atom'
-- config.color_scheme = 'Ayu Dark (Gogh)'
-- config.color_scheme = 'Ayu'
-- config.color_scheme = 'Bitmute (terminal.sexy)'
-- config.color_scheme = 'Bleh-1 (terminal.sexy)'
-- config.color_scheme = 'Cai (Gogh)'
config.color_scheme = 'Colorful Colors (terminal.sexy)'

-- Font Configuration
-- config.font = wezterm.font('Roboto Mono', {weight = 'Medium'})
-- config.freetype_load_target = "Light"
config.font_size = 12.0

-- Tab bar position
config.tab_bar_at_bottom = true
config.tab_max_width = 50

-- Some custom keyboard shortcuts
config.keys = {
  { key = '\\', mods = 'CTRL', action = act.SplitHorizontal{domain='CurrentPaneDomain'} },
--   { key = '\\', mods = 'CTRL|SHIFT', action = act.SplitVertical{domain='CurrentPaneDomain'} },
}

-- Disable audible beep
config.audible_bell = "Disabled"

-- and finally, return the configuration to wezterm
return config
