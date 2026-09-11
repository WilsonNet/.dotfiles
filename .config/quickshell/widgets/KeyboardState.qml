import QtQuick
import qs

Pill {
    id: root

    bg: Theme.alpha(Theme.lavender, 0.75)
    tooltip: `Caps Lock: ${HyprDevices.capsLock ? "on" : "off"}\nNum Lock: ${HyprDevices.numLock ? "on" : "off"}`

    Row {
        spacing: 0

        Item {
            implicitWidth: capsText.implicitWidth + 10
            implicitHeight: capsText.implicitHeight

            Rectangle {
                anchors.fill: parent
                color: Theme.surface0
                visible: HyprDevices.capsLock
            }

            Text {
                id: capsText
                anchors.centerIn: parent
                text: "Caps " + (HyprDevices.capsLock ? "\uF023" : "\uF09C")
                color: Theme.base
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
            }
        }

        Item {
            implicitWidth: numText.implicitWidth + 10
            implicitHeight: numText.implicitHeight

            Rectangle {
                anchors.fill: parent
                color: Theme.surface0
                visible: HyprDevices.numLock
            }

            Text {
                id: numText
                anchors.centerIn: parent
                text: "Num " + (HyprDevices.numLock ? "\uF023" : "\uF09C")
                color: Theme.base
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
            }
        }
    }
}
