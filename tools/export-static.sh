#!/usr/bin/env bash
# ╭────────────────────────────────────────────────────────────────────────────╮
# │  EXPORT A STATIC SHOWCASE                                                  │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# Renders every page to plain HTML with a frozen snapshot of this machine, so
# the result needs no Lua, no Hyprland and no filesystem writes at runtime. Host
# it on Vercel, Netlify, GitHub Pages or any static host.
#
#   tools/export-static.sh              neutral placeholder art (publishable)
#   tools/export-static.sh --real-art   this machine's fetched artwork
#
# --real-art copies Game Science's images into the build. That is fine for a
# private host and is copyright infringement on a public one. Default is the
# placeholder set drawn by tools/placeholder-art.sh.
#
# Editing is disabled in the output: the app renders with ARCHCONFIG_DEMO=1,
# which marks both forms `inert` and puts a banner on every page.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/.tools/local"
DIST="$ROOT/dist"
PORT=8099
REAL_ART=0
NO_VIDEO=0
[[ "${1:-}" == "--real-art" ]] && REAL_ART=1

ROUTES=(
  "/:index.html"
  "/system:system/index.html"
  "/hypr:hypr/index.html"
  "/hypr/binds:hypr/binds/index.html"
  "/resources:resources/index.html"
  "/__missing__:404.html"
)

[[ -x "$TOOLS/bin/lapis" ]] || { echo "Toolchain missing. Run ./.tools/build.sh first." >&2; exit 1; }

listener() { ss -lptnH "sport = :$PORT" 2>/dev/null | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2; }

cleanup() {
  local pid; pid="$(listener)"
  [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> clearing $DIST"
rm -rf "$DIST"
mkdir -p "$DIST/static"

echo "==> copying stylesheet, script and font"
cp -r "$ROOT/src/static/css" "$ROOT/src/static/js" "$ROOT/src/static/fonts" "$DIST/static/"

echo "==> artwork"
if [[ "$REAL_ART" == 1 ]]; then
  mkdir -p "$DIST/static/assets/wukong"
  cp -r "$ROOT/src/static/assets/wukong/." "$DIST/static/assets/wukong/" 2>/dev/null || true
  cp "$ROOT/src/static/favicon.ico" "$DIST/static/favicon.ico" 2>/dev/null || true
  [[ -f "$ROOT/src/static/assets/live-wallpaper-4k.webm" ]] \
    && cp "$ROOT/src/static/assets/live-wallpaper-4k.webm" "$DIST/static/assets/"
  echo "  !! real artwork copied - do NOT host this publicly"
else
  "$ROOT/tools/placeholder-art.sh" "$DIST/static/assets/wukong"
  mv "$DIST/static/assets/wukong/favicon.ico" "$DIST/static/favicon.ico"
  # No video in this build, so do not render a <video> pointing at a 404.
  NO_VIDEO=1
fi

echo "==> starting a render server on :$PORT"
[[ -n "$(listener)" ]] && { echo "port $PORT busy" >&2; exit 1; }
(
  export DOTFILES_ROOT="$ROOT" ARCHCONFIG_DEMO=1 ARCHCONFIG_PORT="$PORT"
  export ARCHCONFIG_NO_VIDEO="${NO_VIDEO:-0}"
  export PATH="$TOOLS/bin:$PATH"
  eval "$("$TOOLS/bin/luarocks" path)"
  export LUA_PATH="$ROOT/?.lua;$ROOT/?/init.lua;$ROOT/src/?.lua;$ROOT/src/?/init.lua;$LUA_PATH"
  cd "$ROOT/src"
  exec "$TOOLS/bin/lapis" server production
) >/dev/null 2>&1 &

for _ in $(seq 1 40); do
  curl -sf -o /dev/null "http://127.0.0.1:$PORT/" && break
  sleep 0.25
done
curl -sf -o /dev/null "http://127.0.0.1:$PORT/" || { echo "server did not come up" >&2; exit 1; }

echo "==> rendering"
for entry in "${ROUTES[@]}"; do
  route="${entry%%:*}"; file="${entry##*:}"
  mkdir -p "$DIST/$(dirname "$file")"
  code=$(curl -sS -o "$DIST/$file" -w '%{http_code}' "http://127.0.0.1:$PORT$route")
  printf '  %-22s %-24s HTTP %s  %sb\n' "$route" "$file" "$code" "$(stat -c%s "$DIST/$file")"
done

echo "==> scrubbing local identifiers"
# The rendered pages carry this machine's mount paths, which include the
# username. Replace it before anything is published.
USER_NAME="$(id -un)"
find "$DIST" -name '*.html' -print0 | while IFS= read -r -d '' f; do
  sed -i "s|/home/$USER_NAME|/home/user|g; s|/run/media/$USER_NAME|/run/media/user|g; s|\b$USER_NAME\b|user|g" "$f"
done
grep -rl "$USER_NAME" "$DIST" 2>/dev/null && echo "  !! still present, check manually" || echo "  clean"

echo "==> vercel.json"
cat > "$DIST/vercel.json" <<'JSON'
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "cleanUrls": true,
  "trailingSlash": false,
  "headers": [
    {
      "source": "/static/(.*)",
      "headers": [{ "key": "cache-control", "value": "public, max-age=31536000, immutable" }]
    }
  ]
}
JSON

echo
echo "Built $DIST ($(du -sh "$DIST" | cut -f1))"
echo
echo "Preview:  cd dist && python3 -m http.server 8000"
echo "Deploy:   cd dist && npx vercel deploy --prod"
