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
  config.lua           Lapis config - cqueues backend, 127.0.0.1:8080
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
  static/              css, js, fonts; artwork fetched by assets/fetch.sh
hypr/                  THE LIVE CONFIG - see the rule above
  settings.lua         machine-managed values
  keybinds.lua         machine-managed combos, plain data
  conf/binds/          dispatch.lua (id -> behaviour) + init.lua (the join)
  conf/rules/          window and layer rules
.tools/                vendored Lua toolchain (gitignored, built by build.sh)
```

## Running it

```bash
./.tools/build.sh             # once: LuaJIT, LuaRocks, Lapis into .tools/ - no root
src/static/assets/fetch.sh    # once: the theme artwork
./dev                         # serve http://127.0.0.1:8080
./dev stop                    # stop it
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
  page the user visits could POST to `127.0.0.1:8080/hypr/save` and silently
  rewrite their config. `routes/hypr.lua` validates a `lapis.csrf` token bound
  to the session cookie. Any new route that writes must do the same.
- **The session secret** is generated per install into `.secret` (gitignored,
  mode 600) by `lib/secret.lua`. Never commit a secret - a shared one in a
  public repo lets anyone forge the cookie the CSRF token is bound to.

## Gotchas found the hard way

- **Never `pkill -f` a pattern that appears in your own command line.** `pkill -f 'lapis server'`
  matches the shell running it. Use `./dev stop`, which finds the listener by port.
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

Three properties of that export matter and are easy to break:

- **`ARCHCONFIG_DEMO=1` must disable editing.** Both forms get `inert`, the save
  buttons are not rendered, and a banner says so. A new editable surface has to
  honour the flag too.
- **The export scrubs the username** from the HTML, because the storage table
  carries `/home/<user>` and `/run/media/<user>` mount paths.
- **Placeholder art is the default.** `tools/placeholder-art.sh` draws original
  shapes in the theme palette so a public build ships none of Game Science's
  images. `--real-art` exists for private hosts and says so loudly.

## Assets

`static/assets/wukong/` is cached from the official site (gamesci.cn/wukong) and
`static/assets/live-wallpaper-4k.webm` came from a wallpaper aggregator. The
palette in `static/css/wukong.css` was derived by frequency-analysing that
site's stylesheet.

**These are not redistributable.** They are Game Science's copyrighted artwork,
fine to cache for a personal offline dashboard, not fine to publish.

This is already handled: the artwork is gitignored and
`src/static/assets/fetch.sh` pulls it at install time, so a clone is functional
without the repo carrying the bytes. The CSS degrades to the flat palette when
it is absent - the wordmark is a background rather than an `<img>` so a missing
file shows nothing instead of a broken-image icon.

`src/static/fonts/CrimsonPro-*` is **Crimson Pro**, SIL OFL 1.1, and is the one
asset shipped in-repo.

Still to do before publishing:

1. Add a `LICENSE` for your own code.
2. Ship `OFL.txt` beside the font, or link Google Fonts instead.
3. Genericise the absolute home paths in `hypr/README.md`.
