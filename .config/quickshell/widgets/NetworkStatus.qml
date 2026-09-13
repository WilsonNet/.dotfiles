import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs

Pill {
    id: root

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wired: findDevice(DeviceType.Wired)
    readonly property var wifi: findDevice(DeviceType.Wifi)
    readonly property var connectedWifi: {
        if (!wifi || !wifi.networks)
            return null;
        return wifi.networks.values.find(n => n.connected) ?? null;
    }
    readonly property string kind: {
        if (wired && wired.connected)
            return "ethernet";
        if (connectedWifi)
            return "wifi";
        return "disconnected";
    }
    readonly property int signalStrength: connectedWifi ? Math.round((connectedWifi.signalStrength || 0) * 100) : -1
    readonly property string icon: {
        if (kind === "ethernet")
            return "\uF796";
        if (kind === "wifi")
            return "\uF1EB";
        return "\u26A0";
    }

    property bool compact: false
    property string ip: ""

    function findDevice(type) {
        let fallback = null;
        for (const device of devices) {
            if (!device || device.type !== type)
                continue;
            if (device.connected)
                return device;
            if (!fallback)
                fallback = device;
        }
        return fallback;
    }

    bg: kind === "disconnected" ? Theme.red : Theme.alpha(Theme.blue, 0.75)
    tooltip: {
        if (root.kind === "ethernet")
            return (root.wired ? root.wired.name : "ethernet") + (root.ip ? ` \u00B7 ${root.ip}` : "");
        if (root.kind === "wifi" && root.connectedWifi)
            return (root.wifi ? root.wifi.name : "wifi") + ` \u00B7 ${root.connectedWifi.name} (${root.signalStrength}%)`;
        return "No connection";
    }

    Text {
        text: {
            if (root.compact)
                return root.icon;
            if (root.kind === "ethernet")
                return (root.ip || "No IP") + ` ${root.icon}`;
            if (root.kind === "wifi" && root.connectedWifi)
                return `${root.connectedWifi.name} (${root.signalStrength}%) ${root.icon}`;
            return `Disconnected ${root.icon}`;
        }
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    Process {
        id: ipProc
        command: ["nmcli", "-t", "-g", "IP4.ADDRESS", "device", "show", root.wired ? root.wired.name : ""]
        stdout: StdioCollector {
            onStreamFinished: root.ip = String(this.text || "").trim().split(",")[0]
        }
    }

    Timer {
        interval: 5000
        running: root.kind === "ethernet"
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.wired)
                ipProc.running = true;
        }
    }
}
