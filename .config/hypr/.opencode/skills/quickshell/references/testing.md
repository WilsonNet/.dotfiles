# Testing the Quickshell bar (verified harness)

Environment facts (this machine): HDMI-A-1 3440x1440 at Hyprland scale 1.3333
→ logical 2580x1080; the bar is a 50-logical-pixel top layer. `grim`,
ImageMagick (`magick`), `ydotool`/`ydotoold`, and `wtype` are installed.
The vision subagent (`task` tool, `subagent_type: vision`) reads screenshots —
pass absolute file paths in the prompt and ask for literal transcription; it
can misread/hallucinate, so corroborate with pixel diffs.

## 1. Logs first

```sh
qs log                        # follow the running instance
nohup quickshell > /tmp/qs.log 2>&1 &   # or run with stderr captured
rg "WARN|ERROR" /tmp/qs.log
```

A healthy reload shows only `Configuration Loaded`. All warnings matter: fix
them before testing function.

## 2. Screenshots and crops

```sh
grim -o HDMI-A-1 /tmp/x.png
magick /tmp/x.png -crop 3440x72+0+0 +repage /tmp/x-bar.png        # bar strip
magick /tmp/x-bar.png -crop 1000x72+1940+0 +repage -resize 300% /tmp/x-right.png
```

Then hand crops to the vision subagent with ground truth ("what SHOULD be
shown") and ask for MATCH/MISMATCH/MISSING per element plus any tofu/overlap.

## 3. Pixel evidence for interactions

Compare screenshot regions before/after an action with PIL:

```python
from PIL import Image, ImageChops
import numpy as np
def diff(a, b, box):
    ia = Image.open(a).crop(box).convert('RGB'); ib = Image.open(b).crop(box).convert('RGB')
    return int((np.array(ImageChops.difference(ia, ib)).sum(axis=2) > 30).sum())
```

`0` = definitely no change. Non-zero needs interpretation: other widgets
changing width can shift the whole right row, so a "diff" may just be a layout
shift. For definitive state, prefer ground truth (below) plus OCR.

## 4. Driving input with ydotool

Button codes: `0xC0` left, `0xC1` right, `0xC2` middle (`0x00` selects but
does nothing; `0x40` down-only, `0x80` up-only).

```sh
ydotool mousemove --absolute 640 540       # park away from the bar first
ydotool click 0xC0                         # left click
ydotool key 1:1 1:0                        # raw keycodes: Escape; CapsLock = 58
ydotool mousemove -w -- 0 1                # wheel up; "0 -1" = wheel down
```

Absolute-coordinate quirk: input is **half the logical coordinate**
(empirically input (1290, 540) lands on logical (2579, 1079)). For physical
pixels use `input = physical / 2.6667` (this monitor's scale). Verify with
`hyprctl cursorpos` after each move.

Hover needs ~0.5-1 s before the tooltip/underline appears. Drop coordinates
from a pill found by color analysis (PIL) rather than eyeballing.

Popup buttons: a popup anchors to its widget and its x shifts with the widget's
width (e.g. the timer pill grows in visual mode), so hardcoded click
coordinates go stale after UI changes. Locate the green Start button (exact
`#a6e3a1`) in a screenshot and compute neighboring buttons from it, or verify
each click's effect immediately (e.g. the `waybar_timer` state or the settings
file).

## 5. Ground truth for widget values

| Widget | Command |
|---|---|
| volume/mic | `wpctl get-volume @DEFAULT_AUDIO_SINK@` / `@DEFAULT_AUDIO_SOURCE@` |
| battery | `upower -i $(upower -e \| grep BAT)` |
| cpu | `top -bn1` (ignore the first idle sample) |
| memory | `free -m` → `(total - available) / total` |
| temperature | `cat /sys/class/thermal/thermal_zone0/temp` |
| backlight | `cat /sys/class/backlight/acpi_video0/brightness /sys/class/backlight/acpi_video0/max_brightness` |
| network | `nmcli -t -f TYPE,STATE,CONNECTION device status`, `nmcli -t -g IP4.ADDRESS device show <iface>` |
| title/layout/keys | `hyprctl activewindow -j`, `hyprctl devices -j` |
| workspaces | `hyprctl activeworkspace -j`, `hyprctl workspaces -j` |
| timer | `timeout 2 /home/wilsonn/bin/waybar_timer hook \| head -1` |
| power mode | `/home/wilsonn/bin/power-mode get` |
| media | `playerctl -l`, `playerctl status` |

## 6. Feature tests (regression checklist)

- **Startup**: fresh `quickshell` → 0 WARN/ERROR; `hyprctl layers` shows one
  `ns=quickshell` surface sized to the bar.
- **Hot reload**: save any file → `Configuration Loaded` in the log.
- **Config-error resilience**: append `@@@` to a config file → shell process
  stays alive, log shows the error; restore the file → recovers with one layer.
- **Hotplug**: `hyprctl output create headless` → `hyprctl layers` shows a
  second `quickshell` layer; `hyprctl output remove HEADLESS-1` → back to one,
  no warnings. Never restart the shell for monitor changes.
- **Workspaces**: click a numeral → `hyprctl activeworkspace` changes.
- **Title**: focus another window → `qs ipc call debug activeWindow` and the
  centered text change; long titles elide, never overlap pills.
- **Media**: pill appears when an MPRIS player exists (Brave does), hidden
  when none; click toggles when the player supports it.
- **Volume**: scroll changes `wpctl get-volume` by 1%; mute/unmute via wpctl
  updates the pill live; click opens pavucontrol.
- **Timer**: wheel up creates/increases, wheel down decreases, right click
  pauses (`alt: "paused"`), middle click cancels (`alt: "standby"`).
- **Network**: `nmcli networking off` → red "Disconnected ⚠"; back on →
  ethernet IP returns.
- **Idle inhibitor**: click toggles coffee/sleep icon and background.
- **Keyboard**: `ydotool key 58:1 58:0` toggles caps; pill lock state follows.
- **Tray**: right click opens the app menu below the bar; submenu entries
  drill in with a back header; Escape/outside click closes.
- **Power menu**: click opens Shutdown/Reboot/Suspend/Hibernate; Escape closes.
- **Tooltips**: hover pills → text below the bar; clock shows the calendar
  with today highlighted; hover underline on every pill.
- **Backlight scroll**: scroll on the cyan pill changes sysfs brightness and
  the pill updates through `FileView`.
- **Resources**: `ps -o pcpu,rss,etime -p $(pgrep -x quickshell)` — idle CPU
  < 1%, RSS stable (~280 MB), only `waybar_timer hook` as a long-lived child.
