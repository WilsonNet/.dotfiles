import QtQuick
import Quickshell
import Quickshell.Io
import qs

Pill {
    id: root

    property string mode: ""
    property string label: ""

    bg: {
        switch (root.mode) {
        case "performance":
            return Theme.alpha(Theme.red, 0.75);
        case "balance_performance":
            return Theme.alpha(Theme.peach, 0.75);
        case "balance_power":
            return Theme.alpha(Theme.blue, 0.75);
        default:
            return Theme.alpha(Theme.teal, 0.75);
        }
    }
    interactive: true

    Process {
        id: proc
        command: ["/home/wilsonn/bin/power-mode", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.mode = data.class || "";
                    root.label = data.text || "";
                    root.tooltip = data.tooltip || "";
                } catch (e) {
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Text {
        text: root.label
        color: Theme.base
        font.pixelSize: 18
        font.family: Theme.fontFamily
    }

    onClicked: Quickshell.execDetached(["/home/wilsonn/bin/power-mode", "next"])
}
