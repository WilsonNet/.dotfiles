import QtQuick
import Quickshell.Wayland
import qs

Text {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel

    property real maxWidth: 700

    text: toplevel ? (toplevel.title || toplevel.appId || "") : ""
    color: Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    elide: Text.ElideRight
    width: Math.min(implicitWidth, maxWidth)
    horizontalAlignment: Text.AlignHCenter
}
