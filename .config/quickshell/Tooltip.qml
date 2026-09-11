pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property Item item: null
    property string text: ""
    property bool shown: false
    property bool calendar: false

    function show(target, value, withCalendar) {
        if (!value && withCalendar !== true)
            return;
        hideTimer.stop();
        root.item = target;
        root.text = value || "";
        root.calendar = withCalendar === true;
        root.shown = true;
    }

    function hide(target) {
        if (root.item !== target)
            return;
        hideTimer.restart();
    }

    function calendarDays() {
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth();
        const firstDow = (new Date(year, month, 1).getDay() + 6) % 7;
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const days = [];
        for (let i = 0; i < firstDow; i++)
            days.push({ label: "", today: false });
        for (let d = 1; d <= daysInMonth; d++)
            days.push({ label: String(d), today: d === now.getDate() });
        return days;
    }

    function calendarTitle(): string {
        return Qt.formatDateTime(new Date(), "MMMM yyyy");
    }

    Timer {
        id: hideTimer
        interval: 120
        onTriggered: root.shown = false
    }
}
