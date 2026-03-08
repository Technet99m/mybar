#!/usr/bin/env bash
# Output JSON: {"volume":N,"muted":bool,"mic_muted":bool,"headset":bool}
# headset=true when the default audio sink is a bluetooth (bluez) device.

vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@   2>/dev/null || echo "Volume: 0.00")
mic_raw=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || echo "Volume: 0.00")

vol_pct=$(echo "$vol_raw" | awk '{printf "%d", $2 * 100}')

vol_muted=false
echo "$vol_raw" | grep -q "MUTED" && vol_muted=true

mic_muted=false
echo "$mic_raw" | grep -q "MUTED" && mic_muted=true

headset=false
default_sink=$(pactl get-default-sink 2>/dev/null)
echo "$default_sink" | grep -q "bluez" && headset=true

printf '{"volume":%d,"muted":%s,"mic_muted":%s,"headset":%s}' \
    "$vol_pct" "$vol_muted" "$mic_muted" "$headset"
