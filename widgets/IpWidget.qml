// IpWidget.qml — Network IP pill.
// Collapsed: network icon only.
// Hover: expands to show LAN / WireGuard / WLAN addresses.
// Unavailable addresses shown as 0.0.0.0 with faded opacity.

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    implicitHeight: parent.height
    implicitWidth:  baseIcon.implicitWidth + 24 +
                    (_hovered ? expandRow.implicitWidth : 0)
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property string _lan:     "0.0.0.0"
    property string _wg:      "0.0.0.0"
    property string _wlan:    "0.0.0.0"
    property bool   _vpn:     false
    property bool   _hovered: false

    // ── Polling ───────────────────────────────────────────────────────────
    Process {
        id: proc
        property string _buf: ""
        command: ["bash", Qt.resolvedUrl("../scripts/localip.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: function(data) { proc._buf += data }
        }
        onRunningChanged: {
            if (running) { _buf = ""; return }
            if (_buf === "") return
            try {
                const j   = JSON.parse(_buf.trim())
                root._lan  = j.lan  ?? "0.0.0.0"
                root._wg   = j.wg   ?? "0.0.0.0"
                root._wlan = j.wlan ?? "0.0.0.0"
                root._vpn  = j.vpn  ?? false
            } catch(e) {
                root._lan  = "0.0.0.0"
                root._wg   = "0.0.0.0"
                root._wlan = "0.0.0.0"
                root._vpn  = false
            }
            _buf = ""
        }
    }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: if (!proc.running) proc.running = true
    }

    Component.onCompleted: proc.running = true

    // ── Background pill ───────────────────────────────────────────────────
    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:       8
        color:        _vpn ? theme.a(theme.accent, 0.14) : theme.a(theme.primary, 0.06)
        border.color: _vpn ? theme.a(theme.accent, 0.35) : theme.a(theme.primary, 0.14)
        border.width: 1
        Behavior on color        { ColorAnimation { duration: 300 } }
        Behavior on border.color { ColorAnimation { duration: 300 } }
    }

    // ── Content ───────────────────────────────────────────────────────────
    Row {
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 0

        // Base icon — always visible
        Text {
            id: baseIcon
            anchors.verticalCenter: parent.verticalCenter
            text:           Icons.ipGlobe
            font.family:    "FiraCode Nerd Font Mono"
            font.pixelSize: Icons.ipSize
            color:          _vpn ? theme.accent : theme.a(theme.primary, 0.75)
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // Expanded IP list
        Row {
            id: expandRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            opacity: root._hovered ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            IpEntry {
                height:  root.height
                address: root._lan
                active:  root._lan  !== "0.0.0.0"
                vpn:     root._vpn
                theme:   root.theme
            }

            IpEntry {
                height:  root.height
                address: root._wg
                active:  root._wg   !== "0.0.0.0"
                vpn:     root._vpn
                theme:   root.theme
            }

            IpEntry {
                height:  root.height
                address: root._wlan
                active:  root._wlan !== "0.0.0.0"
                vpn:     root._vpn
                theme:   root.theme
            }
        }
    }

    // ── Hover ─────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onEntered:    root._hovered = true
        onExited:     root._hovered = false
    }
}
