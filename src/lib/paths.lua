-- Resolves absolute paths so the app works from any cwd.
--
-- DOTFILES_ROOT is exported by ./dev; the fallback walks up from the current
-- directory looking for the repo marker, which keeps `lapis server` usable by
-- hand.

local function exists(p)
  local f = io.open(p, "r")
  if f then f:close() return true end
  return false
end

local function find_root()
  local env = os.getenv("DOTFILES_ROOT")
  if env and exists(env .. "/hypr/init.lua") then return env end

  local dir = "."
  for _ = 1, 6 do
    if exists(dir .. "/hypr/init.lua") then
      local pipe = io.popen("cd '" .. dir .. "' && pwd")
      local abs = pipe:read("*l")
      pipe:close()
      return abs
    end
    dir = dir .. "/.."
  end
  error("could not locate the dotfiles repo root (no hypr/init.lua found)")
end

local root = find_root()

return {
  root           = root,
  hypr_dir       = root .. "/hypr",
  settings       = root .. "/hypr/settings.lua",
  backups        = root .. "/hypr/.backup",
  keybinds       = root .. "/hypr/keybinds.lua",
  live_config    = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/hyprland.lua",
  static         = root .. "/src/static",
  exists         = exists,
}
