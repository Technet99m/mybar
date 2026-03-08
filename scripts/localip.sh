#!/usr/bin/env bash
# Output JSON with primary IP + individual lan/wg/wlan addresses.
# Missing interfaces output "0.0.0.0".

get_ip() {
    local pattern="$1"
    ip -4 addr show 2>/dev/null \
        | awk -v pat="$pattern" '
            /^[0-9]+:/ { split($2, a, ":"); iface = a[1] }
            /inet /    { if (iface ~ pat) { split($2, b, "/"); print b[1]; exit } }
        '
}

lan=$(get_ip  '^(eth|enp|eno|ens)')
wg=$(get_ip   '^(wg|wgcf|tun)')
wlan=$(get_ip '^(wlan|wlp)')

lan="${lan:-0.0.0.0}"
wg="${wg:-0.0.0.0}"
wlan="${wlan:-0.0.0.0}"

# Primary: first non-zero in order LAN > WLAN > WG
primary="$lan"
[ "$primary" = "0.0.0.0" ] && primary="$wlan"
[ "$primary" = "0.0.0.0" ] && primary="$wg"
[ "$primary" = "0.0.0.0" ] && primary="No IP"

vpn=false
[ "$wg" != "0.0.0.0" ] && vpn=true

printf '{"primary":"%s","lan":"%s","wg":"%s","wlan":"%s","vpn":%s}' \
    "$primary" "$lan" "$wg" "$wlan" "$vpn"
