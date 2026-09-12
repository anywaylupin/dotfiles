-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  NAVIGATION REGISTRY                                                     │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- One list drives the top bar and the homepage cards. Adding a section is two
-- lines: an entry here and a route in app.lua. `glyph` is a plain character so
-- there is no icon-font dependency.
--
-- The homepage at "/" is deliberately absent: it is the shell these link out
-- from, not one of the destinations.

return {
  { path = "/system",     name = "system",    label = "System",    glyph = "◲",
    blurb = "Compositor, hardware and disks" },
  { path = "/hypr",       name = "hypr",      label = "Hyprland",  glyph = "◈",
    blurb = "Layout, decoration and input" },
  { path = "/hypr/binds", name = "binds",     label = "Keybinds",  glyph = "⌨",
    blurb = "All 84 binds, editable" },
  { path = "/resources",  name = "resources", label = "Resources", glyph = "❖",
    blurb = "Docs and tools this is built on" },
}
