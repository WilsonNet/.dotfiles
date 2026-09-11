# Quickshell API patterns (verified on 0.3.1)

Copy-paste starting points. All of these are in use in `~/.config/quickshell`.

## One PanelWindow per screen

```qml
// shell.qml
ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }
}

// Bar.qml
PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: Theme.alpha(Theme.base, 0.7)
    WlrLayershell.namespace: "quickshell"
}
```

## Pill (module wrapper)

Set `bg`, `tooltip`, `interactive`; put content `Text` as a child; implement the
signals you need: `onClicked`, `onRightClicked`, `onMiddleClicked`, `onScrolled`.

```qml
Pill {
    id: root
    bg: Theme.alpha(Theme.peach, 0.75)
    tooltip: `${root.percent}% used`
    interactive: true
    Text { text: `${root.percent}% \uF2DB`; color: Theme.base; font.family: Theme.fontFamily }
    onClicked: Quickshell.execDetached(["pavucontrol"])
    onScrolled: (delta) => { /* delta > 0 = up */ }
}
```

## Tooltips (shared surface)

```qml
// Pill.qml does this for you:
onEntered: Tooltip.show(root, root.tooltip, root.tooltipCalendar)
onExited: Tooltip.hide(root)

// Custom (e.g. tray icons):
onEntered: Tooltip.show(iconItem, iconItem.modelData.tooltipTitle || "")
onExited: Tooltip.hide(iconItem)
```

The singleton keeps one `PopupWindow` in `Bar.qml` anchored below the bar.
`Tooltip.show(item, text, withCalendar)` — `withCalendar: true` renders the
month grid (clock widget).

## Anchored popup + outside-click dismissal

```qml
BarPopup {
    id: menu
    anchorItem: someItem

    Column { /* entries */ }
}
// BarPopup: visible: open, HyprlandFocusGrab { windows: [popup, barWindow]; onCleared: close() }
// anchor.onAnchoring() maps the item and sets rect.x/y = below bar (window.height + gapY)
```

## Tray menu with submenu drill-down

```qml
QsMenuOpener { id: menuOpener; menu: root.activeItem ? root.activeItem.menu : null }

// currentChildren: submenuStack.length ? top.opener.children : menuOpener.children
function enterSubmenu(entry, title) {
    const opener = submenuComponent.createObject(root, { menu: entry }); // QsMenuOpener {}
    root.submenuStack = root.submenuStack.concat([{ opener, title }]);
}
onClicked: {
    if (entry.hasChildren) root.enterSubmenu(entry, entry.text || "");
    else { entry.triggered(); menu.close(); }
}
// Entries: .text .icon .enabled .isSeparator .hasChildren .checkState .buttonType
```

## Pipewire (volume)

```qml
PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
readonly property var sink: Pipewire.defaultAudioSink
readonly property var sinkAudio: sink ? sink.audio : null
readonly property real volume: sinkAudio ? sinkAudio.volume : 0     // 0..1, may exceed 1
readonly property bool muted: sinkAudio ? sinkAudio.muted : false
// set: sinkAudio.volume = Math.min(1.5, sinkAudio.volume + 0.01); sinkAudio.muted = !sinkAudio.muted
```

## UPower (batteries)

```qml
import Quickshell.Services.UPower
readonly property var device: UPower.displayDevice   // percentage is 0..1
const capacity = Math.round(device.percentage * 100);
const plugged = device.state === UPowerDeviceState.FullyCharged
    || device.state === UPowerDeviceState.Charging
    || device.state === UPowerDeviceState.PendingCharge;
const seconds = device.state === UPowerDeviceState.Charging ? device.timeToFull : device.timeToEmpty;
```

## MPRIS (media)

```qml
readonly property var players: Mpris.players ? Mpris.players.values : []
readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
// player.trackTitle / trackArtist / trackAlbum / identity / isPlaying
// player.canTogglePlaying|canGoNext|canGoPrevious, togglePlaying() / next() / previous()
// Show only when player !== null; a stopped Brave session has canTogglePlaying false.
```

## Networking (NetworkManager backend)

```qml
readonly property var devices: Networking.devices ? Networking.devices.values : []
readonly property var wired: findDevice(DeviceType.Wired)     // device.type/.connected/.name
readonly property var wifi: findDevice(DeviceType.Wifi)
readonly property var connectedWifi: wifi ? wifi.networks.values.find(n => n.connected) : null
// wifiEnabled, connectivity (NetworkConnectivity.*), checkConnectivity()
// signalStrength is 0..1; ssid/name on the WifiNetwork; guard during transitions (nulls!)
// IPv4 for wired: Process ["nmcli","-t","-g","IP4.ADDRESS","device","show", iface]
```

## FileView (sysfs/live files)

```qml
FileView {
    id: tempFile
    path: "/sys/class/thermal/thermal_zone0/temp"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.milliC = parseInt(tempFile.text()) || 0   // text() is a METHOD
}
```

## Processes

```qml
// one-shot
Process {
    id: proc
    command: ["cat", "/proc/stat"]
    stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
}
Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }

// streaming lines (e.g. waybar_timer hook)
Process {
    command: ["/home/wilsonn/bin/waybar_timer", "hook"]
    running: true
    stdout: SplitParser { onRead: (line) => { try { const d = JSON.parse(line); /* ... */ } catch (e) {} } }
}

// fire and forget
Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = 3 })"]);
Quickshell.execDetached(["sh", "-c", "cmd1 || cmd2"]);
```

## Idle inhibitor / active window / clock

```qml
import Quickshell.Wayland

IdleInhibitor { window: root.QsWindow.window; enabled: root.inhibited }

readonly property var toplevel: ToplevelManager.activeToplevel   // .title, .appId
Text { text: toplevel ? toplevel.title : "" }

SystemClock { id: clock; precision: SystemClock.Minutes }        // clock.date, Qt.formatDateTime(...)
```

## Persisted settings (survives restarts)

`PersistentProperties` only survives reloads. For real persistence, back a
singleton with a `FileView` + `JsonAdapter` in `Quickshell.stateDir`:

```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property alias visualTimer: adapter.visualTimer

    readonly property string settingsPath: Quickshell.stateDir + "/timer-settings.json"
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir])

    FileView {
        id: settingsFile
        path: root.settingsPath
        blockWrites: true          // don't overwrite the file before it loads
        printErrors: false         // first run: file doesn't exist yet
        watchChanges: true
        onFileChanged: reload()
        onLoaded: blockWrites = false
        onLoadFailed: blockWrites = false
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: adapter
            property bool visualTimer: false
            property int customTimerMinutes: 25
        }
    }
}
```

## waybar_timer hook (timer data source)

`waybar_timer hook` streams one JSON line per second while a timer exists:

```json
{"text":"3","alt":"running","tooltip":"Timer expires at 22:57","class":"timer"}
```

- `alt`: `standby` | `running` | `paused`
- `text`: remaining **ceil** minutes; a change from `m` to `m-1` means exactly
  `(m-1)*60` seconds remain, so it can resync a locally decremented countdown.
- `tooltip`: "Timer expires at HH:MM" (minute precision) or "Timer paused".
- Commands: `new <minutes> [command]`, `increase <secs>`, `decrease <secs>`,
  `togglepause`, `cancel`.
