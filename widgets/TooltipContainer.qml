// TooltipContainer.qml — Generic tooltip popup container
// Tweak contentPadding, animDuration, bgOpacity here to affect all tooltips at once.
//
// Usage in a widget:
//   TooltipContainer {
//       id: tip
//       theme:      root.theme
//       targetItem: root
//       hostWindow: QsWindow.window
//       Column { ... }   // content goes here
//   }
//   HoverHandler { onHoveredChanged: hovered ? tip.show() : tip.hide() }

import Quickshell
import QtQuick

PopupWindow {
    id: root

    required property var  theme
    required property Item targetItem

    // ── Tweak these to adjust all tooltips at once ────────────────────────────
    property int  contentPadding: 12
    property int  animDuration:   160
    property real bgOpacity:      0.95

    // ── Content slot ──────────────────────────────────────────────────────────
    default property alias content: contentHost.data

    // ── Size: driven by content (contentHost is unanchored — no binding loop) ─
    implicitWidth:  contentHost.childrenRect.width  + contentPadding * 2
    implicitHeight: contentHost.childrenRect.height + contentPadding * 2

    // ── Position: anchored below targetItem via Quickshell anchor API ──────────
    anchor.item:    targetItem
    anchor.edges:   Edges.Bottom
    anchor.gravity: Edges.Bottom

    // ── Visibility (PopupWindow has no opacity — animate an inner Item) ────────
    visible: false
    color:   "transparent"

    function show() {
        hideDelay.stop()
        fadeOut.stop()
        visible = true
        fadeIn.restart()
    }

    function hide() {
        hideDelay.restart()
    }

    Timer {
        id: hideDelay
        interval: 300
        onTriggered: { fadeIn.stop(); fadeOut.restart() }
    }

    // Fading layer — opacity lives here, not on the window
    Item {
        id: fader

        // Cancel pending hide when mouse enters the tooltip window
        HoverHandler {
            onHoveredChanged: if (hovered) root.show(); else hideDelay.restart()
        }
        anchors.fill: parent
        opacity: 0

        NumberAnimation {
            id: fadeIn
            target: fader; property: "opacity"
            to: 1; duration: root.animDuration; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: fadeOut
            target: fader; property: "opacity"
            to: 0; duration: root.animDuration; easing.type: Easing.InCubic
            onFinished: root.visible = false
        }

        // ── Background ────────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius:       10
            color:        theme.a(theme.surface, root.bgOpacity)
            border.color: theme.a(theme.primary, 0.22)
            border.width: 1
        }

        // ── Content host — unanchored so childrenRect reflects content size ────
        Item {
            id:  contentHost
            x:   root.contentPadding
            y:   root.contentPadding
        }
    }
}
