#!/bin/bash
# Local IP with VPN detection for Waybar
# Outputs JSON: text = primary IP, class = vpn-active or normal, tooltip = all interfaces

# Collect IPs per interface type
get_ips() {
    local result=""
    # Iterate over interfaces with an assigned IPv4
    while IFS= read -r line; do
        iface=$(echo "$line" | awk '{print $2}' | tr -d ':')
        ip=$(echo "$line" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        [[ -z "$ip" ]] && continue
        [[ "$ip" == "127.0.0.1" ]] && continue

        # Determine interface type label
        case "$iface" in
            wg*|wgcf*)   label="  WireGuard" ;;
            tun*|vpn*)   label="  VPN (tun)" ;;
            wlan*|wlp*)  label="  WiFi" ;;
            eth*|enp*|eno*|ens*) label="  Ethernet" ;;
            *)           label="  $iface" ;;
        esac

        result+="${label}: ${ip}\n"
    done < <(ip -4 addr show | grep -E '^\s+inet|^[0-9]')

    echo -e "$result"
}

# Detect VPN: wireguard or tun interfaces (WireGuard reports UNKNOWN not UP)
vpn_iface=$(ip link show | grep -E '(wg[0-9]|tun[0-9]|wgcf)' | grep -iE '(state UP|state UNKNOWN)' | head -1)

# Primary IP (non-loopback, first one)
primary_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
[[ -z "$primary_ip" ]] && primary_ip="No IP"

# Build tooltip: all IPs grouped by interface
tooltip=""
while IFS= read -r iface_line; do
    iface=$(echo "$iface_line" | awk '{print $2}' | tr -d ':')
    ip_line=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    [[ -z "$ip_line" ]] && continue
    [[ "$ip_line" == "127.0.0.1" ]] && continue

    case "$iface" in
        wg*|wgcf*)   label="  WireGuard" ;;
        tun*|vpn*)   label="  VPN tunnel" ;;
        wlan*|wlp*)  label="  WiFi" ;;
        eth*|enp*|eno*|ens*) label="  Ethernet" ;;
        lo|br-*|docker*|veth*|virbr*) continue ;;
        *)           label="  $iface" ;;
    esac

    tooltip+="${label}: ${ip_line}\\n"
done < <(ip link show | grep -E '^[0-9]+:')

# Remove trailing \n
tooltip="${tooltip%\\n}"

if [[ -n "$vpn_iface" ]]; then
    css_class="vpn-active"
    alt_text="  $primary_ip"
else
    css_class="normal"
    alt_text="  $primary_ip"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}' \
    "$alt_text" "$css_class" "$tooltip"
