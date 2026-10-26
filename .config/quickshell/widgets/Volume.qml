import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

Pill {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property var sourceAudio: source ? source.audio : null
    readonly property real sinkVolume: sinkAudio ? sinkAudio.volume : 0
    readonly property bool muted: sinkAudio ? sinkAudio.muted : false
    readonly property real micVolume: sourceAudio ? sourceAudio.volume : 0
    readonly property bool micMuted: sourceAudio ? sourceAudio.muted : false
    readonly property var volumeIcons: ["\uF026", "\uF027", "\uF028"]
    // The pill reads "output mic": the left half targets the sink, the right
    // half the source, matching what is drawn under the cursor.
    readonly property bool overMic: root.mouseX >= root.width / 2

    bg: muted ? Theme.surface1 : Theme.alpha(Theme.maroon, 0.75)
    interactive: true
    tooltip: {
        const target = root.overMic ? "Mic" : "Output";
        const level = root.overMic
            ? `${Math.round(root.micVolume * 100)}%`
            : `${Math.round(root.sinkVolume * 100)}%`;
        const isMuted = root.overMic ? root.micMuted : root.muted;
        const action = isMuted ? "Click to unmute" : "Click to mute";
        return `${target} ${level} \u00B7 ${action} \u00B7 Right-click: mixer`;
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Text {
        // The percentage stays visible while muted so the pill keeps its width:
        // a shrinking pill slides out from under the cursor mid-click.
        text: {
            const micIcon = root.micMuted ? "\uF131" : "\uF130";
            const icon = root.muted
                ? "\uF6A9"
                : root.volumeIcons[Math.min(2, Math.floor(root.sinkVolume * 3))];
            return `${Math.round(root.sinkVolume * 100)}% ${icon} ${Math.round(root.micVolume * 100)}% ${micIcon}`;
        }
        color: root.muted ? Theme.text : Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    onClicked: (x) => {
        const node = x < root.width / 2 ? root.sinkAudio : root.sourceAudio;
        if (node)
            node.muted = !node.muted;
    }
    // Focus an already-running mixer (pavucontrol cannot raise itself across
    // workspaces); only spawn it when no window exists yet.
    onRightClicked: Quickshell.execDetached(["sh", "-c",
        "hyprctl dispatch 'hl.dsp.focus({ window = \"class:org.pulseaudio.pavucontrol\" })' >/dev/null 2>&1; " +
        "hyprctl activewindow -j | grep -q pavucontrol || pavucontrol"])
    onScrolled: (delta) => {
        if (!sinkAudio)
            return;
        const step = delta > 0 ? 0.01 : -0.01;
        sinkAudio.volume = Math.max(0, Math.min(1.5, sinkAudio.volume + step));
    }
}
