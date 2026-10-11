pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.config
import Quickshell.Hyprland._FocusGrab

PanelWindow {
    id: toolsMenu

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    visible: false
    exclusionMode: ExclusionMode.Ignore

    // Public API
    property bool isRecording: screenrecordTool.isRecording
    property string elapsedTime: screenrecordTool.elapsedTime

    function open() {
        visible = true;
        forceActiveFocus();
    }

    function close() {
        visible = false;
    }

    // Focus grab
    HyprlandFocusGrab {
        windows: [toolsMenu]
        active: toolsMenu.visible
    }

    // Dimmer overlay
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: visible ? 0.5 : 0
        Behavior on opacity {
            NumberAnimation { duration: Config.animDuration > 0 ? Config.animDuration : 150 }
        }
    }

    // Tools grid card
    Rectangle {
        anchors.centerIn: parent
        width: toolsColumnLayout.implicitWidth + 48
        height: toolsColumnLayout.implicitHeight + 48
        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.medium
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            id: toolsColumnLayout
            anchors.centerIn: parent
            spacing: 12

            // Title
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Screen Tools"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurface
            }

            // Recording indicator
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: isRecording
                spacing: 8

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: Appearance.colors.colError

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.3; duration: 500 }
                        NumberAnimation { from: 0.3; to: 1; duration: 500 }
                    }
                }

                StyledText {
                    text: "Recording " + elapsedTime
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colError
                }
            }

            // Tools grid
            GridLayout {
                columns: 4
                rowSpacing: 12
                columnSpacing: 12

                // Screen Recording
                ToolButton {
                    icon: isRecording ? "stop" : "videocam"
                    label: isRecording ? "Stop" : "Record"
                    accentColor: isRecording ? Appearance.colors.colError : Appearance.colors.colPrimary
                    onClicked: {
                        if (isRecording) {
                            screenrecordTool.close();
                        } else {
                            toolsMenu.close();
                            screenrecordTool.open();
                        }
                    }
                }

                // Color Picker
                ToolButton {
                    icon: "colorize"
                    label: "Pick Color"
                    onClicked: {
                        toolsMenu.close();
                        colorPicker.start();
                    }
                }

                // OCR / QR
                ToolButton {
                    icon: "document_scanner"
                    label: "OCR / QR"
                    onClicked: {
                        toolsMenu.close();
                        ocrQrTool.start();
                    }
                }

                // Webcam Mirror - use function to avoid binding loop
                ToolButton {
                    icon: mirrorWindow.isActive ? "videocam_off" : "videocam"
                    label: mirrorWindow.isActive ? "Close Cam" : "Mirror"
                    onClicked: {
                        mirrorWindow.toggle();
                        toolsMenu.close();
                    }
                }
            }

            // Hint
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Press Esc to close"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }

    // Embedded tool instances
    ScreenrecordTool {
        id: screenrecordTool
    }

    ColorPicker {
        id: colorPicker
    }

    OcrQrTool {
        id: ocrQrTool
    }

    MirrorWindow {
        id: mirrorWindow
    }

    // Keyboard handling - Item can receive Keys events
    Item {
        id: keyboardHandler
        anchors.fill: parent
        focus: true
        visible: false

        Keys.onEscapePressed: toolsMenu.close()
    }

    // ToolButton component
    component ToolButton: Rectangle {
        required property string icon
        required property string label
        property color accentColor: Appearance.colors.colPrimary
        required property var onClicked

        Layout.preferredWidth: 90
        Layout.preferredHeight: 90
        radius: Appearance.rounding.small
        color: _mouseArea.containsMouse ? Appearance.colors.colSurfaceContainerHighest : Appearance.colors.colSurfaceContainerHigh
        border.width: _mouseArea.containsMouse ? 1 : 0
        border.color: accentColor

        Column {
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                text: icon
                iconSize: 28
                color: accentColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurface
            }
        }

        MouseArea {
            id: _mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: onClicked()
        }
    }
}
