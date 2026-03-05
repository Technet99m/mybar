import QtQuick
import QtCore
import Quickshell.Io

QtObject {
    id: root

    readonly property color primary: Qt.color(primaryHex)
    readonly property color surface: Qt.color(surfaceHex)
    readonly property color accent:  Qt.color(accentHex)

    property string primaryHex: "#c7bfff"
    property string surfaceHex: "#2f285f"
    property string accentHex:  "#c7bfff"

    function a(clr, alpha) {
        return Qt.rgba(clr.r, clr.g, clr.b, alpha)
    }

    // Sources the active theme script and prints the two hex values.
    // Called on startup and whenever the pointer file changes.
    function reload() {
        _reader.running = true
    }

    readonly property Process _reader: Process {
        command: [
            "bash", "-c",
            ". \"$(cat $HOME/.config/ml4w/settings/current-theme)\" 2>/dev/null"
            + " && echo \"$foreground_hex $background_hex $accent_hex\""
        ]
        stdout: SplitParser {
            onRead: function(data) {
                const parts = data.trim().split(" ")
                if (parts.length >= 3) {
                    root.primaryHex = "#" + parts[0]
                    root.surfaceHex = "#" + parts[1]
                    root.accentHex  = "#" + parts[2]
                }
            }
        }
    }

    // Re-run whenever apply.sh writes a new theme path to the pointer file
    readonly property FileView _watcher: FileView {
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation)
              + "/.config/ml4w/settings/current-theme"
        watchChanges: true
        onTextChanged: root.reload()
    }

    Component.onCompleted: reload()
}
