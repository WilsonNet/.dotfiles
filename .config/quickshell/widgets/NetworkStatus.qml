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

    // Network picker state.
    //
    // `listedNetworks` deliberately holds plain values, not the NetworkManager
    // network objects: when the radio goes down NM destroys them, and a
    // ListView rebuilding its delegates over freshly deleted QObjects segfaults
    // Quickshell (QQuickItemView::setModel). Rows resolve their live network by
    // name when clicked instead.
    property var listedNetworks: []
    property string pickerMessage: ""
    property string pendingName: ""

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

    // Open and OWE networks take no passphrase; everything else does.
    function isSecured(network) {
        if (!network)
            return false;
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    function networkFor(name) {
        const device = root.wifi;
        if (!device || !device.networks || !name)
            return null;
        return device.networks.values.find(n => n.name === name) ?? null;
    }

    // Snapshots the live device state. Called on open/rescan/actions only, so a
    // stale strength reading cannot rebuild the list under the pointer.
    function snapshotNetworks() {
        const device = root.wifi;
        if (!device || !device.networks) {
            root.listedNetworks = [];
            return;
        }
        const list = device.networks.values
            .filter(n => n && n.name !== "")
            .map(n => ({
                name: n.name,
                known: n.known,
                connected: n.connected,
                connecting: n.state === ConnectionState.Connecting,
                secured: root.isSecured(n),
                strength: n.signalStrength
            }));
        list.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            if (b.strength !== a.strength)
                return b.strength - a.strength;
            return a.name.localeCompare(b.name);
        });
        root.listedNetworks = list;
    }

    function failText(reason) {
        switch (reason) {
        case ConnectionFailReason.WifiClientDisconnected:
            return "Wi-Fi client disconnected";
        case ConnectionFailReason.WifiClientFailed:
            return "Connection failed \u2014 wrong password?";
        case ConnectionFailReason.WifiAuthTimeout:
            return "Authentication timed out \u2014 check the password";
        case ConnectionFailReason.WifiNetworkLost:
            return "Network lost while connecting";
        }
        return "Connection failed";
    }

    function activate(name) {
        const network = root.networkFor(name);
        if (!network || network.connected || network.state === ConnectionState.Connecting)
            return;
        root.pickerMessage = "";
        root.pendingName = name;
        // Saved profiles already have their PSK; new secured ones need typing,
        // which lives in the overlay dialog (bar popups cannot take keys).
        if (root.isSecured(network) && !network.known) {
            picker.open = false;
            passwordDialog.prompt(network);
            return;
        }
        network.connect();
        Qt.callLater(root.snapshotNetworks);
    }

    function disconnect(name) {
        const network = root.networkFor(name);
        if (network)
            network.disconnect();
        Qt.callLater(root.snapshotNetworks);
    }

    function forget(name) {
        const network = root.networkFor(name);
        if (!network)
            return;
        root.pickerMessage = "";
        network.forget();
        Qt.callLater(root.snapshotNetworks);
    }

    bg: kind === "disconnected" ? Theme.red : Theme.alpha(Theme.blue, 0.75)
    interactive: true
    tooltip: {
        if (!Networking.wifiEnabled)
            return "Wi-Fi is off \u00B7 Click to manage networks \u00B7 Right-click to turn on";
        const hint = "Click for networks \u00B7 Right-click to turn Wi-Fi off";
        if (root.kind === "ethernet")
            return (root.wired ? root.wired.name : "ethernet") + (root.ip ? ` \u00B7 ${root.ip}` : "") + ` \u00B7 ${hint}`;
        if (root.kind === "wifi" && root.connectedWifi)
            return (root.wifi ? root.wifi.name : "wifi") + ` \u00B7 ${root.connectedWifi.name} (${root.signalStrength}%) \u00B7 ${hint}`;
        return `No connection \u00B7 ${hint}`;
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

    onClicked: picker.open = !picker.open
    onRightClicked: Networking.wifiEnabled = !Networking.wifiEnabled

    Connections {
        target: root.networkFor(root.pendingName)

        function onConnectedChanged() {
            const network = root.networkFor(root.pendingName);
            if (root.pendingName !== "" && network && network.connected) {
                root.pendingName = "";
                root.pickerMessage = "";
                picker.open = false;
            }
        }

        function onConnectionFailed(reason) {
            const network = root.networkFor(root.pendingName);
            root.pickerMessage = root.failText(reason);
            root.pendingName = "";
            root.snapshotNetworks();
            // A saved profile with a stale passphrase would otherwise just fail
            // forever: re-prompt while the menu is still up so it can be fixed.
            if (network && picker.open && !passwordDialog.open && root.isSecured(network)
                    && (reason === ConnectionFailReason.WifiClientFailed
                        || reason === ConnectionFailReason.WifiAuthTimeout)) {
                picker.open = false;
                passwordDialog.prompt(network);
            }
        }
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

    // Picks up networks the fresh scan discovered shortly after opening.
    Timer {
        id: scanSettle
        interval: 2500
        onTriggered: root.snapshotNetworks()
    }

    BarPopup {
        id: picker

        anchorItem: root
        gapY: 4

        onOpenChanged: {
            if (open) {
                root.pickerMessage = "";
                root.snapshotNetworks();
                if (root.wifi && Networking.wifiEnabled)
                    root.wifi.scannerEnabled = true;
                scanSettle.restart();
            } else {
                if (root.wifi)
                    root.wifi.scannerEnabled = false;
                scanSettle.stop();
            }
        }

        Column {
            id: content

            width: 320
            spacing: 2

            Item {
                width: content.width
                height: 34

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Wi-Fi"
                    color: Theme.mauve
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                Item {
                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    implicitWidth: 36
                    implicitHeight: 18

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Networking.wifiEnabled ? Theme.alpha(Theme.green, 0.8) : Theme.surface1

                        Rectangle {
                            y: 2
                            width: parent.height - 4
                            height: width
                            radius: width / 2
                            x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                            color: Networking.wifiEnabled ? Theme.base : Theme.text

                            Behavior on x {
                                NumberAnimation {
                                    duration: 110
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                        }
                    }
                }
            }

            Rectangle {
                width: content.width
                height: 1
                color: Theme.surface1
            }

            Item {
                width: content.width
                height: visible ? 32 : 0
                visible: !Networking.wifiEnabled

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Wi-Fi is turned off"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }
            }

            ListView {
                id: networkList

                // Cap the list so a dense neighborhood cannot push the popup
                // past the bottom of the screen; wheel scrolls the remainder.
                width: content.width
                height: visible ? Math.min(count * 34 - (count > 0 ? 2 : 0), 374) : 0
                visible: Networking.wifiEnabled && count > 0
                model: root.listedNetworks
                spacing: 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: networkRow

                    required property var modelData

                    readonly property bool secured: modelData.secured
                    readonly property bool connected: modelData.connected
                    readonly property bool known: modelData.known
                    readonly property bool connecting: modelData.connecting
                    readonly property int bars: Math.max(1, Math.round(modelData.strength * 4))

                    width: networkList.width
                    height: 32

                    // Pointer-level hover: a MouseArea's containsMouse is lost as
                    // soon as the hover-revealed action button takes the cursor,
                    // which would make the button flicker in and out under it.
                    HoverHandler {
                        id: rowHover
                    }

                    MouseArea {
                        id: rowMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(networkRow.modelData.name)
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        radius: Theme.pillRadius
                        color: rowHover.hovered ? Theme.surface0 : "transparent"
                    }

                    Item {
                        id: signalBars

                        width: 14
                        height: 13
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }

                        Repeater {
                            model: 4

                            delegate: Rectangle {
                                required property int index

                                x: index * 4
                                y: 13 - height
                                width: 2
                                height: 3 + index * 3
                                radius: 1
                                color: index < networkRow.bars ? Theme.text : Theme.surface1
                            }
                        }
                    }

                    Text {
                        id: lockIcon

                        width: 10
                        text: networkRow.secured ? "\uF023" : ""
                        color: Theme.subtext
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        anchors {
                            left: signalBars.right
                            leftMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        id: ssidText

                        text: networkRow.modelData.name
                        color: networkRow.connected ? Theme.green : Theme.text
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                        anchors {
                            left: lockIcon.right
                            leftMargin: 6
                            right: statusSlot.left
                            rightMargin: 6
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Item {
                        id: statusSlot

                        width: 84
                        height: parent.height
                        anchors {
                            right: parent.right
                            rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }

                        Text {
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            visible: !(rowHover.hovered && actionText.actionable)
                            text: {
                                if (networkRow.connecting)
                                    return "Connecting\u2026";
                                if (networkRow.connected)
                                    return "Connected";
                                return networkRow.known ? "Saved" : "";
                            }
                            color: networkRow.connecting ? Theme.yellow : (networkRow.connected ? Theme.green : Theme.subtext)
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                        }

                        Text {
                            id: actionText

                            readonly property bool forget: networkRow.known && !networkRow.connected
                            readonly property bool actionable: forget || networkRow.connected
                            readonly property bool hovered: actionMouse.containsMouse

                            visible: rowHover.hovered && actionable
                            text: forget ? "Forget" : "Disconnect"
                            color: hovered ? Theme.red : Theme.subtext
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }

                            MouseArea {
                                id: actionMouse

                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (actionText.forget)
                                        root.forget(networkRow.modelData.name);
                                    else
                                        root.disconnect(networkRow.modelData.name);
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: content.width
                height: visible ? 32 : 0
                visible: Networking.wifiEnabled && root.listedNetworks.length === 0

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Scanning\u2026"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }
            }

            Item {
                width: content.width
                height: visible ? messageText.implicitHeight + 10 : 0
                visible: root.pickerMessage !== ""

                Text {
                    id: messageText

                    text: root.pickerMessage
                    color: Theme.red
                    font.pixelSize: 12
                    font.family: Theme.fontFamily
                    wrapMode: Text.WordWrap
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 12
                        rightMargin: 12
                        topMargin: 4
                    }
                }
            }

            Rectangle {
                width: content.width
                height: 1
                color: Theme.surface1
                visible: Networking.wifiEnabled
            }

            Item {
                width: content.width
                height: visible ? 30 : 0
                visible: Networking.wifiEnabled

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.pillRadius
                    color: rescanMouse.containsMouse ? Theme.surface0 : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uF2F1  Rescan"
                    color: rescanMouse.containsMouse ? Theme.text : Theme.subtext
                    font.pixelSize: 12
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: rescanMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.snapshotNetworks();
                        const device = root.wifi;
                        if (device) {
                            // Re-arm the scanner: a repeated `true` is a no-op.
                            device.scannerEnabled = false;
                            Qt.callLater(() => device.scannerEnabled = true);
                        }
                        scanSettle.restart();
                    }
                }
            }
        }
    }

    WifiPasswordDialog {
        id: passwordDialog
    }
}
