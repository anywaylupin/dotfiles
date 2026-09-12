#!/usr/bin/env bash
# ╭────────────────────────────────────────────────────────────────────────────╮
# │  INSTALL - point Hyprland at this repo                                     │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# ~/.config/hypr stays a real directory; it is NOT symlinked. The only thing
# this touches outside the repo is ~/.config/hypr/hyprland.lua, replaced with a
# stub that puts the repo root on package.path and calls require("hypr").
#
# Anything it displaces is copied to ./.backup/ (gitignored). Safe to re-run.
set -euo pipefail

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # <repo>/hypr
REPO_ROOT="$(dirname "$HYPR_DIR")"                          # <repo>
MODULE="$(basename "$HYPR_DIR")"                            # hypr
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua"

log() { printf '  %s\n' "$*"; }

STUB="$(
  cat <<LUA
-- Managed by ${HYPR_DIR}/install.sh - edits here will be overwritten.
--
-- The real config lives in the dotfiles repo. This stub only puts the repo root
-- on package.path so require() can find it; ${MODULE}/init.lua does the rest.

local repo = "${REPO_ROOT}"

package.path = table.concat({
  repo .. "/?.lua",
  repo .. "/?/init.lua",
  package.path,
}, ";")

require("${MODULE}")
LUA
)"

if [[ ! -d "$(dirname "$TARGET")" ]]; then
  log "ERROR: $(dirname "$TARGET") does not exist - create it, or start Hyprland once"
  exit 1
fi

# Both sides go through command substitution so trailing newlines don't skew it.
if [[ -f "$TARGET" && "$(cat "$TARGET")" == "$STUB" ]]; then
  log "stub already in place: $TARGET -> require(\"$MODULE\")"
elif [[ -e "$TARGET" ]]; then
  backup="$HYPR_DIR/.backup/hyprland.lua.$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$HYPR_DIR/.backup"
  cp "$TARGET" "$backup"
  printf '%s\n' "$STUB" >"$TARGET"
  log "replaced $TARGET (previous version at $backup)"
else
  printf '%s\n' "$STUB" >"$TARGET"
  log "wrote stub: $TARGET"
fi

[[ -d /usr/share/hypr/stubs ]] ||
  log "WARNING: /usr/share/hypr/stubs missing - LSP completion for hl.* will be empty"

log "verifying config..."
if Hyprland --verify-config -c "$TARGET" 2>&1 | grep -q '^config ok'; then
  log "config ok"
else
  log "config has errors:"
  Hyprland --verify-config -c "$TARGET" 2>&1 |
    sed -n '/Config parsing result/,$p' | sed 's/^/    /'
  exit 1
fi
