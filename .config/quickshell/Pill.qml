import QtQuick

Item {
    id: root

    default property alias content: inner.data
    property alias hovered: mouse.containsMouse
    readonly property real mouseX: mouse.mouseX
    property color bg: "transparent"
    property color fg: Theme.base
    property color hoverColor: Theme.mauve
    property bool interactive: false
    property bool hoverUnderline: true
    property string tooltip: ""
    property bool tooltipCalendar: false

    signal clicked(real x)
    signal rightClicked()
    signal middleClicked()
    signal scrolled(int delta)

    implicitWidth: inner.implicitWidth + 2 * Theme.pillPadding
    implicitHeight: Theme.pillHeight

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.pillRadius
        color: root.bg
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 4
            rightMargin: 4
            bottomMargin: 3
        }
        height: 2
        radius: 1
        color: root.hoverColor
        visible: root.hoverUnderline && mouse.containsMouse
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: Tooltip.show(root, root.tooltip, root.tooltipCalendar)
        onExited: Tooltip.hide(root)
        onClicked: (e) => {
            if (e.button === Qt.LeftButton)
                root.clicked(e.x);
            else if (e.button === Qt.RightButton)
                root.rightClicked();
            else if (e.button === Qt.MiddleButton)
                root.middleClicked();
        }
        onWheel: (e) => root.scrolled(e.angleDelta.y)
    }

    // Keep the tooltip live when its text depends on hover position
    // (e.g. Volume's per-half hints).
    onTooltipChanged: {
        if (mouse.containsMouse)
            Tooltip.show(root, root.tooltip, root.tooltipCalendar);
    }

    Item {
        id: inner
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
