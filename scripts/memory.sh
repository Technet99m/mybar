#!/usr/bin/env bash
# Simple memory reporter for Waybar (returns JSON)
# Outputs: {"text":"...","tooltip":"..."}

set -euo pipefail

# Read MemTotal and MemAvailable (in kB)
read memtotal memavail < <(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END{print t,a}' /proc/meminfo)

# Calculate used (kB)
used_kb=$((memtotal - memavail))

# Convert to GB with one decimal place
used_gb=$(awk -v k="$used_kb" 'BEGIN{printf "%.1f", k/1024/1024}')
total_gb=$(awk -v k="$memtotal" 'BEGIN{printf "%.1f", k/1024/1024}')
avail_gb=$(awk -v k="$memavail" 'BEGIN{printf "%.1f", k/1024/1024}')

# Percent used (rounded)
percent=$(awk -v u="$used_kb" -v t="$memtotal" 'BEGIN{printf "%d", (u/t)*100 + 0.5}')

text="${used_gb}GB / ${total_gb}GB (${percent}%)"
tooltip="Used: ${used_gb}GB (${percent}%)\\nAvailable: ${avail_gb}GB\\nTotal: ${total_gb}GB"

printf '%s' "{\"text\":\"${text}\",\"tooltip\":\"${tooltip}\"}"
