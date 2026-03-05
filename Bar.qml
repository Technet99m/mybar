// Bar.qml
// Bottom panel bar — one instance is created per screen via Variants in shell.qml.

import Quickshell
import QtQuick
import QtQuick.Layouts
import "./widgets"

PanelWindow {
    id: root

    // Provided by Variants in shell.qml — the screen this bar lives on
    required property var modelData
    screen: modelData

    anchors {
        left:   true
        right:  true
        bottom: true
    }

    implicitHeight: 36

    // Bar background uses the theme's on_primary (typically dark)
    color: theme.surface

    // ── Theme ───────────────────────────────────────────────────────────────
    Theme { id: theme }

    // ── Layout ──────────────────────────────────────────────────────────────
    // Three sections: left, center, right.
    // Center is truly centered regardless of left/right content widths.
    Item {
        anchors {
            fill:        parent
            leftMargin:  4
            rightMargin: 4
        }

        // ── Left ────────────────────────────────────────────────────────────
        Row {
            anchors {
                left:           parent.left
                verticalCenter: parent.verticalCenter
            }
            spacing: 4

            Workspaces {
                height: root.height
                screen: root.modelData
                theme:  theme
            }
        }

        // ── Center ──────────────────────────────────────────────────────────
        Row {
            anchors.centerIn: parent
            spacing: 4

            Clock {
                height: root.height
                theme:  theme
            }

            IpWidget {
                height: root.height
                theme:  theme
            }

            MemoryWidget {
                height: root.height
                theme:  theme
            }
        }

        // ── Right ───────────────────────────────────────────────────────────
        Row {
            anchors {
                right:          parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 4

            UpdatesWidget {
                height: root.height
                theme:  theme
            }
        }
    }
}
