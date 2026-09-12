-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  HYPR SETTINGS STORE - read, validate, write, verify, reload              │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- The write path is deliberately paranoid, because a bad write lands in a live
-- compositor:
--
--   1. validate every field against the schema, reject the whole submission
--   2. back up the current settings.lua
--   3. write the new one
--   4. `Hyprland --verify-config` against the REAL config entry point
--   5. on failure, restore the backup and report; on success, `hyprctl reload`
--
-- Step 4 is what makes this safe: it type-checks the generated Lua through
-- Hyprland itself rather than trusting the serializer.

local paths  = require("lib.paths")
local schema = require("lib.hypr.schema")

local M = {}

-- ── read ────────────────────────────────────────────────────────────────────

--- Load settings.lua as data. Never runs in the app's own environment: the
--- chunk gets an empty env, so a tampered file cannot reach into the server.
function M.read()
  local chunk, err = loadfile(paths.settings)
  if not chunk then return nil, "settings.lua does not parse: " .. tostring(err) end

  if setfenv then setfenv(chunk, {}) end   -- Lua 5.1 / LuaJIT
  local ok, value = pcall(chunk)
  if not ok then return nil, "settings.lua raised: " .. tostring(value) end
  if type(value) ~= "table" then return nil, "settings.lua did not return a table" end
  return value
end

-- ── validate ────────────────────────────────────────────────────────────────

local function clamp_number(field, raw)
  local n = tonumber(raw)
  if not n then return nil, "not a number" end
  if field.type == "int" then
    if n % 1 ~= 0 then return nil, "must be a whole number" end
  end
  if field.min and n < field.min then return nil, ("below the minimum of %s"):format(field.min) end
  if field.max and n > field.max then return nil, ("above the maximum of %s"):format(field.max) end
  return n
end

local function coerce(field, raw)
  if field.type == "bool" then
    return raw == "1" or raw == "true" or raw == "on"
  elseif field.type == "int" or field.type == "float" then
    return clamp_number(field, raw)
  elseif field.type == "enum" then
    for _, opt in ipairs(field.options) do
      if opt.value == raw then
        return tonumber(raw) or raw   -- follow_mouse is numeric, layout is a string
      end
    end
    return nil, "not one of the allowed options"
  elseif field.type == "text" then
    raw = tostring(raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if raw == "" then return nil, "must not be empty" end
    if field.pattern and not raw:match(field.pattern) then return nil, "contains characters that are not allowed" end
    return raw
  end
  return nil, "unknown field type " .. tostring(field.type)
end

--- Build a settings table out of submitted form params.
--- Returns table, or nil plus a { ["section.key"] = message } error map.
function M.validate(params)
  local out, errors, bad = {}, {}, false

  for _, group in ipairs(schema) do
    out[group.section] = {}
    for _, field in ipairs(group.fields) do
      local name = group.section .. "." .. field.key
      -- An unchecked checkbox submits nothing; that is a legitimate `false`.
      local raw = params[name]
      if raw == nil and field.type == "bool" then raw = "0" end

      if raw == nil then
        errors[name], bad = "missing from the submission", true
      else
        local value, err = coerce(field, raw)
        if err then
          errors[name], bad = err, true
        else
          out[group.section][field.key] = value
        end
      end
    end
  end

  if bad then return nil, errors end
  return out
end

-- ── serialize ───────────────────────────────────────────────────────────────

local HEADER = [[
-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  SETTINGS - MACHINE-MANAGED                                              │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Written by the dotfiles web UI (routes/hypr.lua). Hand edits survive, but the
-- UI rewrites the whole file, so comments you add here will be lost.
--
-- This is the ONLY place these values live. conf/looknfeel.lua and
-- conf/input.lua read them straight out of this table, so there is nothing to
-- keep in sync. A nil here means "not configured" - Hyprland keeps its own
-- default - so removing a key is always safe.
]]

local function literal(v)
  if type(v) == "string" then return ("%q"):format(v) end
  if type(v) == "boolean" then return tostring(v) end
  if type(v) == "number" then
    if v % 1 == 0 then return ("%d"):format(v) end
    return (("%.4f"):format(v):gsub("0+$", ""):gsub("%.$", ".0"))
  end
  error("cannot serialize a " .. type(v))
end

--- Render a settings table as Lua source. Sections and keys are sorted so the
--- output is stable and diffs stay readable.
function M.serialize(settings)
  local sections = {}
  for _, group in ipairs(schema) do sections[#sections + 1] = group.section end

  local buf = { HEADER, "\nreturn {\n" }
  for i, section in ipairs(sections) do
    local values = settings[section] or {}
    local keys = {}
    for k in pairs(values) do keys[#keys + 1] = k end
    table.sort(keys)

    local width = 0
    for _, k in ipairs(keys) do width = math.max(width, #k) end

    buf[#buf + 1] = ("  %s = {\n"):format(section)
    for _, k in ipairs(keys) do
      buf[#buf + 1] = ("    %-" .. width .. "s = %s,\n"):format(k, literal(values[k]))
    end
    buf[#buf + 1] = "  },\n"
    if i < #sections then buf[#buf + 1] = "\n" end
  end
  buf[#buf + 1] = "}\n"

  return table.concat(buf)
end

-- ── shell helpers ───────────────────────────────────────────────────────────

local function run(cmd)
  local pipe = io.popen(cmd .. " 2>&1")
  local output = pipe:read("*a")
  local ok = pipe:close()
  return ok and true or false, output or ""
end

--- Type-check the generated config through Hyprland itself.
function M.verify()
  local _, out = run(("Hyprland --verify-config -c %q"):format(paths.live_config))
  if out:match("\nconfig ok") or out:match("^config ok") then return true end
  local detail = out:match("Config parsing result:%s*(.-)$") or out
  return false, (detail:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Ask a running Hyprland to re-read its config. No-op when it isn't running.
function M.reload()
  if not run("pgrep -x Hyprland >/dev/null") then
    return false, "Hyprland is not running - the file is saved and will apply on next login"
  end
  local ok, out = run("hyprctl reload")
  if not ok then return false, "hyprctl reload failed: " .. out end
  return true
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

--- Persist a validated settings table, verify it, and reload the compositor.
--- Rolls the file back if Hyprland rejects it.
function M.save(settings)
  local source  = M.serialize(settings)
  local previous = read_file(paths.settings)

  if previous == source then
    return { changed = false, message = "No changes - settings already match." }
  end

  os.execute(("mkdir -p %q"):format(paths.backups))
  local stamp = os.date("%Y%m%d-%H%M%S")
  if previous then
    write_file(("%s/settings.lua.%s"):format(paths.backups, stamp), previous)
  end

  local ok, err = write_file(paths.settings, source)
  if not ok then return nil, "could not write settings.lua: " .. tostring(err) end

  local valid, detail = M.verify()
  if not valid then
    if previous then write_file(paths.settings, previous) end
    return nil, "Hyprland rejected the config, so it was rolled back:\n" .. tostring(detail)
  end

  local reloaded, reason = M.reload()
  return {
    changed  = true,
    reloaded = reloaded,
    message  = reloaded and "Saved and applied to the running session."
                         or ("Saved. " .. tostring(reason)),
    backup   = ("hypr/.backup/settings.lua.%s"):format(stamp),
  }
end

return M
