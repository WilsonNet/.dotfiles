import QtQuick
import Quickshell
import Quickshell.Io
import qs

Pill {
    id: root

    property string label: "0"
    property string state: "standby"

    readonly property string icon: state === "paused" ? "\u6B62" : "\u5F85"

    bg: Theme.alpha(Theme.yellow, 0.75)
    interactive: true

    Process {
        id: hookProc
        command: ["/home/wilsonn/bin/waybar_timer", "hook"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const data = JSON.parse(line);
                    root.label = data.text;
                    root.state = data.alt;
                    root.tooltip = data.tooltip || "";
                } catch (e) {
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!hookProc.running)
                hookProc.running = true;
        }
    }

    Text {
        text: `${root.icon} ${root.label}`
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    onClicked: Quickshell.execDetached(["sh", "-c", "/home/wilsonn/bin/waybar_timer new 10 'notify-send \"Session finished\" && mpv $HOME/sounds/not.mp3 --no-resume-playback'"])
    onMiddleClicked: Quickshell.execDetached(["/home/wilsonn/bin/waybar_timer", "cancel"])
    onRightClicked: Quickshell.execDetached(["/home/wilsonn/bin/waybar_timer", "togglepause"])
    onScrolled: (delta) => {
        if (delta > 0)
            Quickshell.execDetached(["sh", "-c", "/home/wilsonn/bin/waybar_timer increase 60 || /home/wilsonn/bin/waybar_timer new 1 'notify-send -u critical \"Timer expired\"'"]);
        else
            Quickshell.execDetached(["/home/wilsonn/bin/waybar_timer", "decrease", "60"]);
    }
}
