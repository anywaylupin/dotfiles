-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  WINDOW RULES - OPACITY                                                  │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- An opacity value is a STRING of up to three numbers: active, inactive,
-- fullscreen. `override` makes the rule win over decoration.active_opacity /
-- inactive_opacity instead of multiplying with it - this is what the old
-- config's HyDE `$&` shorthand expanded to.
--
--   "0.90 override 0.90 override 1.0"   opaque when fullscreen, dimmed otherwise
--   "0.80 0.80"                         multiplied with the global opacity
--
-- Classes are grouped by value and sorted within each group.
--
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- { opacity, class patterns... }
local GROUPS = {
  { "0.95 override 0.95 override 1.0",
    "^([Cc]ode)$",
    "^(code-oss)$",
  },
  { "0.90 override 0.90 override 1.0",
    "^(brave-browser)$",
    "^(firefox)$",
  },
  { "0.80 override 0.80 override 1.0",
    "^(code-insiders-url-handler)$",
    "^(code-url-handler)$",
    "^(kitty)$",
    "^(kvantummanager)$",
    "^(nwg-look)$",
    "^(org.kde.ark)$",
    "^(org.kde.dolphin)$",
    "^(qt5ct)$",
    "^(qt6ct)$",
  },
  -- Tray applets and auth dialogs: dim harder when they lose focus.
  { "0.80 override 0.70 override 1.0",
    "^(blueman-manager)$",
    "^(nm-applet)$",
    "^(nm-connection-editor)$",
    "^(org.freedesktop.impl.portal.desktop.gtk)$",
    "^(org.freedesktop.impl.portal.desktop.hyprland)$",
    "^(org.kde.polkit-kde-authentication-agent-1)$",
    "^(org.pulseaudio.pavucontrol)$",
    "^(polkit-gnome-authentication-agent-1)$",
  },
  { "0.70 override 0.70 override 1.0",
    "^([Ss]potify)$",
    "^([Ss]team)$",
    "^(steamwebhelper)$",
  },
  { "0.90 0.90",
    "^(com.github.rafostar.Clapper)$",
  },
  { "0.80 0.80",
    "^(ArmCord)$",
    "^(Signal)$",
    "^(WebCord)$",
    "^(app.drey.Warp)$",
    "^(com.github.tchx84.Flatseal)$",
    "^(com.github.unrud.VideoDownloader)$",
    "^(com.obsproject.Studio)$",
    "^(discord)$",
    "^(gnome-boxes)$",
    "^(hu.kramo.Cartridges)$",
    "^(io.github.alainm23.planify)$",
    "^(io.github.flattool.Warehouse)$",
    "^(io.gitlab.adhami3310.Impression)$",
    "^(io.gitlab.theevilskeleton.Upscaler)$",
    "^(io.missioncenter.MissionCenter)$",
    "^(net.davidotek.pupgui2)$",
    "^(vesktop)$",
    "^(yad)$",
  },
}

local n = 0
for _, group in ipairs(GROUPS) do
  local value = group[1]
  for i = 2, #group do
    n = n + 1
    hl.window_rule({
      name    = "opacity-" .. n,
      match   = { class = group[i] },
      opacity = value,
    })
  end
end

-- Spotify's class is inconsistent across builds; match the launch title too.
for i, title in ipairs({ "^(Spotify Free)$", "^(Spotify Premium)$" }) do
  hl.window_rule({
    name    = "opacity-spotify-" .. i,
    match   = { initial_title = title },
    opacity = "0.70 override 0.70 override 1.0",
  })
end
