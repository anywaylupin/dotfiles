-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  LAYER RULES                                                             │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Layer surfaces are the shell, not windows: bars, launchers, notifications.
-- Matched by namespace - `hyprctl layers` lists the live ones.
--
-- `ignore_alpha = 0` is hyprlang's old `ignorezero`: skip blurring the fully
-- transparent parts, so a rounded popup doesn't get a blurred rectangle behind
-- its corners.
--
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/#layer-rules

local BLUR = {
  "^(logout_dialog)$",
  "^(notifications)$",
  "^(rofi)$",
  "^(waybar)$",
  "^(wofi)$",
}

for i, namespace in ipairs(BLUR) do
  hl.layer_rule({
    name         = "blur-" .. i,
    match        = { namespace = namespace },
    blur         = true,
    ignore_alpha = 0,
  })
end
