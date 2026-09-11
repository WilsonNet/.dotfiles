import QtQuick
import Quickshell
import Quickshell.Io
import qs

Pill {
    id: root

    property string label: "0"
    property string state: "standby"
    property string hookTooltip: ""
    property int lastMinutes: -1
    property real remainingSeconds: 0
    property real totalSeconds: 0
    property int customMinutes: Settings.customTimerMinutes
    readonly property int defaultMinutes: 10

    readonly property bool running: state === "running"
    readonly property bool paused: state === "paused"
    readonly property bool visual: Settings.visualTimer
    readonly property real fraction: totalSeconds > 0
        ? Math.max(0, Math.min(1, remainingSeconds / totalSeconds))
        : 0
    readonly property bool urgent: running && remainingSeconds > 0 && remainingSeconds <= 60
    readonly property color progressColor: {
        if (!running && !paused)
            return Theme.surface1;
        if (fraction > 0.5)
            return Theme.green;
        if (fraction > 0.25)
            return Theme.yellow;
        if (fraction > 0.1)
            return Theme.peach;
        return Theme.red;
    }

    bg: visual ? Theme.alpha(Theme.surface0, 0.6) : Theme.alpha(Theme.yellow, 0.75)
    interactive: true
    tooltip: state === "standby"
        ? `No timer set \u00B7 left-click starts ${defaultMinutes} min \u00B7 right-click for options`
        : hookTooltip

    function handleHook(line) {
        let data;
        try {
            data = JSON.parse(line);
        } catch (e) {
            return;
        }

        const newState = data.alt || "standby";
        const minutes = parseInt(data.text);
        label = String(data.text !== undefined ? data.text : "0");
        hookTooltip = data.tooltip || "";
        const wasRunning = state === "running";
        state = newState;

        if (newState === "standby") {
            totalSeconds = 0;
            remainingSeconds = 0;
            lastMinutes = -1;
            return;
        }

        if (newState === "paused")
            return;

        if (!wasRunning) {
            const startSeconds = isNaN(minutes) ? 0 : minutes * 60;
            if (totalSeconds <= 0) {
                remainingSeconds = startSeconds;
                totalSeconds = startSeconds;
            } else if (Math.abs(remainingSeconds - startSeconds) > 60) {
                remainingSeconds = startSeconds;
            }
            lastMinutes = minutes;
            return;
        }

        remainingSeconds = Math.max(0, remainingSeconds - 1);

        if (!isNaN(minutes) && minutes !== lastMinutes) {
            remainingSeconds = minutes * 60;
            totalSeconds = Math.max(totalSeconds, remainingSeconds);
            lastMinutes = minutes;
        }
    }

    function startTimer(minutes) {
        const value = Math.max(1, Math.min(180, Math.round(Number(minutes))));
        if (isNaN(value))
            return;
        const command = "notify-send \"Session finished\" && mpv $HOME/sounds/not.mp3 --no-resume-playback";
        Quickshell.execDetached(["sh", "-c", `/home/wilsonn/bin/waybar_timer new ${value} '${command}'`]);
        optionsPopup.close();
    }

    function setCustom(minutes) {
        customMinutes = Math.max(1, Math.min(180, Math.round(minutes)));
        Settings.setCustomTimerMinutes(customMinutes);
    }

    Process {
        id: hookProc
        command: ["/home/wilsonn/bin/waybar_timer", "hook"]
        running: true

        stdout: SplitParser {
            onRead: (line) => root.handleHook(line)
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

    Item {
        id: content

        implicitWidth: root.visual ? visualRow.implicitWidth : labelText.implicitWidth
        implicitHeight: Math.max(18, labelText.implicitHeight)

        Text {
            id: labelText

            anchors.verticalCenter: parent.verticalCenter
            text: `${root.paused ? "\u6B62" : "\u5F85"} ${root.label}`
            color: Theme.base
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            visible: !root.visual
        }

        Row {
            id: visualRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: root.visual

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.running ? "\uF254" : (root.paused ? "\uF04C" : "\uF017")
                color: root.running || root.paused ? root.progressColor : Theme.subtext
                font.pixelSize: 15
                font.family: Theme.fontFamily
            }

            Item {
                id: track

                anchors.verticalCenter: parent.verticalCenter
                width: 74
                height: 14

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.alpha(Theme.base, 0.45)
                    border.width: 1
                    border.color: Theme.alpha(Theme.text, 0.12)
                }

                Rectangle {
                    id: fill

                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 2
                        topMargin: 2
                        bottomMargin: 2
                    }
                    width: Math.max(0, (track.width - 4) * root.fraction)
                    radius: height / 2
                    color: root.progressColor

                    Behavior on width {
                        NumberAnimation { duration: 280; easing.type: Easing.Linear }
                    }
                }

                SequentialAnimation {
                    running: root.urgent
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: fill
                        property: "opacity"
                        to: 0.45
                        duration: 500
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: fill
                        property: "opacity"
                        to: 1.0
                        duration: 500
                        easing.type: Easing.InOutSine
                    }

                    onRunningChanged: if (!running) fill.opacity = 1
                }
            }
        }
    }

    onClicked: root.startTimer(root.defaultMinutes)
    onMiddleClicked: Quickshell.execDetached(["/home/wilsonn/bin/waybar_timer", "cancel"])
    onRightClicked: {
        if (root.state === "standby") {
            Tooltip.hide(root);
            optionsPopup.open = !optionsPopup.open;
        } else {
            Quickshell.execDetached(["/home/wilsonn/bin/waybar_timer", "togglepause"]);
        }
    }
    onScrolled: (delta) => {
        if (delta > 0)
            Quickshell.execDetached(["sh", "-c", "/home/wilsonn/bin/waybar_timer increase 60 || /home/wilsonn/bin/waybar_timer new 1 'notify-send -u critical \"Timer expired\"'"]);
        else
            Quickshell.execDetached(["/home/wilsonn/bin/waybar_timer", "decrease", "60"]);
    }

    BarPopup {
        id: optionsPopup

        anchorItem: root
        gapY: 4

        Column {
            spacing: 10
            width: 300

            Text {
                text: "Start a timer"
                color: Theme.text
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
            }

            Grid {
                columns: 4
                spacing: 6

                Repeater {
                    model: [1, 3, 5, 10, 15, 30, 45, 60]

                    delegate: Rectangle {
                        id: chip

                        required property int modelData

                        width: 70
                        height: 34
                        radius: Theme.pillRadius
                        color: chipMouse.containsMouse ? Theme.surface1 : Theme.surface0

                        Text {
                            anchors.centerIn: parent
                            text: `${chip.modelData} min`
                            color: Theme.text
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startTimer(chip.modelData)
                        }
                    }
                }
            }

            Row {
                spacing: 4

                component AdjustButton: Rectangle {
                    id: adjust

                    required property int delta

                    width: 32
                    height: 34
                    radius: Theme.pillRadius
                    color: adjustMouse.containsMouse ? Theme.surface1 : Theme.surface0

                    Text {
                        anchors.centerIn: parent
                        text: adjust.delta > 0 ? `+${adjust.delta}` : `${adjust.delta}`
                        color: Theme.text
                        font.pixelSize: 14
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: adjustMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setCustom(root.customMinutes + adjust.delta)
                    }
                }

                AdjustButton { delta: -5 }
                AdjustButton { delta: -1 }

                Rectangle {
                    width: 64
                    height: 34
                    radius: Theme.pillRadius
                    color: Theme.surface0
                    border.width: 1
                    border.color: Theme.surface1

                    Text {
                        anchors.centerIn: parent
                        text: `${root.customMinutes} min`
                        color: Theme.text
                        font.pixelSize: 14
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeVerCursor
                        onWheel: (e) => root.setCustom(root.customMinutes + (e.angleDelta.y > 0 ? 1 : -1))
                    }
                }

                AdjustButton { delta: 1 }
                AdjustButton { delta: 5 }

                Rectangle {
                    width: 62
                    height: 34
                    radius: Theme.pillRadius
                    color: startMouse.containsMouse
                        ? Theme.alpha(Theme.green, 0.85)
                        : Theme.green

                    Text {
                        anchors.centerIn: parent
                        text: "Start"
                        color: Theme.base
                        font.pixelSize: 14
                        font.family: Theme.fontFamily
                        font.bold: true
                    }

                    MouseArea {
                        id: startMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.startTimer(root.customMinutes)
                    }
                }
            }

            Row {
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Visual only (no numbers)"
                    color: Theme.text
                    font.pixelSize: 14
                    font.family: Theme.fontFamily
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Settings.visualTimer ? Theme.alpha(Theme.mauve, 0.9) : Theme.surface0
                    }

                    Rectangle {
                        width: 18
                        height: 18
                        y: 2
                        x: Settings.visualTimer ? parent.width - width - 2 : 2
                        radius: 9
                        color: Settings.visualTimer ? Theme.base : Theme.subtext

                        Behavior on x {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.setVisualTimer(!Settings.visualTimer)
                    }
                }
            }

            Text {
                text: "A shrinking, color-shifting bar instead of digits."
                color: Theme.subtext
                font.pixelSize: 12
                font.family: Theme.fontFamily
                wrapMode: Text.WordWrap
                width: parent.width
                visible: Settings.visualTimer
            }
        }
    }
}
