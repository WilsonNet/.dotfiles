import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Wayland
import qs

// Passphrase prompt for networks without a saved profile.
//
// Bar PopupWindows cannot receive keyboard input here (a keyboard grab makes
// the compositor dismiss them), so the prompt is a full-screen layer surface
// with an exclusive keyboard grab — same approach as Shortcuts.qml. The text
// field therefore gets real keystrokes; the rest of the UI stays click-only.
PanelWindow {
    id: root

    property var network: null
    property bool open: false
    property string errorText: ""

    readonly property bool connecting: root.network ? root.network.state === ConnectionState.Connecting : false
    readonly property var targetScreen: {
        const monitor = Hyprland.focusedMonitor;
        return monitor ? Quickshell.screens.find(s => s.name === monitor.name) : null;
    }

    function prompt(network) {
        root.network = network;
        root.errorText = "";
        passwordField.text = "";
        passwordField.echoMode = TextInput.Password;
        root.open = true;
        Qt.callLater(() => passwordField.forceActiveFocus());
    }

    function cancel() {
        if (!root.open)
            return;
        root.open = false;
        root.network = null;
        root.errorText = "";
    }

    function submit() {
        const network = root.network;
        if (!network || root.connecting)
            return;
        const psk = passwordField.text;
        if (psk.length === 0) {
            root.errorText = "Enter the network password";
            return;
        }
        root.errorText = "";
        network.connectWithPsk(psk);
    }

    screen: root.targetScreen
    visible: root.open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell-wifi"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => passwordField.forceActiveFocus());
    }

    Connections {
        target: root.network

        function onConnectedChanged() {
            if (root.network && root.network.connected)
                root.cancel();
        }

        function onConnectionFailed(reason) {
            root.errorText = reason === ConnectionFailReason.WifiAuthTimeout
                ? "Authentication timed out \u2014 check the password"
                : "Connection failed \u2014 check the password";
            passwordField.selectAll();
            passwordField.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.crust, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 380
        height: content.implicitHeight + 36
        radius: 12
        color: Theme.alpha(Theme.base, 0.98)
        border.width: 1
        border.color: Theme.surface1

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 18
            }
            spacing: 10

            Text {
                text: "Connect to Wi-Fi"
                color: Theme.subtext
                font.pixelSize: 12
                font.family: Theme.fontFamily
            }

            Text {
                width: parent.width
                text: root.network ? root.network.name : ""
                color: Theme.text
                font.pixelSize: 17
                font.bold: true
                font.family: Theme.fontFamily
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: 38
                radius: 6
                color: Theme.surface0
                border.width: 1
                border.color: passwordField.activeFocus ? Theme.mauve : "transparent"

                TextInput {
                    id: passwordField

                    anchors {
                        left: parent.left
                        right: showButton.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                        rightMargin: 10
                    }
                    color: Theme.text
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    echoMode: TextInput.Password
                    selectByMouse: true
                    clip: true
                    onAccepted: root.submit()
                    Keys.onEscapePressed: root.cancel()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: passwordField.text === ""
                        text: "Password"
                        color: Theme.subtext
                        font: passwordField.font
                    }
                }

                Text {
                    id: showButton

                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: passwordField.echoMode === TextInput.Password ? "Show" : "Hide"
                    color: showMouse.containsMouse ? Theme.text : Theme.subtext
                    font.pixelSize: 12
                    font.family: Theme.fontFamily

                    MouseArea {
                        id: showMouse

                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: passwordField.echoMode = passwordField.echoMode === TextInput.Password
                            ? TextInput.Normal
                            : TextInput.Password
                    }
                }
            }

            Text {
                width: parent.width
                visible: root.errorText !== ""
                text: root.errorText
                color: Theme.red
                font.pixelSize: 12
                font.family: Theme.fontFamily
                wrapMode: Text.WordWrap
            }

            Item {
                width: parent.width
                height: 34

                Rectangle {
                    id: connectButton

                    anchors.right: parent.right
                    width: 100
                    height: 30
                    radius: 6
                    color: root.connecting
                        ? Theme.alpha(Theme.green, 0.4)
                        : (connectMouse.containsMouse ? Theme.alpha(Theme.green, 0.9) : Theme.alpha(Theme.green, 0.75))

                    Text {
                        anchors.centerIn: parent
                        text: root.connecting ? "Connecting\u2026" : "Connect"
                        color: Theme.base
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: connectMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submit()
                    }
                }

                Rectangle {
                    anchors {
                        right: connectButton.left
                        rightMargin: 8
                        verticalCenter: connectButton.verticalCenter
                    }
                    width: 84
                    height: 30
                    radius: 6
                    color: cancelMouse.containsMouse ? Theme.surface1 : Theme.surface0

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.text
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: cancelMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancel()
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Enter to connect \u00B7 Esc to cancel"
                color: Theme.subtext
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }
    }
}
