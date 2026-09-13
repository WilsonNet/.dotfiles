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
// signalStrength is 0..1; the SSID is Network.name (there is NO `.ssid` — it
// silently renders as "undefined"); guard during transitions (nulls!)
// IPv4 for wired: Process ["nmcli","-t","-g","IP4.ADDRESS","device","show", iface]
```

## Responsive layout / overflowing text

The bar is three independent rows in `PanelWindow`; anchored rows grow toward the
middle, so each widget must cap its own width. Caps/compact flags are set from
`Bar.qml` (`root.width` = screen logical px) because a plain `Row` gives children
no available-width signal. See the official guide
`https://quickshell.org/docs/v0.3.1/guide/size-position` for the underlying rules
(implicit vs actual size, `childrenRect` binding loops, when to prefer Layouts).

Cap + elide, full value in the tooltip:

```qml
readonly property real maxTextWidth: 200
Text {
    text: root.label
    width: Math.min(implicitWidth, root.maxTextWidth)
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
}
```

Marquee — `widgets/Media.qml` scrolls a clipped viewport with two copies of the
text; the infinite animation restarts from 0 after moving exactly one loop
distance, so the wrap is seamless:

```qml
Item {
    id: viewport
    clip: true
    implicitWidth: Math.min(labelText.implicitWidth, root.maxTextWidth)
    implicitHeight: labelText.implicitHeight
    readonly property bool overflowing: labelText.implicitWidth > width
    readonly property real loopDistance: labelText.implicitWidth + track.spacing
    onOverflowingChanged: if (!overflowing) track.x = 0

    Text { id: labelText; visible: false; text: root.label
           font.pixelSize: Theme.fontSize; font.family: Theme.fontFamily }

    Row {
        id: track
        spacing: 32
        Text { text: labelText.text; color: Theme.base; font: labelText.font }
        Text { text: labelText.text; color: Theme.base; font: labelText.font
               visible: viewport.overflowing }
    }

    SequentialAnimation {
        running: viewport.overflowing && !root.hovered   // pause on hover
        loops: Animation.Infinite
        PauseAnimation { duration: 2500 }
        NumberAnimation {
            target: track; property: "x"
            from: 0; to: -viewport.loopDistance
            duration: Math.max(4000, viewport.loopDistance / 45 * 1000)
            easing.type: Easing.Linear
        }
    }
}
```

Icon-only fallback when the bar is tight (NetworkStatus; full info stays in the
tooltip): add `property bool compact: false`, set the Text to
`root.compact ? root.icon : ssid + " (" + pct + "%) " + root.icon`, then from
`Bar.qml`: `NetworkStatus { compact: root.width < 1700 }`.

Center title between both rows (ActiveWindow) without underlapping the right row:

```qml
maxWidth: Math.max(0, rightRow.x - (leftRow.x + leftRow.width) - 24)  // no positive floor
x: Math.round((leftRow.x + leftRow.width + rightRow.x) / 2 - width / 2)
width: Math.min(implicitWidth, maxWidth)
elide: Text.ElideRight
```

Alternative: `import QtQuick.Layouts` + `RowLayout` with the `Layout` attached
object (`fillWidth`, `maximumWidth`, `preferredWidth`) lets the layout shrink
items itself — the official guide prefers Layouts over Row/Column. This bar
predates that and passes caps down instead.

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

    // Write explicitly on user action. Do NOT use `onAdapterUpdated:
    // writeAdapter()`: on config reload the adapter can emit defaults before
    // the file has loaded, overwriting saved values.
    function setVisualTimer(value) {
        if (adapter.visualTimer === value) return;
        adapter.visualTimer = value;
        settingsFile.writeAdapter();
    }

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
