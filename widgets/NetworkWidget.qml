// NetworkWidget.qml — WiFi / Ethernet / Disconnected status pill
// Shows connection type, SSID or interface, signal strength, and VPN indicator.
// Click opens NetworkManager settings.

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    // collapsed = icon only; expanded = icon + label + signal
    readonly property bool _hovered: hoverArea.containsMouse

    width:          content.implicitWidth + 24
    implicitHeight: parent.height

    // ── State ────────────────────────────────────────────────────────────────
    property string _type:   "disconnected"  // "wifi" | "ethernet" | "disconnected"
    property string _ssid:   ""
    property int    _signal: 0
    property string _iface:  ""

    // ── Derived ──────────────────────────────────────────────────────────────
    readonly property color _netColor:
        _type === "disconnected" ? theme.accent : theme.a(theme.primary, 0.90)

    readonly property string _label: {
        if (_type === "wifi")         return _ssid
        if (_type === "ethernet")     return _iface
        return "—"
    }

    // ── Polling (3 s) ────────────────────────────────────────────────────────
    Process {
        id: proc
        property string _buf: ""
        command: ["bash", "-c", "$HOME/dev/rice/mybar/scripts/network-status.sh"]
        stdout: SplitParser {
            onRead: function(data) { proc._buf += data }
        }
        onRunningChanged: {
            if (running) return
            if (_buf === "") return
            try {
                const j      = JSON.parse(_buf.trim())
                root._type   = j.type   ?? "disconnected"
                root._ssid   = j.ssid   ?? ""
                root._signal = j.signal ?? 0
                root._iface  = j.iface  ?? ""
            } catch(e) {}
            _buf = ""
        }
    }

    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: if (!proc.running) proc.running = true
    }

    Component.onCompleted: proc.running = true

    // ── Background pill ───────────────────────────────────────────────────
    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:       8
        color:        theme.a(theme.primary, 0.06)
        border.color: _type === "disconnected"
                        ? theme.a(theme.accent, 0.35)
                        : theme.a(theme.primary, 0.14)
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 300 } }
    }

    // ── Content ───────────────────────────────────────────────────────────
    Row {
        id: content
        anchors.centerIn: parent
        spacing: 7

        // Network icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (root._type === "ethernet")     return Icons.networkEthernet
                if (root._type === "disconnected") return Icons.networkDisconnected
                return Icons.networkWifi
            }
            font.family:    "FiraCode Nerd Font Mono"
            font.pixelSize: Icons.networkSize
            color:          root._netColor
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // Details: SSID + signal — clipped wrapper animates width
        Item {
            id: detailsWrapper
            anchors.verticalCenter: parent.verticalCenter
            height: root.implicitHeight
            width:  root._hovered ? detailsRow.implicitWidth : 0
            clip:    true
            opacity: root._hovered ? 1 : 0
            Behavior on width   { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Row {
                id: detailsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           root._label
                    font.family:    "Fira Sans"
                    font.pixelSize: 13
                    font.weight:    Font.DemiBold
                    color:          root._netColor
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Text {
                    visible:        root._type === "wifi"
                    anchors.verticalCenter: parent.verticalCenter
                    text:           root._signal + "%"
                    font.family:    "Fira Sans"
                    font.pixelSize: 12
                    color:          theme.a(theme.primary, 0.55)
                }
            }
        }
    }

    // ── Interaction ───────────────────────────────────────────────────────
    MouseArea {
        id:           hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    nmProc.running = true
    }

    Process { id: nmProc; command: ["bash", "-c", "~/.config/ml4w/settings/networkmanager.sh"] }
}
