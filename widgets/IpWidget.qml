// IpWidget.qml — Local IP with VPN detection

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    implicitWidth:  label.implicitWidth + 24
    implicitHeight: parent.height

    property string _ip:  "..."
    property bool   _vpn: false

    Process {
        id: proc
        command: ["bash", "-c", "$HOME/dev/rice/mybar/scripts/localip.sh"]
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const j    = JSON.parse(data.trim())
                    const match = (j.text ?? "").match(/[\d.]+/)
                    _ip  = match ? match[0] : "..."
                    _vpn = (j.class === "vpn-active")
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 5000
        running:  true
        repeat:   true
        onTriggered: proc.running = true
    }

    Component.onCompleted: proc.running = true

    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:       8
        color:        _vpn ? theme.a(theme.accent, 0.14)  : theme.a(theme.primary, 0.06)
        border.color: _vpn ? theme.a(theme.accent, 0.35)  : theme.a(theme.primary, 0.14)
        border.width: 1

        Behavior on color        { ColorAnimation { duration: 300 } }
        Behavior on border.color { ColorAnimation { duration: 300 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text:           root._ip
        font.family:    "Fira Sans"
        font.pixelSize: 13
        font.weight:    Font.DemiBold
        color:          _vpn ? theme.accent : theme.a(theme.primary, 0.90)

        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
