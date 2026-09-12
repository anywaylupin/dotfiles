-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  AUTOSTART AND ENVIRONMENT                                               │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- `hl.env` must run at config load, before anything spawns, or children won't
-- inherit the variable. Processes go inside the `hyprland.start` handler so
-- they launch once per session, not on every config reload.
--
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

local p = require("hypr.conf.programs")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.on("hyprland.start", function()
  hl.exec_cmd(p.notifier)
end)
