// UpdatesWidget.qml — Pending system update count
// Hidden when there are 0 updates (script outputs nothing in that case).
// Click opens the installer in a kitty terminal.

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    visible:        _count !== ""
    implicitWidth:  visible ? content.implicitWidth + 24 : 0
    implicitHeight: parent.height

    property string _count: ""
    property string _class: "green"

    readonly property color _pillColor: {
        if (_class === "red")    return theme.a(Qt.color("#e06060"), 0.18)
        if (_class === "yellow") return theme.a(Qt.color("#e0b860"), 0.18)
        return theme.a(theme.primary, 0.06)
    }
    readonly property color _borderColor: {
        if (_class === "red")    return theme.a(Qt.color("#e06060"), 0.50)
        if (_class === "yellow") return theme.a(Qt.color("#e0b860"), 0.45)
        return theme.a(theme.primary, 0.14)
    }
    readonly property color _textColor: {
        if (_class === "red")    return Qt.color("#e06060")
        if (_class === "yellow") return Qt.color("#e0b860")
        return theme.a(theme.primary, 0.90)
    }

    function refresh() {
        _count = ""
        proc.running = true
    }

    Process {
        id: proc
        property string _buf: ""
        command: ["bash", "-c", "$HOME/dev/rice/mybar/scripts/check-updates.sh"]
        stdout: SplitParser {
            onRead: function(data) { proc._buf += data }
        }
        onRunningChanged: {
            if (!running && _buf !== "") {
                try {
                    const j = JSON.parse(_buf.trim())
                    _count = j.text  ?? ""
                    _class = j.class ?? "green"
                } catch(e) {}
                _buf = ""
            }
        }
    }

    Process {
        id: installer
        command: ["bash", "-c", "~/.config/ml4w/settings/installupdates.sh"]
    }

    Timer {
        interval: 1800000
        running:  true
        repeat:   true
        onTriggered: refresh()
    }

    Component.onCompleted: refresh()

    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        visible:      parent.visible
        radius:       8
        color:        _pillColor
        border.color: _borderColor
        border.width: 1

        Behavior on color        { ColorAnimation { duration: 300 } }
        Behavior on border.color { ColorAnimation { duration: 300 } }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 7

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           "\uf487"
            font.family:    "FiraCode Nerd Font Mono"
            font.pixelSize: 18
            color:          _textColor

            Behavior on color { ColorAnimation { duration: 300 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           root._count
            font.family:    "Fira Sans"
            font.pixelSize: 13
            font.weight:    Font.DemiBold
            color:          _textColor

            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    installer.running = true
    }
}
