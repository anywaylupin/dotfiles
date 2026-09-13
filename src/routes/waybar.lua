-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  ROUTE - /waybar                                                         │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Edits waybar/config.jsonc: bar geometry and which modules are placed. Module
-- options stay hand-written in waybar/modules.jsonc.
--
-- Same shape as the /hypr routes: CSRF on every write, validate the whole
-- submission or reject it, roll back if what was written does not parse.

local lapis      = require("lapis")
local respond_to = require("lapis.application").respond_to
local csrf       = require("lapis.csrf")
local schema     = require("lib.waybar.schema")
local store      = require("lib.waybar.store")

local app = lapis.Application()
app:enable("etlua")

local function load_page(self, values)
  local config, err = values, nil
  if not config then
    config, err = store.read()
    if not config then
      self.load_error = err
      config = {}
    end
  end

  self.page_title  = "Waybar"
  self.csrf_token  = csrf.generate_token(self)
  self.config      = config
  self.schema      = schema
  self.enabled     = store.enabled(config)
  self.defined     = store.defined()
  self.running     = os.execute("pgrep -x waybar >/dev/null") and true or false
  return config
end

app:match("bar", "", function(self)
  load_page(self)
  return { render = "waybar.index" }
end)

app:match("bar_slash", "/", function() return { redirect_to = "/waybar" } end)

app:match("save", "/save", respond_to({
  GET = function() return { redirect_to = "/waybar" } end,

  POST = function(self)
    local token_ok, token_err = csrf.validate_token(self)
    if not token_ok then
      load_page(self)
      self.error_message = "Rejected: " .. tostring(token_err or "bad CSRF token") ..
        ".\nReload the page and try again."
      return { render = "waybar.index", status = 403 }
    end

    local values, errors = store.validate(self.params)
    if not values then
      load_page(self)
      self.field_errors  = errors
      self.error_message = "Nothing was written - fix the fields below."
      return { render = "waybar.index", status = 400 }
    end

    local result, err = store.save(values)
    if not result then
      load_page(self)
      self.error_message = err
      return { render = "waybar.index", status = 500 }
    end

    load_page(self)
    self.notice = result.message
    self.backup = result.backup
    return { render = "waybar.index" }
  end,
}))

return app
