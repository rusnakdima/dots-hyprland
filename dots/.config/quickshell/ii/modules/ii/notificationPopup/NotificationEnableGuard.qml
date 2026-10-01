import QtQuick
import Quickshell

/**
 * NotificationEnableGuard - guards notification popup visibility.
 *
 * Reads Config.options.notifications.popup.enable, falling back to true.
 * Exists as a separate module so it can be imported by both the ii
 * NotificationPopup and the waffle WaffleNotificationPopup without
 * duplicating the logic.
 */
pragma Singleton
pragma ComponentBehavior: Bound

QtObject {
    function isEnabled() {
        return Config.options?.notifications?.popup?.enable ?? true
    }
}
