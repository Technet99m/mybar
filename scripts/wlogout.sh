#!/usr/bin/env bash
# Open wlogout with top/bottom margins of 27% of the focused monitor's
# logical height (physical height / scale).
w_margin=$(hyprctl -j monitors 2>/dev/null \
    | jq -r '.[] | select(.focused == true) | (.height * 0.27 / .scale | floor)' 2>/dev/null)

if [[ "$w_margin" =~ ^[0-9]+$ ]]; then
    wlogout -b 5 -T "$w_margin" -B "$w_margin"
else
    wlogout -b 5
fi
