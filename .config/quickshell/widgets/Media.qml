import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs

Pill {
    id: root

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player !== null && player.isPlaying
    readonly property string label: {
        if (!player)
            return "";
        const state = playing ? "\uF04B" : "\uF04C";
        const artist = player.trackArtist || "";
        const title = player.trackTitle || "";
        const track = artist && title ? `${artist} - ${title}` : (title || artist || player.identity || "");
        return `${state} ${track} \uF001`;
    }

    property real maxTextWidth: 200

    visible: player !== null
    bg: playing ? Theme.alpha(Theme.green, 0.75) : Theme.alpha(Theme.teal, 0.75)
    interactive: visible
    tooltip: {
        if (!root.player)
            return "";
        const artist = root.player.trackArtist || "";
        const title = root.player.trackTitle || "";
        const album = root.player.trackAlbum || "";
        const label = artist && title ? `${artist} - ${title}` : (title || artist || root.player.identity || "");
        return album ? `${label}\n${album}` : label;
    }

    onLabelChanged: track.x = 0

    Item {
        id: viewport

        clip: true
        implicitWidth: Math.min(labelText.implicitWidth, root.maxTextWidth)
        implicitHeight: labelText.implicitHeight

        readonly property bool overflowing: labelText.implicitWidth > width
        readonly property real loopDistance: labelText.implicitWidth + track.spacing

        onOverflowingChanged: {
            if (!overflowing)
                track.x = 0;
        }

        Text {
            id: labelText

            visible: false
            text: root.label
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }

        Row {
            id: track

            spacing: 32

            Text {
                text: labelText.text
                color: Theme.base
                font: labelText.font
            }

            Text {
                text: labelText.text
                color: Theme.base
                font: labelText.font
                visible: viewport.overflowing
            }
        }

        SequentialAnimation {
            running: viewport.overflowing && !root.hovered
            loops: Animation.Infinite

            PauseAnimation { duration: 2500 }
            NumberAnimation {
                target: track
                property: "x"
                from: 0
                to: -viewport.loopDistance
                duration: Math.max(4000, viewport.loopDistance / 45 * 1000)
                easing.type: Easing.Linear
            }
        }
    }

    onClicked: {
        if (root.player && root.player.canTogglePlaying)
            root.player.togglePlaying();
    }
    onMiddleClicked: {
        if (root.player && root.player.canGoNext)
            root.player.next();
    }
    onScrolled: (delta) => {
        if (!root.player)
            return;
        if (delta > 0 && root.player.canGoNext)
            root.player.next();
        else if (delta < 0 && root.player.canGoPrevious)
            root.player.previous();
    }
}
