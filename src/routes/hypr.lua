-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  ROUTE - /hypr                                                           │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- A standalone Lapis sub-app. Route names are prefixed with `hypr_` by the
-- include in app.lua.
--
-- Two editable surfaces, each with its own store:
--   /hypr        settings  -> lib/hypr/store.lua -> hypr/settings.lua
--   /hypr/binds  keybinds  -> lib/hypr/binds.lua -> hypr/keybinds.lua
--
-- Both writes are CSRF-protected: a plain form POST is not blocked by the
-- same-origin policy, so without a token any page the user visits could rewrite
-- their compositor config.

local lapis      = require("lapis")
local respond_to = require("lapis.application").respond_to
local csrf       = require("lapis.csrf")
local schema     = require("lib.hypr.schema")
local store      = require("lib.hypr.store")
local binds      = require("lib.hypr.binds")
local hyprctl    = require("lib.hypr.hyprctl")

local app = lapis.Application()
app:enable("etlua")

-- ── settings ────────────────────────────────────────────────────────────────

local function load_settings(self)
  local settings, err = store.read()
  if not settings then
    self.load_error = err
    settings = {}
  end
  self.page_title = "Hyprland"
  self.csrf_token = csrf.generate_token(self)
  self.settings   = settings
  self.schema     = schema
  self.summary    = hyprctl.summary()
  return settings
end

app:match("settings", "", function(self)
  load_settings(self)
  return { render = "hypr.index" }
end)

-- Tolerate the trailing slash rather than 404ing on it.
app:match("settings_slash", "/", function() return { redirect_to = "/hypr" } end)

app:match("save", "/save", respond_to({
  GET = function() return { redirect_to = "/hypr" } end,

  POST = function(self)
    local token_ok, token_err = csrf.validate_token(self)
    if not token_ok then
      load_settings(self)
      self.error_message = "Rejected: " .. tostring(token_err or "bad CSRF token") ..
        ".\nReload the page and try again."
      return { render = "hypr.index", status = 403 }
    end

    local settings, errors = store.validate(self.params)
    if not settings then
      load_settings(self)
      self.field_errors  = errors
      self.settings      = self.params    -- keep what was typed
      self.raw_values    = true
      self.error_message = "Nothing was written - fix the fields below."
      return { render = "hypr.index", status = 400 }
    end

    local result, err = store.save(settings)
    if not result then
      load_settings(self)
      self.error_message = err
      return { render = "hypr.index", status = 500 }
    end

    load_settings(self)
    self.notice = result.message
    self.backup = result.backup
    return { render = "hypr.index" }
  end,
}))

-- ── keybinds ────────────────────────────────────────────────────────────────

local function load_binds(self, entries, conflicts)
  if not entries then
    local err
    entries, err = binds.read()
    if not entries then
      self.load_error = err
      entries = {}
    end
  end

  self.page_title = "Keybinds"
  self.csrf_token = csrf.generate_token(self)
  self.entries    = entries
  self.groups     = binds.grouped(entries)
  self.conflicts  = conflicts or binds.conflicts(entries)
  self.live       = hyprctl.running()

  local count = 0
  for _ in pairs(self.conflicts) do count = count + 1 end
  self.conflict_count = count
  return entries
end

app:match("binds", "/binds", function(self)
  load_binds(self)
  return { render = "hypr.binds" }
end)

app:match("binds_save", "/binds/save", respond_to({
  GET = function() return { redirect_to = "/hypr/binds" } end,

  POST = function(self)
    local token_ok, token_err = csrf.validate_token(self)
    if not token_ok then
      load_binds(self)
      self.error_message = "Rejected: " .. tostring(token_err or "bad CSRF token") ..
        ".\nReload the page and try again."
      return { render = "hypr.binds", status = 403 }
    end

    local entries, result = binds.apply(self.params)
    if not entries then
      load_binds(self)
      self.field_errors  = result
      self.error_message = "Nothing was written - fix the combos below."
      return { render = "hypr.binds", status = 400 }
    end

    -- Duplicate combos are legal in Hyprland (the last registered wins), so a
    -- conflict is a warning the user has to acknowledge, not a hard error.
    local conflicts = result
    local acknowledged = self.params.accept_conflicts == "1"
    local has_conflicts = next(conflicts) ~= nil

    if has_conflicts and not acknowledged then
      load_binds(self, entries, conflicts)
      self.pending_conflicts = true
      self.error_message = "Not saved: some combos are used more than once. " ..
        "Change them, or press Save again to keep the duplicates."
      return { render = "hypr.binds", status = 409 }
    end

    local saved, err = binds.save(entries)
    if not saved then
      load_binds(self, entries, conflicts)
      self.error_message = err
      return { render = "hypr.binds", status = 500 }
    end

    load_binds(self)
    self.notice = saved.message
    self.backup = saved.backup
    return { render = "hypr.binds" }
  end,
}))

return app
