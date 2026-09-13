-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  HYPR SETTINGS SCHEMA                                                    │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- The single source of truth for what the web UI may edit. The form, the
-- validation and the writer are all generated from this table - add a field
-- here and it appears in the browser with no other change.
--
-- Each field: { key, label, type, ... }
--   type "int"    min, max, step
--   type "float"  min, max, step
--   type "bool"
--   type "enum"   options = { { value, label }, ... }
--   type "text"   pattern (optional Lua pattern the value must match)
--
-- `section` is the table in hypr/settings.lua the fields are written into.

return {
  {
    section = "general",
    glyph   = "界",
    title   = "Layout",
    blurb   = "Gaps, borders and the tiling algorithm.",
    fields  = {
      { key = "gaps_in",          label = "Inner gap",     type = "int",  min = 0, max = 50, help = "Between windows." },
      { key = "gaps_out",         label = "Outer gap",     type = "int",  min = 0, max = 100, help = "Window to screen edge." },
      { key = "border_size",      label = "Border width",  type = "int",  min = 0, max = 12 },
      { key = "resize_on_border", label = "Resize on border", type = "bool", help = "Drag borders and gaps to resize." },
      { key = "layout",           label = "Tiling layout", type = "enum",
        options = {
          { value = "dwindle",   label = "Dwindle - split the focused window" },
          { value = "master",    label = "Master - one main window plus a stack" },
          { value = "scrolling", label = "Scrolling - an endless column strip" },
        } },
    },
  },
  {
    section = "decoration",
    glyph   = "飾",
    title   = "Decoration",
    blurb   = "Corners and window opacity.",
    fields  = {
      { key = "rounding",         label = "Corner radius", type = "int",   min = 0, max = 30 },
      { key = "rounding_power",   label = "Corner curve",  type = "float", min = 2, max = 10, step = 0.1,
        help = "2 is circular; higher is squarer." },
      { key = "active_opacity",   label = "Active opacity",   type = "float", min = 0.1, max = 1, step = 0.01 },
      { key = "inactive_opacity", label = "Inactive opacity", type = "float", min = 0.1, max = 1, step = 0.01 },
    },
  },
  {
    section = "blur",
    glyph   = "霧",
    title   = "Blur",
    blurb   = "Costs GPU time; passes are more expensive than size.",
    fields  = {
      { key = "enabled", label = "Enabled", type = "bool" },
      { key = "size",    label = "Size",    type = "int", min = 1, max = 20 },
      { key = "passes",  label = "Passes",  type = "int", min = 1, max = 5 },
    },
  },
  {
    section = "shadow",
    glyph   = "影",
    title   = "Shadow",
    fields  = {
      { key = "enabled", label = "Enabled", type = "bool" },
      { key = "range",   label = "Range",   type = "int", min = 0, max = 50 },
    },
  },
  {
    section = "animations",
    glyph   = "動",
    title   = "Animations",
    blurb   = "The curves and leaf tree stay in hypr/conf/animations.lua.",
    fields  = {
      { key = "enabled", label = "Enabled", type = "bool" },
    },
  },
  {
    section = "misc",
    glyph   = "字",
    title   = "Typography",
    blurb   = "Used by Hyprland's own surfaces: the group bar and the splash.",
    fields  = {
      { key = "font_family", label = "Font family", type = "text",
        pattern = "^[%a][%w%s,_%-]*$",
        help = "Also set in waybar/style.css, which Hyprland cannot read." },
    },
  },
  {
    section = "input",
    glyph   = "觸",
    title   = "Input",
    fields  = {
      { key = "kb_layout",    label = "Keyboard layout", type = "text", pattern = "^[%a][%a%d,_%-]*$",
        help = "An xkb layout name, or a comma-separated list." },
      { key = "follow_mouse", label = "Focus follows mouse", type = "enum",
        options = {
          { value = "0", label = "0 - off" },
          { value = "1", label = "1 - focus follows the cursor" },
          { value = "2", label = "2 - loose, keyboard focus stays" },
          { value = "3", label = "3 - focus follows, no click-through" },
        } },
      { key = "sensitivity",    label = "Mouse sensitivity", type = "float", min = -1, max = 1, step = 0.05 },
      { key = "natural_scroll", label = "Natural scroll",    type = "bool", help = "Touchpad." },
    },
  },
}
