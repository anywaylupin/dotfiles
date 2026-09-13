# AGENTS.md

Instructions for coding agents working in this repository. Humans: this doubles as
the orientation doc.

## What this is

A personal Arch Linux config repo with a local-first web UI for managing it.

- `hypr/` - a **live** Hyprland configuration, written as a Lua project.
- `src/` - a [Lapis](https://leafo.net/lapis/) web app that reads and writes it,
  themed after *Black Myth: Wukong*.

Config for other tools goes in a sibling directory of `hypr/`, never inside
`src/`. That split is the point: `src/` is the app, the rest is configuration.

Nothing here talks to the network. The server binds `127.0.0.1` deliberately: it
edits the running compositor's config, so it has no business on a LAN interface.

## The one rule that matters

**`hypr/` is the live config of the machine you are running on. Do not move it,
rename it, or change how it is loaded.**

`~/.config/hypr/hyprland.lua` is a small stub that puts this repo's root on
`package.path` and calls `require("hypr")`. Move the directory and the user's
desktop falls back to the stock config on next login.

After **any** change under `hypr/`, run:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

It must print `config ok`. This is not optional - it is the only thing standing
between an edit and a broken session. `./install.sh` in `hypr/` runs it too.

## Layout

```text
dev                    start/stop the server
src/
  app.lua              Lapis root app: mounts sub-apps, serves /static, 404
  config.lua           Lapis config - cqueues backend, 127.0.0.1:1024
  routes/hypr.lua      the /hypr section (a standalone Lapis sub-app)
                       /, /system and /resources live in app.lua
  lib/
    menu.lua           nav registry - drives the top bar AND the homepage tiles
    paths.lua          absolute path resolution, cwd-independent
    secret.lua         per-install session secret
    system.lua         hardware and OS facts from /proc, /sys, /etc
    references.lua     the links rendered on the overview
    hypr/schema.lua    which settings the UI exposes, and their bounds
    hypr/store.lua     settings: read / validate / write / verify / reload
    hypr/binds.lua     keybinds: the same, plus combo parsing and conflicts
    hypr/hyprctl.lua   read-only live state from the running compositor
  views/               etlua templates
    layout.etlua       top bar + full-width stage; every page but the homepage
    home.etlua         the homepage, a complete bare document with no top bar
  static/              css, js, font, favicon, wallpaper
hypr/                  THE LIVE CONFIG - see the rule above
  settings.lua         machine-managed values
  keybinds.lua         machine-managed combos, plain data
  presets/             snapshots of both files, applied as one action
  conf/binds/          dispatch.lua (id -> behaviour) + init.lua (the join)
  conf/services.lua    startup processes, shared by autostart and the restart bind
waybar/                config.jsonc + style.css, launched with -c/-s from services.lua
  conf/rules/          window and layer rules
.tools/                vendored Lua toolchain (gitignored, built by build.sh)
```

## Running it

```bash
./.tools/build.sh   # once: LuaJIT, LuaRocks, Lapis into .tools/ - no root
./dev               # serve http://127.0.0.1:1024
./dev stop          # stop it
```

`dev` runs lapis with cwd `src/` and puts both the repo root and `src/` on
`LUA_PATH`, so `require("hypr.*")` reaches the config and `require("lib.*")`
reaches the app.

The toolchain is vendored on purpose. `luarocks`, `luajit` and OpenResty are not
installed system-wide, `sudo` needs a password an agent cannot supply, and
`openresty` is AUR-only. Everything builds into `.tools/local` as the user.

Two notes if you touch the build:

- LuaRocks' `configure` requires `unzip`, which is not installed. `.tools/local/bin/unzip`
  is a shim over `bsdtar`. Keep it on `PATH` before running luarocks.
- The cqueues server backend needs the `http` rock as well as `cqueues`.

## Layouts

There are two, and they are not nested:

- `views/layout.etlua` - the top bar plus a full-width stage. Every page except
  the homepage.
- `views/home.etlua` - the homepage. A **complete document of its own**, with no
  top bar, selected with `layout = "home"` in the route. It is the shell the
  other routes hang off, not one of the destinations, which is why `menu.lua`
  does not list `/`.

Page content goes inside a `<div class="grid">`: two columns, filling the page.
A panel holding a wide table opts out with `panel--wide`. There is no sidebar
and no max-width on the stage - use the whole page.

## Conventions

**Comments.** Every file opens with a boxed banner naming its job, then `-- ── Section ──`
dividers. Comments explain *why*, not *what* - the code says what.

**No commented-out config.** If it is disabled, delete it and note it in prose.
Dead settings pretending to be documentation are how config rots.

**Fenced code blocks always name a language** - `bash`, `lua`, `text`. A bare
fence is a bug.

**Write `-`, never an em or en dash**, in code, comments, docs and UI copy.

**Keybinds carry a `desc`** and are grouped by `group`, in file order. Order has
no behavioural effect - it is only what the UI shows.

**Duplicate combos are legal.** Hyprland keeps whichever bind registered last,
so the UI treats a clash as a warning needing a second Save, not an error.
Do not turn it into a hard failure.

**Window rules are ordered by intent, not alphabetically.** Order *does* matter -
later rules layer over earlier ones. Only the patterns inside a group are sorted.

**`hypr/settings.lua` is machine-managed.** The web UI rewrites the whole file.
Comments added to it will be lost. It is the only place those values live;
`conf/looknfeel.lua` and `conf/input.lua` reference them, marked `(ui)`, so
there is nothing to keep in sync.

## Adding a section to the site

For a single page, a route in `src/app.lua` is enough. For a section with
several pages, make it a sub-app:

1. `src/routes/<name>.lua` returning a `lapis.Application`.
2. `app:include(require("routes.<name>"), { path = "/<name>", name = "<name>_" })`.
3. An entry in `src/lib/menu.lua`.

Both the top bar and the homepage tiles render from that registry, so there is
no fourth step.

Mounting gotcha: a sub-app's index route is `""`, not `"/"`. `"/"` under a
`/foo` prefix becomes `/foo/` and leaves `/foo` unmatched.

## Adding an editable setting

Add a field to `src/lib/hypr/schema.lua` and reference it from the relevant
`hypr/conf/*.lua`. The form, the validation, the serializer and the write path
are all generated from the schema - nothing else needs editing.

## Adding a keybind

Two halves, joined by `id`:

1. an entry in `hypr/keybinds.lua` - `{ id, group, combo, desc }` plus optional
   `locked` / `repeating` / `mouse`
2. a dispatcher in `hypr/conf/binds/dispatch.lua` under the same `id`

`keybinds.lua` is **plain data with no `hl` calls**, which is what lets the web
app load it with an empty environment and rewrite it. Keep it that way:
behaviour belongs in `dispatch.lua`. Parameterised families (workspace numbers,
the four directions) resolve there by pattern rather than being listed 30 times.

An entry with no dispatcher is skipped with a printed notice rather than
throwing, so a stale id costs one bind instead of the session.

Every field needs real bounds. The validator rejects the whole submission if any
field fails, and `type = "text"` fields must carry a `pattern`: these values are
serialized into Lua source that a compositor then executes.

## Services

`hypr/conf/services.lua` holds the startup processes once, used by both
`conf/autostart.lua` and the `services.restart` dispatcher. Add a service there,
not in either consumer.

**Do not add PipeWire or WirePlumber.** They are systemd user units with socket
activation already enabled; launching them from Hyprland races with systemd and
produces two session managers. The file says so, and it keeps getting suggested.

Every entry is guarded with `command -v`, so an uninstalled package is skipped.
Keep that: this config is expected to load on a machine missing some tools.

## Waybar

`waybar/` is versioned and launched with `-c`/`-s` from `conf/services.lua`,
which derives the repo root from `package.path` rather than hardcoding it. Do
not move it to `~/.config/waybar`.

`waybar/style.css` is **GTK CSS**. Browser CSS habits break it: no `:root`
custom properties (use `@define-color`), no `rgb(0 0 0 / 0.5)` slash syntax (use
`alpha(@color, 0.5)`), and selectors are widget names. It is not the same
language as `src/static/css/wukong.css` despite sharing the palette.

Waybar does not reload on config change: `SUPER + SHIFT + R`.

## Waybar config

Split deliberately: `waybar/config.jsonc` is machine-managed by `/waybar`,
`waybar/modules.jsonc` is hand-written. Waybar's `include` resolves conflicts in
favour of the **including** file, so the machine file must include the hand file
and not the reverse. This was verified, not assumed.

Waybar has no `--verify-config`, so `src/lib/waybar/store.lua` re-parses what it
wrote and rolls back if the result is not valid JSON. Keep that check.

GTK CSS traps that cost time: `font-feature-settings` takes one string
(`"calt 1, ss01 1"`), and `@keyframes` takes `from`/`to`/single percentages, not
the grouped `0%, 100%` selector.

## hyprctl under a Lua config

`hyprctl dispatch` wraps its argument in `hl.dispatch(...)`, so it needs **Lua**,
not hyprlang:

```bash
hyprctl dispatch 'hl.dsp.focus({ workspace = 7 })'   # works
hyprctl dispatch workspace 7                          # error near '7'
```

Every shell command in this repo that dispatches must use the Lua form. This
also breaks waybar's built-in workspace `activate`, which sends the hyprlang
string over the IPC socket - verified against the raw socket, not assumed. There
is no compatibility flag in `hyprctl` and no legacy keyword in the Lua API, so
the bar uses ten `custom/wsN` buttons that dispatch the Lua form. Do not
"simplify" them back to `hyprland/workspaces`: clicking would stop working.

## Icons on the bar

Lucide SVGs for function, Mandarin only for workspace numbers. An icon a reader
cannot decode is not an icon.

librsvg renders SVG for GTK `background-image` but **ignores animation inside
the file** - no SMIL, no CSS keyframes within an SVG. Hover and state animation
must act on the widget (`background-size`, `background-position`, `opacity`).

**Writing glyphs through a bash heredoc silently drops them.** The private-use
codepoints came through as empty strings and the bar rendered blank labels. Emit
them from Python by codepoint, and check coverage with
`fc-list :charset=<hex>` before using one.

## Function keys

The bare F1-F12 row is intentionally unbound. Volume, media and brightness use
the `XF86*` codes the keyboard emits. Binding bare F-keys hijacks them from
applications, which is what the previous HyDE config did.

`msi-ec` does not load on this hardware (EC firmware `14DLEMS1.105` is
unsupported and the module takes no override), so there is no software Fn-swap
to wire up. Fn Lock is Fn + Esc, handled by the embedded controller.

## Presets

A preset in `hypr/presets/` is a snapshot of both `settings.lua` and
`keybinds.lua`. `src/lib/hypr/presets.lua` applies one.

The invariant that matters: **applying is atomic across both files.** It backs
both up, writes both, verifies once, and restores **both** on rejection. A
half-applied preset - new keybinds against old settings - is worse than not
applying at all, so do not split the verify or let one write succeed alone.

`presets.get` rejects any slug that is not `[%w_-]+`, which is what stops a
path-traversal slug reaching the filesystem. Keep that check.

Restoring is a two-press action in the UI because it overwrites work, matching
how keybind conflicts are confirmed.

## Safety properties worth preserving

`lib/hypr/store.lua` is deliberately paranoid, in this order:

1. validate every field against the schema; reject the whole submission on any error
2. back up the current `settings.lua` to `hypr/.backup/`
3. write
4. `Hyprland --verify-config` against the real entry point
5. on failure, restore the backup and report; on success, `hyprctl reload`

Step 4 is the load-bearing one: it type-checks generated Lua through Hyprland
itself rather than trusting the serializer. Do not remove it, and do not reorder
5 before 4.

`store.read()` loads `settings.lua` with an empty environment, so a tampered
file cannot reach the server process.

## Security properties

The server binds `127.0.0.1` and writes the compositor config, so two things
matter and both are easy to break by accident:

- **CSRF.** A plain form POST is not blocked by the same-origin policy, so any
  page the user visits could POST to `127.0.0.1:1024/hypr/save` and silently
  rewrite their config. `routes/hypr.lua` validates a `lapis.csrf` token bound
  to the session cookie. Any new route that writes must do the same.
- **The session secret** is generated per install into `.secret` (gitignored,
  mode 600) by `lib/secret.lua`. Never commit a secret - a shared one in a
  public repo lets anyone forge the cookie the CSRF token is bound to.

## Gotchas found the hard way

- **Never `pkill -f` a pattern that appears in your own command line.** `pkill -f 'lapis server'`
  matches the shell running it. Use `./dev stop`, which finds the listener by port.
- **`render()` in etlua writes to the buffer and returns nil**, so `<%- render(...) %>`
  prints a stray "nil" on the page. Use the statement form, `<% render(...) %>`.
- **etlua has no comment tag.** `<%-- ... --%>` parses as `<%-` plus a stray `-`
  and throws. Use `<% --[[ ... ]] %>`.
- **Variables assigned inside a view do not reach the layout.** `<% page_title = "x" %>`
  in a template silently does nothing - every page title was broken this way for
  a while. Set them on `self` in the route handler instead.
- Long `max-age` on `/static` means edits do not show up. Assets are linked with
  a `?v=` buster from `app.lua`; keep it.
- `hyprctl` reports keybind modifiers as a bitfield, not names. `lib/hypr/hyprctl.lua`
  decodes it.
- Every Lua-registered bind reports its dispatcher as `__lua` to hyprctl, so
  that column carries no information and is not shown.
- **A CSS rule that sets `display` outranks the UA stylesheet's `[hidden]`.**
  Every grid or flex row the search filters, and the capture overlay, stopped
  respecting `hidden` until `[hidden] { display: none !important }` was added.
- **`font-display: swap` made every heading resize on load.** The fallback serif
  has different metrics. It is `block` now, with the font preloaded in the
  layout.
- Prefer `event.code` when capturing keys - it is the physical key, so a bind
  survives a layout change - but fall back to `event.key`, because synthesized
  events carry no code.
- The live wallpaper is **WebM/VP9**, despite arriving named `.mp4`. It is named
  `.webm` now; `app.lua` must map the extension or Firefox will refuse it.

## Motion

Pages render in their final state. There are **no entrance animations and no
view transitions** - they were removed because cross-document transitions
combined with the font swap made headings visibly jump on every navigation.
Interaction feedback (hover, focus, toggles, sliders) still animates; that is
responsiveness, not a page transition. Do not reintroduce page-level animation.

## Deployment

The app is a local agent, not a hostable service: it shells out to `hyprctl` and
`Hyprland --verify-config`, reads `/proc` and `/sys`, and writes into the repo.
It cannot be deployed to a serverless host, and Vercel has no Lua runtime in any
case. Do not add a serverless adapter - it would produce a page that renders
blanks and fails every write.

`tools/export-static.sh` is the supported answer: it renders every route to
static HTML with `ARCHCONFIG_DEMO=1` and a frozen data snapshot.

**`dist/` is committed on purpose.** Vercel serves it with no build step, which
`vercel.json` at the repo root configures (`outputDirectory: dist`, empty build
and install commands). Do not add a build command and do not gitignore `dist/`
again - a Vercel build container cannot render these pages, so committing the
output is the only way the git integration can work. `tools/publish.sh` rebuilds
and commits it, and refuses to run with unrelated uncommitted changes.

Three properties of that export matter and are easy to break:

- **`ARCHCONFIG_DEMO=1` must disable editing.** Both forms get `inert`, the save
  buttons are not rendered, and a banner says so. A new editable surface has to
  honour the flag too.
- **The export scrubs the username** from the HTML, because the storage table
  carries `/home/<user>` and `/run/media/<user>` mount paths.
- **The export copies all of `src/static`**, so the wallpaper, poster, favicon
  and font come from your own domain while the theme images stay hotlinked.

## Theme

**Oxocarbon Dark** throughout.

- Palette: <https://github.com/nyoom-engineering/base16-oxocarbon>
- Desktop theme: <https://github.com/rishav12s/Oxo-Carbon>, vendored in
  `themes/oxo-carbon/` and installed to `~/.local/share/themes` and
  `~/.config/Kvantum`. Standard locations on purpose: the point was to get the
  theme without HyDE managing it, so it stays editable.

The bar is a transparent tray with modules grouped into rounded islands, which
is upstream's design (`bar-bg` is `rgba(0,0,0,0)`). Do not put a background back
on `window#waybar`, and do not add dividers between modules.

The base16 names are kept as the variable names in `waybar/style.css`
(`@define-color base00` ...) so the palette can be checked against the source
without translation. `src/static/css/wukong.css` keeps its older variable names
but holds Oxocarbon values.

**One exception, and it is deliberate**: Clawd keeps Claude's `#D97757`. Do not
fold him into the palette - he is the one thing on the bar that is not
Oxocarbon, and that is the point.

## Assets

The theme's nine images are **hotlinked from gamesci.cn** by the stylesheet, not
stored here. They are declared once as `--art-*` custom properties at the top of
`src/static/css/wukong.css`; use those variables rather than writing a URL
inline, so there is one place to repair.

Those filenames are content-hashed by their build, so they will eventually 404.
That degrades to the flat palette rather than breaking, which is the intended
failure mode - do not add a fallback image, and do not start caching copies into
the repo.

In the repo: `src/static/assets/live-wallpaper-4k.webm` (9 MB),
`src/static/assets/wallpaper-poster.jpg` (a frame of it, so there is no black
flash before the video decodes) and `src/static/favicon.ico` (the site's own).
`src/static/fonts/CrimsonPro-*` is SIL OFL 1.1 and is the one asset with a
licence that permits redistribution.

Publishing note: hotlinking keeps their images out of the repo, but a public
deploy still displays their artwork and serves the wallpaper from your domain.
That is the user's call and they have made it.
