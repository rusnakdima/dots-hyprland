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
    id: quickSettingsScope

    PanelWindow {
        id: panelWindow
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
        visible: GlobalStates.quickSettingsOpen

        WlrLayershell.namespace: "quickshell:quickSettings"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.quickSettingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: !Config.options.bar.bottom
            bottom: Config.options.bar.bottom
            right: true
        }

        margins {
            right: Appearance.sizes.spacing
            top: Appearance.sizes.spacing
            bottom: Appearance.sizes.spacing
        }

        implicitWidth: 380
        implicitHeight: quickSettingsLayout.implicitHeight + 40

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.quickSettingsOpen = false;
            }
        }

        // Background
        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: Appearance.colors.colBackgroundSurfaceContainer
            opacity: 0.95
            radius: Appearance.rounding.windowRounding
        }

        Column {
            id: quickSettingsLayout
            anchors.centerIn: parent
            spacing: 16

            // Header
            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: "Quick Settings"
                    font.family: Appearance.font.family
                    font.pixelSize: 18
                    font.bold: true
                    color: Appearance.colors.colOnSurface
                }

                MaterialSymbol {
                    text: "close"
                    iconSize: 18
                    color: Appearance.colors.colOnSurfaceVariant
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GlobalStates.quickSettingsOpen = false
                    }
                }
            }

            // Toggles row
            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                // WiFi toggle
                ToggleTile {
                    icon: Network.enabled ? "wifi" : "wifi_off"
                    label: "WiFi"
                    toggled: Network.enabled
                    onClicked: Network.enabled = !Network.enabled
                }

                // Bluetooth toggle
                ToggleTile {
                    icon: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                    label: "Bluetooth"
                    toggled: BluetoothStatus.enabled
                    onClicked: BluetoothStatus.enabled = !BluetoothStatus.enabled
                }

                // Night Light toggle
                ToggleTile {
                    icon: Hyprsunset.enabled ? "wb_twilight" : "wb_sunny"
                    label: "Night Light"
                    toggled: Hyprsunset.enabled
                    onClicked: {
                        if (Hyprsunset.enabled) {
                            Hyprsunset.disable();
                        } else {
                            Hyprsunset.enable();
                        }
                    }
                }

                // DND toggle
                ToggleTile {
                    icon: Notifications.silent ? "do_not_disturb_on" : "do_not_disturb_off"
                    label: "DND"
                    toggled: Notifications.silent
                    onClicked: Notifications.silent = !Notifications.silent
                }
            }

            // Volume slider
            Rectangle {
                width: 340
                height: 60
                radius: Appearance.rounding.roundedMd
                color: Appearance.colors.colLayer1Hover

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    MaterialSymbol {
                        text: Audio.muted ? "volume_off" : (Audio.volume > 0.5 ? "volume_up" : "volume_down")
                        iconSize: 24
                        color: Appearance.colors.colOnSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Slider {
                        width: 240
                        from: 0
                        to: 1
                        value: Audio.volume
                        onMoved: Audio.volume = value
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: Math.round(Audio.volume * 100) + "%"
                        font.family: Appearance.font.family
                        font.pixelSize: 14
                        color: Appearance.colors.colOnSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Brightness slider
            Rectangle {
                width: 340
                height: 60
                radius: Appearance.rounding.roundedMd
                color: Appearance.colors.colLayer1Hover

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    MaterialSymbol {
                        text: Brightness.brightness > 0 ? "brightness_high" : "brightness_low"
                        iconSize: 24
                        color: Appearance.colors.colOnSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Slider {
                        width: 240
                        from: 0
                        to: 1
                        value: Brightness.brightness
                        onMoved: Brightness.brightness = value
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: Math.round(Brightness.brightness * 100) + "%"
                        font.family: Appearance.font.family
                        font.pixelSize: 14
                        color: Appearance.colors.colOnSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Power saver toggle
            ToggleTile {
                icon: "battery_saver"
                label: "Power Saver"
                toggled: false
                onClicked: {
                    // Could integrate with system power profiles
                }
            }

            // Notification history
            Rectangle {
                width: 340
                height: 150
                radius: Appearance.rounding.roundedMd
                color: Appearance.colors.colLayer1Hover

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Row {
                        spacing: 8

                        Text {
                            text: "Recent Notifications"
                            font.family: Appearance.font.family
                            font.pixelSize: 14
                            font.bold: true
                            color: Appearance.colors.colOnSurface
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Clear"
                            font.family: Appearance.font.family
                            font.pixelSize: 12
                            color: Appearance.colors.colAccent
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.clear()
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: 100
                        model: Notifications.notifications.slice(0, 5)
                        clip: true

                        delegate: Rectangle {
                            width: parent.width
                            height: 24
                            color: "transparent"

                            Text {
                                text: modelData?.summary || modelData?.appName || "Notification"
                                font.family: Appearance.font.family
                                font.pixelSize: 12
                                color: Appearance.colors.colOnSurface
                                elide: Text.ElideRight
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "quickSettings"

        function toggle(): void {
            GlobalStates.quickSettingsOpen = !GlobalStates.quickSettingsOpen;
        }
        function close(): void {
            GlobalStates.quickSettingsOpen = false;
        }
        function open(): void {
            GlobalStates.quickSettingsOpen = true;
        }
    }
}

// Toggle tile component
Rectangle {
    id: toggleRoot
    width: 72
    height: 72
    radius: Appearance.rounding.roundedMd
    color: toggled ? Appearance.colors.colAccentContainer : Appearance.colors.colLayer1Hover

    property string icon: "wifi"
    property string label: "Toggle"
    property bool toggled: false
    signal clicked()

    Column {
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: icon
            iconSize: 24
            color: toggled ? Appearance.colors.colOnAccentContainer : Appearance.colors.colOnSurface
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: label
            font.family: Appearance.font.family
            font.pixelSize: 11
            color: toggled ? Appearance.colors.colOnAccentContainer : Appearance.colors.colOnSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleRoot.clicked()
    }
}
