---
name: quickshell
description: Develop, debug, and extend the Quickshell desktop shell/bar (QML) on this machine. Use whenever the user works on ~/.config/quickshell, asks for a new bar widget, popup, tooltip or tray menu, reports QML/runtime errors or wrong (tofu) icons, wants to look up Quickshell APIs, upgrade Quickshell, or port Waybar modules — even if they only say "the bar", "the clock", or "my top bar".
---

# Quickshell Development (this machine)

Quickshell 0.3.1 (Arch `extra`) is the Hyprland bar since Sep 2026, replacing Waybar (which stays installed, disabled, as a fallback; its config is untouched at `~/.config/waybar`).

- Config: `~/.config/quickshell` → symlink to `~/.dotfiles/.config/quickshell` (tracked in dotfiles).
- Autostart: `hyprland.lua` runs `quickshell -n` (dedupe) after `apply_monitors()`.
- Layer namespace: `quickshell` (`hyprctl layers`).

This skill holds the workflow, the API gotchas that cost real debugging time, and a test harness. Read it before writing QML here — most apparent "Quickshell bugs" are one of the gotchas below.

## Documentation and sources of truth

Check data before trusting memory; 0.3.x changes fast.

- **Official docs (versioned)**: https://quickshell.org/docs/v0.3.1/ — the site defaults to the docs of the latest release, so always match the version selector to `quickshell --version`. Type reference index: https://quickshell.org/docs/v0.3.1/types/ (e.g. `Quickshell.Services.Pipewire/PwNodeAudio`).
- **Changelog / breaking changes**: https://quickshell.org/changelog/
- **Installed stubs (exact ground truth for this machine)**: `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes` — grep property/method/signal names, e.g. `rg "activeToplevel" /usr/lib/qt6/qml/Quickshell/`.
- **Official examples**: https://github.com/quickshell-mirror/quickshell-examples
- **Production reference (tray menus, panels, OSD, protocols)**: Omarchy's shell, https://github.com/basecamp/omarchy/tree/quattro/shell
- Qt Quick docs for plain QML: https://doc.qt.io/qt-6/qtquick-qmlmodule.html

## Config layout

- `shell.qml` — `ShellRoot`, `Variants` over `Quickshell.screens` (one `Bar` per screen), `debug` `IpcHandler`.
- `Bar.qml` — `PanelWindow` (50px, alpha `.7`, namespace `quickshell`), left/center/right rows, shared tooltip `PopupWindow`.
- `Theme.qml` — Catppuccin Mocha palette + metrics (`barHeight`, `pillHeight/Radius/Padding/Spacing`, `fontSize`, `fontFamily`) and `alpha(color, a)`.
- `Pill.qml` — every module is wrapped in this: bg color, bottom hover underline, tooltip plumbing, `clicked/rightClicked/middleClicked/scrolled`.
- `BarPopup.qml` — anchored popup below the bar + `HyprlandFocusGrab` outside-click dismissal (tray/power menus).
- `Tooltip.qml` — singleton; one shared tooltip surface driven by `Tooltip.show(item, text, calendar?)` / `hide(item)`.
- `HyprDevices.qml` — singleton polling `hyprctl devices -j` 1/s for caps/num/layout.
- `widgets/` — one file per module (Workspaces, ActiveWindow, Media, Volume, Timer, NetworkStatus, IdleInhibit, PowerMode, Cpu, Memory, Temperature, Backlight, KeyboardState, Language, Battery, Clock, Tray, PowerButton).

## Dev loop

1. Edit a `.qml` file and save — the running shell hot-reloads. On error the previous UI survives; check the log, fix, save again.
2. Logs: `qs log` follows the running instance; run `quickshell` in a terminal for live stderr. Save to a file: `nohup quickshell > /tmp/qs.log 2>&1 &`.
3. Hard restart: `qs kill; quickshell &` (never needed for edits).
4. Live introspection: `qs ipc call debug activeWindow` / `qs ipc call debug workspaces`. Add temporary functions to the `IpcHandler` in `shell.qml` to dump widget state, then remove them.
5. Visual verification: `grim` + crops, see `references/testing.md`.

### qmllint setup

`import qs.*` is Quickshell-specific; qmllint needs an import shim:

```sh
mkdir -p /tmp/opencode/qmlimports && ln -sfn ~/.config/quickshell /tmp/opencode/qmlimports/qs
qmllint -I /usr/lib/qt6/qml -I /tmp/opencode/qmlimports <file.qml>
```

