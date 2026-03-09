// MemoryWidget.qml — RAM usage pill + per-process breakdown tooltip on hover

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    implicitWidth:  label.implicitWidth + 24
    implicitHeight: parent.height

    property string _value: "..."
    property var    _procs: []

    // ── Main usage (display text) ─────────────────────────────────────────────
    Process {
        id: proc
        command: ["bash", Qt.resolvedUrl("../scripts/memory.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: function(data) {
                try { _value = JSON.parse(data.trim()).text ?? "..." } catch(e) {}
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: proc.running = true
    }

    Component.onCompleted: proc.running = true

    // ── Top-processes (tooltip data) ──────────────────────────────────────────
    Process {
        id: procTop
        command: ["bash", Qt.resolvedUrl("../scripts/memory-top.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: function(data) {
                try { _procs = JSON.parse(data.trim()) } catch(e) {}
            }
        }
    }

    // Refresh every 3 s while tooltip is visible
    Timer {
        interval: 3000
        running:  memTip.visible
        repeat:   true
        onTriggered: procTop.running = true
    }

    // ── Pill ─────────────────────────────────────────────────────────────────
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

    // ── Hover ─────────────────────────────────────────────────────────────────
    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                procTop.running = true   // fetch immediately on open
                memTip.show()
            } else {
                memTip.hide()
            }
        }
    }

    // ── Memory tooltip ────────────────────────────────────────────────────────
    TooltipContainer {
        id: memTip
        theme:      root.theme
        targetItem: root


        Column {
            width:   240
            spacing: 6

            // Header
            Text {
                width:          parent.width
                text:           "Top processes"
                font.family:    "Fira Sans"
                font.pixelSize: 11
                font.weight:    Font.DemiBold
                color:          theme.a(theme.primary, 0.55)
            }

            // Process rows
            Repeater {
                model: root._procs

                Item {
                    width:  parent.width
                    height: 18

                    // Name
                    Text {
                        id: procName
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        width:          100
                        text:           modelData.name
                        elide:          Text.ElideRight
                        font.family:    "Fira Sans"
                        font.pixelSize: 12
                        color:          theme.a(theme.primary, 0.85)
                    }

                    // Bar track
                    Rectangle {
                        id: barTrack
                        anchors {
                            left:           procName.right
                            leftMargin:     6
                            verticalCenter: parent.verticalCenter
                        }
                        width:  80; height: 4; radius: 2
                        color:  theme.a(theme.primary, 0.15)

                        Rectangle {
                            // cap at 100% using 30% RAM as "full bar"
                            width:  Math.round(parent.width * Math.min(modelData.pct / 30, 1))
                            height: parent.height
                            radius: parent.radius
                            color:  theme.a(theme.primary, 0.7)
                        }
                    }

                    // MB value
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text:           modelData.mb + " MB"
                        font.family:    "Fira Sans"
                        font.pixelSize: 11
                        color:          theme.a(theme.primary, 0.6)
                    }
                }
            }
        }
    }
}
