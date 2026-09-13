#!/bin/sh
# Which input method fcitx5 is on, for the bar.
#
# fcitx5-remote prints 1 when the IM is inactive (plain US keyboard) and 2 when
# it is active (Unikey, i.e. Vietnamese). Ctrl+Shift toggles between them.
set -eu

state=$(fcitx5-remote 2>/dev/null || echo 0)

case "$state" in
  2) text=VI; class=vietnamese; tip="Vietnamese - Telex" ;;
  1) text=EN; class=english;    tip="English - US keyboard" ;;
  *) text=--; class=off;        tip="fcitx5 is not running" ;;
esac

printf '{"text":"%s","class":"%s","tooltip":"%s\\nCtrl+Shift to switch"}\n' "$text" "$class" "$tip"
