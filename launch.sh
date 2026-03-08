#!/usr/bin/env bash
# Kill any running instance and launch mybar.
pkill -f "quickshell.*mybar" 2>/dev/null
sleep 0.2
quickshell -p "$HOME/dev/rice/mybar" &
