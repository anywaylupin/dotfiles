-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  LOOK AND FEEL                                                           │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Values marked (ui) come from ../settings.lua, which the web UI owns. They are
-- referenced rather than copied, so there is no second copy to drift. A nil
-- reads as "not set" and Hyprland falls back to its own default.
--
-- Everything else is hand-managed: edit it here.
--
-- https://wiki.hypr.land/Configuring/Basics/Variables/

local s = require("hypr.settings")

hl.config({
  general = {
    gaps_in          = s.general.gaps_in,           -- (ui) between windows
    gaps_out         = s.general.gaps_out,          -- (ui) window to screen edge
    border_size      = s.general.border_size,       -- (ui)
    resize_on_border = s.general.resize_on_border,  -- (ui) drag borders to resize
    layout           = s.general.layout,            -- (ui) dwindle | master | scrolling

    col = {
      active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
      inactive_border = "rgba(595959aa)",
    },

    allow_tearing = false,   -- read the wiki's Tearing page before enabling
  },

  decoration = {
    rounding         = s.decoration.rounding,          -- (ui)
    rounding_power   = s.decoration.rounding_power,    -- (ui) 2 = circular, higher = squarer
    active_opacity   = s.decoration.active_opacity,    -- (ui)
    inactive_opacity = s.decoration.inactive_opacity,  -- (ui)

    blur = {
      enabled  = s.blur.enabled,   -- (ui)
      size     = s.blur.size,      -- (ui)
      passes   = s.blur.passes,    -- (ui)
      vibrancy = 0.1696,
    },

    shadow = {
      enabled      = s.shadow.enabled,   -- (ui)
      range        = s.shadow.range,     -- (ui)
      render_power = 3,
      color        = 0xee1a1a1a,
    },
  },

  -- Dwindle: every new window splits the focused one in half.
  dwindle = {
    preserve_split = true,   -- keep the split direction when windows close
  },

  misc = {
    force_default_wallpaper = -1,   -- 0 or 1 disables the anime mascots
  },

  ecosystem = {
    no_update_news = true,
  },
})
