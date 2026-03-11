// Workspaces.qml
// Shows 10 persistent workspace indicators on the left side of the bar.
// - Active workspace is highlighted with the theme primary color
// - Occupied workspaces show their number at full opacity
// - Empty workspaces show their number dimmed
// Scroll up/down on the widget cycles through workspaces.

import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    required property var   screen   // QuickshellScreenInfo from Bar
    required property var   theme    // Theme instance from Bar

    // Find the Hyprland monitor that corresponds to this screen
    readonly property var hyprMonitor: {
        const mons = Hyprland.monitors.values
        for (let i = 0; i < mons.length; i++) {
            if (mons[i].name === screen.name)
                return mons[i]
        }
        return null
    }

    readonly property int activeId: hyprMonitor?.activeWorkspace?.id ?? -1

    // Total widget width: pill content + horizontal padding
    implicitWidth: row.implicitWidth + 16

    // Pill background
    Rectangle {
        anchors {
            fill: parent
            topMargin:    4
            bottomMargin: 4
        }
        radius: 8
        color:        theme.a(theme.primary, 0.06)
        border.color: theme.a(theme.primary, 0.14)
        border.width: 1
    }

    // Workspace buttons
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: 10

            delegate: Rectangle {
                id: wsBtn

                required property int index

                readonly property int  wsId:       index + 1
                readonly property bool isActive:   wsId === root.activeId
                readonly property bool isOccupied: {
                    const wss = Hyprland.workspaces.values
                    for (let i = 0; i < wss.length; i++) {
                        if (wss[i].id === wsId) return true
                    }
                    return false
                }

                property bool hovered: false

                width:  isActive ? 28 : 24
                height: 24
                radius: 6

                color: isActive
                    ? theme.a(theme.primary, 0.20)
                    : hovered
                        ? theme.a(theme.primary, 0.10)
                        : "transparent"

                border.color: isActive
                    ? theme.a(theme.primary, 0.40)
                    : hovered
                        ? theme.a(theme.primary, 0.20)
                        : "transparent"
                border.width: 1

                Behavior on width {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Text {
                    anchors.centerIn: parent
                    text: wsBtn.wsId
                    font.family:    "Fira Sans"
                    font.pixelSize: 12
                    font.weight:    wsBtn.isActive ? Font.Bold : Font.Medium
                    color: wsBtn.isActive
                           ? theme.primary
                           : wsBtn.isOccupied
                               ? theme.a(theme.primary, 0.65)
                               : theme.a(theme.primary, 0.28)
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked:  Hyprland.dispatch("workspace " + wsBtn.wsId)
                    onEntered:  wsBtn.hovered = true
                    onExited:   wsBtn.hovered = false
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0)
                            Hyprland.dispatch("workspace r-1")
                        else
                            Hyprland.dispatch("workspace r+1")
                    }
                }
            }
        }
    }
}
