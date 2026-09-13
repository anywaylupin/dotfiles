-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  PRESET: default
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- A complete snapshot of ../settings.lua and ../keybinds.lua. Applying it from
-- the web UI overwrites both, so this is the "put it back" state.
--
-- Regenerate after deliberate changes:  tools/save-preset.sh default
--
-- Presets are plain data, like the files they restore: the app loads them with
-- an empty environment.

return {
  name = "default",
  description = "Oxocarbon. The configuration as it ships.",

  settings = {
    general = {
      border_size      = 2,
      gaps_in          = 2,
      gaps_out         = 6,
      layout           = "dwindle",
      resize_on_border = false,
    },

    decoration = {
      active_opacity   = 1,
      inactive_opacity = 1,
      rounding         = 10,
      rounding_power   = 2,
    },

    blur = {
      enabled = true,
      passes  = 1,
      size    = 3,
    },

    shadow = {
      enabled = true,
      range   = 4,
    },

    animations = {
      enabled = true,
    },

    misc = {
      font_family = "Cascadia Code",
    },

    input = {
      follow_mouse   = 1,
      kb_layout      = "us",
      natural_scroll = false,
      sensitivity    = 0,
    },
  },

  keybinds = {
    -- Window
    { id = "window.close", group = "Window", combo = "SUPER + Q", desc = "close focused window" },
    { id = "window.close.alt", group = "Window", combo = "ALT + F4", desc = "close focused window" },
    { id = "window.cycle", group = "Window", combo = "ALT + Tab", desc = "cycle focus" },
    { id = "window.fullscreen", group = "Window", combo = "SHIFT + F11", desc = "toggle fullscreen" },
    { id = "window.float", group = "Window", combo = "SUPER + Space", desc = "toggle floating" },
    { id = "window.pin", group = "Window", combo = "SUPER + SHIFT + F", desc = "toggle pin" },
    { id = "layout.togglesplit", group = "Window", combo = "SUPER + J", desc = "toggle split (dwindle)" },
    { id = "group.toggle", group = "Window", combo = "SUPER + G", desc = "toggle group" },
    { id = "group.prev", group = "Window", combo = "SUPER + CTRL + H", desc = "previous window in group" },
    { id = "group.next", group = "Window", combo = "SUPER + CTRL + L", desc = "next window in group" },
    { id = "session.exit", group = "Window", combo = "SUPER + Delete", desc = "exit hyprland session" },
    { id = "window.drag.key", group = "Window", combo = "SUPER + Z", desc = "hold to move window", mouse = true },
    { id = "window.resize.key", group = "Window", combo = "SUPER + X", desc = "hold to resize window", mouse = true },
    { id = "window.drag.lmb", group = "Window", combo = "SUPER + mouse:272", desc = "hold to move window", mouse = true },
    { id = "window.resize.rmb", group = "Window", combo = "SUPER + mouse:273", desc = "hold to resize window", mouse = true },

    -- Motion
    { id = "focus.left", group = "Motion", combo = "SUPER + Left", desc = "focus left" },
    { id = "focus.right", group = "Motion", combo = "SUPER + Right", desc = "focus right" },
    { id = "focus.up", group = "Motion", combo = "SUPER + Up", desc = "focus up" },
    { id = "focus.down", group = "Motion", combo = "SUPER + Down", desc = "focus down" },
    { id = "resize.left", group = "Motion", combo = "SUPER + SHIFT + Left", desc = "resize window left", repeating = true },
    { id = "resize.right", group = "Motion", combo = "SUPER + SHIFT + Right", desc = "resize window right", repeating = true },
    { id = "resize.up", group = "Motion", combo = "SUPER + SHIFT + Up", desc = "resize window up", repeating = true },
    { id = "resize.down", group = "Motion", combo = "SUPER + SHIFT + Down", desc = "resize window down", repeating = true },
    { id = "move.left", group = "Motion", combo = "SUPER + CTRL + SHIFT + Left", desc = "move window left", repeating = true },
    { id = "move.right", group = "Motion", combo = "SUPER + CTRL + SHIFT + Right", desc = "move window right", repeating = true },
    { id = "move.up", group = "Motion", combo = "SUPER + CTRL + SHIFT + Up", desc = "move window up", repeating = true },
    { id = "move.down", group = "Motion", combo = "SUPER + CTRL + SHIFT + Down", desc = "move window down", repeating = true },

    -- Workspaces
    { id = "workspace.focus.1", group = "Workspaces", combo = "SUPER + 1", desc = "switch to workspace 1" },
    { id = "workspace.focus.2", group = "Workspaces", combo = "SUPER + 2", desc = "switch to workspace 2" },
    { id = "workspace.focus.3", group = "Workspaces", combo = "SUPER + 3", desc = "switch to workspace 3" },
    { id = "workspace.focus.4", group = "Workspaces", combo = "SUPER + 4", desc = "switch to workspace 4" },
    { id = "workspace.focus.5", group = "Workspaces", combo = "SUPER + 5", desc = "switch to workspace 5" },
    { id = "workspace.focus.6", group = "Workspaces", combo = "SUPER + 6", desc = "switch to workspace 6" },
    { id = "workspace.focus.7", group = "Workspaces", combo = "SUPER + 7", desc = "switch to workspace 7" },
    { id = "workspace.focus.8", group = "Workspaces", combo = "SUPER + 8", desc = "switch to workspace 8" },
    { id = "workspace.focus.9", group = "Workspaces", combo = "SUPER + 9", desc = "switch to workspace 9" },
    { id = "workspace.focus.10", group = "Workspaces", combo = "SUPER + 0", desc = "switch to workspace 10" },
    { id = "workspace.move.1", group = "Workspaces", combo = "SUPER + SHIFT + 1", desc = "move window to workspace 1" },
    { id = "workspace.move.2", group = "Workspaces", combo = "SUPER + SHIFT + 2", desc = "move window to workspace 2" },
    { id = "workspace.move.3", group = "Workspaces", combo = "SUPER + SHIFT + 3", desc = "move window to workspace 3" },
    { id = "workspace.move.4", group = "Workspaces", combo = "SUPER + SHIFT + 4", desc = "move window to workspace 4" },
    { id = "workspace.move.5", group = "Workspaces", combo = "SUPER + SHIFT + 5", desc = "move window to workspace 5" },
    { id = "workspace.move.6", group = "Workspaces", combo = "SUPER + SHIFT + 6", desc = "move window to workspace 6" },
    { id = "workspace.move.7", group = "Workspaces", combo = "SUPER + SHIFT + 7", desc = "move window to workspace 7" },
    { id = "workspace.move.8", group = "Workspaces", combo = "SUPER + SHIFT + 8", desc = "move window to workspace 8" },
    { id = "workspace.move.9", group = "Workspaces", combo = "SUPER + SHIFT + 9", desc = "move window to workspace 9" },
    { id = "workspace.move.10", group = "Workspaces", combo = "SUPER + SHIFT + 0", desc = "move window to workspace 10" },
    { id = "workspace.move_silent.1", group = "Workspaces", combo = "SUPER + ALT + 1", desc = "move window to workspace 1 (silent)" },
    { id = "workspace.move_silent.2", group = "Workspaces", combo = "SUPER + ALT + 2", desc = "move window to workspace 2 (silent)" },
    { id = "workspace.move_silent.3", group = "Workspaces", combo = "SUPER + ALT + 3", desc = "move window to workspace 3 (silent)" },
    { id = "workspace.move_silent.4", group = "Workspaces", combo = "SUPER + ALT + 4", desc = "move window to workspace 4 (silent)" },
    { id = "workspace.move_silent.5", group = "Workspaces", combo = "SUPER + ALT + 5", desc = "move window to workspace 5 (silent)" },
    { id = "workspace.move_silent.6", group = "Workspaces", combo = "SUPER + ALT + 6", desc = "move window to workspace 6 (silent)" },
    { id = "workspace.move_silent.7", group = "Workspaces", combo = "SUPER + ALT + 7", desc = "move window to workspace 7 (silent)" },
    { id = "workspace.move_silent.8", group = "Workspaces", combo = "SUPER + ALT + 8", desc = "move window to workspace 8 (silent)" },
    { id = "workspace.move_silent.9", group = "Workspaces", combo = "SUPER + ALT + 9", desc = "move window to workspace 9 (silent)" },
    { id = "workspace.move_silent.10", group = "Workspaces", combo = "SUPER + ALT + 0", desc = "move window to workspace 10 (silent)" },
    { id = "workspace.focus.next", group = "Workspaces", combo = "SUPER + CTRL + Right", desc = "next workspace" },
    { id = "workspace.focus.prev", group = "Workspaces", combo = "SUPER + CTRL + Left", desc = "previous workspace" },
    { id = "workspace.focus.empty", group = "Workspaces", combo = "SUPER + CTRL + Down", desc = "switch to nearest empty workspace" },
    { id = "workspace.move.next", group = "Workspaces", combo = "SUPER + CTRL + ALT + Right", desc = "move window to next workspace" },
    { id = "workspace.move.prev", group = "Workspaces", combo = "SUPER + CTRL + ALT + Left", desc = "move window to previous workspace" },
    { id = "workspace.scroll.next", group = "Workspaces", combo = "SUPER + mouse_down", desc = "next workspace" },
    { id = "workspace.scroll.prev", group = "Workspaces", combo = "SUPER + mouse_up", desc = "previous workspace" },
    { id = "scratchpad.toggle", group = "Workspaces", combo = "SUPER + S", desc = "toggle scratchpad" },
    { id = "scratchpad.move", group = "Workspaces", combo = "SUPER + SHIFT + S", desc = "move to scratchpad" },
    { id = "scratchpad.move_silent", group = "Workspaces", combo = "SUPER + ALT + S", desc = "move to scratchpad (silent)" },

    -- Launchers
    { id = "launch.terminal", group = "Launchers", combo = "SUPER + T", desc = "terminal emulator" },
    { id = "launch.terminal.alt", group = "Launchers", combo = "SUPER + RETURN", desc = "terminal emulator" },
    { id = "launch.editor", group = "Launchers", combo = "SUPER + C", desc = "text editor" },
    { id = "launch.explorer", group = "Launchers", combo = "SUPER + E", desc = "file explorer" },
    { id = "launch.browser", group = "Launchers", combo = "SUPER + B", desc = "web browser" },
    { id = "launch.ai", group = "Launchers", combo = "SUPER + SHIFT + C", desc = "ai assistant" },
    { id = "launch.launcher", group = "Launchers", combo = "SUPER + R", desc = "application finder" },
    { id = "launch.window_menu", group = "Launchers", combo = "SUPER + TAB", desc = "window switcher" },
    { id = "shot.region", group = "Launchers", combo = "SUPER + P", desc = "screenshot a region" },
    { id = "shot.screen", group = "Launchers", combo = "Print", desc = "screenshot all monitors", locked = true },
    { id = "launch.clipboard", group = "Launchers", combo = "SUPER + V", desc = "clipboard history" },
    { id = "launch.colorpick", group = "Launchers", combo = "SUPER + SHIFT + P", desc = "pick a colour" },
    { id = "launch.lock", group = "Launchers", combo = "SUPER + L", desc = "lock the screen" },

    -- Hardware
    { id = "audio.mute", group = "Hardware", combo = "XF86AudioMute", desc = "toggle output mute", locked = true },
    { id = "audio.down", group = "Hardware", combo = "XF86AudioLowerVolume", desc = "decrease volume", locked = true, repeating = true },
    { id = "audio.up", group = "Hardware", combo = "XF86AudioRaiseVolume", desc = "increase volume", locked = true, repeating = true },
    { id = "audio.mic_mute", group = "Hardware", combo = "XF86AudioMicMute", desc = "toggle mic mute", locked = true },
    { id = "bright.down", group = "Hardware", combo = "XF86MonBrightnessDown", desc = "decrease brightness", locked = true, repeating = true },
    { id = "bright.up", group = "Hardware", combo = "XF86MonBrightnessUp", desc = "increase brightness", locked = true, repeating = true },

    -- Media
    { id = "media.play", group = "Media", combo = "XF86AudioPlay", desc = "play or pause", locked = true },
    { id = "media.pause", group = "Media", combo = "XF86AudioPause", desc = "play or pause", locked = true },
    { id = "media.next", group = "Media", combo = "XF86AudioNext", desc = "next track", locked = true },
    { id = "media.prev", group = "Media", combo = "XF86AudioPrev", desc = "previous track", locked = true },

    -- Display
    { id = "display.nightlight", group = "Display", combo = "SUPER + SHIFT + N", desc = "toggle night light" },

    -- Session
    { id = "services.restart", group = "Session", combo = "SUPER + SHIFT + R", desc = "restart startup services" },
  },
}