Two qmllint issues with this Qt (6.11.2) build — **runtime is fine**, the linter exits 255 with no message. Avoid these in code so lint stays clean:

- `?.` optional chaining → use explicit null checks (`x ? x.y : null`).
- `: var` return annotations on functions that return arrays → drop the `: var`.

If a file crashes qmllint, bisect for these two before blaming the config.

## Verified gotchas

- `Text.font.families` **does not exist**; use `font.family`. `Theme.fontFamily` is `"Font Awesome 7 Free Solid"` so FA codepoints resolve before fontconfig fallback — with a text font first, `\uF001` (music) and `\uF796` (ethernet) rendered as wrong glyphs/tofu. CJK/emoji/backlight glyphs still fall back correctly.
- `FileView.text()` is a **method**, not a property: `onLoaded: value = parseInt(file.text())`. `watchChanges: true` + `onFileChanged: reload()` works on sysfs (`/sys/class/backlight/...`, `/sys/class/thermal/...`).
- `Hyprland.activeToplevel` stays `null` until a focus event fires (broken at shell startup). Use `ToplevelManager.activeToplevel` (`Quickshell.Wayland`) for the focused window; `Hyprland.focusedWorkspace`, `Hyprland.workspaces`, `Hyprland.toplevels` are reliable.
- `Hyprland.toplevels[].activated` can stay `false` even for the focused window; don't use it to find the active window.
- Bar → compositor commands go through `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'` (via `Quickshell.execDetached`). Old hyprlang dispatcher strings fail on Lua configs, and `Hyprland.dispatch()` sends old-style requests — avoid it.
- `Quickshell.Wayland.IdleInhibitor { window: <window>; enabled: bool }` — `window` from `root.QsWindow.window`. hypridle respects it (Waybar's DBus ScreenSaver variant did not).
- Tray right-click menus: `SystemTray.items.values`, `item.menu` → `QsMenuOpener`. Submenus are **not** displayable via the platform (`display()` needs QApplication mode); render in-shell instead: for an entry with `hasChildren`, create a new `QsMenuOpener { menu: entry }` (QsMenuEntry is a QsMenuHandle), keep a stack, and show a back header. Leaves: `entry.triggered()`.
- `PanelWindow` anchors are booleans (which screen edges), not item anchors. Popups must anchor below the bar: set `anchor.rect.y = window.height + gap`, not `target.height + gap`.
- `Pill`-style click handlers: ydotool's `0x00` does nothing; real clicks are `0xC0` (left), `0xC1` (right), `0xC2` (middle).
- `Process` streams: `stdio`-style `SplitParser { onRead: (line) => ... }` for line streams (`waybar_timer hook`), `StdioCollector { onStreamFinished: ... }` for one-shot commands. `this.text` inside the collector handlers.
- `Quickshell.execDetached(["cmd", "arg"])` for fire-and-forget; use `["sh", "-c", "..."]` when shell features (env vars, `||`) are needed.
- Restarting the shell on monitor changes is unnecessary and leaves stale layers: `Variants` over `Quickshell.screens` creates/removes a `PanelWindow` per screen automatically.

## Testing (summary)

Full harness in `references/testing.md`. Core loop: change → `qs log` clean → screenshot with `grim` → crop/zoom with ImageMagick → read with the vision subagent → corroborate with pixel diffs → drive interactions with `ydotool` → compare values against ground truth (`wpctl`, `upower`, `nmcli`, `hyprctl`, `/proc`, sysfs).

Quick recipes:

```sh
# hotplug test (safe, no hardware): second bar should appear/disappear
hyprctl output create headless && hyprctl layers      # HEADLESS-1 ns=quickshell
hyprctl output remove HEADLESS-1

# negative test: network state
nmcli networking off   # pill -> "Disconnected ⚠" red
nmcli networking on

# config-error resilience: break a file, shell must survive, then restore
printf '\n@@@\n' >> ~/.config/quickshell/Tooltip.qml   # then fix it
```

## Conventions

- Colors/metrics only from `Theme`; never hardcode hex outside `Theme.qml`.
- New bar modules: a `widgets/Foo.qml` rooted in `Pill`, plus one line in `Bar.qml`'s right row in the intended position. Set `bg`, content `Text`(s), optional `tooltip`, click handlers.
- Tooltips and hover underline come free from `Pill` — don't reimplement them.
- Menus/popups: use `BarPopup` (focus-grabbed) or the `Tooltip` singleton, not ad-hoc windows.
- Keep `qmllint` clean with the command above; treat a 255 exit as one of the two known linter crashes.

Reference API snippets: `references/api-patterns.md`.
