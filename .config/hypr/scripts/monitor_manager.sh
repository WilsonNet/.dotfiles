#!/bin/bash
# Monitor management: handles lid switch + monitor hotplug via Hyprland IPC
# Replaces kanshi for dynamic display configuration

reapply() {
    # Debounce: skip if another reapply is already running
    local lock="/tmp/hypr-monitor.lock"
    mkdir "$lock" 2>/dev/null || return

    sleep 0.3
    if hyprctl monitors all 2>/dev/null | grep -q "LG ULTRAWIDE"; then
        hyprctl keyword monitor "desc:LG Electronics LG ULTRAWIDE 209AZPU4U744, 3440x1440@84.96, auto, 1.333333"
        hyprctl keyword monitor "eDP-1, disable"
    elif hyprctl monitors all | grep -q "LG HDR WFHD"; then
        hyprctl keyword monitor "desc:LG Electronics LG HDR WFHD 0x01010101, 2560x1080@74.99, auto, 1.333333"
        hyprctl keyword monitor "eDP-1, disable"
    else
        hyprctl keyword monitor "eDP-1, preferred, auto, 1.6"
    fi
    pkill waybar 2>/dev/null; waybar &
    rmdir "$lock" 2>/dev/null
}

stream_sp() {
    hyprctl keyword monitor "desc:LG Electronics LG ULTRAWIDE 209AZPU4U744, 2560x1440@120, auto, 1.333333"
    hyprctl keyword monitor "eDP-1, disable"
    pkill waybar 2>/dev/null; waybar &
}

stream_ctb() {
    hyprctl keyword monitor "desc:LG Electronics LG HDR WFHD 0x01010101, 1920x1080@60, auto, 1.333333"
    hyprctl keyword monitor "eDP-1, disable"
    pkill waybar 2>/dev/null; waybar &
}

# Handle direct invocation
case "$1" in
    --lid-open)
        reapply
        exit 0
        ;;
    --stream)
        case "$2" in
            sp) stream_sp ;;
            ctb) stream_ctb ;;
            *) echo "Usage: $0 --stream {sp|ctb}"; exit 1 ;;
        esac
        exit 0
        ;;
esac

# Apply config on startup
reapply

# Daemon mode: listen for Hyprland socket2 events
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
while true; do
    nc -U "$SOCKET" 2>/dev/null | while read -r line; do
        case "$line" in
            monitoradded*|monitorremoved*)
                reapply &
                ;;
        esac
    done
    # Reconnect if the socket disconnects
    sleep 1
done
