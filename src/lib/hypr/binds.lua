-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  KEYBIND STORE - read, validate, detect conflicts, write                 │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- hypr/keybinds.lua is plain data, so it loads here with an empty environment
-- and rewrites cleanly. Only `combo` is editable from the browser: ids are
-- looked up by conf/binds/dispatch.lua, and descriptions describe behaviour
-- that lives in Lua.
--
-- The write path mirrors lib/hypr/store.lua: back up, write, verify through
-- Hyprland, roll back on rejection, reload on success.

local paths = require("lib.paths")
local store = require("lib.hypr.store")

local M = {}

-- ── modifiers and keys ──────────────────────────────────────────────────────

-- Canonical order, so "SHIFT + SUPER + Q" and "SUPER + SHIFT + Q" compare equal.
local MOD_ORDER = { SUPER = 1, CTRL = 2, ALT = 3, SHIFT = 4 }

local MOD_ALIASES = {
  SUPER = "SUPER", META = "SUPER", WIN = "SUPER", MOD4 = "SUPER", CMD = "SUPER",
  CTRL = "CTRL", CONTROL = "CTRL",
  ALT = "ALT", MOD1 = "ALT",
  SHIFT = "SHIFT",
}

local function split(combo)
  local parts = {}
  for token in tostring(combo):gmatch("[^+]+") do
    token = token:gsub("^%s+", ""):gsub("%s+$", "")
    if token ~= "" then parts[#parts + 1] = token end
  end
  return parts
end

--- A key token Hyprland will plausibly accept.
local function valid_key(key)
  if key:match("^mouse:%d+$") then return true end          -- mouse:272
  if key == "mouse_up" or key == "mouse_down" then return true end
  if key:match("^XF86%w+$") then return true end            -- XF86AudioMute
  if key:match("^code:%d+$") then return true end           -- raw keycode
  if key:match("^[%w_]+$") then return true end             -- Q, 5, Left, Print, F11
  return false
end

--- Parse a combo into { mods = {...}, key = "..." } or nil plus a reason.
function M.parse(combo)
  local parts = split(combo)
  if #parts == 0 then return nil, "empty" end

  local key = table.remove(parts)
  if not valid_key(key) then
    return nil, ("%q is not a key Hyprland recognises"):format(key)
  end

  local mods, seen = {}, {}
  for _, raw in ipairs(parts) do
    local mod = MOD_ALIASES[raw:upper()]
    if not mod then
      return nil, ("%q is not a modifier (use SUPER, CTRL, ALT or SHIFT)"):format(raw)
    end
    if not seen[mod] then
      seen[mod] = true
      mods[#mods + 1] = mod
    end
  end

  table.sort(mods, function(a, b) return MOD_ORDER[a] < MOD_ORDER[b] end)
  return { mods = mods, key = key }
end

--- Canonical spelling: modifiers in a fixed order, then the key.
function M.normalize(combo)
  local parsed, err = M.parse(combo)
  if not parsed then return nil, err end
  local out = {}
  for _, m in ipairs(parsed.mods) do out[#out + 1] = m end
  out[#out + 1] = parsed.key
  return table.concat(out, " + ")
end

-- ── read ────────────────────────────────────────────────────────────────────

function M.read()
  local chunk, err = loadfile(paths.keybinds)
  if not chunk then return nil, "keybinds.lua does not parse: " .. tostring(err) end
  if setfenv then setfenv(chunk, {}) end
  local ok, value = pcall(chunk)
  if not ok then return nil, "keybinds.lua raised: " .. tostring(value) end
  if type(value) ~= "table" then return nil, "keybinds.lua did not return a list" end
  return value
end

--- Group the flat list for display, preserving first-seen group order.
function M.grouped(entries)
  local groups, index = {}, {}
  for _, e in ipairs(entries) do
    local name = e.group or "Other"
    if not index[name] then
      index[name] = { title = name, entries = {} }
      groups[#groups + 1] = index[name]
    end
    table.insert(index[name].entries, e)
  end
  return groups
end

-- ── conflicts ───────────────────────────────────────────────────────────────

--- Find combos claimed by more than one bind.
--- Returns { [id] = { combo = ..., others = { "desc", ... } } }.
--- Duplicates are legal in Hyprland - the last one registered wins - so this is
--- a warning, not an error.
function M.conflicts(entries)
  local by_combo = {}
  for _, e in ipairs(entries) do
    local canonical = M.normalize(e.combo)
    if canonical then
      by_combo[canonical] = by_combo[canonical] or {}
      table.insert(by_combo[canonical], e)
    end
  end

  local found = {}
  for canonical, sharing in pairs(by_combo) do
    if #sharing > 1 then
      for _, e in ipairs(sharing) do
        local others = {}
        for _, other in ipairs(sharing) do
          if other.id ~= e.id then
            others[#others + 1] = ("%s (%s)"):format(other.desc or other.id, other.id)
          end
        end
        found[e.id] = { combo = canonical, others = others }
      end
    end
  end
  return found
end

-- ── validate a submission ───────────────────────────────────────────────────

--- Apply submitted combos onto the stored list.
--- Returns entries, conflicts or nil plus a { [id] = message } error map.
function M.apply(params)
  local entries, err = M.read()
  if not entries then return nil, { _file = err } end

  local errors, bad = {}, false
  for _, e in ipairs(entries) do
    local submitted = params["combo." .. e.id]
    if submitted ~= nil then
      submitted = tostring(submitted):gsub("^%s+", ""):gsub("%s+$", "")
      local canonical, reason = M.normalize(submitted)
      if not canonical then
        errors[e.id], bad = reason, true
      else
        e.combo = canonical
      end
    end
  end

  if bad then return nil, errors end
  return entries, M.conflicts(entries)
end

-- ── serialize ───────────────────────────────────────────────────────────────

local HEADER = [[
-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  KEYBINDS - MACHINE-MANAGED                                              │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- The source of truth for which key runs what. Written by the web UI at
-- /hypr/binds; hand edits are fine but the UI rewrites the whole file, so
-- comments you add here will be lost.
--
-- This is plain data on purpose: the web app loads it with an empty
-- environment, so it needs no access to the `hl` API to read or rewrite it.
-- conf/binds/dispatch.lua maps each `id` to what it actually does, and
-- conf/binds/init.lua joins the two.
--
--   id        stable name. Changing it orphans the bind - the dispatcher is
--             looked up by this, so it must match dispatch.lua.
--   combo     one string, e.g. "SUPER + SHIFT + Left". This is what the UI edits.
--   group     which section of the UI it appears under.
--   locked    still fires while the screen is locked  (hyprlang bindl)
--   repeating fires while held                        (hyprlang binde)
--   mouse     hold-to-drag, released on button up     (hyprlang bindm)
]]

function M.serialize(entries)
  local buf = { HEADER, "\nreturn {\n" }
  local last_group

  for _, e in ipairs(entries) do
    if e.group ~= last_group then
      if last_group then buf[#buf + 1] = "\n" end
      buf[#buf + 1] = ("  -- %s\n"):format(e.group or "Other")
      last_group = e.group
    end

    local fields = {
      ("id = %q"):format(e.id),
      ("group = %q"):format(e.group or "Other"),
      ("combo = %q"):format(e.combo),
      ("desc = %q"):format(e.desc or ""),
    }
    if e.locked    then fields[#fields + 1] = "locked = true" end
    if e.repeating then fields[#fields + 1] = "repeating = true" end
    if e.mouse     then fields[#fields + 1] = "mouse = true" end

    buf[#buf + 1] = ("  { %s },\n"):format(table.concat(fields, ", "))
  end

  buf[#buf + 1] = "}\n"
  return table.concat(buf)
end

-- ── write ───────────────────────────────────────────────────────────────────

local function read_file(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local c = f:read("*a"); f:close(); return c
end

local function write_file(p, content)
  local f, err = io.open(p, "wb")
  if not f then return nil, err end
  f:write(content); f:close(); return true
end

function M.save(entries)
  local source   = M.serialize(entries)
  local previous = read_file(paths.keybinds)

  if previous == source then
    return { changed = false, message = "No changes - keybinds already match." }
  end

  os.execute(("mkdir -p %q"):format(paths.backups))
  local stamp = os.date("%Y%m%d-%H%M%S")
  if previous then
    write_file(("%s/keybinds.lua.%s"):format(paths.backups, stamp), previous)
  end

  local ok, err = write_file(paths.keybinds, source)
  if not ok then return nil, "could not write keybinds.lua: " .. tostring(err) end

  local valid, detail = store.verify()
  if not valid then
    if previous then write_file(paths.keybinds, previous) end
    return nil, "Hyprland rejected the config, so it was rolled back:\n" .. tostring(detail)
  end

  local reloaded, reason = store.reload()
  return {
    changed  = true,
    reloaded = reloaded,
    message  = reloaded and "Saved and applied to the running session."
                         or ("Saved. " .. tostring(reason)),
    backup   = ("hypr/.backup/keybinds.lua.%s"):format(stamp),
  }
end

return M
