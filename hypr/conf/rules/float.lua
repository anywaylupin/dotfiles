-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  WINDOW RULES - FLOAT                                                    │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Apps that are dialogs or single-purpose utilities in practice, and behave
-- badly when tiled. Sorted by class.
--
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Settings panels that behave like popups rather than documents: floated,
-- sized, and parked under the bar at the top right where their bar module is.
local POPUPS = {
  { class = "^(org.pulseaudio.pavucontrol)$", size = "560 640" },
  { class = "^(nm-connection-editor)$",       size = "520 600" },
  { class = "^(blueman-manager)$",            size = "480 560" },
}

for i, popup in ipairs(POPUPS) do
  hl.window_rule({
    name  = "popup-" .. i,
    match = { class = popup.class },
    float = true,
    size  = popup.size,
    move  = "100%-w-12 46",     -- 12px in from the right, just below the bar
  })
end

local FLOAT = {
  "^(Signal)$",
  "^(app.drey.Warp)$",
  "^(com.github.rafostar.Clapper)$",
  "^(com.github.unrud.VideoDownloader)$",
  "^(eog)$",
  "^(io.github.alainm23.planify)$",
  "^(io.gitlab.adhami3310.Impression)$",
  "^(io.gitlab.theevilskeleton.Upscaler)$",
  "^(io.missioncenter.MissionCenter)$",
  "^(net.davidotek.pupgui2)$",
  "^(yad)$",
}

for i, class in ipairs(FLOAT) do
  hl.window_rule({
    name  = "float-" .. i,
    match = { class = class },
    float = true,
  })
end
