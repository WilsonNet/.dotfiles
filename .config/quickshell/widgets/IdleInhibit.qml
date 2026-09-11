import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

Pill {
    id: root

    property bool inhibited: false

    bg: inhibited ? Theme.alpha(Theme.rosewater, 0.75) : Theme.alpha(Theme.surface0, 0.6)
    interactive: true
    tooltip: root.inhibited ? "Keeping the system awake" : "Allow the system to sleep"

    IdleInhibitor {
        window: root.QsWindow.window
        enabled: root.inhibited
    }

    Text {
        text: root.inhibited ? "\u2615" : "\u{1F4A4}"
        color: root.inhibited ? Theme.base : Theme.text
        font.pixelSize: 18
        font.family: Theme.fontFamily
    }

    onClicked: root.inhibited = !root.inhibited
}
