-- Scrolling layout defaults and keybindings for the fleet.

hl.config({
  general = {
    layout = "scrolling",
  },

  scrolling = {
    column_width = 1.0,
    direction = "right",
    focus_fit_method = 1,
    follow_focus = true,
    fullscreen_on_one_column = false,
    explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
  },
})
