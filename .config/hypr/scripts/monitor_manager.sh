#!/bin/bash
# Monitor management: handles lid switch + monitor hotplug via Hyprland IPC
# Replaces kanshi for dynamic display configuration

reapply() {
    sleep 0.3
    if hyprctl monitors all 2>/dev/null | grep -q "LG Electronics"; then
        if hyprctl monitors all | grep -q "LG ULTRAWIDE"; then
            hyprctl keyword monitor "LG Electronics LG ULTRAWIDE 209AZPU4U744, 3440x1440@84.96, auto, 1.333333"
        elif hyprctl monitors all | grep -q "LG HDR WFHD"; then
            hyprctl keyword monitor "LG Electronics LG HDR WFHD 0x01010101, 2560x1080@74.99, auto, 1.333333"
        fi
        hyprctl keyword monitor "eDP-1, disable"
    else
        hyprctl keyword monitor "eDP-1, preferred, auto, 1.6"
    fi
    pkill waybar 2>/dev/null; waybar &
}

# Handle direct invocation (from lid-open binding)
if [ "$1" = "--lid-open" ]; then
    reapply
    exit 0
fi

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
