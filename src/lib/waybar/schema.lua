-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  WAYBAR SCHEMA                                                           │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- What the UI may change in waybar/config.jsonc. Module OPTIONS are not here:
-- those live in waybar/modules.jsonc, hand-written with comments, and the UI
-- never rewrites that file. This covers the bar itself and which modules appear
-- in which slot.

return {
  bar = {
    title  = "Bar",
    blurb  = "Geometry and stacking. Waybar does not reload itself, so saving restarts it.",
    fields = {
      { key = "position", label = "Position", type = "enum",
        options = {
          { value = "top",    label = "Top" },
          { value = "bottom", label = "Bottom" },
        } },
      { key = "layer", label = "Layer", type = "enum",
        help = "`top` sits above windows; `bottom` lets them cover it.",
        options = {
          { value = "top",     label = "Top" },
          { value = "bottom",  label = "Bottom" },
          { value = "overlay", label = "Overlay - above fullscreen too" },
        } },
      { key = "height",  label = "Height",  type = "int", min = 20, max = 64 },
      { key = "spacing", label = "Spacing", type = "int", min = 0,  max = 24,
        help = "Gap between modules, in pixels." },
    },
  },

  -- Every module the bar knows about, in the order they are placed within a
  -- slot. Turning one off removes it from its array; the definition stays in
  -- modules.jsonc, so it comes back unchanged when re-enabled.
  modules = {
    -- The ten workspace buttons are one logical control, so the UI toggles them
    -- together rather than offering ten switches.
    { key = "custom/ws*", slot = "left", label = "Workspaces", glyph = "一",
      expands = 10,
      help = "Ten clickable buttons, numbered in Han." },
    { key = "hyprland/submap",     slot = "left",   label = "Submap",      glyph = "變",
      help = "Shows the active submap, if any." },
    { key = "custom/date",         slot = "center", label = "Date",        glyph = "日",
      help = "Written out in Simplified Chinese." },
    { key = "clock",               slot = "center", label = "Clock",       glyph = "時" },
    { key = "mpris", slot = "left", label = "Now playing", glyph = "♪",
      help = "Whatever MPRIS player is active - Spotify, a browser tab." },
    { key = "custom/im", slot = "right", label = "Input method", glyph = "文",
      help = "EN or VI. Click to toggle, or Ctrl+Shift anywhere." },
    { key = "custom/ai", slot = "right", label = "Clawd", glyph = "🦀",
      help = "Claude usage across both rate-limit windows." },
    { key = "wireplumber",         slot = "right",  label = "Volume",      glyph = "音" },
    { key = "backlight",           slot = "right",  label = "Brightness",  glyph = "明" },
    { key = "battery",             slot = "right",  label = "Battery",     glyph = "氣" },
    { key = "network",             slot = "right",  label = "Network",     glyph = "雲" },
    { key = "tray",                slot = "right",  label = "System tray", glyph = "寶" },
  },
}
