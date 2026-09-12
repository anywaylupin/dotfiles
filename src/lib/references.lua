-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  REFERENCES                                                              │
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- Everything this project was built against. Rendered on the overview page so
-- the sources are one click away instead of buried in comments.

return {
  {
    title = "Hyprland",
    links = {
      { label = "Wiki",              url = "https://wiki.hypr.land/",                              note = "the reference for everything below" },
      { label = "Configuring: start", url = "https://wiki.hypr.land/Configuring/Start/",            note = "the Lua config format" },
      { label = "Variables",          url = "https://wiki.hypr.land/Configuring/Basics/Variables/", note = "general, decoration, input" },
      { label = "Binds",              url = "https://wiki.hypr.land/Configuring/Basics/Binds/",     note = "combos, flags, dispatchers" },
      { label = "Window rules",       url = "https://wiki.hypr.land/Configuring/Basics/Window-Rules/" },
      { label = "Animations",         url = "https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/" },
      { label = "Source",             url = "https://github.com/hyprwm/Hyprland" },
    },
  },
  {
    title = "Arch Linux",
    links = {
      { label = "ArchWiki: Hyprland", url = "https://wiki.archlinux.org/title/Hyprland" },
      { label = "ArchWiki: Dotfiles", url = "https://wiki.archlinux.org/title/Dotfiles" },
      { label = "Package search",     url = "https://archlinux.org/packages/" },
    },
  },
  {
    title = "Web stack",
    links = {
      { label = "Lapis",     url = "https://leafo.net/lapis/",                       note = "the framework this app runs on" },
      { label = "etlua",     url = "https://github.com/leafo/etlua",                 note = "the templates in src/views" },
      { label = "LuaJIT",    url = "https://luajit.org/",                            note = "vendored into .tools" },
      { label = "LuaRocks",  url = "https://luarocks.org/",                          note = "vendored into .tools" },
      { label = "cqueues",   url = "https://github.com/wahern/cqueues",              note = "the server backend, in place of nginx" },
      { label = "lua-http",  url = "https://github.com/daurnimator/lua-http" },
    },
  },
  {
    title = "Tools the config calls",
    links = {
      { label = "wofi",          url = "https://hg.sr.ht/~scoopta/wofi",                 note = "launcher" },
      { label = "grim",          url = "https://sr.ht/~emersion/grim/",                   note = "screenshots" },
      { label = "slurp",         url = "https://github.com/emersion/slurp",              note = "region select" },
      { label = "WirePlumber",   url = "https://pipewire.pages.freedesktop.org/wireplumber/", note = "wpctl, volume" },
      { label = "dunst",         url = "https://dunst-project.org/",                     note = "notifications" },
    },
  },
  {
    title = "Theme",
    links = {
      { label = "Black Myth: Wukong", url = "https://gamesci.cn/wukong",
        note = "palette and artwork source - fetched at install, not redistributed" },
      { label = "Crimson Pro",        url = "https://fonts.google.com/specimen/Crimson+Pro",
        note = "the display serif, SIL OFL 1.1" },
    },
  },
}
