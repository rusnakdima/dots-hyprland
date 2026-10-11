import qs.modules.common
import qs.modules.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property bool dashboardOpen: false
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false

    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    IpcHandler {
        target: "globalstates"

        property bool barOpen: root.barOpen
        property bool dashboardOpen: root.dashboardOpen
        property bool screenLocked: root.screenLocked

        function openDashboard(): void { root.dashboardOpen = true; }
        function closeDashboard(): void { root.dashboardOpen = false; }
        function lockScreen(): void { root.screenLocked = true; }

        signal barOpenChanged(bool open)
        signal dashboardOpenChanged(bool open)
        signal screenLockedChanged(bool locked)

        onBarOpenChanged: barOpenChanged(root.barOpen)
        onDashboardOpenChanged: dashboardOpenChanged(root.dashboardOpen)
        onScreenLockedChanged: screenLockedChanged(root.screenLocked)
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true
        }
        onReleased: {
            root.superDown = false
        }
    }
}