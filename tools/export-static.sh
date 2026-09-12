#!/usr/bin/env bash
# ╭────────────────────────────────────────────────────────────────────────────╮
# │  EXPORT A STATIC SHOWCASE                                                  │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# Renders every page to plain HTML with a frozen snapshot of this machine, so
# the result needs no Lua, no Hyprland and no filesystem writes at runtime. Host
# it on Vercel, Netlify, GitHub Pages or any static host.
#
#   tools/export-static.sh
#
# The build looks exactly like the local app: the theme images are loaded from
# gamesci.cn by the stylesheet, and the wallpaper, its poster and the favicon
# are copied from src/static since they live in this repo.
#
# The only difference is that editing is off. The app renders with
# ARCHCONFIG_DEMO=1, which marks both forms `inert`, drops the save buttons and
# puts a banner on every page - there is no server behind the output to save to.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/.tools/local"
DIST="$ROOT/dist"
PORT=8099

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

echo "==> copying static files"
# Everything under src/static, which is the stylesheet, the script, the font,
# the favicon, the wallpaper and its poster. The theme images are not here:
# the stylesheet points at gamesci.cn for those.
cp -r "$ROOT/src/static/." "$DIST/static/"
find "$DIST/static" -type f | sed "s|$DIST/static/|  |" | sort

echo "==> starting a render server on :$PORT"
[[ -n "$(listener)" ]] && { echo "port $PORT busy" >&2; exit 1; }
(
  export DOTFILES_ROOT="$ROOT" ARCHCONFIG_DEMO=1 ARCHCONFIG_PORT="$PORT"
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
echo
echo "The theme images load from gamesci.cn at view time. If they ever vanish,"
echo "their content hashes changed - update the nine URLs at the top of"
echo "src/static/css/wukong.css."
