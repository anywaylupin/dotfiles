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

local M = {
  { path = "/system",     name = "system",    label = "System",    glyph = "◲",
    blurb = "Compositor, hardware and disks" },
  { path = "/hypr",       name = "hypr",      label = "Hyprland",  glyph = "◈",
    blurb = "Layout, decoration and input" },
  { path = "/hypr/binds", name = "binds",     label = "Keybinds",  glyph = "⌨",
    blurb = "All 84 binds, editable" },
  { path = "/waybar",     name = "waybar",    label = "Waybar",    glyph = "▤",
    blurb = "Bar layout and modules" },
  { path = "/resources",  name = "resources", label = "Resources", glyph = "❖",
    blurb = "Docs and tools this is built on" },
}

-- Shown at the right of the top bar. Read once from the git remote, so it stays
-- correct if the repo moves; falls back to nil and the link is not rendered.
local function repo_url()
  local pipe = io.popen("git -C " .. ("%q"):format(require("lib.paths").root)
    .. " remote get-url origin 2>/dev/null")
  if not pipe then return nil end
  local url = pipe:read("*l")
  pipe:close()
  if not url or url == "" then return nil end
  -- git@github.com:user/repo.git and https://github.com/user/repo.git both
  -- normalise to a browsable https URL.
  url = url:gsub("^git@([^:]+):", "https://%1/"):gsub("%.git$", "")
  return url
end

return { items = M, repo = repo_url() }
