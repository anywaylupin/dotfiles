-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  SETTINGS - MACHINE-MANAGED                                              │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Written by the dotfiles web UI (routes/hypr.lua). Hand edits survive, but the
-- UI rewrites the whole file, so comments you add here will be lost.
--
-- This is the ONLY place these values live. conf/looknfeel.lua and
-- conf/input.lua read them straight out of this table, so there is nothing to
-- keep in sync. A nil here means "not configured" - Hyprland keeps its own
-- default - so removing a key is always safe.

return {
  general = {
    border_size      = 2,
    gaps_in          = 6,
    gaps_out         = 20,
    layout           = "dwindle",
    resize_on_border = false,
  },

  decoration = {
    active_opacity   = 1,
    inactive_opacity = 1,
    rounding         = 10,
    rounding_power   = 2,
  },

  blur = {
    enabled = true,
    passes  = 1,
    size    = 3,
  },

  shadow = {
    enabled = true,
    range   = 4,
  },

  animations = {
    enabled = true,
  },

  input = {
    follow_mouse   = 1,
    kb_layout      = "us",
    natural_scroll = false,
    sensitivity    = 0,
  },
}
