pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell

/**
 * Workspaces — displays workspace buttons and handles workspace switching.
 * Stub implementation when Hyprland IPC is disabled (HYPRLAND_IPC=OFF).
 * Shows nothing since HyprlandMonitor type is unavailable.
 */
ButtonMouseArea {
    id: root

    // HyprlandMonitor is unavailable when HYPRLAND_IPC=OFF
    visible: false
    implicitWidth: 0
    implicitHeight: 0

    property bool vertical: false
}
