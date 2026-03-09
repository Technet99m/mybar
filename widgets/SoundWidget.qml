// SoundWidget.qml — Volume, mic, and bluetooth status pill
// - Volume icon + percentage (red when muted, headphone icon when BT audio active)
// - Mic icon (red when muted)
// - Bluetooth icon (hidden when adapter off, blue when connected/active)
// Left-click: pavucontrol  Right-click: bluetooth manager  Scroll: adjust volume

import QtQuick
import Quickshell.Io

Item {
    id: root
    required property var theme

    implicitWidth:  content.implicitWidth + 24
    implicitHeight: parent.height

    // ── State ────────────────────────────────────────────────────────────────
    property int    _volume:   50
    property bool   _muted:    false
    property bool   _micMuted: false
    property bool   _headset:  false   // true when default sink is bluez
    property string _btStatus: "off"   // "off" | "on" | "connected"
    property bool   _btActive: false   // true when bluez is default sink

    // ── Derived ──────────────────────────────────────────────────────────────
    readonly property color _volColor:
        _muted ? theme.accent : theme.a(theme.primary, 0.90)

    readonly property color _micColor:
        _micMuted ? theme.accent : theme.a(theme.primary, 0.90)

    readonly property color _btColor: {
        if (_btActive)                 return theme.accent
        if (_btStatus === "connected") return theme.a(theme.primary, 0.85)
        if (_btStatus === "on")        return theme.a(theme.primary, 0.45)
        return                                theme.a(theme.primary, 0.20) // off — very dim
    }

    // ── Sound polling (1 s) ───────────────────────────────────────────────
    Process {
        id: soundProc
        property string _buf: ""
        command: ["bash", Qt.resolvedUrl("../scripts/sound-status.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: function(data) { soundProc._buf += data }
        }
        onRunningChanged: {
            if (running) return
            if (_buf === "") return
            try {
                const j        = JSON.parse(_buf.trim())
                root._volume   = j.volume    ?? 50
                root._muted    = j.muted     ?? false
                root._micMuted = j.mic_muted ?? false
                root._headset  = j.headset   ?? false
            } catch(e) {}
            _buf = ""
        }
    }

    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: if (!soundProc.running) soundProc.running = true
    }

    // ── Bluetooth polling (5 s) ───────────────────────────────────────────
    Process {
        id: btProc
        property string _buf: ""
        command: ["bash", Qt.resolvedUrl("../scripts/bluetooth-status.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: function(data) { btProc._buf += data }
        }
        onRunningChanged: {
            if (running) return
            if (_buf === "") return
            try {
                const j        = JSON.parse(_buf.trim())
                root._btStatus = j.status ?? "off"
                root._btActive = j.active ?? false
            } catch(e) {}
            _buf = ""
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: if (!btProc.running) btProc.running = true
    }

    Component.onCompleted: {
        soundProc.running = true
        btProc.running    = true
    }

    // ── Volume scroll processes ───────────────────────────────────────────
    Process {
        id: volUpProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]
        onRunningChanged: if (!running) soundProc.running = true
    }
    Process {
        id: volDownProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
        onRunningChanged: if (!running) soundProc.running = true
    }

    // ── Background pill ───────────────────────────────────────────────────
    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:       8
        color:        theme.a(theme.primary, 0.06)
        border.color: theme.a(theme.primary, 0.14)
        border.width: 1
    }

    // ── Content row ───────────────────────────────────────────────────────
    // Two clickable sections side-by-side inside the pill:
    //   audioSection  |  btSection
    Row {
        id: content
        anchors.centerIn: parent
        spacing: 0

        // ── Audio section (vol + mic) — click opens pavucontrol ────────────
        Item {
            id: audioSection
            height:        root.height
            implicitWidth: audioRow.implicitWidth + 14  // 7px padding each side

            Row {
                id: audioRow
                anchors.centerIn: parent
                spacing: 7

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (root._muted)       return Icons.volOff
                        if (root._headset)     return Icons.headphone
                        if (root._volume < 34) return Icons.volLow
                        return Icons.volHigh
                    }
                    font.family:    "FiraCode Nerd Font Mono"
                    font.pixelSize: Icons.volSize
                    color:          root._volColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           root._muted ? "—" : (root._volume + "%")
                    font.family:    "Fira Sans"
                    font.pixelSize: 13
                    font.weight:    Font.DemiBold
                    color:          root._volColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Rectangle {
                    width: 1; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: theme.a(theme.primary, 0.20)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           root._micMuted ? Icons.micSlash : Icons.micOn
                    font.family:    "FiraCode Nerd Font Mono"
                    font.pixelSize: Icons.micSize
                    color:          root._micColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    pavucontrolProc.running = true
                onWheel: function(wheel) {
                    if (wheel.angleDelta.y > 0) {
                        if (!volUpProc.running)   volUpProc.running   = true
                    } else {
                        if (!volDownProc.running) volDownProc.running = true
                    }
                }
            }
        }

        // ── Bluetooth section — always visible, click opens bluetooth manager ─
        Item {
            id: btSection
            width:  btRow.implicitWidth + 14
            height: root.height

            Row {
                id: btRow
                anchors.centerIn: parent
                spacing: 7

                Rectangle {
                    width: 1; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: theme.a(theme.primary, 0.20)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (root._btActive)                 return Icons.headphone
                        if (root._btStatus === "connected") return Icons.bluetooth
                        return Icons.bluetooth
                    }
                    font.family:    "FiraCode Nerd Font Mono"
                    font.pixelSize: Icons.bluetoothSize
                    color:          root._btColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // "off" label — only shown when adapter is off
                Text {
                    visible:        root._btStatus === "off"
                    width:          visible ? implicitWidth : 0
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "off"
                    font.family:    "Fira Sans"
                    font.pixelSize: 12
                    color:          theme.a(theme.primary, 0.20)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    btManagerProc.running = true
            }
        }
    }

    Process { id: pavucontrolProc; command: ["pavucontrol"] }
    Process { id: btManagerProc;   command: ["blueman-manager"] }
}
