-- Dev workspaces defaults: direct developer tools and agentic environments to dedicated workspaces.

local cursor_classes = "^(Cursor|cursor|cursor-ide|cursor-ade)$"
local antigravity_classes = "^(antigravity-ide|Antigravity|antigravity)$"
local dev_classes = "^(Cursor|cursor|cursor-ide|cursor-ade|antigravity-ide|Antigravity|antigravity)$"

-- Main development windows:
-- • Cursor IDE / ADE -> workspace 9
o.window(cursor_classes, {
  workspace = "9",
})

-- • Antigravity IDE / Desktop -> workspace 8
o.window(antigravity_classes, {
  workspace = "8",
})

-- Explicit exclusions for file pickers and dialogs:
o.window({
  class = dev_classes,
  title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
}, {
  workspace = "unset",
  tag = "+floating-window",
})

-- Explicit exclusions for detached DevTools:
o.window({
  class = dev_classes,
  title = "^(DevTools.*|Developer Tools.*)",
}, {
  workspace = "unset",
  tag = "+floating-window",
})

-- Explicit exclusions for authentication, OAuth and extension popups:
o.window({
  class = dev_classes,
  title = "^(Sign in.*|Sign In.*|Log [I|i]n.*|OAuth.*|Extension:.*)",
}, {
  workspace = "unset",
  tag = "+floating-window",
})
