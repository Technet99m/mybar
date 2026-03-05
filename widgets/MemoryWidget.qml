// MemoryWidget.qml — RAM usage

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    implicitWidth:  label.implicitWidth + 24
    implicitHeight: parent.height

    property string _value: "..."

    Process {
        id: proc
        command: ["bash", "-c", "$HOME/dev/rice/mybar/scripts/memory.sh"]
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const j = JSON.parse(data.trim())
                    _value = j.text ?? "..."
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 2000
        running:  true
        repeat:   true
        onTriggered: proc.running = true
    }

    Component.onCompleted: proc.running = true

    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:       8
        color:        theme.a(theme.primary, 0.06)
        border.color: theme.a(theme.primary, 0.14)
        border.width: 1
    }

    Text {
        id: label
        anchors.centerIn: parent
        text:           root._value
        font.family:    "Fira Sans"
        font.pixelSize: 13
        font.weight:    Font.DemiBold
        color:          theme.a(theme.primary, 0.90)
    }
}
