import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

/**
 * ActiveWindow — displays the currently active window title and icon.
 * Stub implementation when Hyprland IPC is disabled (HYPRLAND_IPC=OFF).
 * Shows empty/inactive state.
 */
Item {
    id: root

    // HyprlandMonitor is unavailable when HYPRLAND_IPC=OFF
    // Just show an empty/invisible widget
    visible: false
    implicitWidth: 0
    implicitHeight: 0
}
