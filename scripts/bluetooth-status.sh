#!/usr/bin/env bash
# Output JSON: {"status":"off"|"on"|"connected","active":bool}
# Detects bluetooth via pactl (bluez sinks) and rfkill — no bluetoothctl needed.
# active=true when the default sink is a bluetooth device.

# Count bluez audio sinks registered in PipeWire/PulseAudio
bt_sinks=$(pactl list sinks short 2>/dev/null | grep -c "bluez_output" || echo 0)

if [ "$bt_sinks" -gt 0 ]; then
    default_sink=$(pactl get-default-sink 2>/dev/null)
    active=false
    echo "$default_sink" | grep -q "bluez" && active=true
    printf '{"status":"connected","active":%s}' "$active"
    exit 0
fi

# No bluez sinks — check if the adapter is powered via rfkill
bt_unblocked=$(rfkill list bluetooth 2>/dev/null | grep -c "Soft blocked: no" || echo 0)
if [ "$bt_unblocked" -gt 0 ]; then
    echo '{"status":"on","active":false}'
else
    echo '{"status":"off","active":false}'
fi
