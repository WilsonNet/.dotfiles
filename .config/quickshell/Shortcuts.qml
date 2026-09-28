import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs

// Modal cheat sheet with every hyprctl bind that has a description
// (hyprland.lua sets them as "Group · Label"). Toggled by SUPER + slash;
// Esc, clicking the backdrop or the same shortcut again closes it.
PanelWindow {
    id: root

    property bool shown: false
    property var targetScreen: null
    property var columns: []
    property int shortcutCount: 0

    readonly property int columnWidth: 380
    readonly property int rowHeight: 20

    function open() {
        const monitor = Hyprland.focusedMonitor;
        root.targetScreen = monitor ? Quickshell.screens.find(s => s.name === monitor.name) : null;
        root.shown = true;
    }

    function close() {
        root.shown = false;
    }

    function toggle() {
        if (root.shown)
            root.close();
        else
            root.open();
    }

    function modifierNames(mask) {
        const names = [];
        if (mask & 64)
            names.push("SUPER");
        if (mask & 4)
            names.push("CTRL");
        if (mask & 8)
            names.push("ALT");
        if (mask & 1)
            names.push("SHIFT");
        return names;
    }

    function prettyKey(key) {
        const special = {
            "RETURN": "Enter",
            "slash": "/",
            "down": "↓",
            "up": "↑",
            "left": "←",
            "right": "→",
            "mouse_down": "Scroll ↓",
            "mouse_up": "Scroll ↑",
            "mouse:272": "Left mouse",
            "mouse:273": "Right mouse",
            "XF86AudioRaiseVolume": "Vol +",
            "XF86AudioLowerVolume": "Vol −",
            "XF86AudioMute": "Mute",
            "XF86AudioMicMute": "Mic mute",
            "XF86MonBrightnessUp": "Bright +",
            "XF86MonBrightnessDown": "Bright −",
            "XF86AudioNext": "Next",
            "XF86AudioPrev": "Prev",
            "XF86AudioPlay": "Play",
            "XF86AudioPause": "Pause"
        };
        if (special[key] !== undefined)
            return special[key];
        if (key.length === 1)
            return key.toUpperCase();
        return key;
    }

    function keyCaps(bind) {
        const caps = root.modifierNames(bind.modmask);
        caps.push(root.prettyKey(bind.key));
        return caps;
    }

    function parseBinds(text) {
        let entries = [];
        try {
            for (const bind of JSON.parse(text)) {
                if (!bind.has_description || !bind.description || bind.submap !== "")
                    continue;
                const sep = bind.description.indexOf("·");
                entries.push({
                    group: sep >= 0 ? bind.description.slice(0, sep).trim() : "Other",
                    label: sep >= 0 ? bind.description.slice(sep + 1).trim() : bind.description.trim(),
                    keys: root.keyCaps(bind)
                });
            }
        } catch (e) {
            entries = [];
        }
        root.shortcutCount = entries.length;
        root.columns = root.buildColumns(entries);
    }

    // Greedy longest-processing-time schedule: fill the currently shortest
    // column (weighted by rows) so the columns end up roughly equal height.
    function buildColumns(entries) {
        const groups = [];
        const byName = ({});
        for (const entry of entries) {
            let group = byName[entry.group];
            if (!group) {
                group = { name: entry.group, entries: [] };
                byName[entry.group] = group;
                groups.push(group);
            }
            group.entries.push(entry);
        }

        // Largest groups first: the greedy schedule balances far better when
        // the tall columns (Workspaces) are placed before the small ones.
        groups.sort((a, b) => b.entries.length - a.entries.length);

        const columnCount = root.width > 1300 ? 3 : 2;
        const columns = [];
        const weights = [];
        for (let i = 0; i < columnCount; i++) {
            columns.push([]);
            weights.push(0);
        }
        for (const group of groups) {
            let shortest = 0;
            for (let i = 1; i < columnCount; i++) {
                if (weights[i] < weights[shortest])
                    shortest = i;
            }
            columns[shortest].push(group);
            weights[shortest] += group.entries.length + 2;
        }
        return columns.filter(c => c.length > 0);
    }

    screen: root.targetScreen
    visible: root.shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell-shortcuts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Process {
        id: bindsProcess

        command: ["hyprctl", "binds", "-j"]
        running: root.shown

        stdout: StdioCollector {
            onStreamFinished: root.parseBinds(this.text)
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.close()
    }

    Rectangle {
        id: backdrop

        anchors.fill: parent
        color: Theme.alpha(Theme.crust, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(1260, parent.width - 80)
        height: Math.min(840, parent.height - 80)
        radius: 14
        color: Theme.alpha(Theme.base, 0.97)
        border.width: 1
        border.color: Theme.surface1
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.98

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Keyboard shortcuts"
                    color: Theme.text
                    font.pixelSize: 19
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.shortcutCount + " binds"
                    color: Theme.subtext
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: flick

                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: grid.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: grid

                        spacing: 18

                        Repeater {
                            model: root.columns

                            delegate: Column {
                                required property var modelData

                                spacing: 16
                                width: root.columnWidth

                                Repeater {
                                    model: modelData

                                    delegate: Rectangle {
                                        required property var modelData

                                        width: parent.width
                                        implicitHeight: groupColumn.implicitHeight + 26
                                        radius: 10
                                        color: Theme.alpha(Theme.surface0, 0.4)

                                        Column {
                                            id: groupColumn

                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                top: parent.top
                                                margins: 13
                                            }
                                            spacing: 7

                                            Text {
                                                text: modelData.name
                                                color: Theme.mauve
                                                font.pixelSize: 13
                                                font.bold: true
                                                font.family: Theme.fontFamily
                                            }

                                            Repeater {
                                                model: modelData.entries

                                                delegate: Item {
                                                    required property var modelData

                                                    width: groupColumn.width
                                                    height: root.rowHeight

                                                    Text {
                                                        id: label

                                                        width: parent.width - caps.width - 8
                                                        text: modelData.label
                                                        color: Theme.subtext
                                                        font.pixelSize: 13
                                                        font.family: Theme.fontFamily
                                                        elide: Text.ElideRight
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    Row {
                                                        id: caps

                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: 3

                                                        Repeater {
                                                            model: modelData.keys

                                                            delegate: Rectangle {
                                                                required property string modelData

                                                                width: capText.implicitWidth + 9
                                                                height: root.rowHeight
                                                                radius: 4
                                                                color: Theme.surface0

                                                                Text {
                                                                    id: capText

                                                                    anchors.centerIn: parent
                                                                    text: modelData
                                                                    color: Theme.lavender
                                                                    font.pixelSize: 11
                                                                    font.bold: true
                                                                    font.family: Theme.fontFamily
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    width: 4
                    radius: 2
                    color: Theme.surface1
                    visible: flick.contentHeight > flick.height
                    y: flick.visibleArea.yPosition * flick.height
                    height: Math.max(28, flick.visibleArea.heightRatio * flick.height)
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "SUPER + / toggles · Esc or click outside to close"
                color: Theme.subtext
                font.pixelSize: 12
                font.family: Theme.fontFamily
            }
        }
    }
}
