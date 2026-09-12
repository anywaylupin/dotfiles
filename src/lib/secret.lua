-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  SESSION SECRET                                                          │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Generated per install into .secret (gitignored, mode 600) rather than being
-- committed. A shared hardcoded secret in a public repo would let anyone forge
-- the session cookie that the CSRF token is bound to.

local paths = require("lib.paths")
local FILE  = paths.root .. "/.secret"

local function generate()
  local urandom = assert(io.open("/dev/urandom", "rb"), "cannot read /dev/urandom")
  local bytes = urandom:read(32)
  urandom:close()
  return (bytes:gsub(".", function(c) return ("%02x"):format(c:byte()) end))
end

local function load()
  local f = io.open(FILE, "r")
  if f then
    local existing = f:read("*l")
    f:close()
    if existing and #existing >= 32 then return existing end
  end

  local fresh = generate()
  local out = assert(io.open(FILE, "w"), "cannot write " .. FILE)
  out:write(fresh, "\n")
  out:close()
  os.execute(("chmod 600 %q"):format(FILE))
  return fresh
end

return load()
