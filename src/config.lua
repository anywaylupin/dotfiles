-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  LAPIS CONFIG                                                            │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Local-first: the cqueues server backend, so there is no nginx or OpenResty in
-- the picture. `lapis server` reads `server = "cqueues"` from here.
--
-- Bound to 127.0.0.1 on purpose - this app writes your compositor config, so it
-- has no business listening on a LAN interface.

local config = require("lapis.config")

-- Per-install, generated on first run. See lib/secret.lua.
local secret = require("lib.secret")

-- tools/export-static.sh runs a second instance on another port so it does not
-- fight a dev server you already have open.
local port = tonumber(os.getenv("ARCHCONFIG_PORT")) or 8080

config("development", {
  server      = "cqueues",
  code_cache  = "off",        -- reload Lua on every request while developing
  host        = "127.0.0.1",
  port        = port,
  secret      = secret,
  measure_performance = false,
})

config("production", {
  server     = "cqueues",
  code_cache = "on",
  host       = "127.0.0.1",
  port       = port,
  secret     = secret,
})
