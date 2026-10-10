import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Dashboard — system dashboard with widgets.
 * Stub implementation when Hyprland IPC is disabled (HYPRLAND_IPC=OFF).
 */
Scope {
    id: dashboardScope

    PanelWindow {
        id: panelWindow
        property var monitor: null
        property bool monitorIsFocused: false
        visible: GlobalStates.dashboardOpen

        WlrLayershell.namespace: "quickshell:dashboard"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.dashboardOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        implicitWidth: dashboardLayout.implicitWidth + 80
        implicitHeight: dashboardLayout.implicitHeight + 80

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.dashboardOpen = false;
            }
        }

        // Background
        Rectangle {
            anchors.fill: parent
            anchors.margins: 20
            color: Appearance.colors.colBackgroundSurfaceContainer
            opacity: 0.95
            radius: Appearance.rounding.windowRounding
        }

        Column {
            id: dashboardLayout
            anchors.centerIn: parent
            spacing: 24

            // Title
            Text {
                text: "Dashboard"
                font.pixelSize: 32
                font.bold: true
                color: Appearance.colors.colOnSurface
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Widget blocks row
            Row {
                id: widgetRow
                spacing: 16
                anchors.horizontalCenter: parent.horizontalCenter

                // Quick actions widget
                QuickActionsWidget {
                    width: 280
                    height: 160
                }

                // System stats widget block
                SystemStatsWidget {
                    width: 280
                    height: 160
                }

                // Weather widget block
                WeatherWidget {
                    width: 220
                    height: 160
                }
            }

            // Close hint
            Text {
                text: "Press Esc or Super+D to close"
                font.pixelSize: 12
                color: Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
        }
        function close(): void {
            GlobalStates.dashboardOpen = false;
        }
        function open(): void {
            GlobalStates.dashboardOpen = true;
        }
    }

    GlobalShortcut {
        name: "dashboardToggle"
        description: "Toggles dashboard on Super+D"

        onPressed: {
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
        }
    }
}
