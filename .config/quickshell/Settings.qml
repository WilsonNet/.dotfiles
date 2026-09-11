pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias visualTimer: adapter.visualTimer
    property alias customTimerMinutes: adapter.customTimerMinutes

    readonly property string settingsPath: Quickshell.stateDir + "/timer-settings.json"

    function setVisualTimer(value) {
        if (adapter.visualTimer === value)
            return;
        adapter.visualTimer = value;
        settingsFile.writeAdapter();
    }

    function setCustomTimerMinutes(value) {
        if (adapter.customTimerMinutes === value)
            return;
        adapter.customTimerMinutes = value;
        settingsFile.writeAdapter();
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir])

    FileView {
        id: settingsFile

        path: root.settingsPath
        blockWrites: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: blockWrites = false
        onLoadFailed: blockWrites = false

        adapter: JsonAdapter {
            id: adapter

            property bool visualTimer: false
            property int customTimerMinutes: 25
        }
    }
}
