import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

Item {
    id: root

    readonly property var numerals: ["\u4E00", "\u4E8C", "\u4E09", "\u56DB", "\u4E94", "\u516D", "\u4E03", "\u516B", "\u4E5D", "\u5341"]

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.pillHeight

    function labelFor(id, name) {
        if (id >= 1 && id <= 10)
            return numerals[id - 1];
        return name;
    }

    function workspaceById(id) {
        return Hyprland.workspaces.values.find(ws => ws.id === id) ?? null;
    }

    function workspaceIds() {
        return Hyprland.workspaces.values
            .filter(ws => ws.id > 0)
            .map(ws => ws.id)
            .sort((a, b) => a - b);
    }

    function focusWorkspace(id) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + id + " })"]);
    }

    Row {
        id: row

        anchors.fill: parent

        Repeater {
            id: repeater

            model: root.workspaceIds()

            delegate: Item {
                id: item

                required property int modelData

                readonly property var workspace: root.workspaceById(modelData)
                readonly property bool focused: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === modelData : false
                readonly property bool urgent: workspace !== null && workspace.urgent

                width: label.implicitWidth + 30
                height: row.height

                Rectangle {
                    anchors.fill: parent
                    color: item.urgent ? Theme.red : (item.focused ? Theme.surface1 : (hover.containsMouse ? Theme.surface0 : "transparent"))
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    width: 1
                    height: 16
                    color: Theme.surface0
                    visible: item.index > 0
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    width: 1
                    height: 16
                    color: Theme.surface0
                    visible: item.index < repeater.count - 1
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: root.labelFor(item.modelData, item.workspace ? item.workspace.name : "")
                    color: Theme.text
                    font.pixelSize: 19
                    font.family: Theme.fontFamily
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 3
                    color: Theme.mauve
                    visible: item.focused
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(item.modelData)
                }
            }
        }
    }
}
