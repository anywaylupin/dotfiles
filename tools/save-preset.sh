#!/usr/bin/env bash
# ╭────────────────────────────────────────────────────────────────────────────╮
# │  SAVE A PRESET                                                             │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# Snapshots the current settings.lua and keybinds.lua into hypr/presets/<name>.lua.
#
#   tools/save-preset.sh default          overwrite the default preset
#   tools/save-preset.sh minimal "..."    create one with a description
#
# Overwriting `default` redefines what the reset button restores, so do it only
# when the current configuration is genuinely the state you want to return to.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/.tools/local"
NAME="${1:?usage: save-preset.sh <name> [description]}"
DESC="${2:-Saved on $(date +'%Y-%m-%d')}"

[[ "$NAME" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "name must be alphanumeric, - or _" >&2; exit 1; }
[[ -x "$TOOLS/bin/luajit" ]] || { echo "Toolchain missing. Run ./.tools/build.sh first." >&2; exit 1; }

TARGET="$ROOT/hypr/presets/$NAME.lua"
if [[ -f "$TARGET" ]]; then
  read -r -p "Overwrite $NAME? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "cancelled"; exit 0; }
fi

mkdir -p "$ROOT/hypr/presets"

export DOTFILES_ROOT="$ROOT"
export PATH="$TOOLS/bin:$PATH"
eval "$("$TOOLS/bin/luarocks" path)"
export LUA_PATH="$ROOT/?.lua;$ROOT/?/init.lua;$ROOT/src/?.lua;$ROOT/src/?/init.lua;$LUA_PATH"

cd "$ROOT"
PRESET_NAME="$NAME" PRESET_DESC="$DESC" "$TOOLS/bin/luajit" -e '
local store = require("lib.hypr.store")
local binds = require("lib.hypr.binds")

local name = os.getenv("PRESET_NAME")
local desc = os.getenv("PRESET_DESC")

local settings = assert(store.read())
local entries  = assert(binds.read())

-- Reuse the store serializers so a preset is byte-identical to a normal save,
-- then strip their file headers: a preset holds two tables, not a module.
local function body(source)
  return (source:gsub("^.-\nreturn ", ""):gsub("%s+$", ""))
end

local function indent(block)
  local out = {}
  for line in block:gmatch("[^\n]*\n?") do
    if line ~= "" then out[#out + 1] = (line:match("^%s*$") and line) or ("  " .. line) end
  end
  return (table.concat(out):gsub("^%s+", ""))
end

local header = ([[
-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │  PRESET: %s
-- ╰──────────────────────────────────────────────────────────────────────────╯
--
-- A complete snapshot of ../settings.lua and ../keybinds.lua. Applying it from
-- the web UI overwrites both, so this is the "put it back" state.
--
-- Regenerate after deliberate changes:  tools/save-preset.sh %s
--
-- Presets are plain data, like the files they restore: the app loads them with
-- an empty environment.

return {
  name = %q,
  description = %q,

  settings = ]]):format(name, name, name, desc)

local f = assert(io.open("hypr/presets/" .. name .. ".lua", "w"))
f:write(header, indent(body(store.serialize(settings))),
        ",\n\n  keybinds = ", indent(body(binds.serialize(entries))), ",\n}\n")
f:close()

print(("  wrote hypr/presets/%s.lua  (%d binds)"):format(name, #entries))
'
