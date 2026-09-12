-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  WINDOW RULES - BEHAVIOUR                                                │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- hyprlang wrote one rule per line as `windowrule = <effect>, <match>`. In Lua
-- one call is one NAMED rule: a `match` table plus the effects as fields. The
-- name shows up in `hyprctl rules` and lets you toggle a rule at runtime.
--
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Ignore maximize requests from every app; let the layout decide instead.
hl.window_rule({
  name           = "suppress-maximize",
  match          = { class = ".*" },
  suppress_event = "maximize",
})

-- Unfocusable phantom windows XWayland creates mid-drag. Without this, dragging
-- between XWayland apps drops the payload.
hl.window_rule({
  name  = "fix-xwayland-drags",
  match = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

-- JetBrains IDE popups steal focus on open, which makes them flicker shut.
hl.window_rule({
  name             = "jetbrains-popup-flicker",
  match            = { class = "^(.*jetbrains.*)$", title = "^(win[0-9]+)$" },
  no_initial_focus = true,
})

-- ── Idle inhibit ────────────────────────────────────────────────────────────
-- Block the idle timer while these are fullscreen, so video doesn't get
-- interrupted by the lock screen.

local INHIBIT_WHEN_FULLSCREEN = {
  "^(.*[Ss]potify.*)$",
  "^(.*celluloid.*)$|^(.*mpv.*)$|^(.*vlc.*)$",
  "^(.*LibreWolf.*)$|^(.*floorp.*)$|^(.*brave-browser.*)$|^(.*firefox.*)$|^(.*chromium.*)$|^(.*zen.*)$|^(.*vivaldi.*)$",
}

for i, class in ipairs(INHIBIT_WHEN_FULLSCREEN) do
  hl.window_rule({
    name         = "idle-inhibit-" .. i,
    match        = { class = class },
    idle_inhibit = "fullscreen",
  })
end

-- ── Picture-in-picture ──────────────────────────────────────────────────────
-- Two rules: one tags any PiP window by title, the second styles everything
-- carrying that tag. Splitting it this way means a new browser needs no change.

hl.window_rule({
  name  = "tag-picture-in-picture",
  match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
  tag   = "+picture-in-picture",
})

hl.window_rule({
  name  = "picture-in-picture",
  match = { tag = "picture-in-picture" },

  float             = true,
  keep_aspect_ratio = true,
  pin               = true,          -- visible on every workspace
  move              = "73% 72%",     -- bottom right
  size              = "25% 25%",
})
