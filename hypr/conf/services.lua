-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  SESSION SERVICES                                                        │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- The long-running processes the desktop needs. One list, used twice:
-- conf/autostart.lua starts them on login, and the `services.restart`
-- dispatcher (SUPER + SHIFT + R) kills and relaunches the lot.
--
-- FCITX5 IS DELIBERATELY ABSENT. Arch ships both
-- /etc/xdg/autostart/org.fcitx.Fcitx5.desktop and the systemd user unit
-- app-org.fcitx.Fcitx5@autostart.service, so the input method already starts
-- twice. A third copy from here loses the race for the D-Bus name and quits:
--     Failed to create addon: dbus Unable to request dbus name.
-- which is what left the session with no input method at all.
--
-- AUDIO IS DELIBERATELY ABSENT. PipeWire and WirePlumber are started by systemd
-- as user units - `pipewire.socket` and `pipewire-pulse.socket` are enabled and
-- socket-activated, and `wireplumber.service` is enabled. Launching them from
-- here would race with systemd and give you two session managers. Check them
-- with `systemctl --user status wireplumber`, not this file.

-- The stub in ~/.config/hypr/hyprland.lua puts the repo root on package.path as
-- its first entry, so tools that accept a config path can be pointed at files
-- kept in this repo rather than loose in ~/.config.
local ROOT = package.path:match("^([^;]+)/%?%.lua")

local M = {}

M.root = ROOT

-- One place to change the desktop background.
M.wallpaper = os.getenv("HOME") .. "/Pictures/The Four Heavenly Kings Black Myth Wukong Original.jpg"
local WALLPAPER = M.wallpaper

M.list = {
  { binary = "dunst",      cmd = "dunst",                      label = "notifications", delay = 1 },
  -- Keeps the workspace buttons' state cache warm and signals waybar on change,
  -- so the ten custom buttons never poll. See waybar/scripts/ws-watch.py.
  { binary = "ws-watch.py",
    cmd = ("python3 %s/waybar/scripts/ws-watch.py"):format(ROOT),
    label = "workspace watcher" },
  { binary = "waybar",
    cmd = ("waybar -c %s/waybar/config.jsonc -s %s/waybar/style.css"):format(ROOT, ROOT),
    label = "status bar", delay = 1 },
  -- swaybg rather than hyprpaper: hyprpaper 0.8.4 stopped honouring the
  -- preload/wallpaper keys this config used - it reports "Monitor eDP-1 has no
  -- target" and paints nothing, and those key names are not even strings in the
  -- 0.8.4 binary any more. swaybg is one flag and has no config file to drift.
  { binary = "swaybg",
    cmd = ('swaybg -m fill -i %q'):format(WALLPAPER),
    label = "wallpaper" },
  { binary = "hypridle",   cmd = "hypridle",                   label = "idle timeouts" },
  -- Night light on from login. Toggle it with SUPER + SHIFT + N, or give it a
  -- schedule in ~/.config/hypr/hyprsunset.conf and drop the flag here.
  { binary = "hyprsunset", cmd = "hyprsunset --temperature 4000", label = "night light" },
}

--- Run a service only if it is actually installed, so a missing package is
--- skipped rather than leaving a failed process behind.
--- `delay` exists because external Wayland clients can beat the compositor to
--- readiness. waybar and dunst both start at hyprland.start, find no layer-shell
--- yet, and exit - which is why the bar was missing after every login while
--- hyprpaper and hyprsunset, being Hyprland's own, came up fine.
function M.start_command(service)
  local command = service.cmd
  if not service.binary:match("%.py$") then
    command = ("command -v %s >/dev/null 2>&1 && %s"):format(service.binary, service.cmd)
  end
  if service.delay then
    command = ("sleep %s; %s"):format(service.delay, command)
  end
  return command
end

--- One shell command that stops every service, waits for the sockets to clear,
--- then brings them all back. Used by the restart bind.
function M.restart_command()
  local kills, starts = {}, {}

  for _, service in ipairs(M.list) do
    -- A python script's process name is "python3", so match its command line
    -- instead. The pattern is anchored on the script path, which cannot match
    -- the shell running this command.
    if service.binary:match("%.py$") then
      -- Kill by PID, never by pattern. `pkill -f ws-watch.py` matches ANY
      -- process whose command line mentions that path - an editor, a grep, or
      -- the shell running this very command - so the restart used to kill
      -- itself before reaching the sleep. The script writes its own pidfile.
      kills[#kills + 1] = ('[ -r "$XDG_RUNTIME_DIR/ws-watch.pid" ] && '
        .. 'kill "$(cat "$XDG_RUNTIME_DIR/ws-watch.pid")" 2>/dev/null')
    else
      kills[#kills + 1] = ("pkill -x %s"):format(service.binary)
    end
    starts[#starts + 1] = ("( %s ) &"):format(M.start_command(service))
  end

  return table.concat(kills, "; ")
    .. "; sleep 0.4; "
    .. table.concat(starts, " ")
    .. ' notify-send -a "arch config" -i view-refresh "Services restarted"'
    .. (' "%d services"'):format(#M.list)
end

return M
