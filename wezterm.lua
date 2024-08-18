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

config.scrollback_lines = 100000

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
-- config.font = wezterm.font('Iosevka Fixed Extended', {weight = 'Regular'})
-- config.font = wezterm.font('Cousine', {weight = 'Regular'})
-- config.font = wezterm.font('Source Code Pro', {weight = 'Regular'})
config.font = wezterm.font('B612 Mono', {weight = 'Regular'})
-- config.freetype_load_target = "Light"
config.font_size = 12.0

-- Tab bar position
config.tab_bar_at_bottom = true
config.tab_max_width = 50

-- Some custom keyboard shortcuts
config.keys = {
  { 
      key = '\\',
      mods = 'CTRL',
      action = act.SplitHorizontal{domain='CurrentPaneDomain'}
  },
--   { 
--      key = '\\',
--      mods = 'CTRL|SHIFT',
--      action = act.SplitVertical{domain='CurrentPaneDomain'}
--   },
  {
    key = 'E',
    mods = 'CTRL|SHIFT',
    action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
}



-- Disable audible beep
config.audible_bell = "Disabled"

-- updates
config.check_for_updates = true
config.check_for_updates_interval_seconds = 86400

-- and finally, return the configuration to wezterm
return config
