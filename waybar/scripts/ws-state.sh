#!/bin/sh
# One workspace button's state, read from the cache ws-watch.py maintains.
# Deliberately shell and not python: ten of these run on every workspace change,
# so process startup is the whole cost.
#
#   ws-state.sh <id> <glyph>
set -eu

ID="${1:?usage: ws-state.sh <id> <glyph>}"
GLYPH="${2:-$ID}"
CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-workspaces"

active=""
occupied=""
if [ -r "$CACHE" ]; then
  read -r line < "$CACHE" || line=""
  active=${line#*active=}; active=${active%% *}
  occupied=${line#*occupied=}
fi

if [ "$active" = "$ID" ]; then
  class=active
elif printf '%s' ",$occupied," | grep -q ",$ID,"; then
  class=occupied
else
  # Empty and not focused: print nothing. Waybar hides a custom module whose
  # output is empty, so the bar only ever shows workspaces in use plus the one
  # you are on.
  printf '{"text":"","class":"empty"}\n'
  exit 0
fi

printf '{"text":"%s","class":"%s","tooltip":"workspace %s"}\n' "$GLYPH" "$class" "$ID"
