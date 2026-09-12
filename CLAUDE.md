# CLAUDE.md

The working instructions for this repo live in **[AGENTS.md](AGENTS.md)** - read
that first. It covers the layout, how to run the server, the conventions, and
the safety properties of the config write path.

Claude-specific notes:

- **`hypr/` is the live config of this machine.** Verify after every change with
  `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`; it must print
  `config ok`. Do not move or rename the directory - `~/.config/hypr/hyprland.lua`
  requires it by path.
- **`sudo` needs a password here**, which you cannot supply. The Lua toolchain is
  vendored into `.tools/` for exactly this reason. Do not propose `pacman -S`
  as a step; extend `.tools/build.sh` instead.
- **Use `./dev stop`, never `pkill -f`.** A `-f` pattern also matches the shell
  running your command, so `kill` takes out your own session. This happened
  twice while building this.
- Saving from the UI reloads the user's running compositor. When testing a
  round-trip, restore the original values afterwards.
- The editable surfaces are `src/lib/hypr/schema.lua` (settings) and
  `hypr/keybinds.lua` + `hypr/conf/binds/dispatch.lua` (binds). Prefer adding an
  entry there over hand-rolling a form.
- **No page animations.** They were removed on request; interaction feedback
  stays. See AGENTS.md#motion before adding any.
- Write `-`, not an em dash, in code, comments, docs and UI copy.
