#!/usr/bin/env bash
# Set up the rice on a fresh Arch machine:
#   1. install dependencies (pacman, only what's missing)
#   2. clone mybar, quick-nm and theme-switch side by side
#   3. wire them together (~/.config/tc99m) and apply a theme
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Technet99m/mybar/master/bootstrap.sh)
#   ./bootstrap.sh                 # from an existing mybar checkout
#
# Environment:
#   RICE_DIR   where the repos live (default: parent of this mybar checkout,
#              otherwise ~/dev/rice)
#   RICE_GIT   git base URL (default: https://github.com/Technet99m,
#              e.g. git@github.com:Technet99m for SSH)
#   NO_DEPS=1  skip package installation

set -euo pipefail

REPOS=(mybar quick-nm theme-switch)
GIT_BASE="${RICE_GIT:-https://github.com/Technet99m}"

# "dependency" or "dependency:package-to-install" (for virtual provides)
DEPS=(
    git
    # Quickshell runtime (Qt5Compat is used by theme-switch)
    quickshell qt6-5compat
    # mybar data sources
    hyprland jq python networkmanager wireplumber
    libpulse pulse-native-provider:pipewire-pulse
    util-linux iproute2 pacman-contrib
    # mybar click actions
    hyprlock pavucontrol blueman nm-connection-editor kitty
    # theme-switch
    awww imagemagick swaync
    # fonts
    ttf-fira-sans ttf-firacode-nerd
)

# Installed with yay/paru when one is available
AUR_DEPS=(wlogout)

say()  { printf '\e[1;34m::\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m::\e[0m %s\n' "$*" >&2; }

# When run from a mybar checkout, keep the other repos next to it
self="${BASH_SOURCE[0]}"
if [ -f "$self" ] && [ -f "$(dirname "$self")/shell.qml" ]; then
    default_dir="$(cd "$(dirname "$self")/.." && pwd)"
else
    default_dir="$HOME/dev/rice"
fi
RICE_DIR="${RICE_DIR:-$default_dir}"

# -------------------------------------------------------
# 1. Dependencies
# -------------------------------------------------------
if [ "${NO_DEPS:-}" = 1 ]; then
    say "Skipping dependency installation (NO_DEPS=1)"
elif ! command -v pacman >/dev/null; then
    warn "pacman not found — install the dependencies listed in the READMEs manually"
else
    missing=()
    for entry in "${DEPS[@]}"; do
        dep="${entry%%:*}"
        pkg="${entry#*:}"
        pacman -T "$dep" >/dev/null || missing+=("$pkg")
    done

    if [ ${#missing[@]} -gt 0 ]; then
        say "Installing: ${missing[*]}"
        sudo pacman -S --needed "${missing[@]}"
    else
        say "All dependencies already installed"
    fi

    missing_aur=()
    for dep in "${AUR_DEPS[@]}"; do
        pacman -T "$dep" >/dev/null || missing_aur+=("$dep")
    done

    if [ ${#missing_aur[@]} -gt 0 ]; then
        aur_helper=$(command -v yay || command -v paru || true)
        if [ -n "$aur_helper" ]; then
            say "Installing from AUR: ${missing_aur[*]}"
            "$aur_helper" -S --needed "${missing_aur[@]}"
        else
            warn "No AUR helper (yay/paru) — install manually: ${missing_aur[*]}"
        fi
    fi
fi

# -------------------------------------------------------
# 2. Clone
# -------------------------------------------------------
mkdir -p "$RICE_DIR"
for repo in "${REPOS[@]}"; do
    if [ -d "$RICE_DIR/$repo/.git" ]; then
        say "$repo already present in $RICE_DIR"
    else
        say "Cloning $repo"
        git clone "$GIT_BASE/$repo.git" "$RICE_DIR/$repo"
    fi
done

# -------------------------------------------------------
# 3. Wire together
# -------------------------------------------------------
# mybar's network widget opens quick-nm through this link
mkdir -p "$HOME/.config/tc99m"
ln -sfn "$RICE_DIR/quick-nm/launch.sh" "$HOME/.config/tc99m/quick-nm.sh"

# Themes whose wallpaper is missing still apply, just without a wallpaper
for theme in "$RICE_DIR"/theme-switch/themes/*.sh; do
    wallpaper=$(theme_wallpaper=""; source "$theme"; echo "$theme_wallpaper")
    if [ -n "$wallpaper" ] && [ ! -f "$wallpaper" ]; then
        warn "$(basename "$theme"): wallpaper not found at $wallpaper"
    fi
done

# Apply the saved theme (or the default one) — this also starts mybar
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    say "Applying theme and starting mybar"
    "$RICE_DIR/theme-switch/apply.sh"
else
    say "Not inside Hyprland — the theme will be applied on next login"
fi

# -------------------------------------------------------
# 4. Hyprland integration hint
# -------------------------------------------------------
if grep -rqs "theme-switch/apply.sh" "$HOME/.config/hypr"; then
    say "Hyprland config already starts theme-switch/apply.sh"
else
    say "Add this to your Hyprland config to start the rice on login:"
    if [ -f "$HOME/.config/hypr/hyprland.lua" ]; then
        cat <<EOF

hl.on("hyprland.start", function()
    hl.exec_cmd("$RICE_DIR/theme-switch/apply.sh") -- applies theme, starts mybar
end)
hl.bind("SUPER + N", hl.dsp.exec_cmd("$RICE_DIR/quick-nm/launch.sh"))
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("$RICE_DIR/mybar/reload.sh"))
hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd("qs -p $RICE_DIR/theme-switch"))

EOF
    else
        cat <<EOF

exec-once = $RICE_DIR/theme-switch/apply.sh  # applies theme, starts mybar
bind = SUPER, N, exec, $RICE_DIR/quick-nm/launch.sh
bind = SUPER SHIFT, B, exec, $RICE_DIR/mybar/reload.sh
bind = SUPER CTRL, T, exec, qs -p $RICE_DIR/theme-switch

EOF
    fi
fi

say "Done"
