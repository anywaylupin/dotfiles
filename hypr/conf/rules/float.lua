-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  WINDOW RULES - FLOAT                                                    │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Apps that are dialogs or single-purpose utilities in practice, and behave
-- badly when tiled. Sorted by class.
--
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

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
