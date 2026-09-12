-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  SYSTEM AND HARDWARE                                                     │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Everything here is read straight out of /proc, /sys and /etc - no root, no
-- daemons, no extra packages. Every field is optional: a machine without a
-- battery or a readable thermal zone gets nil, and the view omits the row
-- rather than showing a zero.

local M = {}

-- ── readers ─────────────────────────────────────────────────────────────────

local function slurp(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  if not content then return nil end
  content = content:gsub("%s+$", "")
  return content ~= "" and content or nil
end

local function first_line(path)
  local content = slurp(path)
  return content and content:match("^[^\n]*") or nil
end

local function sh(cmd)
  local pipe = io.popen(cmd .. " 2>/dev/null")
  if not pipe then return nil end
  local out = pipe:read("*a")
  pipe:close()
  if not out then return nil end
  out = out:gsub("%s+$", "")
  return out ~= "" and out or nil
end

local function glob(pattern)
  local out = sh("ls -d " .. pattern)
  if not out then return {} end
  local paths = {}
  for line in out:gmatch("[^\n]+") do paths[#paths + 1] = line end
  return paths
end

-- ── formatting ──────────────────────────────────────────────────────────────

local function human_bytes(kb)
  if not kb then return nil end
  local mb = kb / 1024
  if mb < 1024 then return ("%.0f MB"):format(mb) end
  return ("%.1f GB"):format(mb / 1024)
end

local function human_duration(seconds)
  if not seconds then return nil end
  seconds = math.floor(seconds)
  local d = math.floor(seconds / 86400)
  local h = math.floor((seconds % 86400) / 3600)
  local m = math.floor((seconds % 3600) / 60)
  if d > 0 then return ("%dd %dh"):format(d, h) end
  if h > 0 then return ("%dh %dm"):format(h, m) end
  return ("%dm"):format(m)
end

-- ── probes ──────────────────────────────────────────────────────────────────

local function meminfo()
  local values = {}
  local f = io.open("/proc/meminfo", "r")
  if not f then return values end
  for line in f:lines() do
    local key, kb = line:match("^(%w+):%s+(%d+) kB")
    if key then values[key] = tonumber(kb) end
  end
  f:close()
  return values
end

local function cpu()
  local model, threads = nil, 0
  local f = io.open("/proc/cpuinfo", "r")
  if f then
    for line in f:lines() do
      if not model then model = line:match("^model name%s*:%s*(.+)$") end
      if line:match("^processor%s*:") then threads = threads + 1 end
    end
    f:close()
  end
  -- Trim the marketing tail; the GPU is reported separately.
  if model then model = model:gsub("%s+with Radeon Graphics$", ""):gsub("%s+$", "") end
  return model, (threads > 0 and threads or nil)
end

local function gpu()
  local pci = sh("lspci 2>/dev/null | grep -iE 'vga|3d controller|display controller' | head -1")
  if pci then
    -- "03:00.0 VGA compatible controller: AMD/ATI Lucienne (rev c2)" -> the name
    local name = pci:match(":%s*[^:]+:%s*(.+)$") or pci
    return (name:gsub("%s*%(rev %w+%)%s*$", ""))
  end
  -- No pciutils: fall back to the DRM driver name.
  for _, card in ipairs(glob("/sys/class/drm/card[0-9]")) do
    local driver = sh(("readlink -f %s/device/driver 2>/dev/null"):format(card))
    if driver then return (driver:match("([^/]+)$")) end
  end
  return nil
end

local function battery()
  for _, path in ipairs(glob("/sys/class/power_supply/BAT*")) do
    local capacity = first_line(path .. "/capacity")
    if capacity then
      return {
        name     = path:match("([^/]+)$"),
        percent  = tonumber(capacity),
        status   = first_line(path .. "/status"),
        health   = (function()
          local full = tonumber(first_line(path .. "/energy_full") or first_line(path .. "/charge_full"))
          local design = tonumber(first_line(path .. "/energy_full_design") or first_line(path .. "/charge_full_design"))
          if full and design and design > 0 then
            return math.floor((full / design) * 100 + 0.5)
          end
        end)(),
      }
    end
  end
  return nil
end

local function temperature()
  local hottest
  for _, zone in ipairs(glob("/sys/class/thermal/thermal_zone*")) do
    local milli = tonumber(first_line(zone .. "/temp") or "")
    if milli and milli > 0 and milli < 200000 then
      local celsius = math.floor(milli / 1000)
      if not hottest or celsius > hottest.celsius then
        hottest = { celsius = celsius, zone = first_line(zone .. "/type") }
      end
    end
  end
  return hottest
end

local function disks()
  local out = sh("df -h -x tmpfs -x devtmpfs -x efivarfs --output=target,size,used,pcent 2>/dev/null | tail -n +2")
  if not out then return {} end
  local rows = {}
  for line in out:gmatch("[^\n]+") do
    local mount, size, used, percent = line:match("^%s*(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s*$")
    if mount and mount:match("^/") then
      rows[#rows + 1] = { mount = mount, size = size, used = used, percent = percent }
    end
  end
  return rows
end

local function os_release()
  local f = io.open("/etc/os-release", "r")
  if not f then return nil end
  local name
  for line in f:lines() do
    name = name or line:match('^PRETTY_NAME="?([^"]+)"?')
  end
  f:close()
  return name
end

-- ── public ──────────────────────────────────────────────────────────────────

--- A snapshot of the machine. Cheap enough to call per request.
function M.info()
  local mem = meminfo()
  local model, threads = cpu()
  local uptime_seconds = tonumber((first_line("/proc/uptime") or ""):match("^([%d%.]+)"))
  local load1, load5, load15 = (first_line("/proc/loadavg") or ""):match("^(%S+) (%S+) (%S+)")

  local used_kb = mem.MemTotal and mem.MemAvailable and (mem.MemTotal - mem.MemAvailable)

  return {
    -- Machine
    vendor  = first_line("/sys/class/dmi/id/sys_vendor"),
    product = first_line("/sys/class/dmi/id/product_name"),
    board   = first_line("/sys/class/dmi/id/board_name"),

    -- OS
    distro = os_release(),
    kernel = first_line("/proc/sys/kernel/osrelease"),
    uptime = human_duration(uptime_seconds),
    load   = load1 and ("%s  %s  %s"):format(load1, load5, load15) or nil,

    -- Compute
    cpu     = model,
    threads = threads,
    gpu     = gpu(),
    temp    = temperature(),

    -- Memory
    mem_total = human_bytes(mem.MemTotal),
    mem_used  = human_bytes(used_kb),
    mem_percent = (used_kb and mem.MemTotal and mem.MemTotal > 0)
      and math.floor((used_kb / mem.MemTotal) * 100 + 0.5) or nil,
    swap_total = (mem.SwapTotal and mem.SwapTotal > 0) and human_bytes(mem.SwapTotal) or nil,

    -- Storage and power
    disks   = disks(),
    battery = battery(),
  }
end

return M
