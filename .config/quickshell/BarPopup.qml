import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: root

    required property Item anchorItem
    property bool open: false
    property int gapY: 6
    property int screenMargin: 8

    default property alias content: holder.data

    function close() {
        root.open = false;
    }

    visible: open
    color: "transparent"
    implicitWidth: Math.ceil(frame.implicitWidth)
    implicitHeight: Math.ceil(frame.implicitHeight)

    HyprlandFocusGrab {
        active: root.open
        windows: {
            const barWindow = root.anchorItem ? root.anchorItem.QsWindow.window : null;
            return barWindow ? [root, barWindow] : [root];
        }
        onCleared: root.close()
    }

    anchor {
        id: anchorGroup

        window: root.anchorItem ? root.anchorItem.QsWindow.window : null
        adjustment: PopupAdjustment.Slide
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        rect.width: 1
        rect.height: 1

        onAnchoring: {
            const target = root.anchorItem;
            const window = target ? target.QsWindow.window : null;
            if (!window)
                return;
            const point = window.contentItem.mapFromItem(target, target.width / 2 - root.implicitWidth / 2, 0);
            point.x = Math.max(root.screenMargin, Math.min(point.x, window.width - root.implicitWidth - root.screenMargin));
            anchorGroup.rect.x = Math.round(point.x);
            anchorGroup.rect.y = Math.round(window.height + root.gapY);
        }
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        implicitWidth: holder.implicitWidth + 16
        implicitHeight: holder.implicitHeight + 12
        radius: Theme.pillRadius
        color: Theme.alpha(Theme.base, 0.98)
        border.width: 1
        border.color: Theme.surface1

        Item {
            id: holder

            anchors.centerIn: parent
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
