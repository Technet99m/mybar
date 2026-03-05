#!/bin/bash
# VPN Status Checker for Waybar

# Check if VPN is active (look for tun interface or wireguard)
vpn_active=$(ip link show | grep -E "(tun|wg)" | head -1)

if [ -n "$vpn_active" ]; then
    echo '{"text": "🔒 VPN", "class": "connected", "tooltip": "VPN Connected"}'
else
    echo '{"text": "🔓", "class": "disconnected", "tooltip": "VPN Disconnected"}'
fi
