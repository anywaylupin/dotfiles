-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  HYPRCTL - live compositor state                                         │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Everything here is read-only introspection of the RUNNING session, which is
-- why the UI reads binds and monitors from hyprctl rather than parsing the Lua
-- config: hyprctl reports what is actually loaded, including the `desc` strings.

local cjson = require("cjson")

local M = {}

local function sh(cmd)
  local pipe = io.popen(cmd .. " 2>/dev/null")
  if not pipe then return nil end
  local out = pipe:read("*a")
  pipe:close()
  return out
end

--- True when a compositor is up and answering.
function M.running()
  local out = sh("pgrep -x Hyprland")
  return out ~= nil and out:match("%d") ~= nil
end

--- Decode `hyprctl -j <what>`. Returns nil when Hyprland isn't running.
local function query(what)
  if not M.running() then return nil end
  local raw = sh("hyprctl -j " .. what)
  if not raw or raw == "" then return nil end
  local ok, value = pcall(cjson.decode, raw)
  if not ok then return nil end
  return value
end

M.query = query

function M.monitors() return query("monitors") or {} end
function M.workspaces() return query("workspaces") or {} end
function M.clients() return query("clients") or {} end

--- Live keybinds, grouped by modifier set and sorted, for the reference table.
function M.binds()
  local raw = query("binds") or {}
  local out = {}

  for _, b in ipairs(raw) do
    -- Hyprland reports modmask as a bitfield; name the bits we care about.
    local mods = {}
    local mask = tonumber(b.modmask) or 0
    if mask % 2 >= 1            then mods[#mods + 1] = "SHIFT" end
    if math.floor(mask / 4) % 2 == 1  then mods[#mods + 1] = "CTRL" end
    if math.floor(mask / 8) % 2 == 1  then mods[#mods + 1] = "ALT" end
    if math.floor(mask / 64) % 2 == 1 then mods[#mods + 1] = "SUPER" end

    local key = b.key
    if (key == nil or key == "") and b.keycode and b.keycode ~= 0 then
      key = "code:" .. tostring(b.keycode)
    end

    local combo = #mods > 0 and (table.concat(mods, " + ") .. " + " .. tostring(key)) or tostring(key)

    -- Binds registered from Lua report as the internal dispatcher `__lua` plus
    -- a callback index, which tells a reader nothing. Name it for what it is
    -- and drop the index.
    local dispatcher, arg = b.dispatcher, (b.arg ~= "" and b.arg) or nil
    if dispatcher == "__lua" then
      dispatcher, arg = "lua", nil
    end

    out[#out + 1] = {
      combo       = combo,
      description = (b.description ~= "" and b.description) or nil,
      dispatcher  = dispatcher,
      arg         = arg,
      locked      = b.locked,
      repeating   = b["repeat"],
      mouse       = b.mouse,
    }
  end

  table.sort(out, function(a, b) return a.combo < b.combo end)
  return out
end

--- Version string of the running compositor, or nil.
function M.version()
  local v = query("version")
  if not v then return nil end
  return v.tag or v.version
end

--- A compact summary for the dashboard.
function M.summary()
  if not M.running() then
    return { running = false }
  end
  local monitors = M.monitors()
  return {
    running    = true,
    version    = M.version(),
    monitors   = #monitors,
    workspaces = #M.workspaces(),
    clients    = #M.clients(),
    monitor_list = monitors,
  }
end

return M
