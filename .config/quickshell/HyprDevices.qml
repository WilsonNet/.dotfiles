pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool capsLock: false
    property bool numLock: false
    property string activeKeymap: ""
    property string layout: ""

    function parse(text) {
        try {
            const devices = JSON.parse(text);
            const main = devices.keyboards.find(k => k.main) || devices.keyboards[0];
            if (main) {
                root.capsLock = main.capsLock;
                root.numLock = main.numLock;
                root.activeKeymap = main.active_keymap || "";
                root.layout = main.layout || "";
            }
        } catch (e) {
        }
    }

    Process {
        id: proc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
