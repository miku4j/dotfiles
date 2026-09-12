local wezterm = require("wezterm")
local mux = wezterm.mux
local config = wezterm.config_builder()

-- Hide tab bar completely
config.enable_tab_bar = false

-- Default to home (portable, no hardcoded username)
config.default_cwd = os.getenv("HOME")

-- Font: JetBrainsMono Nerd Font, fallback to installed JetBrains Mono
config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "JetBrains Mono",
  "monospace",
})
config.font_size = 11.0
config.warn_about_missing_glyphs = false

-- Theme: named schemes — switch with one `color_scheme` line
config.force_reverse_video_cursor = true
config.color_schemes = {
  ["Kanso Zen"] = { -- upstream: https://github.com/webhooked/kanso.nvim/blob/main/extras/wezterm/kanso-zen.lua
    foreground = "#C5C9C7",
    background = "#090E13",
    cursor_bg = "#C5C9C7",
    cursor_fg = "#090E13",
    cursor_border = "#C5C9C7",
    selection_fg = "#C5C9C7",
    selection_bg = "#22262D",
    scrollbar_thumb = "#22262D",
    split = "#22262D",
    ansi = { "#090E13", "#C4746E", "#8A9A7B", "#C4B28A", "#8BA4B0", "#A292A3", "#8EA4A2", "#A4A7A4" },
    brights = { "#A4A7A4", "#E46876", "#87A987", "#E6C384", "#7FB4CA", "#938AA9", "#7AA89F", "#C5C9C7" },
  },
}
-- config.color_scheme = "Kanso Zen"
config.color_scheme = "Kasugano"

-- Wallpaper (full-bright image + dark overlay for readability)
config.background = {
  {
    source = { File = os.getenv("HOME") .. "/Pictures/wallpaper/robin-summeretto-3.png" },
    width = "Cover",
    height = "Cover",
    horizontal_align = "Center",
    vertical_align = "Middle",
  },
  {
    -- source = { Color = "#0F1419" },
    source = { Color = "#000" },
    width = "100%",
    height = "100%",
    opacity = 0.93,
  },
}

-- Start maximized (not fullscreen)
wezterm.on("gui-startup", function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

return config
