-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  MONITORS                                                                │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- `hyprctl monitors` lists connected outputs and their available modes.
--
-- position is the top-left corner in the shared coordinate space. eDP-1 sits to
-- the right of the HDMI panel and 280px down, so the two screens line up along
-- their bottom edges rather than their tops.
--
-- https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({ output = "HDMI-A-1", mode = "2560x1080", position = "0x0",      scale = 1 })
hl.monitor({ output = "eDP-1",    mode = "1920x1080", position = "2560x280", scale = 1 })

-- Catch-all for anything else plugged in, so a new display comes up rather
-- than staying dark. Must be last - monitor rules match first-listed-wins.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
