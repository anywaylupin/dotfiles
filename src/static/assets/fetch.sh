#!/usr/bin/env bash
# ╭────────────────────────────────────────────────────────────────────────────╮
# │  FETCH ARTWORK                                                             │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# The theme's artwork is Game Science's, cached locally rather than committed:
# it is fine to keep a personal copy, not fine to redistribute. This pulls it
# from the official site at install time. Safe to re-run; skips what it has.
#
# The site is a Vue SPA with content-hashed filenames, so the hashes below are
# pinned. If one 404s, open https://gamesci.cn/wukong, read the hashed name out
# of css/app.*.css, and update it here.
#
# The app degrades to a flat palette without these - it just looks plainer.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WUKONG="$DIR/wukong"
FONTS="$DIR/../fonts"
BASE="https://gamesci.cn"
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36'

mkdir -p "$WUKONG" "$FONTS"

# remote path : local file
ART=(
  "wukong/img/img_bg.4428a08d.png:$WUKONG/bg-main.png"
  "wukong/img/header_bg.addf97d2.png:$WUKONG/header-bg.png"
  "wukong/img/logo_en.3e47ed17.png:$WUKONG/logo-wordmark.png"
  "wukong/img/new-item-bc.39d8bfee.png:$WUKONG/card-frame.png"
  "wukong/img/corner_off.ff84ef53.png:$WUKONG/corner.png"
  "wukong/img/btn2_normal.9226547a.png:$WUKONG/btn.png"
  "wukong/img/btn1_hover_active.865cb454.png:$WUKONG/btn-hover.png"
  "wukong/img/slider-bg.bde8d4aa.png:$WUKONG/slider-bg.png"
  "wukong/img/video-overlay-bg.81dc354b.png:$WUKONG/video-overlay.png"
  "wukong/favicon.ico:$DIR/../favicon.ico"
  "wukong/fonts/CrimsonPro-Regular.9278c3fe.woff2:$FONTS/CrimsonPro-Regular.woff2"
  "wukong/fonts/CrimsonPro-Regular.cbe55311.woff:$FONTS/CrimsonPro-Regular.woff"
)

ok=0; skip=0; fail=0
for entry in "${ART[@]}"; do
  remote="${entry%%:*}"; local_file="${entry#*:}"
  name="$(basename "$local_file")"

  if [[ -s "$local_file" ]]; then
    printf '  have  %s\n' "$name"; skip=$((skip + 1)); continue
  fi

  if curl -sSfL --max-time 60 -A "$UA" -e "$BASE/wukong" "$BASE/$remote" -o "$local_file" 2>/dev/null \
     && [[ -s "$local_file" ]]; then
    printf '  got   %-24s %8sb\n' "$name" "$(stat -c%s "$local_file")"; ok=$((ok + 1))
  else
    rm -f "$local_file"
    printf '  FAIL  %-24s %s\n' "$name" "$remote"; fail=$((fail + 1))
  fi
done

# Poster frame for the live wallpaper, if one is present and ffmpeg is around.
WALL="$DIR/live-wallpaper-4k.webm"
POSTER="$WUKONG/wallpaper-poster.jpg"
if [[ -s "$WALL" && ! -s "$POSTER" ]] && command -v ffmpeg >/dev/null; then
  ffmpeg -v error -y -ss 2 -i "$WALL" -frames:v 1 -vf scale=1920:-1 -q:v 6 "$POSTER" \
    && printf '  made  %-24s %8sb\n' "$(basename "$POSTER")" "$(stat -c%s "$POSTER")"
fi

echo
echo "  $ok fetched, $skip already present, $fail failed"
[[ ! -s "$WALL" ]] && cat <<'NOTE'

  No live wallpaper found. The overview page falls back to the still key art.
  To use one, drop a video at src/static/assets/live-wallpaper-4k.webm and
  re-run this script to generate its poster frame.
NOTE
exit 0
