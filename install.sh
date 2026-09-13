#!/usr/bin/env bash
# ╭────────────────────────────────────────────────────────────────────────────╮
# │  INSTALL EVERYTHING                                                        │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
#   ./install.sh              packages, toolchain, configs
#   ./install.sh --no-pacman  skip the package step (everything else still runs)
#
# The only step that needs root is pacman; it is asked for once, up front, and
# everything after it runs as you. Safe to re-run: each step is idempotent.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

SKIP_PACMAN=0
[[ "${1:-}" == "--no-pacman" ]] && SKIP_PACMAN=1

step() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }
ok()   { printf '    %s\n' "$*"; }

PACKAGES=(
  # compositor and session
  hyprland hyprpaper hyprlock hypridle hyprsunset hyprpicker
  # bar, launcher, notifications
  waybar rofi dunst swaybg mission-center btop
  # terminal, files, browser, editor
  kitty dolphin firefox
  # audio, backlight, media, clipboard, screenshots
  wireplumber pavucontrol playerctl brightnessctl
  wl-clipboard cliphist grim slurp
  # input method: Vietnamese Telex alongside US
  fcitx5 fcitx5-unikey fcitx5-chinese-addons fcitx5-configtool fcitx5-gtk fcitx5-qt
  # fonts: Cascadia for latin, Nerd Font for glyphs, Kaiti for the brush numerals
  ttf-cascadia-code ttf-cascadia-code-nerd ttf-arphic-ukai adobe-source-han-sans-cn-fonts
  # shell and odds and ends
  zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
  blueman network-manager-applet ffmpeg librsvg
  # Qt theming, so Dolphin and other Qt apps follow Oxocarbon too
  kvantum qt5ct qt6ct papirus-icon-theme
)

if [[ "$SKIP_PACMAN" == 0 ]]; then
  step "Packages (${#PACKAGES[@]})"
  sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
else
  step "Packages"; ok "skipped (--no-pacman)"
fi

step "Lua toolchain"
if [[ -x "$ROOT/.tools/local/bin/lapis" ]]; then
  ok "already built"
else
  "$ROOT/.tools/build.sh"
fi

step "Hyprland config"
"$ROOT/hypr/install.sh"

step "Companion configs"
# hyprpaper, hypridle and hyprlock take no -c flag, so they are copied rather
# than pointed at. Without hypridle.conf the daemon exits at startup.
mkdir -p "$HOME/.config/hypr"
for f in "$ROOT"/hypr/companions/*.conf; do
  [ -e "$f" ] || continue
  install -m644 "$f" "$HOME/.config/hypr/$(basename "$f")"
  ok "$(basename "$f")"
done

step "fcitx5"
# fcitx5 rewrites its config on exit, so stop it before copying over the top.
pkill -x fcitx5 2>/dev/null || true
sleep 1
mkdir -p "$HOME/.config/fcitx5/conf"
install -m644 "$ROOT/fcitx5/profile"          "$HOME/.config/fcitx5/profile"
install -m644 "$ROOT/fcitx5/config"           "$HOME/.config/fcitx5/config"
install -m644 "$ROOT/fcitx5/conf/unikey.conf" "$HOME/.config/fcitx5/conf/unikey.conf"
ok "US + Vietnamese Telex, Ctrl+Shift to switch"
# Arch autostarts fcitx5 via xdg and a systemd user unit already; do not add a
# third, or they race for the D-Bus name and the loser exits.
ok "left to the system's own autostart (xdg + systemd user unit)"

step "Oxocarbon theme"
# GTK (pavucontrol, nwg-look, most of the small settings apps).
mkdir -p "$HOME/.local/share/themes"
tar xzf "$ROOT/themes/oxo-carbon/Gtk_Oxo-Carbon.tar.gz" -C "$HOME/.local/share/themes"
ok "GTK theme -> ~/.local/share/themes/Oxo-Carbon"

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
for v in 3.0 4.0; do
  cat > "$HOME/.config/gtk-$v/settings.ini" <<'INI'
[Settings]
gtk-theme-name=Oxo-Carbon
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Cascadia Code 10
gtk-application-prefer-dark-theme=1
gtk-cursor-theme-size=24
INI
done
# GTK4 reads its stylesheet from the config dir rather than settings.ini.
ln -sfn "$HOME/.local/share/themes/Oxo-Carbon/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme 'Oxo-Carbon'    2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface font-name 'Cascadia Code 10' 2>/dev/null || true
fi
ok "GTK applied"

# Qt (Dolphin). Kvantum paints the widgets; QT_STYLE_OVERRIDE points Qt at it.
mkdir -p "$HOME/.config/Kvantum/Oxo-Carbon"
install -m644 "$ROOT/themes/oxo-carbon/Oxo-Carbon.kvantum"  "$HOME/.config/Kvantum/Oxo-Carbon/Oxo-Carbon.svg"
install -m644 "$ROOT/themes/oxo-carbon/Oxo-Carbon.kvconfig" "$HOME/.config/Kvantum/Oxo-Carbon/Oxo-Carbon.kvconfig"
printf '[General]\ntheme=Oxo-Carbon\n' > "$HOME/.config/Kvantum/kvantum.kvconfig"
ok "Kvantum theme -> ~/.config/Kvantum/Oxo-Carbon"
ok "Qt apps need QT_STYLE_OVERRIDE=kvantum - hypr/conf/autostart.lua sets it"

step "Shell"
if [[ "$SHELL" != */zsh ]] && command -v zsh >/dev/null; then
  ok "run 'chsh -s $(command -v zsh)' to make zsh your login shell"
else
  ok "zsh already the login shell"
fi

step "Fonts"
fc-cache -f >/dev/null 2>&1 || true
for f in "Cascadia Code" "CaskaydiaCove Nerd Font" "AR PL UKai CN" "Source Han Sans CN"; do
  if fc-list : family | grep -qF "$f"; then ok "$f"; else ok "MISSING: $f"; fi
done

step "Checks"
if Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua" 2>&1 | grep -q '^config ok'; then
  ok "hyprland config ok"
else
  ok "HYPRLAND CONFIG HAS ERRORS - run: Hyprland --verify-config -c ~/.config/hypr/hyprland.lua"
fi
if command -v waybar >/dev/null; then
  if waybar -c "$ROOT/waybar/config.jsonc" -s "$ROOT/waybar/style.css" --log-level error >/dev/null 2>&1 & then
    sleep 2; pkill -x waybar 2>/dev/null || true; ok "waybar config parses"
  fi
fi

cat <<'DONE'

    Done. Next:

      hyprctl reload          pick up the config
      SUPER + SHIFT + R       start the bar and the rest of the services
      ./dev                   the web UI on http://127.0.0.1:1024

    Ctrl+Shift switches English / Vietnamese Telex.
DONE
