import QtQuick
import Quickshell.Io
import qs

Pill {
    id: root

    bg: Theme.alpha(Theme.peach, 0.75)

    property real usage: 0
    property real prevTotal: 0
    property real prevIdle: 0
    property bool havePrev: false

    function parse(text) {
        const parts = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = parts[3] + (parts[4] || 0);
        const total = parts.reduce((a, b) => a + b, 0);
        if (havePrev) {
            const dt = total - prevTotal;
            const di = idle - prevIdle;
            if (dt > 0)
                usage = Math.max(0, Math.min(1, 1 - di / dt));
        }
        prevTotal = total;
        prevIdle = idle;
        havePrev = true;
    }

    Process {
        id: statProc
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    Text {
        text: `${Math.round(root.usage * 100)}% \uF2DB`
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }
}
