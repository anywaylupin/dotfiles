-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  ROOT APPLICATION                                                        │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Each section of the site is a standalone Lapis sub-app under routes/, mounted
-- here with `app:include`. To add one:
--
--   1. write routes/<name>.lua returning a lapis.Application
--   2. app:include(require("routes.<name>"), { path = "/<name>", name = "<name>_" })
--   3. add an entry to lib/menu.lua
--
-- Nothing else needs to know about it - the layout renders the menu from that
-- registry.

local lapis      = require("lapis")
local paths      = require("lib.paths")
local menu       = require("lib.menu")
local hyprctl    = require("lib.hypr.hyprctl")
local system     = require("lib.system")
local references = require("lib.references")

-- Cache buster for /static links. With code_cache off (development) this module
-- is re-read per request, so it changes constantly and edits always show up;
-- with caching on it is fixed for the life of the process.
local ASSET_V = tostring(os.time())

-- Read-only showcase mode, set by tools/export-static.sh. Editing is disabled
-- and every page says so, because the exported HTML has no server behind it.
local DEMO = os.getenv("ARCHCONFIG_DEMO") == "1"

local app = lapis.Application()

app:enable("etlua")
app.layout = "layout"

-- Every page gets the menu and the current path, for highlighting.
app:before_filter(function(self)
  self.menu = menu.items
  self.repo_url = menu.repo
  self.current_path = self.req.parsed_url.path
  self.asset_v = ASSET_V
  self.demo = DEMO
end)

-- The homepage is the only page without the top bar: it is the shell the other
-- routes hang off, so it gets its own bare layout.
app:match("home", "/", function(self)
  -- The static export can ship without the video (placeholder art build), in
  -- which case the poster still carries the page.
  self.wallpaper = os.getenv("ARCHCONFIG_NO_VIDEO") ~= "1"
    and paths.exists(paths.static .. "/assets/live-wallpaper-4k.webm")
  self.system    = system.info()
  self.summary   = hyprctl.summary()
  return { render = "home", layout = "home" }
end)

app:match("system", "/system", function(self)
  self.page_title = "System"
  self.summary    = hyprctl.summary()
  self.system     = system.info()
  return { render = "system" }
end)

app:match("resources", "/resources", function(self)
  self.page_title = "Resources"
  self.references = references
  return { render = "resources" }
end)

-- ── Sections ────────────────────────────────────────────────────────────────

app:include(require("routes.hypr"), { path = "/hypr", name = "hypr_" })
app:include(require("routes.waybar"), { path = "/waybar", name = "waybar_" })

-- ── Static files ────────────────────────────────────────────────────────────
--
-- nginx would do this itself; the cqueues backend does not, so serve them here.
-- The splat is rejected unless it is a plain relative path, which keeps `..`
-- from escaping static/.

-- Local app: a long max-age just means edits do not show up until the browser
-- feels like it. Revalidate every time instead.
local CACHE = "no-cache"

local MIME = {
  css = "text/css", js = "application/javascript", json = "application/json",
  png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg", webp = "image/webp",
  svg = "image/svg+xml", woff2 = "font/woff2", woff = "font/woff",
  ico = "image/vnd.microsoft.icon",
  mp4 = "video/mp4", webm = "video/webm",
}

app:match("static", "/static/*", function(self)
  local rel = self.params.splat
  if rel:match("%.%.") or rel:match("^/") then return { status = 403, layout = false, "forbidden" } end

  local file = io.open(paths.static .. "/" .. rel, "rb")
  if not file then return { status = 404, layout = false, "not found" } end
  local body = file:read("*a")
  file:close()

  local ext = rel:match("%.([%w]+)$") or ""
  return {
    status  = 200,
    layout  = false,
    content_type = MIME[ext:lower()] or "application/octet-stream",
    headers = { ["cache-control"] = CACHE },
    body,
  }
end)

app:match("favicon", "/favicon.ico", function(self)
  return { redirect_to = "/static/favicon.ico", status = 301 }
end)

-- Unmatched paths get the themed shell rather than Lapis's dev traceback.
app.handle_404 = function(self)
  self.menu = menu.items
  self.repo_url = menu.repo
  self.current_path = self.req.parsed_url.path
  self.asset_v = ASSET_V
  self.demo = DEMO
  self.page_title = "Not found"
  return { status = 404, render = "not_found" }
end

return app
