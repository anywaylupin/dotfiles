#!/usr/bin/env bash
# ╭────────────────────────────────────────────────────────────────────────────╮
# │  PLACEHOLDER ART                                                           │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# Generates neutral stand-ins for every image the theme references, so a public
# build carries none of Game Science's artwork. Original shapes only, in the
# same ink-and-gold palette, drawn with rsvg-convert and ffmpeg.
#
#   tools/placeholder-art.sh <output-dir>
#
# The real artwork stays local and is fetched by src/static/assets/fetch.sh.
set -euo pipefail

OUT="${1:?usage: placeholder-art.sh <output-dir>}"
mkdir -p "$OUT"

INK=0a0908
GOLD=b0813f
GOLD_LIGHT=dab176
CINNABAR=a83d32
PAPER=dfdad3

svg() {   # svg <width> <height> <file> ; body on stdin
  local w=$1 h=$2 file=$3
  { printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s">' "$w" "$h" "$w" "$h"
    cat
    printf '</svg>'
  } > /tmp/pa.svg
  rsvg-convert -w "$w" -h "$h" /tmp/pa.svg -o "$file"
  printf '  %-24s %7sb\n' "$(basename "$file")" "$(stat -c%s "$file")"
}

# 1. Body tile: dark grain. ffmpeg's noise filter, kept very subtle.
ffmpeg -v error -y -f lavfi -i "color=c=0x121110:s=256x256,noise=alls=12:allf=t+u" \
  -frames:v 1 "$OUT/bg-main.png"
printf '  %-24s %7sb\n' bg-main.png "$(stat -c%s "$OUT/bg-main.png")"

# 2. Hero plate: a soft gradient with a horizon, standing in for the key art.
svg 1920 538 "$OUT/header-bg.png" <<SVG
<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#2b2724"/><stop offset="0.55" stop-color="#1a1817"/>
    <stop offset="1" stop-color="#$INK"/>
  </linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.62" r="0.55">
    <stop offset="0" stop-color="#$GOLD" stop-opacity="0.34"/>
    <stop offset="1" stop-color="#$GOLD" stop-opacity="0"/>
  </radialGradient>
</defs>
<rect width="1920" height="538" fill="url(#sky)"/>
<rect width="1920" height="538" fill="url(#glow)"/>
<path d="M0 430 C 320 372, 520 452, 840 412 C 1180 370, 1420 448, 1920 396 L1920 538 L0 538 Z"
      fill="#0d0c0b" opacity="0.9"/>
<path d="M0 470 C 420 432, 700 492, 1060 462 C 1440 430, 1700 486, 1920 456 L1920 538 L0 538 Z"
      fill="#$INK"/>
SVG

# 3. Wordmark: an original mark, a broken ring with a seal. Light on transparent.
svg 838 550 "$OUT/logo-wordmark.png" <<SVG
<g fill="none" stroke="#$PAPER" stroke-linecap="round">
  <path d="M419 96 A 179 179 0 1 1 240 275" stroke-width="26" opacity="0.92"/>
  <path d="M262 300 A 179 179 0 0 0 400 452" stroke-width="14" opacity="0.55"/>
</g>
<rect x="556" y="150" width="58" height="58" rx="5" fill="#$CINNABAR" opacity="0.92"/>
<g fill="#$PAPER" opacity="0.9" font-family="serif" font-size="58" letter-spacing="14"
   text-anchor="middle">
  <text x="419" y="300">ARCH</text>
</g>
<g fill="#$PAPER" opacity="0.5" font-family="serif" font-size="26" letter-spacing="16"
   text-anchor="middle">
  <text x="419" y="352">CONFIG</text>
</g>
SVG

# 4. Panel top edge: a rough stroke, used as a CSS mask so only shape matters.
{
  printf '<svg xmlns="http://www.w3.org/2000/svg" width="1258" height="206" viewBox="0 0 1258 206">'
  printf '<path fill="#fff" d="M0 26'
  x=0
  while [ $x -lt 1258 ]; do
    y=$(( 8 + (x * 7919 % 23) ))
    printf ' L%d %d' "$x" "$y"
    x=$(( x + 17 ))
  done
  printf ' L1258 20 L1258 206 L0 206 Z"/></svg>'
} > /tmp/pa.svg
rsvg-convert -w 1258 -h 206 /tmp/pa.svg -o "$OUT/card-frame.png"
printf '  %-24s %7sb\n' card-frame.png "$(stat -c%s "$OUT/card-frame.png")"

