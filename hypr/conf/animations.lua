-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  ANIMATIONS                                                              │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Two steps: name the easing curves, then attach them to animation leaves.
--
--   bezier  two control points, classic CSS-style easing
--   spring  physical simulation; `speed` is ignored for the shape, only timing
--
-- Leaves are a tree - `global` is the root, and a leaf like `windowsIn`
-- inherits from `windows` unless it sets its own values. `speed` is in tenths
-- of a second, so 4.79 is ~479ms.
--
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

local s = require("hypr.settings")

hl.config({ animations = { enabled = s.animations.enabled } })   -- (ui)

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

local LEAVES = {
  { leaf = "global",     speed = 10,   bezier = "default" },
  { leaf = "border",     speed = 5.39, bezier = "easeOutQuint" },
  { leaf = "fade",       speed = 3.03, bezier = "quick" },
  { leaf = "fadeIn",     speed = 1.73, bezier = "almostLinear" },
  { leaf = "fadeOut",    speed = 1.46, bezier = "almostLinear" },
  { leaf = "layers",     speed = 3.81, bezier = "easeOutQuint" },
  { leaf = "layersIn",   speed = 4,    bezier = "easeOutQuint", style = "fade" },
  { leaf = "layersOut",  speed = 1.5,  bezier = "linear",       style = "fade" },
  { leaf = "windows",    speed = 4.79, spring = "easy" },
  { leaf = "windowsIn",  speed = 4.1,  spring = "easy",         style = "popin 87%" },
  { leaf = "windowsOut", speed = 1.49, bezier = "linear",       style = "popin 87%" },
  { leaf = "workspaces", speed = 1.94, bezier = "almostLinear", style = "fade" },
  { leaf = "zoomFactor", speed = 7,    bezier = "quick" },
}

for _, leaf in ipairs(LEAVES) do
  leaf.enabled = true
  hl.animation(leaf)
end
