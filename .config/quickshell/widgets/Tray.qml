import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs

Pill {
    id: root

    bg: Theme.alpha(Theme.surface1, 0.6)

    property var activeItem: null
    property var activeAnchor: null
    property var submenuStack: []

    readonly property var currentChildren: submenuStack.length > 0
        ? submenuStack[submenuStack.length - 1].opener.children
        : menuOpener.children
    readonly property string currentTitle: submenuStack.length > 0
        ? submenuStack[submenuStack.length - 1].title
        : ""

    function openMenu(item, anchor) {
        if (!item || !item.menu)
            return;
        resetSubmenus();
        root.activeItem = item;
        root.activeAnchor = anchor;
        trayMenu.open = true;
    }

    function resetSubmenus() {
        const stack = root.submenuStack;
        root.submenuStack = [];
        for (let i = stack.length - 1; i >= 0; i--)
            stack[i].opener.destroy();
    }

    function enterSubmenu(entry, title) {
        const opener = submenuComponent.createObject(root, { menu: entry });
        if (!opener)
            return;
        root.submenuStack = root.submenuStack.concat([{ opener: opener, title: title }]);
    }

    function leaveSubmenu() {
        if (root.submenuStack.length === 0)
            return;
        const stack = root.submenuStack.slice();
        const top = stack.pop();
        top.opener.destroy();
        root.submenuStack = stack;
    }

    Component {
        id: submenuComponent

        QsMenuOpener {}
    }

    Row {
        id: trayRow

        spacing: 10

        Repeater {
            model: SystemTray.items.values

            delegate: Item {
                id: iconItem

                required property var modelData

                width: 21
                height: 21
                opacity: modelData.status === Status.Passive ? 0.5 : 1

                Image {
                    anchors.fill: parent
                    source: iconItem.modelData.icon
                    sourceSize.width: Math.round(width * Screen.devicePixelRatio)
                    sourceSize.height: Math.round(height * Screen.devicePixelRatio)
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: Tooltip.show(iconItem, iconItem.modelData.tooltipTitle || iconItem.modelData.title || "")
                    onExited: Tooltip.hide(iconItem)
                    onClicked: (e) => {
                        const item = iconItem.modelData;
                        if (e.button === Qt.RightButton) {
                            root.openMenu(item, iconItem);
                        } else if (e.button === Qt.MiddleButton) {
                            if (item.secondaryActivate)
                                item.secondaryActivate();
                        } else if (item.onlyMenu) {
                            root.openMenu(item, iconItem);
                        } else {
                            item.activate();
                        }
                    }
                }
            }
        }
    }

    QsMenuOpener {
        id: menuOpener

        menu: root.activeItem ? root.activeItem.menu : null
    }

    BarPopup {
        id: trayMenu

        anchorItem: root.activeAnchor || root
        gapY: 4

        onOpenChanged: if (!open) Qt.callLater(root.resetSubmenus)

        Column {
            Item {
                implicitWidth: 180
                implicitHeight: root.submenuStack.length > 0 ? 28 : 0
                visible: root.submenuStack.length > 0

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.pillRadius
                    color: backMouse.containsMouse ? Theme.surface0 : "transparent"
                }

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 12
                    }
                    text: "\u2039 " + root.currentTitle
                    color: Theme.text
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.leaveSubmenu()
                }
            }

            Repeater {
                model: root.currentChildren

                delegate: Item {
                    id: entryItem

                    required property var modelData

                    implicitWidth: Math.max(180, entryText.implicitWidth + 44)
                    implicitHeight: modelData.isSeparator ? 9 : 28
                    opacity: modelData.enabled ? 1 : 0.45

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 4
                            rightMargin: 4
                        }
                        height: 1
                        color: Theme.surface1
                        visible: entryItem.modelData.isSeparator
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.pillRadius
                        color: entryMouse.containsMouse && entryItem.modelData.enabled ? Theme.surface0 : "transparent"
                        visible: !entryItem.modelData.isSeparator
                    }

                    Text {
                        id: entryText

                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 12
                        }
                        text: entryItem.modelData.text || ""
                        color: Theme.text
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        visible: !entryItem.modelData.isSeparator
                    }

                    Text {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: 8
                        }
                        text: "\u203A"
                        color: Theme.text
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        visible: !entryItem.modelData.isSeparator && entryItem.modelData.hasChildren
                    }

                    MouseArea {
                        id: entryMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !entryItem.modelData.isSeparator && entryItem.modelData.enabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (entryItem.modelData.hasChildren) {
                                root.enterSubmenu(entryItem.modelData, entryItem.modelData.text || "");
                            } else {
                                entryItem.modelData.triggered();
                                trayMenu.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
