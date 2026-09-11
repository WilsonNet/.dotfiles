import QtQuick
import Quickshell.Io
import qs

Pill {
    id: root

    readonly property var icons: ["\uF76B", "\uF2C9", "\uF769"]
    property int criticalThreshold: 80
    property int milliC: 0

    readonly property int tempC: Math.round(milliC / 1000)
    readonly property bool critical: tempC >= criticalThreshold
    readonly property string icon: tempC >= 70 ? icons[2] : (tempC >= 45 ? icons[1] : icons[0])

    bg: critical ? Theme.alpha(Theme.red, 0.75) : Theme.alpha(Theme.yellow, 0.75)
    tooltip: `${root.tempC}\u00B0C \u00B7 critical at ${root.criticalThreshold}\u00B0C`

    FileView {
        id: tempFile
        path: "/sys/class/thermal/thermal_zone0/temp"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.milliC = parseInt(tempFile.text()) || 0
    }

    Text {
        text: `${root.tempC}\u00B0C ${root.icon}`
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }
}
