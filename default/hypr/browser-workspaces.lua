-- Browser workspaces defaults: direct main browser windows to workspace 10 with active focus.

local browser_classes = "^(google-chrome|Google-chrome|microsoft-edge|zen|brave-origin|brave-browser)$"

-- Main browser windows:
-- • Google Chrome (google-chrome, Google-chrome)
-- • Microsoft Edge (microsoft-edge)
-- • Zen Browser (zen)
-- • Brave Origin (brave-origin, brave-browser)
o.window(browser_classes, {
  workspace = "10",
})

-- Explicit exclusions for file pickers and dialogs:
o.window({
  class = browser_classes,
  title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
}, {
  workspace = "unset",
  tag = "+floating-window",
})

-- Explicit exclusions for detached DevTools:
o.window({
  class = browser_classes,
  title = "^(DevTools.*|Developer Tools.*)",
}, {
  workspace = "unset",
  tag = "+floating-window",
})

-- Explicit exclusions for authentication, OAuth and extension popups:
o.window({
  class = browser_classes,
  title = "^(Sign in.*|Sign In.*|Log [I|i]n.*|OAuth.*|Extension:.*)",
}, {
  workspace = "unset",
  tag = "+floating-window",
})

-- Picture-in-Picture overlays: stay in origin workspace and float/pin via pip.lua
o.window({
  class = browser_classes,
  title = "(Picture.?in.?[Pp]icture)",
}, {
  workspace = "unset",
})
