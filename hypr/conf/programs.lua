-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  PROGRAMS                                                                │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Every command the binds and autostart reach for, in one place. Values are
-- shell strings handed to hl.exec_cmd / hl.dsp.exec_cmd, so pipes and `||`
-- work. Swap an application here and every bind follows.

return {
  -- Applications
  ai       = "claude-desktop",
  browser  = "firefox",
  editor   = "code",
  explorer = "dolphin",
  terminal = "kitty",

  -- Menus. `pkill -x` first so the same key closes an open menu.
  launcher    = "pkill -x wofi || wofi --show drun",
  window_menu = "pkill -x wofi || wofi --show window",

  -- Utilities. `pkill -x ... ||` makes each key a toggle.
  clipboard  = "cliphist list | rofi -dmenu | cliphist decode | wl-copy",
  colorpick  = "hyprpicker -an | wl-copy",
  lock       = "hyprlock",
  -- hyprsunset runs as a daemon, so killing it is how you turn the filter off.
  nightlight = "pkill -x hyprsunset || hyprsunset --temperature 4000",

  -- Screenshots to the clipboard. Needs wl-clipboard for wl-copy.
  shot_region = 'grim -g "$(slurp)" - | wl-copy',
  shot_screen = "grim - | wl-copy",

  -- Audio, via wireplumber. -l 1.0 caps volume at 100%.
  mic_mute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
  vol_down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
  vol_mute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
  vol_up   = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+",

  -- Media, via playerctl.
  media_next  = "playerctl next",
  media_play  = "playerctl play-pause",
  media_prev  = "playerctl previous",

  -- Backlight. -e4 is a perceptual curve, -n2 stops it reaching zero.
  bright_down = "brightnessctl -e4 -n2 set 5%-",
  bright_up   = "brightnessctl -e4 -n2 set 5%+",

  -- Session services, started by conf/autostart.lua.
  bar       = "waybar",
  idle      = "hypridle",
  notifier  = "dunst",
  wallpaper = "hyprpaper",
}
