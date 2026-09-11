import QtQuick
import Quickshell.Io
import qs

Pill {
    id: root

    bg: Theme.alpha(Theme.mauve, 0.75)

    property int percent: 0
    property real totalKb: 0
    property real usedKb: 0

    tooltip: root.totalKb > 0
        ? `${(root.usedKb / 1048576).toFixed(1)} / ${(root.totalKb / 1048576).toFixed(1)} GiB`
        : ""

    function parse(text) {
        let total = 0;
        let available = 0;
        for (const line of text.split("\n")) {
            if (line.startsWith("MemTotal:"))
                total = parseInt(line.split(/\s+/)[1]);
            else if (line.startsWith("MemAvailable:"))
                available = parseInt(line.split(/\s+/)[1]);
        }
        if (total > 0)
            percent = Math.round((total - available) * 100 / total);
        totalKb = total;
        usedKb = total - available;
    }

    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memProc.running = true
    }

    Text {
        text: `${root.percent}% \uF0C9`
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }
}