# 5. Section tab: a lacquer plate.
svg 324 179 "$OUT/corner.png" <<SVG
<defs>
  <linearGradient id="lac" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#c04a3d"/><stop offset="1" stop-color="#8d2f26"/>
  </linearGradient>
</defs>
<rect x="14" y="14" width="296" height="151" rx="18" fill="url(#lac)"/>
<rect x="34" y="34" width="256" height="111" rx="10" fill="none" stroke="#f7eadb" stroke-opacity="0.16" stroke-width="3"/>
SVG

# 6. Button plates: grain, greyscale, tinted by the CSS above them.
for name in btn btn-hover; do
  seed=$([ "$name" = btn ] && echo 7 || echo 21)
  ffmpeg -v error -y -f lavfi -i "color=c=0x8a8a8a:s=296x65,noise=alls=${seed}:allf=t+u" \
    -frames:v 1 "$OUT/$name.png"
  printf '  %-24s %7sb\n' "$name.png" "$(stat -c%s "$OUT/$name.png")"
done

# 7. Panel title band: a small repeating motif.
svg 895 79 "$OUT/slider-bg.png" <<SVG
<rect width="895" height="79" fill="#1f1d1b"/>
<g stroke="#2b2724" stroke-width="3" fill="none">
$(for i in $(seq 0 24); do x=$(( i * 36 )); printf '<path d="M%d 58 q 9 -20 18 0 t 18 0"/>' "$x" "$x"; done)
</g>
SVG

# 8. Vignette over the wallpaper.
svg 1920 1080 "$OUT/video-overlay.png" <<SVG
<defs>
  <radialGradient id="vig" cx="0.5" cy="0.5" r="0.72">
    <stop offset="0.45" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity="0.78"/>
  </radialGradient>
</defs>
<rect width="1920" height="1080" fill="url(#vig)"/>
SVG

# 9. Wallpaper still: the homepage backdrop when no video is present.
svg 1920 1080 /tmp/pa-poster.png <<SVG
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#312c27"/><stop offset="0.5" stop-color="#1b1917"/>
    <stop offset="1" stop-color="#$INK"/>
  </linearGradient>
  <radialGradient id="sun" cx="0.5" cy="0.56" r="0.34">
    <stop offset="0" stop-color="#$GOLD_LIGHT" stop-opacity="0.5"/>
    <stop offset="1" stop-color="#$GOLD_LIGHT" stop-opacity="0"/>
  </radialGradient>
</defs>
<rect width="1920" height="1080" fill="url(#bg)"/>
<rect width="1920" height="1080" fill="url(#sun)"/>
<g fill="#0f0e0d">
  <path d="M0 760 C 300 660, 560 790, 900 720 C 1260 646, 1560 768, 1920 700 L1920 1080 L0 1080 Z" opacity="0.85"/>
  <path d="M0 860 C 380 800, 720 900, 1100 848 C 1480 796, 1700 880, 1920 840 L1920 1080 L0 1080 Z"/>
</g>
SVG
ffmpeg -v error -y -i /tmp/pa-poster.png -q:v 5 "$OUT/wallpaper-poster.jpg"
printf '  %-24s %7sb\n' wallpaper-poster.jpg "$(stat -c%s "$OUT/wallpaper-poster.jpg")"

# 10. Favicon: a 32px mark, wrapped as a real ICO around a PNG payload.
svg 64 64 /tmp/pa-icon.png <<SVG
<rect width="64" height="64" fill="#$INK"/>
<circle cx="32" cy="32" r="19" fill="none" stroke="#$GOLD" stroke-width="6"/>
<rect x="40" y="12" width="12" height="12" rx="2" fill="#$CINNABAR"/>
SVG
python3 - "$OUT/favicon.ico" <<'PY'
import struct, sys
png = open("/tmp/pa-icon.png", "rb").read()
# ICO directory entry pointing at an embedded PNG (valid since Vista).
header = struct.pack("<HHH", 0, 1, 1)
entry = struct.pack("<BBBBHHII", 64, 64, 0, 0, 1, 32, len(png), 6 + 16)
open(sys.argv[1], "wb").write(header + entry + png)
print("  %-24s %7sb" % ("favicon.ico", len(header) + len(entry) + len(png)))
PY

rm -f /tmp/pa.svg /tmp/pa-poster.png /tmp/pa-icon.png
