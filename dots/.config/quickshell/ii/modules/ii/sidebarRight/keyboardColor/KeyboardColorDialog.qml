import qs
import qs.modules.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 380
    backgroundWidth: 350

    WindowDialogTitle {
        text: Translation.tr("Keyboard backlight color")
    }

    WindowDialogSeparator {}

    // Filler Item so Flow gets all remaining height
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.topMargin: 8
        Layout.bottomMargin: 8

        Flow {
            anchors.fill: parent
            spacing: 10

            Repeater {
                model: KeyboardBacklight.presets

                delegate: Rectangle {
                    required property var modelData
                    width: 44
                    height: 44
                    radius: 8
                    color: Qt.rgba(
                        modelData.c[0] / 4.0,
                        modelData.c[1] / 4.0,
                        modelData.c[2] / 4.0,
                        1
                    )
                    border.width: isSelected(modelData.c) ? 2 : 1
                    border.color: border.width > 1
                        ? Appearance.colors.colOnSurface
                        : Appearance.m3colors.m3outline

                    function isSelected(presetChannels) {
                        const cur = KeyboardBacklight.currentRgb
                        return cur[0] === presetChannels[0]
                            && cur[1] === presetChannels[1]
                            && cur[2] === presetChannels[2]
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            KeyboardBacklight.apply(modelData.c)
                            root.dismiss()
                        }
                    }
                }
            }
        }
    }

    WindowDialogSeparator {}

    WindowDialogButtonRow {
        Item { Layout.fillWidth: true }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
