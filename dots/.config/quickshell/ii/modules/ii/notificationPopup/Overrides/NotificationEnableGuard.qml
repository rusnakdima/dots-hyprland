import QtQuick
import Quickshell

/**
 * NotificationEnableGuard - Override for NotificationPopup
 *
 * Guards notification popup visibility against missing config.
 * Falls back to enabled=true when notifications.popup is absent.
 */
pragma Singleton
pragma ComponentBehavior: Bound

QtObject {
    function isEnabled() {
        return Config.options?.notifications?.popup?.enable ?? true
    }
}
