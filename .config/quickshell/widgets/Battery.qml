import QtQuick
import Quickshell.Services.UPower
import qs

Pill {
    id: root

    property var device: UPower.displayDevice
    property bool showTime: false
    property bool blinkOn: true

    readonly property int capacity: device && device.isPresent ? Math.round(device.percentage * 100) : -1
    readonly property int state: device ? device.state : UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool plugged: state === UPowerDeviceState.FullyCharged
        || state === UPowerDeviceState.PendingCharge
        || state === UPowerDeviceState.Charging
    readonly property bool critical: !plugged && capacity >= 0 && capacity < 15
    readonly property var icons: ["\uF244", "\uF243", "\uF242", "\uF241", "\uF240"]
    readonly property string icon: capacity < 10 ? icons[0]
        : capacity < 30 ? icons[1]
        : capacity < 60 ? icons[2]
        : capacity < 90 ? icons[3]
        : icons[4]

    bg: {
        if (root.critical && root.blinkOn)
            return Theme.alpha(Theme.red, 0.75);
        if (root.plugged)
            return Theme.alpha(Theme.teal, 0.75);
        return Theme.alpha(Theme.green, 0.75);
    }
    interactive: true
    tooltip: {
        if (!root.device)
            return "";
        const stateText = root.charging ? "Charging" : (root.plugged ? "Plugged in" : "Discharging");
        const time = root.formatTime();
        return `${root.capacity}% \u00B7 ${stateText}` + (time ? ` (${time})` : "");
    }

    Timer {
        interval: 500
        running: root.critical
        repeat: true
        onTriggered: root.blinkOn = !root.blinkOn
    }

    function formatTime() {
        if (!device)
            return "";
        const seconds = charging ? device.timeToFull : device.timeToEmpty;
        if (!seconds || seconds <= 0)
            return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return `${h}:${m.toString().padStart(2, "0")}`;
    }

    Text {
        visible: root.capacity >= 0
        text: root.showTime
            ? root.formatTime()
            : `${root.capacity}% ${root.charging ? "\uF5E7" : root.plugged ? "\uF1E6" : root.icon}`
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    onClicked: root.showTime = !root.showTime
}
