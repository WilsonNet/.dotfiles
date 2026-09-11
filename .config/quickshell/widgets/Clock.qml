import QtQuick
import Quickshell
import qs

Pill {
    id: root

    bg: Theme.alpha(Theme.surface1, 0.6)
    interactive: true

    property bool showDate: false

    tooltip: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    tooltipCalendar: true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        text: root.showDate
            ? Qt.formatDateTime(clock.date, "yyyy-MM-dd")
            : Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.text
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    onClicked: root.showDate = !root.showDate
}
