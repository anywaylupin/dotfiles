-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  AUTOSTART AND ENVIRONMENT                                               │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- `hl.env` must run at config load, before anything spawns, or children will
-- not inherit the variable. Processes go inside the `hyprland.start` handler so
-- they launch once per session rather than on every config reload.
--
-- The service list itself lives in conf/services.lua, shared with the restart
-- bind on SUPER + SHIFT + R.
--
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

local services = require("hypr.conf.services")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Input method (fcitx5). Hyprland implements text-input-v3, so native Wayland
-- apps reach fcitx5 without any module variable - setting GTK_IM_MODULE or
-- QT_IM_MODULE here would push them down the legacy path instead, which is the
-- usual cause of "it works everywhere except one app".
--
-- XMODIFIERS is still needed: XWayland clients have no text-input-v3.
hl.env("XMODIFIERS", "@im=fcitx")

-- Qt applications (Dolphin) take their widget style from Kvantum, which paints
-- the Oxocarbon theme installed by install.sh. GTK apps read it from
-- ~/.config/gtk-*/settings.ini instead and need nothing here.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

hl.on("hyprland.start", function()
  for _, service in ipairs(services.list) do
    hl.exec_cmd(services.start_command(service))
  end
end)
