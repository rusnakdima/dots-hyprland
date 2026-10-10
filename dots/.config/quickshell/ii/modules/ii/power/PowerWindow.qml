pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: powerScope

    PanelWindow {
        id: panelWindow
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
        visible: GlobalStates.powerMenuOpen

        WlrLayershell.namespace: "quickshell:power"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.powerMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            horizontalCenter: parent.horizontalCenter
        }

        implicitWidth: 320
        implicitHeight: powerMenuLayout.implicitHeight + 40

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.powerMenuOpen = false;
            }
        }

        // Background
        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: Appearance.colors.colBackgroundSurfaceContainerHigh
            opacity: 0.98
            radius: Appearance.rounding.windowRounding
        }

        Column {
            id: powerMenuLayout
            anchors.centerIn: parent
            spacing: 16

            // Header
            Text {
                text: "Power Menu"
                font.family: Appearance.font.family
                font.pixelSize: 20
                font.bold: true
                color: Appearance.colors.colOnSurface
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Power buttons
            GridLayout {
                columns: 2
                columnSpacing: 16
                rowSpacing: 16
                anchors.horizontalCenter: parent.horizontalCenter

                // Lock
                PowerButton {
                    icon: "lock"
                    label: "Lock"
                    color: Appearance.colors.colAccent
                    onClicked: {
                        PowerService.lock();
                        GlobalStates.powerMenuOpen = false;
                    }
                }

                // Sleep
                PowerButton {
                    icon: "bedtime"
                    label: "Sleep"
                    color: Appearance.colors.colTertiary
                    onClicked: {
                        PowerService.suspend();
                        GlobalStates.powerMenuOpen = false;
                    }
                }

                // Reboot
                PowerButton {
                    icon: "restart"
                    label: "Reboot"
                    color: Appearance.colors.colWarning
                    onClicked: {
                        PowerService.reboot();
                        GlobalStates.powerMenuOpen = false;
                    }
                }

                // Power Off
                PowerButton {
                    icon: "power_settings_new"
                    label: "Power Off"
                    color: Appearance.colors.colError
                    onClicked: {
                        PowerService.poweroff();
                        GlobalStates.powerMenuOpen = false;
                    }
                }
            }

            // Close button
            MaterialSymbol {
                text: "close"
                iconSize: 24
                color: Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalStates.powerMenuOpen = false
                }
            }

            // Hint
            Text {
                text: "Press Esc to close"
                font.family: Appearance.font.family
                font.pixelSize: 12
                color: Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            GlobalStates.powerMenuOpen = !GlobalStates.powerMenuOpen;
        }
        function close(): void {
            GlobalStates.powerMenuOpen = false;
        }
        function open(): void {
            GlobalStates.powerMenuOpen = true;
        }
    }

    // Global shortcut for power menu (Ctrl+Alt+Delete style)
    GlobalShortcut {
        name: "powerMenuToggle"
        description: "Opens power menu"

        onPressed: {
            GlobalStates.powerMenuOpen = !GlobalStates.powerMenuOpen;
        }
    }
}

// Power button component
Rectangle {
    id: powerButtonRoot
    width: 120
    height: 100
    radius: Appearance.rounding.roundedLg
    color: Appearance.colors.colLayer1Hover

    property string icon: "power_settings_new"
    property string label: "Power"
    property color color: Appearance.colors.colAccent
    signal clicked()

    Column {
        anchors.centerIn: parent
        spacing: 8

        MaterialSymbol {
            text: icon
            iconSize: 40
            color: powerButtonRoot.color
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: label
            font.family: Appearance.font.family
            font.pixelSize: 14
            font.bold: true
            color: Appearance.colors.colOnSurface
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: powerButtonRoot.clicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: Appearance.animation.durationShort
        }
    }
}
