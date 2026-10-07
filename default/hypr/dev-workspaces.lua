-- Dev workspaces defaults: direct developer tools and agentic environments to dedicated workspaces.

local cursor_classes = "^(Cursor|cursor|cursor-ide|cursor-ade)$"
local antigravity_classes = "^(antigravity-ide|Antigravity|antigravity)$"

-- Main development windows:
-- • Cursor IDE / ADE -> workspace 9
o.window(cursor_classes, {
  workspace = "9",
})

-- • Antigravity IDE / Desktop -> workspace 8
o.window(antigravity_classes, {
  workspace = "8",
})
