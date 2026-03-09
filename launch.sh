#!/usr/bin/env bash
# Kill any running instance and launch mybar.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pkill -f "quickshell.*mybar" 2>/dev/null
sleep 0.2
quickshell -p "$DIR" &
