import QtQuick
import Quickshell
import Quickshell.Io
import qs

Pill {
    id: root

    readonly property var icons: ["\uE38D", "\uE3D3", "\uE3D1", "\uE3CF", "\uE3CE", "\uE3CD", "\uE3CA", "\uE3C8", "\uE39B"]

    property int brightness: 0
    property int maxBrightness: 1

    readonly property int percent: Math.round(brightness * 100 / Math.max(1, maxBrightness))
    readonly property string icon: icons[Math.min(icons.length - 1, Math.floor(percent / 100 * icons.length))]

    bg: Theme.alpha(Theme.sky, 0.75)
    interactive: true
    tooltip: `Brightness ${root.percent}%`

    FileView {
        id: maxFile
        path: "/sys/class/backlight/acpi_video0/max_brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.maxBrightness = parseInt(maxFile.text()) || 1
    }

    FileView {
        id: brightnessFile
        path: "/sys/class/backlight/acpi_video0/brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.brightness = parseInt(brightnessFile.text()) || 0
    }

    Text {
        text: `${root.percent}% ${root.icon}`
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    onScrolled: (delta) => Quickshell.execDetached(["brightnessctl", "s", delta > 0 ? "5%+" : "5%-"])
}
