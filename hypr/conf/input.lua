-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  INPUT                                                                   │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Values marked (ui) come from ../settings.lua, which the web UI owns.
--
-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- https://wiki.hypr.land/Configuring/Basics/Gestures/

local s = require("hypr.settings")

hl.config({
  input = {
    kb_layout    = s.input.kb_layout,     -- (ui)
    follow_mouse = s.input.follow_mouse,  -- (ui) 0 off, 1 follow, 2 loose
    sensitivity  = s.input.sensitivity,   -- (ui) -1.0 .. 1.0, 0 = untouched

    touchpad = {
      natural_scroll = s.input.natural_scroll,   -- (ui)
    },
  },
})

-- Three-finger horizontal swipe switches workspaces. Gestures are their own
-- call now; hyprlang had them inside a `gestures { }` block.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
