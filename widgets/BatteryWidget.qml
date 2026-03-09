// BatteryWidget.qml — Battery level and charge status pill
// Hover expands to reveal remaining/charge time.
// States: Charging (plug/bolt), Full (plug), Discharging (level icon)
// Warning <30%: accent  Critical <15%: accent (brighter)

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    implicitWidth:  content.implicitWidth + 24
    implicitHeight: parent.height

    // ── State ────────────────────────────────────────────────────────────────
    property int    _capacity: 0
    property string _status:   "Unknown"
    property string _time:     ""
    property bool   _hovered:  false

    // ── Derived ──────────────────────────────────────────────────────────────
    readonly property bool _charging: _status === "Charging"
    readonly property bool _full:     _status === "Full"
    readonly property bool _critical: !_charging && !_full && _capacity < 15
    readonly property bool _warning:  !_charging && !_full && !_critical && _capacity < 30

    readonly property color _textColor:
        (_critical || _warning) ? theme.accent : theme.primary

    readonly property color _pillColor:
        (_critical || _warning) ? theme.a(theme.accent, 0.10)
        : theme.a(theme.primary, 0.06)

    readonly property color _borderColor:
        (_critical || _warning) ? theme.a(theme.accent, 0.35)
        : theme.a(theme.primary, 0.14)

    // ── Polling (30 s) ────────────────────────────────────────────────────
    Process {
        id: proc
        property string _buf: ""
        command: ["bash", Qt.resolvedUrl("../scripts/battery-status.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: function(data) { proc._buf += data }
        }
        onRunningChanged: {
            if (running) return
            if (_buf === "") return
            try {
                const j        = JSON.parse(_buf.trim())
                root._capacity = j.capacity ?? 0
                root._status   = j.status   ?? "Unknown"
                root._time     = j.time     ?? ""
            } catch(e) {}
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
        color:        root._pillColor
        border.color: root._borderColor
        border.width: 1
        Behavior on color        { ColorAnimation { duration: 400 } }
        Behavior on border.color { ColorAnimation { duration: 400 } }
    }

    // ── Content ───────────────────────────────────────────────────────────
    Row {
        id: content
        anchors.centerIn: parent
        spacing: 0

        // Always-visible: icon + percentage
        Row {
            id: baseRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (root._full)           return Icons.batteryPlugged
                    if (root._charging)       return Icons.batteryCharging
                    if (root._capacity >= 88) return Icons.batteryFull
                    if (root._capacity >= 63) return Icons.batteryThreeQuarter
                    if (root._capacity >= 38) return Icons.batteryHalf
                    if (root._capacity >= 13) return Icons.batteryQuarter
                    return                          Icons.batteryEmpty
                }
                font.family:    "FiraCode Nerd Font Mono"
                font.pixelSize: root._full     ? Icons.batteryPluggedSize
                              : root._charging ? Icons.batteryChargingSize
                              : Icons.batterySize
                color:          theme.a(root._textColor, 0.90)
                Behavior on color { ColorAnimation { duration: 400 } }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           root._capacity + "%"
                font.family:    "Fira Sans"
                font.pixelSize: 13
                font.weight:    Font.DemiBold
                color:          theme.a(root._textColor, 0.90)
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }

        // Spacer + separator — only visible on hover
        Item { width: 6; height: 1 }

        Rectangle {
            width: 1; height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: theme.a(root._textColor, 0.25)
            opacity: root._hovered ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on color   { ColorAnimation  { duration: 400 } }
        }

        // Expandable time section — slides in on hover
        Item {
            id: timeSection
            clip:   true
            height: root.height
            width:  (root._hovered && root._time !== "") ? timeLabel.implicitWidth + 8 : 0

            Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Text {
                id: timeLabel
                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                text:           root._time
                font.family:    "Fira Sans"
                font.pixelSize: 13
                font.weight:    Font.DemiBold
                color:          theme.a(root._textColor, 0.75)
                opacity:        root._hovered ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }

    // ── Hover detection ───────────────────────────────────────────────────
    MouseArea {
        anchors.fill:  parent
        hoverEnabled:  true
        cursorShape:   Qt.PointingHandCursor
        onEntered:     root._hovered = true
        onExited:      root._hovered = false
    }
}
