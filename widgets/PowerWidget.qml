// PowerWidget.qml — Power menu / lock screen button
// Left-click: wlogout power menu
// Right-click: hyprlock (lock screen)

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    implicitWidth:  implicitHeight
    implicitHeight: parent.height

    property bool _hovered: false

    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:       8
        color:        root._hovered
                        ? theme.a(theme.accent, 0.18)
                        : theme.a(theme.primary, 0.06)
        border.color: root._hovered
                        ? theme.a(theme.accent, 0.50)
                        : theme.a(theme.primary, 0.14)
        border.width: 1
        Behavior on color        { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text:           Icons.powerOff
        font.family:    "FiraCode Nerd Font Mono"
        font.pixelSize: Icons.powerSize
        color:          root._hovered
                            ? theme.accent
                            : theme.a(theme.primary, 0.75)
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill:    parent
        hoverEnabled:    true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape:     Qt.PointingHandCursor
        onEntered:       root._hovered = true
        onExited:        root._hovered = false
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton)
                wlogoutProc.running = true
            else
                hyprlockProc.running = true
        }
    }

    Process { id: wlogoutProc;  command: ["bash", Qt.resolvedUrl("../scripts/wlogout.sh").toString().replace("file://", "")] }
    Process { id: hyprlockProc; command: ["hyprlock"] }
}
