-- Browser workspaces defaults: direct main browser windows to workspace 10 with active focus.

-- Main browser windows:
-- • Google Chrome (google-chrome, Google-chrome)
-- • Microsoft Edge (microsoft-edge)
-- • Zen Browser (zen)
-- • Brave Origin (brave-origin, brave-browser)
o.window("^(google-chrome|Google-chrome|microsoft-edge|zen|brave-origin|brave-browser)$", {
  workspace = "10",
})
