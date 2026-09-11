pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color sapphire: "#74c7ec"
    readonly property color sky: "#89dceb"
    readonly property color teal: "#94e2d5"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color peach: "#fab387"
    readonly property color maroon: "#eba0ac"
    readonly property color red: "#f38ba8"
    readonly property color mauve: "#cba6f7"
    readonly property color pink: "#f5c2e7"
    readonly property color flamingo: "#f2cdcd"
    readonly property color rosewater: "#f5e0dc"

    readonly property int barHeight: 50
    readonly property int pillHeight: 42
    readonly property int pillRadius: 4
    readonly property int pillPadding: 10
    readonly property int pillSpacing: 4

    readonly property int fontSize: 16
    readonly property string fontFamily: "Font Awesome 7 Free Solid"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
