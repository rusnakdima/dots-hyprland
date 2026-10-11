pragma ComponentBehavior: Bound

import qs
import qs.modules.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/*
 * LockScreen — per-screen lock UI.
 * Each screen instantiates one of these via its Lock.qml loader.
 *
 * On the monitor that was active when lock was engaged (isMain === true):
 *   shows the full LockCenter widget.
 * On all other monitors (isMain === false):
 *   shows LockClockOnly at 50% opacity — a dimmed clock so users can
 *   still read the time without being distracted by the full lock UI.
 *
 * The locked monitor is tracked by services/LockService.qml singleton.
 */
Scope {
    id: root

    required property Component lockSurface
    /* The screen this lock UI is shown on. Set by the instantiating Loader. */
    required property string screenName

    /* True when this screen was the one that had focus when lock was triggered. */
    property bool isMain: LockService.lockedMonitor === root.screenName

    property alias context: lockContext
    property Component sessionLockSurface: WlSessionLockSurface {
        id: sessionLockSurface
        color: "transparent"

        /* Per-monitor lock UI: full lock on main monitor, dimmed clock on others. */
        Loader {
            active: GlobalStates.screenLocked
            anchors.fill: parent
            opacity: active ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            sourceComponent: root.isMain ? root.lockSurface : lockClockOnly
        }

        /* Minimal clock for non-main monitors. */
        component LockClockOnlyComponent: Item {
            id: clockRoot
            opacity: 0.5
            anchors.fill: parent

            property string timeText: {
                var now = new Date()
                return now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
            }
            property string dateText: {
                var now = new Date()
                return now.toLocaleDateString(Qt.locale(), Locale.LongFormat)
            }

            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: {
                    clockRoot.timeText = new Date().toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                    clockRoot.dateText = new Date().toLocaleDateString(Qt.locale(), Locale.LongFormat)
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: clockRoot.timeText
                    color: Appearance?.colors?.colOnSurface ?? "#ffffff"
                    font.pixelSize: 64
                    font.weight: Font.Light
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: clockRoot.dateText
                    color: Appearance?.colors?.colOnSurfaceVariant ?? "#aaaaaa"
                    font.pixelSize: 24
                    font.weight: Font.Normal
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        /* Reference to the LockClockOnlyComponent for the Loader above. */
        property Component lockClockOnly: LockClockOnlyComponent {}
    }

    Process {
        id: unlockKeyringProc
        onExited: (exitCode, exitStatus) => {
            KeyringStorage.fetchKeyringData();
        }
    }
    function unlockKeyring() {
        unlockKeyringProc.exec({
            environment: ({
                "UNLOCK_PASSWORD": lockContext.currentText
            }),
            command: ["bash", "-c", Quickshell.shellPath("scripts/keyring/unlock.sh")]
        })
    }

    // This stores all the information shared between the lock surfaces on each screen.
    LockContext {
        id: lockContext

        Connections {
            target: GlobalStates
            function onScreenLockedChanged() {
                if (GlobalStates.screenLocked) {
                    lockContext.reset();
                    lockContext.tryFingerUnlock();
                }
            }
        }

        onUnlocked: (targetAction) => {
            if (targetAction == LockContext.ActionEnum.Poweroff) {
                Session.poweroff();
                return;
            } else if (targetAction == LockContext.ActionEnum.Reboot) {
                Session.reboot();
                return;
            }

            if (Config.options.lock.security.unlockKeyring) root.unlockKeyring();

            // Unlock via LockService so lockedMonitor is cleared
            LockService.unlock();

            lockContext.reset();

            if (lockContext.alsoInhibitIdle) {
                lockContext.alsoInhibitIdle = false;
                Idle.toggleInhibit(true);
            }
        }
    }

    WlSessionLock {
        id: lock
        locked: GlobalStates.screenLocked
        surface: root.sessionLockSurface
    }

    function lock() {
        if (Config.options.lock.useHyprlock) {
            Quickshell.execDetached(["bash", "-c", "pidof hyprlock || hyprlock"]);
            return;
        }
        // Capture focused monitor before setting lock state
        LockService.lock();
    }

    IpcHandler {
        target: "lock"

        function activate(): void {
            root.lock();
        }
        function focus(): void {
            lockContext.shouldReFocus();
        }
    }

    GlobalShortcut {
        name: "lock"
        description: "Locks the screen"

        onPressed: {
            root.lock()
        }
    }

    GlobalShortcut {
        name: "lockFocus"
        description: "Re-focuses the lock screen after wake"

        onPressed: {
            lockContext.shouldReFocus();
        }
    }

    function initIfReady() {
        if (!Config.ready || !Persistent.ready) return;
        if (Config.options.lock.launchOnStartup && Persistent.isNewHyprlandInstance) {
            root.lock();
        } else {
            KeyringStorage.fetchKeyringData();
        }
    }
    Connections {
        target: Config
        function onReadyChanged() {
            root.initIfReady();
        }
    }
    Connections {
        target: Persistent
        function onReadyChanged() {
            root.initIfReady();
        }
    }
}
