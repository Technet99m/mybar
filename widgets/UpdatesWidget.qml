// UpdatesWidget.qml — Pending system update count
// Hidden when there are 0 updates (script outputs nothing in that case).
// Click opens the installer in a kitty terminal.

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property var theme

    visible:        _count !== ""
    implicitWidth:  visible ? content.implicitWidth + 24 : 0
    implicitHeight: parent.height

    property string _count: ""
    property string _class: "green"
    property var    _packages: []

    readonly property bool _alert: _class === "red" || _class === "yellow"

    readonly property color _pillColor:
        _alert ? theme.a(theme.accent, 0.12) : theme.a(theme.primary, 0.06)
    readonly property color _borderColor:
        _alert ? theme.a(theme.accent, 0.40) : theme.a(theme.primary, 0.14)
    readonly property color _textColor:
        _alert ? theme.accent : theme.a(theme.primary, 0.90)

    function refresh() {
        _count = ""
        proc.running = true
    }

    Process {
        id: proc
        property string _buf: ""
        command: ["bash", Qt.resolvedUrl("../scripts/check-updates.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: function(data) { proc._buf += data }
        }
        onRunningChanged: {
            if (!running && _buf !== "") {
                try {
                    const j = JSON.parse(_buf.trim())
                    _count    = j.text     ?? ""
                    _class    = j.class    ?? "green"
                    _packages = j.packages ?? []
                } catch(e) {}
                _buf = ""
            }
        }
    }

    Process {
        id: installer
        command: ["kitty", "--", "yay"]
        onRunningChanged: if (!running) refresh()
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
            text:           Icons.updates
            font.family:    "FiraCode Nerd Font Mono"
            font.pixelSize: Icons.updatesSize
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
        anchors.fill:    parent
        cursorShape:     Qt.PointingHandCursor
        hoverEnabled:    true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.refresh()
            else installer.running = true
        }
        onEntered: tip.show()
        onExited:  tip.hide()
    }

    TooltipContainer {
        id:         tip
        theme:      root.theme
        targetItem: root

        Column {
            spacing: 2

            Text {
                text:           _packages.length + " pending update" + (_packages.length === 1 ? "" : "s")
                color:          root._textColor
                font.family:    "Fira Sans"
                font.pixelSize: 12
                font.weight:    Font.DemiBold
                bottomPadding:  4
            }

            Repeater {
                model: Math.min(root._packages.length, 20)
                Text {
                    text:           root._packages[index]
                    color:          root.theme.a(root.theme.primary, 0.85)
                    font.family:    "FiraCode Nerd Font Mono"
                    font.pixelSize: 12
                }
            }

            Text {
                visible:        root._packages.length > 20
                text:           "… and " + (root._packages.length - 20) + " more"
                color:          root.theme.a(root.theme.primary, 0.5)
                font.family:    "Fira Sans"
                font.pixelSize: 11
                topPadding:     2
            }
        }
    }
}
