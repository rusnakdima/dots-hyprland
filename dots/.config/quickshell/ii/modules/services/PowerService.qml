pragma Singleton

// PowerService.qml - System power actions (suspend, hibernate, etc.)
//
// Quickshell global shortcuts can call these via `quickshell:power_sleep`.
// Detached processes so the Quickshell main thread doesn't block on the
// systemd call.

import Quickshell
import QtQuick

Singleton {
    id: root

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"])
    }

    function hibernate() {
        Quickshell.execDetached(["systemctl", "hibernate"])
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"])
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"])
    }

    function lock() {
        Quickshell.execDetached(["hyprlock"])
    }
}
