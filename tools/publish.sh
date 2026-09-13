#!/usr/bin/env bash
# ╭────────────────────────────────────────────────────────────────────────────╮
# │  PUBLISH                                                                   │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# Rebuilds the static export and commits it, so Vercel has something to serve.
#
#   tools/publish.sh            rebuild and commit dist/
#   tools/publish.sh --push     also push to origin
#   tools/publish.sh --dry-run  rebuild and show what would be committed
#
# The build has to happen here rather than on Vercel: rendering reads this
# machine's /proc, /sys and hyprctl, none of which exist in a build container.
# Vercel serves the committed output with no build step - see vercel.json.
#
# Deploying is separate. Pushing triggers Vercel's git integration if it is
# enabled; otherwise use Redeploy in the dashboard.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PUSH=0
DRY=0
for arg in "$@"; do
  case "$arg" in
    --push)    PUSH=1 ;;
    --dry-run) DRY=1 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

# A dirty tree would get swept into the export commit, so stop early.
if [[ -n "$(git status --porcelain -- . ':(exclude)dist')" ]]; then
  echo "Working tree has changes outside dist/. Commit or stash them first:" >&2
  git status --short -- . ':(exclude)dist' | sed 's/^/  /' >&2
  exit 1
fi

echo "==> building"
tools/export-static.sh

echo
echo "==> staging dist/"
git add -A dist

if git diff --cached --quiet -- dist; then
  echo "  no change - the export is identical to what is committed"
  exit 0
fi

git diff --cached --stat -- dist | tail -5 | sed 's/^/  /'

if [[ "$DRY" == 1 ]]; then
  echo
  echo "Dry run, nothing committed. Unstage with: git restore --staged dist"
  exit 0
fi

STAMP="$(date +'%Y-%m-%d %H:%M')"
git commit -q -m "chore: rebuild static export ($STAMP)"
echo "  committed $(git rev-parse --short HEAD)"

if [[ "$PUSH" == 1 ]]; then
  echo "==> pushing"
  git push
else
  echo
  echo "Not pushed. When you are ready:  git push"
fi

echo
echo "Then deploy from the Vercel dashboard, or let the git integration do it."
