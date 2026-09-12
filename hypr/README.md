# hypr

Hyprland config as a Lua project. Targets Hyprland **0.56.2** (Lua config, not hyprlang).

```text
init.lua                 module entry point - requires everything below
settings.lua             MACHINE-MANAGED - values, written by the web UI
keybinds.lua             MACHINE-MANAGED - combos, written by the web UI
conf/
  programs.lua           every command the binds and autostart run
  monitors.lua
  looknfeel.lua          general, decoration, dwindle, misc, ecosystem
  animations.lua         easing curves + the animation leaf tree
  input.lua              keyboard, touchpad, gestures
  autostart.lua          env vars + hyprland.start
  binds/
    dispatch.lua         maps each keybind id to what it does
    init.lua             joins ../../keybinds.lua to those dispatchers
  rules/
    behaviour.lua        idle inhibit, picture-in-picture, workarounds
    opacity.lua
    float.lua
    layer.lua            bars, launchers, notifications
install.sh               writes the ~/.config/hypr/hyprland.lua stub (idempotent)
.luarc.json              lua_ls config: loads /usr/share/hypr/stubs for hl.* completion
```

Values marked `(ui)` in `conf/looknfeel.lua`, `conf/input.lua` and
`conf/animations.lua` are referenced out of `settings.lua`, which the web UI at
the repo root owns. They are referenced rather than copied, so there is no second
copy to drift, and a nil there reads as "not configured" - Hyprland keeps its own
default. Keybind combos live in `keybinds.lua` the same way. Run `./dev` at the repo root
and open <http://127.0.0.1:8080/hypr> to edit either in a browser; it verifies
and reloads for you.

Two ordering conventions, because they differ:

- **Binds are grouped, not sorted.** Combos are data in `keybinds.lua`, joined to
  behaviour in `conf/binds/dispatch.lua` by `id`. Order has no effect.
- **Rules are ordered by intent.** Order *does* matter: later rules layer on top of
  earlier ones. Within a group, patterns are sorted.

## How it's wired

`~/.config/hypr` stays a real directory. The only file in it is a stub that puts this
repo's root on `package.path` and requires this module:

```lua
local repo = "/path/to/dotfiles"
package.path = table.concat({
  repo .. "/?.lua",
  repo .. "/?/init.lua",
  package.path,
}, ";")
require("hypr")
```

`require("hypr")` resolves to `<repo>/hypr/init.lua`. Module paths inside the repo are
fully qualified (`hypr.conf.*`) on purpose: `~/.config/hypr` is *also* on `package.path`,
so a bare `require("conf.x")` could be shadowed, and a repo file named `hyprland.lua`
could make `require` recurse into the stub. Nothing here carries that name.

## Install

```bash
./install.sh
```

Writes the stub, keeps whatever it displaces in `.backup/`, and runs `--verify-config`.
Re-running is a no-op. It derives the repo path from its own location, so it works from
any checkout path on a new machine.

## Validate without restarting

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

`require` in `init.lua` is Hyprland's wrapped version, so a broken module is reported as
a config error naming the repo file and line rather than killing the session.

## Editor

`.luarc.json` is read by `lua_ls` (lua-language-server) directly, so it covers both the
VS Code **sumneko.lua** extension and a Neovim `lua_ls` setup with no extra config. It
puts `/usr/share/hypr/stubs` on `workspace.library` - where the `hl.meta.lua` API stub
ships - and declares `hl` / `__require` as globals.

## Migrated from hyprlang

| hyprlang | Lua |
| --- | --- |
| `source = file.conf` | `require("hypr.conf.file")` |
| `bind` / `bindd` | `hl.bind(combo, dispatcher, { desc = ... })` |
| `binde` / `bindl` / `bindm` | `opts.repeating` / `opts.locked` / `opts.mouse` |
| `$mainMod, SHIFT, Left` | one string: `"SUPER + SHIFT + Left"` |
| `windowrule = float, class:^(x)$` | `hl.window_rule({ name, match = { class }, float = true })` |
| `$&` (HyDE override shorthand) | `override` inside the opacity string |
| `layerrule = ignorezero` | `ignore_alpha = 0` |
| `gestures { workspace_swipe }` | `hl.gesture({ ... })` |
| `exec-once` | `hl.on("hyprland.start", ...)` |

The `hyprctl activewindow -j | jq -r .floating` round-trip that decided how to move a
window is now an in-process callback in `conf/binds/motion.lua`.

`general` / `decoration` / `animations` were inherited from HyDE's base config, not from
the old files. They're restated as Hyprland's upstream defaults so the values are yours.

## Not carried over

The old config was **HyDE**'s, and HyDE isn't installed - no `hyde-shell`, no
`~/.local/share/hyde/`, no `$scrPath` scripts. Substituted where something installed does
the job: `wofi` for `rofi`, `grim`/`slurp` for the screenshot scripts, `wpctl` for
`volumecontrol.sh`, `dunst` for `swaync`.

Dropped, needing a package that isn't installed: lock screen (`hyprlock`), colour picker
(`hyprpicker`), media keys (`playerctl`), brightness (`brightnessctl`), bar toggle
(`waybar`), clipboard history (`cliphist`).

Dropped, HyDE-only with no drop-in replacement: wallpaper / theme / animation / hyprlock
layout selectors, keybind hint overlay, game mode and game launcher, pypr dropdown
terminal, logout menu, emoji and glyph pickers, keyboard-layout switcher, freeze-and-snip,
per-monitor screenshot, `dontkillsteam.sh`.

`shot_region` / `shot_screen` pipe to `wl-copy` - install `wl-clipboard`.

## Companion tools

`hyprpaper`, `hyprlock` and `hypridle` read `~/.config/hypr/<tool>.conf` and take no `-c`
flag. Since `~/.config/hypr` is a real directory here, their configs are **not** versioned
by this repo - they'd need their own per-file symlinks. They also still use hyprlang.
