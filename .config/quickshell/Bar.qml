import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.widgets

PanelWindow {
    id: root

    required property var modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: Theme.alpha(Theme.base, 0.7)
    exclusionMode: ExclusionMode.Auto

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top

    Row {
        id: leftRow

        anchors {
            left: parent.left
            leftMargin: Theme.pillSpacing
            verticalCenter: parent.verticalCenter
        }

        Workspaces {}
    }

    ActiveWindow {
        id: activeWindow

        anchors.verticalCenter: parent.verticalCenter
        maxWidth: Math.max(80, rightRow.x - (leftRow.x + leftRow.width) - 24)
        x: Math.round((leftRow.x + leftRow.width + rightRow.x) / 2 - width / 2)
    }

    Row {
        id: rightRow

        anchors {
            right: parent.right
            rightMargin: Theme.pillSpacing
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.pillSpacing

        Media {}
        Volume {}
        Timer {}
        NetworkStatus {}
        IdleInhibit {}
        PowerMode {}
        Cpu {}
        Memory {}
        Temperature {}
        Backlight {}
        KeyboardState {}
        Language {}
        Battery {}
        Clock {}
        Tray {}
        PowerButton {}
    }

    PopupWindow {
        id: tooltipWindow

        visible: Tooltip.shown && Tooltip.item !== null && (Tooltip.text !== "" || Tooltip.calendar)
        color: "transparent"
        implicitWidth: Math.ceil(tooltipBubble.implicitWidth)
        implicitHeight: Math.ceil(tooltipBubble.implicitHeight)

        anchor {
            id: tooltipAnchor

            window: Tooltip.item ? Tooltip.item.QsWindow.window : null
            adjustment: PopupAdjustment.Slide
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            rect.width: 1
            rect.height: 1

            onAnchoring: {
                const target = Tooltip.item;
                const window = target ? target.QsWindow.window : null;
                if (!window)
                    return;
                const point = window.contentItem.mapFromItem(target,
                    target.width / 2 - tooltipWindow.implicitWidth / 2,
                    0);
                point.x = Math.max(8, Math.min(point.x, window.width - tooltipWindow.implicitWidth - 8));
                tooltipAnchor.rect.x = Math.round(point.x);
                tooltipAnchor.rect.y = Math.round(window.height + 6);
            }
        }

        Rectangle {
            id: tooltipBubble

            anchors.fill: parent
            implicitWidth: tooltipColumn.implicitWidth + 20
            implicitHeight: tooltipColumn.implicitHeight + 12
            radius: Theme.pillRadius
            color: Theme.alpha(Theme.base, 0.98)
            border.width: 1
            border.color: Theme.surface1

            Column {
                id: tooltipColumn

                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Tooltip.text
                    color: Theme.text
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    visible: text !== ""
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Tooltip.calendarTitle()
                    color: Theme.text
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    visible: Tooltip.calendar
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7
                    spacing: 2
                    visible: Tooltip.calendar

                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                        delegate: Text {
                            required property string modelData

                            width: 26
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Theme.subtext
                            font.pixelSize: 12
                            font.family: Theme.fontFamily
                        }
                    }
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7
                    spacing: 2
                    visible: Tooltip.calendar

                    Repeater {
                        model: Tooltip.calendarDays()

                        delegate: Text {
                            required property var modelData

                            width: 26
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.label
                            color: modelData.today ? Theme.mauve : Theme.text
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            font.bold: modelData.today
                        }
                    }
                }
            }
        }
    }
}
