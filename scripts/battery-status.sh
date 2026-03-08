#!/usr/bin/env bash
# Output JSON: {"capacity":N,"status":"...","time":"Xh Ym"}
# time is remaining (discharging) or until full (charging).
# Reads energy_now/energy_full/power_now from sysfs.

bat_dir=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)

if [ -z "$bat_dir" ]; then
    echo '{"capacity":0,"status":"Unknown","time":""}'
    exit 0
fi

capacity=$(cat "$bat_dir/capacity"   2>/dev/null || echo 0)
status=$(  cat "$bat_dir/status"     2>/dev/null || echo "Unknown")

energy_now=$(  cat "$bat_dir/energy_now"  2>/dev/null || echo 0)
energy_full=$( cat "$bat_dir/energy_full" 2>/dev/null || echo 0)
power_now=$(   cat "$bat_dir/power_now"   2>/dev/null || echo 0)

time_str=""
if [ "$power_now" -gt 0 ]; then
    if [ "$status" = "Discharging" ]; then
        # seconds remaining = energy_now / power_now * 3600
        seconds=$(awk -v e="$energy_now" -v p="$power_now" \
            'BEGIN { printf "%d", (e / p) * 3600 }')
    elif [ "$status" = "Charging" ]; then
        seconds=$(awk -v ef="$energy_full" -v en="$energy_now" -v p="$power_now" \
            'BEGIN { printf "%d", ((ef - en) / p) * 3600 }')
    fi

    if [ -n "$seconds" ] && [ "$seconds" -gt 0 ]; then
        h=$((seconds / 3600))
        m=$(( (seconds % 3600) / 60 ))
        if [ "$h" -gt 0 ]; then
            time_str="${h}h ${m}m"
        else
            time_str="${m}m"
        fi
    fi
fi

printf '{"capacity":%d,"status":"%s","time":"%s"}' \
    "$capacity" "$status" "$time_str"
