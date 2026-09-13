-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  WAYBAR STORE - read, validate, write, restart                           │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Writes waybar/config.jsonc only. waybar/modules.jsonc is hand-written and
-- never touched, which is why module options are absent from the schema.
--
-- JSON is emitted by hand rather than through cjson.encode: the output is a
-- file a human reads and diffs, so key order has to be stable and the comment
-- header has to survive. cjson gives neither.
--
-- There is no `--verify-config` for waybar, so the check is different from the
-- Hyprland stores: re-parse what was written, and roll back if it is not valid
-- JSON. A bad config would otherwise leave the bar dead until next login.

local paths  = require("lib.paths")
local schema = require("lib.waybar.schema")
local cjson  = require("cjson")

local M = {}

local CONFIG  = paths.root .. "/waybar/config.jsonc"
local MODULES = paths.root .. "/waybar/modules.jsonc"

-- ── read ────────────────────────────────────────────────────────────────────

local function read_file(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local c = f:read("*a"); f:close(); return c
end

local function write_file(p, content)
  local f, err = io.open(p, "wb")
  if not f then return nil, err end
  f:write(content); f:close(); return true
end

--- jsonc is json plus // comments. Strip whole-line comments before decoding;
--- the files here never put one mid-line.
local function decode_jsonc(text)
  if not text then return nil, "file is missing" end
  local stripped = text:gsub("\n%s*//[^\n]*", "\n"):gsub("^%s*//[^\n]*", "")
  local ok, value = pcall(cjson.decode, stripped)
  if not ok then return nil, "not valid json: " .. tostring(value) end
  return value
end

function M.read()
  local config, err = decode_jsonc(read_file(CONFIG))
  if not config then return nil, "waybar/config.jsonc " .. tostring(err) end
  return config
end

--- Which modules are currently placed, as a set keyed by module name.
function M.enabled(config)
  local on = {}
  for _, slot in ipairs({ "modules-left", "modules-center", "modules-right" }) do
    for _, name in ipairs(config[slot] or {}) do
      on[name] = true
      -- A family counts as enabled if any of its members is placed.
      local stem = name:match("^(.-)%d+$")
      if stem then on[stem .. "*"] = true end
    end
  end
  return on
end

--- True when modules.jsonc actually defines a module, so the UI can flag an
--- entry that would be enabled but has no definition behind it.
function M.defined()
  local modules = decode_jsonc(read_file(MODULES)) or {}
  local present = {}
  for key in pairs(modules) do
    present[key] = true
    local stem = key:match("^(.-)%d+$")
    if stem then present[stem .. "*"] = true end
  end
  return present
end

-- ── validate ────────────────────────────────────────────────────────────────

function M.validate(params)
  local out, errors, bad = {}, {}, false

  for _, field in ipairs(schema.bar.fields) do
    local raw = params["bar." .. field.key]
    local name = "bar." .. field.key

    if raw == nil then
      errors[name], bad = "missing from the submission", true
    elseif field.type == "int" then
      local n = tonumber(raw)
      if not n or n % 1 ~= 0 then
        errors[name], bad = "must be a whole number", true
      elseif n < field.min or n > field.max then
        errors[name], bad = ("must be between %d and %d"):format(field.min, field.max), true
      else
        out[field.key] = n
      end
    elseif field.type == "enum" then
      local allowed = false
      for _, opt in ipairs(field.options) do
        if opt.value == raw then allowed = true end
      end
      if not allowed then
        errors[name], bad = "not one of the allowed options", true
      else
        out[field.key] = raw
      end
    end
  end

  -- Module toggles rebuild the slot arrays in schema order, so the bar's
  -- left-to-right layout is defined in one place rather than by form order.
  local slots = { left = {}, center = {}, right = {} }
  for _, module in ipairs(schema.modules) do
    if params["module." .. module.key] == "1" then
      if module.expands then
        -- One switch stands for a numbered family, e.g. custom/ws1..custom/ws10.
        local stem = module.key:gsub("%*$", "")
        for i = 1, module.expands do
          table.insert(slots[module.slot], stem .. i)
        end
      else
        table.insert(slots[module.slot], module.key)
      end
    end
  end
  out.slots = slots

  if bad then return nil, errors end
  return out
end

-- ── serialize ───────────────────────────────────────────────────────────────

local HEADER = [[
// ╭──────────────────────────────────────────────────────────────────────────╮
// │  WAYBAR - BAR LAYOUT (MACHINE-MANAGED)                                   │
// ╰──────────────────────────────────────────────────────────────────────────╯
//
// Written by the web UI at /waybar. Hand edits survive until the next save,
// which rewrites the whole file - so comments added here will be lost.
//
// Module options live in modules.jsonc, which this includes. The direction
// matters: waybar resolves conflicts in favour of the INCLUDING file, so the
// tunables must sit here and the definitions there, not the other way round.
]]

local function json_array(items)
  local quoted = {}
  for i, item in ipairs(items) do quoted[i] = ("%q"):format(item) end
  return "[" .. table.concat(quoted, ", ") .. "]"
end

function M.serialize(values)
  return table.concat({
    HEADER,
    "{\n",
    ('  "include": [%q],\n\n'):format(paths.root .. "/waybar/modules.jsonc"),
    ('  "layer": %q,\n'):format(values.layer),
    ('  "position": %q,\n'):format(values.position),
    ('  "height": %d,\n'):format(values.height),
    ('  "spacing": %d,\n\n'):format(values.spacing),
    ('  "modules-left": %s,\n'):format(json_array(values.slots.left)),
    ('  "modules-center": %s,\n'):format(json_array(values.slots.center)),
    ('  "modules-right": %s\n'):format(json_array(values.slots.right)),
    "}\n",
  })
end

-- ── write ───────────────────────────────────────────────────────────────────

local function run(cmd)
  local pipe = io.popen(cmd .. " 2>&1")
  local out = pipe:read("*a")
  local ok = pipe:close()
  return ok and true or false, out or ""
end

--- waybar has no reload signal worth relying on, so it is killed and relaunched
--- exactly the way conf/services.lua starts it.
function M.restart()
  if not run("pgrep -x waybar >/dev/null") then
    return false, "waybar is not running - it will pick this up when it starts"
  end
  run("pkill -x waybar")
  os.execute("sleep 0.3")
  local ok = os.execute(([[( command -v waybar >/dev/null 2>&1 && ]] ..
    [[waybar -c %q -s %q >/dev/null 2>&1 & ) ]]):format(CONFIG, paths.root .. "/waybar/style.css"))
  if not ok then return false, "could not relaunch waybar" end
  return true
end

function M.save(values)
  local source   = M.serialize(values)
  local previous = read_file(CONFIG)

  if previous == source then
    return { changed = false, message = "No changes - the bar already matches." }
  end

  os.execute(("mkdir -p %q"):format(paths.backups))
  local stamp = os.date("%Y%m%d-%H%M%S")
  if previous then
    write_file(("%s/waybar-config.jsonc.%s"):format(paths.backups, stamp), previous)
  end

  local ok, err = write_file(CONFIG, source)
  if not ok then return nil, "could not write config.jsonc: " .. tostring(err) end

  -- Waybar has no config checker, so prove it is still parseable ourselves.
  local reparsed, parse_err = decode_jsonc(read_file(CONFIG))
  if not reparsed then
    if previous then write_file(CONFIG, previous) end
    return nil, "the generated config did not parse, so it was rolled back:\n" .. tostring(parse_err)
  end

  local restarted, reason = M.restart()
  return {
    changed   = true,
    restarted = restarted,
    message   = restarted and "Saved and restarted the bar."
                           or ("Saved. " .. tostring(reason)),
    backup    = ("hypr/.backup/waybar-config.jsonc.%s"):format(stamp),
  }
end

return M
