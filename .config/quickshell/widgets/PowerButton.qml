import QtQuick
import Quickshell
import qs

Pill {
    id: root

    bg: Theme.alpha(Theme.red, 0.75)
    interactive: true
    hoverUnderline: false

    readonly property var entries: [
        { label: "Shutdown", command: ["systemctl", "poweroff"] },
        { label: "Reboot", command: ["systemctl", "reboot"] },
        { label: "Suspend", command: ["systemctl", "suspend"] },
        { label: "Hibernate", command: ["systemctl", "hibernate"] }
    ]

    Text {
        text: "\u23FB"
        color: Theme.base
        font.pixelSize: 22
        font.family: Theme.fontFamily
    }

    onClicked: powerMenu.open = !powerMenu.open

    BarPopup {
        id: powerMenu

        anchorItem: root

        Column {
            Repeater {
                model: root.entries

                delegate: Item {
                    id: entryItem

                    required property var modelData

                    implicitWidth: 150
                    implicitHeight: 32

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.pillRadius
                        color: entryMouse.containsMouse ? Theme.surface0 : "transparent"
                    }

                    Text {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 12
                        }
                        text: entryItem.modelData.label
                        color: Theme.text
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: entryMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(entryItem.modelData.command);
                            powerMenu.close();
                        }
                    }
                }
            }
        }
    }
}
