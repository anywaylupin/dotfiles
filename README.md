# arch config

Arch Linux + Hyprland configuration, with a local web UI to edit it.

- **`hypr/`** - the live Hyprland config. Loaded by `~/.config/hypr/hyprland.lua`.
- **`src/`** - a [Lapis](https://leafo.net/lapis/) app that reads and writes it,
  themed after *Black Myth: Wukong*.

Config for another tool goes in a sibling of `hypr/` (`waybar/` is the first);
the web app stays in `src/`.

## How to use this

### 1. Set it up on a new machine

Clone wherever you like - the install script resolves its own path.

```bash
git clone <your-remote> ~/repos/dotfiles
cd ~/repos/dotfiles
```

Install Hyprland and the tools the config calls:

```bash
sudo pacman -S --needed hyprland kitty dolphin firefox code \
  wofi rofi waybar hyprpaper hyprlock hypridle hyprsunset hyprpicker \
  grim slurp wl-clipboard cliphist wireplumber playerctl brightnessctl \
  dunst pavucontrol blueman ffmpeg \
  zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
```

To make zsh your login shell (it is the shell, not the terminal - kitty stays
the terminal emulator):

```bash
chsh -s /usr/bin/zsh
```

Then run the two setup steps. Neither needs root:

```bash
./.tools/build.sh   # builds LuaJIT, LuaRocks and Lapis into .tools/
hypr/install.sh     # points ~/.config/hypr at this repo
```

`hypr/install.sh` writes a small stub to `~/.config/hypr/hyprland.lua` that adds
this repo to Lua's `package.path` and calls `require("hypr")`. It backs up
anything it replaces into `hypr/.backup/`, verifies the result, and is safe to
re-run. Your `~/.config/hypr` directory is otherwise left alone, so
`hyprpaper.conf` and friends can still live there.

Log out and back into Hyprland, or run `hyprctl reload`.

### 2. Edit it in the browser

```bash
./dev
```

Open <http://127.0.0.1:1024>. The homepage links to four pages:

| Page | What it does |
|---|---|
| **System** | Compositor, CPU, GPU, memory, battery, disks. Read-only. |
| **Hyprland** | Gaps, borders, rounding, opacity, blur, shadow, animations, input. |
| **Keybinds** | All 84 binds. Click a combo and hold the keys you want. |
| **Resources** | The docs and tools this is built on. |

Press `/` on any page to jump to its search box. Stop the server with
`./dev stop`.

Every save writes the file, backs the old one up to `hypr/.backup/`, checks it
with `Hyprland --verify-config`, then reloads the session - and restores the
backup if the check fails. Duplicate keybinds are flagged as you type and need a
second press of Save, since Hyprland keeps whichever bind registered last.

### 3. Edit it by hand

Two files are rewritten wholesale by the UI, so do not put comments in them:

- `hypr/settings.lua` - gaps, rounding, opacity, input
- `hypr/keybinds.lua` - which key runs what

Everything else in `hypr/conf/` is yours. Values marked `(ui)` are read out of
`settings.lua`, so there is one copy of each number, not two.

After any hand edit:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua   # must print: config ok
hyprctl reload
```

### 4. Extend it

- **A setting in the UI**: one entry in `src/lib/hypr/schema.lua`. The form,
  validation and file writer are generated from it.
- **A keybind**: one entry in `hypr/keybinds.lua` and a dispatcher under the
  same `id` in `hypr/conf/binds/dispatch.lua`.
- **Another config** (waybar, kitty, nvim): a new directory beside `hypr/`.
- **Another page**: `src/routes/<name>.lua`, an `app:include` in `src/app.lua`,
  and an entry in `src/lib/menu.lua`. The top bar and homepage build themselves
  from that list.

### 5. Move or remove it

Moving the repo breaks the stub, which holds an absolute path. Re-run
`hypr/install.sh` from the new location. To back out entirely, restore the
newest `hypr/.backup/hyprland.lua.*` over `~/.config/hypr/hyprland.lua`.

## Deploying a showcase

This app cannot run on Vercel, and it is worth being clear why: there is no Lua
runtime there, and the pages read `/proc`, `/sys` and `hyprctl` and write your
config - none of which exists on a serverless host. A deployed copy would show
blank hardware and fail every save.

What does work is a **static snapshot**: every page rendered to plain HTML with a
frozen copy of this machine's data. It looks exactly like the local app and is
read-only.

The build has to happen here, not on Vercel, because this is where the data
lives. So `dist/` is committed and Vercel serves it with no build step.

```bash
tools/publish.sh        # rebuild dist/ and commit it
git push                # when you are ready
```

Then deploy from the Vercel dashboard, or let the git integration do it on push.

`tools/publish.sh --push` pushes too; `--dry-run` builds and shows the diff
without committing. It refuses to run while you have uncommitted work outside
`dist/`, so an export never sweeps up unrelated changes.

`vercel.json` at the repo root is what tells Vercel not to build:

| Field | Why |
|---|---|
| `outputDirectory: "dist"` | Serve the committed export |
| `buildCommand: ""` | Run nothing. There is nothing to build. |
| `installCommand: ""` | No dependencies to install |
| `cleanUrls: true` | `/system` rather than `/system/index.html` |

If Vercel ever ignores a field, the same settings exist in the dashboard under
Project Settings, Build and Deployment, and those override the file.

What the export does:

- renders `/`, `/system`, `/hypr`, `/hypr/binds`, `/resources` and a `404.html`
- runs the app with `ARCHCONFIG_DEMO=1`, which marks both forms `inert`, drops
  the save buttons and puts a "read-only demo" banner on every page
- copies everything in `src/static`, so the wallpaper, its poster, the favicon
  and the font are all served from your own domain
- **scrubs your username** out of the HTML, since the storage table lists mount
  paths under `/home/<you>` and `/run/media/<you>`

Search and browsing still work in the export; only editing is off.

The wallpaper ends up committed at two paths, `src/static/assets/` and
`dist/static/assets/`. That costs nothing: the bytes are identical, and git
stores one blob per content hash. Each rebuild adds roughly 150 KB of changed
HTML.

### Where the images come from

The theme's nine images are loaded from `gamesci.cn` by the stylesheet rather
than copied into this repo, which keeps the repo free of their artwork. The URLs
are declared once as custom properties at the top of
`src/static/css/wukong.css`.

Those filenames are **content-hashed by their build**. When Game Science
redeploys their site the hashes change and all nine 404 - the pages still work,
they just fall back to the flat palette. To repair it, open
<https://gamesci.cn/wukong>, read the new names out of `css/app.*.css`, and
update the nine URLs.

### Getting at the real thing remotely

If what you want is to edit your config from another machine, a static export is
the wrong tool - run it on the laptop and reach it over Tailscale or a
Cloudflare Tunnel. It binds `127.0.0.1` today, so that needs a bind-address
option and some authentication first. Ask and I will add it.

## Command reference

| | |
|---|---|
| `./.tools/build.sh` | Build the local Lua toolchain. Run once. |
| `hypr/install.sh` | Point `~/.config/hypr` at this repo. Idempotent. |
| `./dev` | Serve <http://127.0.0.1:1024> |
| `./dev production` | Same, with code caching on |
| `./dev stop` | Stop the server |
| `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` | Check the config. |
| `hyprctl reload` | Re-read the config in the running session |
| `hyprctl monitors` | List outputs and their modes |
| `hyprctl binds` | List the binds actually loaded |
| `tools/save-preset.sh <name>` | Snapshot settings + keybinds as a preset |
| `tools/export-static.sh` | Build the static showcase into `dist/` |
| `tools/publish.sh` | Rebuild `dist/` and commit it for Vercel |

## Where things live

```text
dev                      start/stop the server
tools/
  export-static.sh       render every page to dist/ as a static site
  publish.sh             rebuild dist/ and commit it
dist/                    the committed static build Vercel serves
vercel.json              tells Vercel to serve dist/ without building
src/
  app.lua                root app: routes, /static, 404
  config.lua             port, backend, secret
  routes/hypr.lua        the /hypr section
  lib/
    menu.lua             top bar and homepage entries
    system.lua           CPU, GPU, memory, battery, disks from /proc and /sys
    references.lua       the links on /resources
    hypr/schema.lua      which settings are editable, and their bounds
    hypr/store.lua       settings: read / validate / write / verify / reload
    hypr/binds.lua       keybinds: the same, plus conflict detection
    hypr/presets.lua     snapshot and restore both files together
    hypr/hyprctl.lua     live compositor state
  views/                 etlua templates; home.etlua is the bare layout
  static/                css, js, font, favicon, wallpaper
hypr/                    THE LIVE CONFIG
  settings.lua           machine-managed values
  keybinds.lua           machine-managed combos, as plain data
  presets/default.lua    a snapshot of both, for the reset button
  conf/binds/            dispatch.lua maps each id to what it does
  conf/rules/            window and layer rules, ordered by intent
```

## Notes

- The toolchain is vendored in `.tools/` (LuaJIT, LuaRocks, Lapis on cqueues).
  Nothing is installed system-wide and `sudo` is only needed for `pacman`.
- The server binds `127.0.0.1` only. It writes compositor config, so writes are
  CSRF-protected and the session secret is generated per install into `.secret`.
- The theme images are hotlinked from `gamesci.cn`, so none of their artwork is
  stored here. The repo does carry the 9 MB wallpaper, its poster frame and the
  favicon. Crimson Pro is SIL OFL 1.1 and safe to ship.

More detail, conventions and gotchas: [AGENTS.md](AGENTS.md).
