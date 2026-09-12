local wezterm = require("wezterm")
local mux = wezterm.mux
local config = wezterm.config_builder()

-- Hide tab bar completely
config.enable_tab_bar = false

-- Default to home (portable, no hardcoded username)
config.default_cwd = os.getenv("HOME")

-- Theme
config.color_scheme = "Kasugano (terminal.sexy)"

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
    source = { Color = "#1b1b1b" },
    width = "100%",
    height = "100%",
    opacity = 0.95,
  },
}

-- Start maximized (not fullscreen)
wezterm.on("gui-startup", function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

return config
