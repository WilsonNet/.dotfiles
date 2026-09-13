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
    readonly property bool hasCJK: /[\u3000-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uff00-\uffef]/.test(label)
    property real ledCellSize: hasCJK ? 1.6 : 2.1
    property real ledDotRadius: 0.5
    readonly property color ledColor: playing ? Theme.ledGreen : Theme.ledAmber

    visible: player !== null
    bg: Theme.alpha(Theme.crust, 0.9)
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
            font.pixelSize: 22
            font.bold: true
            font.family: Theme.fontFamily
        }

        Item {
            id: marqueeArea

            anchors.fill: parent
            clip: true

            Row {
                id: track

                spacing: 32

                Text {
                    text: labelText.text
                    color: "white"
                    font: labelText.font
                }

                Text {
                    text: labelText.text
                    color: "white"
                    font: labelText.font
                    visible: viewport.overflowing
                }
            }
        }

        ShaderEffectSource {
            id: marqueeSource

            sourceItem: marqueeArea
            live: true
            hideSource: true
        }

        ShaderEffect {
            id: ledPanel

            anchors.fill: parent
            property var source: marqueeSource
            property vector2d res: Qt.vector2d(width, height)
            property real cell: root.ledCellSize
            property real dotRadius: root.ledDotRadius
            property color led: root.ledColor
            property real bloom: 0.85
            fragmentShader: "../shaders/led.frag.qsb"
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
