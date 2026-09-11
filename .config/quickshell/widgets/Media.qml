import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs

Pill {
    id: root

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player !== null && player.isPlaying

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

    Text {
        text: {
            if (!root.player)
                return "";
            const state = root.playing ? "\uF04B" : "\uF04C";
            const artist = root.player.trackArtist || "";
            const title = root.player.trackTitle || "";
            const label = artist && title ? `${artist} - ${title}` : (title || artist || root.player.identity || "");
            return `${state} ${label} \uF001`;
        }
        color: Theme.base
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 420)
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
