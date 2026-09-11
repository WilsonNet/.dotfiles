import QtQuick
import qs

Pill {
    id: root

    bg: Theme.alpha(Theme.sapphire, 0.75)
    tooltip: HyprDevices.activeKeymap

    Text {
        text: HyprDevices.activeKeymap
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 220)
    }
}
