-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  PRESETS - snapshot and restore the whole configuration                  │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- A preset is one file in hypr/presets/ holding both tables: the values from
-- settings.lua and the combos from keybinds.lua. Applying one overwrites both,
-- which is what makes "put it back" a single action.
--
-- The write is the same paranoid sequence the individual stores use, extended
-- to two files: back both up, write both, verify through Hyprland once, and
-- restore BOTH if it is rejected. A half-applied preset would be worse than no
-- preset at all.

local paths = require("lib.paths")
local store = require("lib.hypr.store")
local binds = require("lib.hypr.binds")

local M = {}

local DIR = paths.root .. "/hypr/presets"

-- ── read ────────────────────────────────────────────────────────────────────

local function load_data(path)
  local chunk, err = loadfile(path)
  if not chunk then return nil, tostring(err) end
  if setfenv then setfenv(chunk, {}) end   -- data only, no reach into the app
  local ok, value = pcall(chunk)
  if not ok then return nil, tostring(value) end
  if type(value) ~= "table" then return nil, "did not return a table" end
  return value
end

--- Every preset on disk, sorted with `default` first.
function M.list()
  local pipe = io.popen(("ls -1 %q/*.lua 2>/dev/null"):format(DIR))
  if not pipe then return {} end

  local found = {}
  for line in pipe:lines() do
    local name = line:match("([^/]+)%.lua$")
    local data = name and load_data(line)
    if data then
      found[#found + 1] = {
        name        = data.name or name,
        slug        = name,
        description = data.description,
        settings    = data.settings,
        keybinds    = data.keybinds,
        binds_count = data.keybinds and #data.keybinds or 0,
      }
    end
  end
  pipe:close()

  table.sort(found, function(a, b)
    if a.slug == "default" then return true end
    if b.slug == "default" then return false end
    return a.slug < b.slug
  end)
  return found
end

function M.get(slug)
  if not slug or not slug:match("^[%w_-]+$") then return nil, "bad preset name" end
  for _, preset in ipairs(M.list()) do
    if preset.slug == slug then return preset end
  end
  return nil, "no preset called " .. slug
end

-- ── compare ─────────────────────────────────────────────────────────────────

--- True when the live files already match the preset, so the UI can say
--- "you are on default" instead of offering a pointless reset.
function M.matches(preset)
  local settings = store.read()
  local entries  = binds.read()
  if not settings or not entries then return false end
  return store.serialize(settings) == store.serialize(preset.settings)
     and binds.serialize(entries)  == binds.serialize(preset.keybinds)
end

-- ── apply ───────────────────────────────────────────────────────────────────

local function read_file(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local c = f:read("*a"); f:close(); return c
end

local function write_file(p, content)
  local f, err = io.open(p, "wb")
  if not f then return nil, err end
  f:write(content); f:close(); return true
end

--- Overwrite settings.lua and keybinds.lua from a preset, verify, reload.
function M.apply(preset)
  if not preset.settings or not preset.keybinds then
    return nil, "preset is missing its settings or keybinds"
  end

  local new_settings = store.serialize(preset.settings)
  local new_binds    = binds.serialize(preset.keybinds)

  local old_settings = read_file(paths.settings)
  local old_binds    = read_file(paths.keybinds)

  if old_settings == new_settings and old_binds == new_binds then
    return { changed = false, message = ("Already on %q - nothing to restore."):format(preset.name) }
  end

  os.execute(("mkdir -p %q"):format(paths.backups))
  local stamp = os.date("%Y%m%d-%H%M%S")
  if old_settings then write_file(("%s/settings.lua.%s"):format(paths.backups, stamp), old_settings) end
  if old_binds    then write_file(("%s/keybinds.lua.%s"):format(paths.backups, stamp), old_binds) end

  local function restore()
    if old_settings then write_file(paths.settings, old_settings) end
    if old_binds    then write_file(paths.keybinds, old_binds) end
  end

  local ok, err = write_file(paths.settings, new_settings)
  if not ok then restore(); return nil, "could not write settings.lua: " .. tostring(err) end

  ok, err = write_file(paths.keybinds, new_binds)
  if not ok then restore(); return nil, "could not write keybinds.lua: " .. tostring(err) end

  local valid, detail = store.verify()
  if not valid then
    restore()
    return nil, ("Hyprland rejected %q, so both files were rolled back:\n%s")
      :format(preset.name, tostring(detail))
  end

  local reloaded, reason = store.reload()
  return {
    changed  = true,
    reloaded = reloaded,
    message  = reloaded and ("Restored %q and applied it to the running session."):format(preset.name)
                         or ("Restored %q. %s"):format(preset.name, tostring(reason)),
    backup   = ("hypr/.backup/{settings,keybinds}.lua.%s"):format(stamp),
  }
end

return M
