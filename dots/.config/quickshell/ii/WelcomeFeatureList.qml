import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    ContentSection {
        icon: "info"
        title: Translation.tr("Info")

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "keyboard_alt"
                onClicked: {
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "cheatsheet", "toggle"]);
                }
                mainContentComponent: Component {
                    RowLayout {
                        spacing: 10
                        StyledText {
                            font.pixelSize: Appearance.font.pixelSize.small
                            text: Translation.tr("Keybinds")
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        RowLayout {
                            spacing: 3
                            KeyboardKey {
                                key: "󰖳"
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                text: "+"
                            }
                            KeyboardKey {
                                key: "/"
                            }
                        }
                    }
                }
            }

            RippleButtonWithIcon {
                materialIcon: "help"
                mainText: Translation.tr("Usage")
                onClicked: {
                    Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/");
                }
            }

            RippleButtonWithIcon {
                materialIcon: "construction"
                mainText: Translation.tr("Configuration")
                onClicked: {
                    Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/03config/");
                }
            }
        }
    }

    ContentSection {
        icon: "monitoring"
        title: Translation.tr("Useless buttons")

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                nerdIcon: "󰊤"
                mainText: Translation.tr("GitHub")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland");
                }
            }

            RippleButtonWithIcon {
                materialIcon: "favorite"
                mainText: "Funny number"
                onClicked: {
                    Qt.openUrlExternally("https://github.com/sponsors/end-4");
                }
            }
        }
    }
}
