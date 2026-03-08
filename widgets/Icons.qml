// Icons.qml — Nerd Font icon codepoints and per-icon pixel sizes.
// Adjust sizes here to tune every widget without touching individual files.

pragma Singleton
import QtQuick

Item {
    // ── Battery level icons (empty → full) ───────────────────────────────────
    readonly property string batteryFull:         "\uf240"
    readonly property string batteryThreeQuarter: "\uf241"
    readonly property string batteryHalf:         "\uf242"
    readonly property string batteryQuarter:      "\uf243"
    readonly property string batteryEmpty:        "\uf244"
    readonly property int    batterySize:         22

    // ── Battery bolt (shown while charging) ───────────────────────────────────
    readonly property string batteryCharging:     "\uf0e7"
    readonly property int    batteryChargingSize: 16

    // ── Battery plug (shown when full / not charging) ─────────────────────────
    readonly property string batteryPlugged:      "\uf1e6"
    readonly property int    batteryPluggedSize:  16

    // ── Network ───────────────────────────────────────────────────────────────
    readonly property string networkWifi:         "\uf1eb"
    readonly property string networkEthernet:     "\uf796"
    readonly property string networkDisconnected: "\uf127"   // chain-broken
    readonly property int    networkSize:         22

    // ── IP ────────────────────────────────────────────────────────────────────
    readonly property string ipGlobe: "\uf0ac"
    readonly property int    ipSize:  22

    // ── Volume ────────────────────────────────────────────────────────────────
    readonly property string volOff:  "\uf026"
    readonly property string volLow:  "\uf027"
    readonly property string volHigh: "\uf028"
    readonly property int    volSize: 24

    // ── Headphone (vol sink override + BT audio active) ───────────────────────
    readonly property string headphone:     "\uf025"
    readonly property int    headphoneSize: 24

    // ── Microphone ────────────────────────────────────────────────────────────
    readonly property string micOn:      "\uf130"
    readonly property string micSlash:   "\uf131"
    readonly property int    micSize:    24

    // ── Bluetooth ─────────────────────────────────────────────────────────────
    readonly property string bluetooth:     "\uf293"
    readonly property int    bluetoothSize: 18

    // ── Updates ───────────────────────────────────────────────────────────────
    readonly property string updates:     "\uf487"
    readonly property int    updatesSize: 22

    // ── Power ─────────────────────────────────────────────────────────────────
    readonly property string powerOff:  "\uf011"
    readonly property int    powerSize: 22
}
