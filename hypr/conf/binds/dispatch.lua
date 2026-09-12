-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  BINDS - DISPATCHERS                                                     │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Maps the `id` of each entry in ../../keybinds.lua to what it does. The split
-- exists so the combos stay pure data the web UI can rewrite, while the
-- behaviour stays here in Lua where it belongs.
--
-- Parameterised families (workspace numbers, the four directions) resolve by
-- pattern rather than being listed 30 times.
--
-- https://wiki.hypr.land/Configuring/Basics/Binds/

local p = require("hypr.conf.programs")

local STEP = 30   -- pixels per resize/move step

local DIRECTIONS = {
  left  = { x = -STEP, y = 0 },
  right = { x = STEP,  y = 0 },
  up    = { x = 0,     y = -STEP },
  down  = { x = 0,     y = STEP },
}

-- Floating windows move by pixels, tiled ones move within the layout. This
-- replaces the `hyprctl activewindow -j | jq -r .floating` shell round-trip the
-- old hyprlang config used - same decision, made in-process.
local function move_window(direction)
  local delta = DIRECTIONS[direction]
  return function()
    local win = hl.get_active_window()
    if win and win.floating then
      hl.dispatch(hl.dsp.window.move({ x = delta.x, y = delta.y }))
    else
      hl.dispatch(hl.dsp.window.move({ direction = direction }))
    end
  end
end

local EXACT = {
  ["window.close"]       = function() return hl.dsp.window.close() end,
  ["window.close.alt"]   = function() return hl.dsp.window.close() end,
  ["window.cycle"]       = function() return hl.dsp.window.cycle_next() end,
  ["window.fullscreen"]  = function() return hl.dsp.window.fullscreen() end,
  ["window.float"]       = function() return hl.dsp.window.float({ action = "toggle" }) end,
  ["window.pin"]         = function() return hl.dsp.window.pin() end,
  ["window.drag.key"]    = function() return hl.dsp.window.drag() end,
  ["window.drag.lmb"]    = function() return hl.dsp.window.drag() end,
  ["window.resize.key"]  = function() return hl.dsp.window.resize() end,
  ["window.resize.rmb"]  = function() return hl.dsp.window.resize() end,
  ["layout.togglesplit"] = function() return hl.dsp.layout("togglesplit") end,

  ["group.toggle"] = function() return hl.dsp.group.toggle() end,
  ["group.prev"]   = function() return hl.dsp.group.prev() end,
  ["group.next"]   = function() return hl.dsp.group.next() end,

  ["session.exit"] = function() return hl.dsp.exit() end,

  ["workspace.focus.next"]  = function() return hl.dsp.focus({ workspace = "r+1" }) end,
  ["workspace.focus.prev"]  = function() return hl.dsp.focus({ workspace = "r-1" }) end,
  ["workspace.focus.empty"] = function() return hl.dsp.focus({ workspace = "empty" }) end,
  ["workspace.move.next"]   = function() return hl.dsp.window.move({ workspace = "r+1" }) end,
  ["workspace.move.prev"]   = function() return hl.dsp.window.move({ workspace = "r-1" }) end,
  ["workspace.scroll.next"] = function() return hl.dsp.focus({ workspace = "e+1" }) end,
  ["workspace.scroll.prev"] = function() return hl.dsp.focus({ workspace = "e-1" }) end,

  ["scratchpad.toggle"]      = function() return hl.dsp.workspace.toggle_special("magic") end,
  ["scratchpad.move"]        = function() return hl.dsp.window.move({ workspace = "special:magic" }) end,
  ["scratchpad.move_silent"] = function() return hl.dsp.window.move({ workspace = "special:magic", silent = true }) end,

  ["launch.terminal"]     = function() return hl.dsp.exec_cmd(p.terminal) end,
  ["launch.terminal.alt"] = function() return hl.dsp.exec_cmd(p.terminal) end,
  ["launch.editor"]       = function() return hl.dsp.exec_cmd(p.editor) end,
  ["launch.explorer"]     = function() return hl.dsp.exec_cmd(p.explorer) end,
  ["launch.browser"]      = function() return hl.dsp.exec_cmd(p.browser) end,
  ["launch.ai"]           = function() return hl.dsp.exec_cmd(p.ai) end,
  ["launch.launcher"]     = function() return hl.dsp.exec_cmd(p.launcher) end,
  ["launch.window_menu"]  = function() return hl.dsp.exec_cmd(p.window_menu) end,
  ["shot.region"]         = function() return hl.dsp.exec_cmd(p.shot_region) end,
  ["shot.screen"]         = function() return hl.dsp.exec_cmd(p.shot_screen) end,

  ["audio.mute"]      = function() return hl.dsp.exec_cmd(p.vol_mute) end,
  ["audio.mute.fkey"] = function() return hl.dsp.exec_cmd(p.vol_mute) end,
  ["audio.down"]      = function() return hl.dsp.exec_cmd(p.vol_down) end,
  ["audio.down.fkey"] = function() return hl.dsp.exec_cmd(p.vol_down) end,
  ["audio.up"]        = function() return hl.dsp.exec_cmd(p.vol_up) end,
  ["audio.up.fkey"]   = function() return hl.dsp.exec_cmd(p.vol_up) end,
  ["audio.mic_mute"]  = function() return hl.dsp.exec_cmd(p.mic_mute) end,
}

--- Resolve an id to a dispatcher, or nil if nothing matches.
return function(id)
  local exact = EXACT[id]
  if exact then return exact() end

  local direction = id:match("^focus%.(%a+)$")
  if direction and DIRECTIONS[direction] then
    return hl.dsp.focus({ direction = direction })
  end

  direction = id:match("^resize%.(%a+)$")
  if direction and DIRECTIONS[direction] then
    local d = DIRECTIONS[direction]
    return hl.dsp.window.resize({ x = d.x, y = d.y })
  end

  direction = id:match("^move%.(%a+)$")
  if direction and DIRECTIONS[direction] then
    return move_window(direction)
  end

  local workspace = id:match("^workspace%.focus%.(%d+)$")
  if workspace then return hl.dsp.focus({ workspace = tonumber(workspace) }) end

  workspace = id:match("^workspace%.move%.(%d+)$")
  if workspace then return hl.dsp.window.move({ workspace = tonumber(workspace) }) end

  workspace = id:match("^workspace%.move_silent%.(%d+)$")
  if workspace then
    return hl.dsp.window.move({ workspace = tonumber(workspace), silent = true })
  end

  return nil
end
