// Clock.qml — Date/time pill + calendar tooltip on hover

import QtQuick

Item {
    id: root
    required property var theme

    implicitWidth:  label.implicitWidth + 24
    implicitHeight: parent.height

    property string _now: Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: root._now = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")
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
        text:           root._now
        font.family:    "Fira Sans"
        font.pixelSize: 13
        font.weight:    Font.DemiBold
        color:          theme.a(theme.primary, 0.90)
    }

    // ── Hover ─────────────────────────────────────────────────────────────────
    HoverHandler {
        onHoveredChanged: hovered ? calTip.show() : calTip.hide()
    }

    // ── Calendar tooltip ──────────────────────────────────────────────────────
    TooltipContainer {
        id: calTip
        theme:      root.theme
        targetItem: root


        // Browseable month state — reset to today when tooltip closes
        property int calYear:  new Date().getFullYear()
        property int calMonth: new Date().getMonth()   // 0-indexed

        onVisibleChanged: if (!visible) {
            calYear  = new Date().getFullYear()
            calMonth = new Date().getMonth()
        }

        function prevMonth() {
            if (calMonth === 0) { calMonth = 11; calYear-- } else calMonth--
        }
        function nextMonth() {
            if (calMonth === 11) { calMonth = 0; calYear++ } else calMonth++
        }
        function monthLabel(m) {
            return ["January","February","March","April","May","June",
                    "July","August","September","October","November","December"][m]
        }
        function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
        function firstWeekday(y, m) { return (new Date(y, m, 1).getDay() + 6) % 7 } // Mon=0

        readonly property int _fd:   firstWeekday(calYear, calMonth)
        readonly property int _dim:  daysInMonth(calYear, calMonth)
        readonly property int _size: Math.ceil((_fd + _dim) / 7) * 7

        Column {
            width:   200
            spacing: 8

            // ── Month header ──────────────────────────────────────────────────
            Item {
                width: parent.width; height: 22

                Text {
                    anchors.centerIn: parent
                    text:           calTip.monthLabel(calTip.calMonth) + "  " + calTip.calYear
                    font.family:    "Fira Sans"
                    font.pixelSize: 13
                    font.weight:    Font.DemiBold
                    color:          theme.a(theme.primary, 0.95)
                }
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text:           "\uf053"
                    font.family:    "FiraCode Nerd Font Mono"
                    font.pixelSize: 11
                    color:          theme.a(theme.primary, 0.6)
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: calTip.prevMonth()
                    }
                }
                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text:           "\uf054"
                    font.family:    "FiraCode Nerd Font Mono"
                    font.pixelSize: 11
                    color:          theme.a(theme.primary, 0.6)
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: calTip.nextMonth()
                    }
                }
            }

            // ── Day-of-week headers ───────────────────────────────────────────
            Row {
                spacing: 3
                Repeater {
                    model: ["M","T","W","T","F","S","S"]
                    Text {
                        width: 26; height: 16
                        text:                modelData
                        horizontalAlignment: Text.AlignHCenter
                        font.family:    "Fira Sans"
                        font.pixelSize: 11
                        font.weight:    Font.DemiBold
                        color: index >= 5 ? theme.a(theme.primary, 0.45)
                                          : theme.a(theme.primary, 0.55)
                    }
                }
            }

            // ── Day grid ──────────────────────────────────────────────────────
            Grid {
                columns:       7
                columnSpacing: 3
                rowSpacing:    2

                Repeater {
                    model: calTip._size

                    Rectangle {
                        width: 26; height: 20
                        radius: 4

                        property int  day:     index - calTip._fd + 1
                        property bool isEmpty: index < calTip._fd || day > calTip._dim
                        property bool isToday: {
                            if (isEmpty) return false
                            root._now  // reactive dependency — re-evaluates every second
                            var n = new Date()
                            return day === n.getDate()
                                && calTip.calMonth === n.getMonth()
                                && calTip.calYear  === n.getFullYear()
                        }
                        property bool isWeekend: !isEmpty && (index % 7) >= 5

                        color: isToday ? theme.a(theme.primary, 0.28) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text:           parent.isEmpty ? "" : parent.day
                            font.family:    "Fira Sans"
                            font.pixelSize: 12
                            color: parent.isToday   ? theme.primary
                                 : parent.isWeekend ? theme.a(theme.primary, 0.5)
                                 : parent.isEmpty   ? "transparent"
                                 :                    theme.a(theme.primary, 0.85)
                        }
                    }
                }
            }
        }
    }
}
