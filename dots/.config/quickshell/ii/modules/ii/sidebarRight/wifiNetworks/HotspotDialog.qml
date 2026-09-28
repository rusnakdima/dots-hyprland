import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 300

    WindowDialogTitle {
        text: Translation.tr("Hotspot")
    }

    WindowDialogSeparator {}

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        // Status row
        Row {
            spacing: 10
            Layout.alignment: Qt.AlignHCenter
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: Network.hotspotMaterialSymbol
                iconSize: 24
                color: Appearance.colors.colOnLayer0
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                text: Network.hotspotActive ? Translation.tr("Active") : Translation.tr("Inactive")
            }
        }

        // Hotspot info when active
        Column {
            visible: Network.hotspotActive
            spacing: 8
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Network: %1").arg(Network.hotspotName)
            }

            Row {
                spacing: 8
                anchors.horizontalCenter: parent.horizontalCenter

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    text: Translation.tr("Password: %1").arg(Network.hotspotPassword)
                }

                RippleButton {
                    anchors.verticalCenter: parent.verticalCenter
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "content_copy"
                        iconSize: 16
                        color: Appearance.colors.colOnLayer0
                    }
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", `echo -n '${Network.hotspotPassword}' | xclip -selection clipboard`]);
                    }
                    StyledToolTip {
                        text: Translation.tr("Copy password")
                    }
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOutline
                text: Translation.tr("%1 device(s) connected").arg(Network.hotspotConnectedDevices)
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    WindowDialogSeparator {}

    WindowDialogButtonRow {
        DialogButton {
            buttonText: Network.hotspotActive ? Translation.tr("Stop Hotspot") : Translation.tr("Start Hotspot")
            onClicked: Network.toggleHotspot()
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
