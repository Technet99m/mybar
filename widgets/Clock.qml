// Clock.qml — Date and time pill for the center section

import QtQuick

Item {
    id: root
    required property var theme

    implicitWidth:  label.implicitWidth + 24
    implicitHeight: parent.height

    property string _now: Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: parent._now = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")
    }

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
}
