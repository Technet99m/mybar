// IpEntry.qml — Single IP address inside IpWidget's hover-expand section.
// Shows: separator | address
// Inactive (0.0.0.0) entries are faded.

import QtQuick

Item {
    id: root
    required property var    theme
    required property string address
    required property bool   active
    required property bool   vpn

    implicitWidth:  row.implicitWidth + 16
    implicitHeight: parent.height

    readonly property color _fg:
        vpn ? theme.accent : theme.a(theme.primary, 0.90)

    Row {
        id: row
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 8

        Rectangle {
            width: 1; height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: root.vpn
                ? theme.a(theme.accent, 0.30)
                : theme.a(theme.primary, 0.20)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           root.address
            font.family:    "Fira Sans"
            font.pixelSize: 12
            font.weight:    Font.DemiBold
            color:          root._fg
            opacity:        root.active ? 1.0 : 0.25
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
