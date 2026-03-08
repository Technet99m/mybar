#!/usr/bin/env bash
# Output JSON: {"type":"wifi"|"ethernet"|"disconnected","ssid":"...","signal":N,"iface":"...","vpn":bool}

# Check for active WiFi
wifi_conn=$(nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null \
    | grep "^wifi:connected:" | head -1)

# Check for active Ethernet
eth_conn=$(nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null \
    | grep "^ethernet:connected:" | grep -v "externally" | head -1)

# VPN active if wireguard or vpn type is connected
vpn=false
nmcli -t -f TYPE,STATE device status 2>/dev/null \
    | grep -qE "^(wireguard|vpn):connected" && vpn=true

if [ -n "$wifi_conn" ]; then
    ssid=$(echo "$wifi_conn" | cut -d: -f3-)
    signal=$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null \
        | grep "^yes:" | cut -d: -f2 | head -1)
    signal=${signal:-0}
    # Escape quotes in SSID
    ssid=$(echo "$ssid" | sed 's/"/\\"/g')
    printf '{"type":"wifi","ssid":"%s","signal":%d,"vpn":%s}' \
        "$ssid" "$signal" "$vpn"
elif [ -n "$eth_conn" ]; then
    iface=$(nmcli -t -f TYPE,STATE,DEVICE device status 2>/dev/null \
        | grep "^ethernet:connected:" | grep -v "externally" \
        | cut -d: -f3 | head -1)
    printf '{"type":"ethernet","iface":"%s","vpn":%s}' "$iface" "$vpn"
else
    echo '{"type":"disconnected","vpn":false}'
fi
