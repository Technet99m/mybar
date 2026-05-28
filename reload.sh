#!/usr/bin/env bash
# Compatibility entrypoint for Hyprland keybindings.
# launch.sh already restarts the bar, so reload delegates to it.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/launch.sh"
