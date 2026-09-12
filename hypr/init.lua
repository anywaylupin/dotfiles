-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  HYPRLAND CONFIG - ENTRY POINT                                           │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Loaded as the Lua module `hypr`. `~/.config/hypr/hyprland.lua` is a stub that
-- puts this repo's root on package.path and calls require("hypr").
--
-- Module paths are fully qualified (`hypr.conf.*`) because `~/.config/hypr` is
-- also on package.path - a bare `require("conf.x")` could be shadowed.
--
-- `require` below is Hyprland's wrapped version: a module that raises is
-- reported as a config error instead of taking the session down. `__require` is
-- stock Lua, if you ever need to bypass that.
--
--   Docs      https://wiki.hypr.land/Configuring/Start/
--   API stub  /usr/share/hypr/stubs/hl.meta.lua
--   Validate  Hyprland --verify-config -c ~/.config/hypr/hyprland.lua

-- Appearance and behaviour
require("hypr.conf.monitors")
require("hypr.conf.looknfeel")
require("hypr.conf.animations")
require("hypr.conf.input")

-- Rules. ORDER MATTERS: later rules layer on top of earlier ones.
require("hypr.conf.rules.behaviour")
require("hypr.conf.rules.opacity")
require("hypr.conf.rules.float")
require("hypr.conf.rules.layer")

-- Keybinds. Combos are data in keybinds.lua; this joins them to dispatchers.
require("hypr.conf.binds")

require("hypr.conf.autostart")
