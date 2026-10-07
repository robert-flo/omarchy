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

if _G.omarchy_default_bindings ~= false then
  -- Lateral navigation
  o.rebind("SUPER + LEFT", "Focus on left window (scrolling)", hl.dsp.layout("focus l"))
  o.rebind("SUPER + RIGHT", "Focus on right window (scrolling)", hl.dsp.layout("focus r"))
  o.bind("SUPER + H", "Focus on left window (scrolling)", hl.dsp.layout("focus l"))
  o.rebind("SUPER + L", "Focus on right window (scrolling)", hl.dsp.layout("focus r"))
  o.bind("SUPER + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

  -- Column reordering (swap)
  o.rebind("SUPER + CTRL + LEFT", "Swap window left (scrolling)", hl.dsp.layout("swapcol l"))
  o.rebind("SUPER + CTRL + RIGHT", "Swap window right (scrolling)", hl.dsp.layout("swapcol r"))

  -- Column width cyclic toggle (0.333 -> 0.5 -> 0.667 -> 1.0)
  o.rebind("SUPER + CTRL + F", "Toggle/cycle column width (scrolling)", hl.dsp.layout("colresize +conf"))

  -- Window promotion
  o.rebind("SUPER + P", "Promote window to column", hl.dsp.layout("promote"))
  o.bind("SUPER + ALT + P", "Pseudo window", hl.dsp.window.pseudo())
end
