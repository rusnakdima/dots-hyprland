pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

/*
 * LockService — tracks which monitor was active when the screen was locked.
 * Created by cluster-g; replaces ad-hoc locked-monitor tracking that used
 * to live in individual QML files.
 *
 * Usage:
 *   import Quickshell.Services as QS
 *   QS.LockService.lockedMonitor   // string: monitor name, "" when unlocked
 *   QS.LockService.isLocked       // bool
 *
 * LockScreen.qml (or any lock UI) should call lock() and unlock() here
 * rather than setting GlobalStates directly, so this service stays in sync.
 */
Singleton {
    id: root

    /* Monitor name that was focused when lock was engaged. Empty string = unlocked. */
    property string lockedMonitor: ""

    /* Convenience: true when screen is locked (lockedMonitor != ""). */
    property bool isLocked: lockedMonitor !== ""

    /* Name of the primary/locked screen. Empty when unlocked.
     * Components on non-primary screens show a minimal clock overlay. */
    // property string primaryScreen: isLocked ? lockedMonitor : ""

    /* Lock the screen, capturing the currently focused monitor. */
    function lock() {
        lockedMonitor = Hyprland.focusedMonitor?.name ?? ""
        GlobalStates.screenLocked = true
    }

    /* Unlock: clear the locked-monitor state. */
    function unlock() {
        lockedMonitor = ""
        GlobalStates.screenLocked = false
    }

    /* Toggle lock state. */
    function toggle() {
        if (isLocked) {
            unlock()
        } else {
            lock()
        }
    }
}
