pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

WListView {
    id: root

    property list<DesktopEntry> desktopEntries: [...DesktopEntries.applications.values].sort((a, b) => a.name.localeCompare(b.name))

    implicitHeight: 300
    spacing: 4

    component AppListItem: WButton {
        id: appListItem
        required property DesktopEntry desktopEntry

        property bool pinnedStart: LauncherApps.isPinned(appListItem.desktopEntry.id);
        property bool pinnedTaskbar: TaskbarApps.isPinned(appListItem.desktopEntry.id);

        Layout.fillWidth: true
        implicitHeight: 48

        contentItem: RowLayout {
            spacing: 16
            WAppIcon {
                Layout.leftMargin: 12
                iconName: appListItem.desktopEntry.icon
                implicitSize: 28
                tryCustomIcon: false
            }
            WText {
                Layout.fillWidth: true
                text: appListItem.desktopEntry.name
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.large
            }
        }

        onClicked: {
            GlobalStates.searchOpen = false;
            appListItem.desktopEntry.execute();
        }

        altAction: () => {
            appListMenu.popup()
        }

        WMenu {
            id: appListMenu
            downDirection: true

            WMenuItem {
                icon.name: appListItem.pinnedStart ? "pin-off" : "pin"
                text: appListItem.pinnedStart ? Translation.tr("Unpin from Start") : Translation.tr("Pin to Start")
                onTriggered: {
                    LauncherApps.togglePin(appListItem.desktopEntry.id);
                }
            }
            WMenuItem {
                icon.name: appListItem.pinnedTaskbar ? "pin-off" : "pin"
                text: appListItem.pinnedTaskbar ? Translation.tr("Unpin from taskbar") : Translation.tr("Pin to taskbar")
                onTriggered: {
                    TaskbarApps.togglePin(appListItem.desktopEntry.id);
                }
            }
        }
    }

    Repeater {
        model: root.desktopEntries
        delegate: AppListItem {
            required property DesktopEntry modelData
            desktopEntry: modelData
        }
    }
}
