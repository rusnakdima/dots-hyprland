/**
 * KeyboardSwitcher.qml — Fork-owned Overview keyboard layout switcher
 *
 * Adds a keyboard layout switcher row to the Overview panel.
 * Lists all configured layouts from config.json and switches the active
 * layout on click.
 *
 * Usage: import this component in OverviewWidget.qml or load as a panel
 * via Quickshell's LazyLoader override system.
 */

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property bool compact: false

    // Layout abbreviation map
    function abbrev(layoutCode, layoutName) {
        const raw = (layoutCode || layoutName || "us").toLowerCase()
        const known = {
            "us": "EN", "gb": "EN", "au": "EN", "ca": "EN",
            "fr": "FR", "de": "DE", "es": "ES", "it": "IT",
            "pt": "PT", "pl": "PL", "cz": "CZ", "sk": "SK",
            "se": "SE", "no": "NO", "dk": "DK", "fi": "FI",
            "nl": "NL", "be": "BE", "ch": "CH", "at": "AT",
            "ru": "RU", "ua": "UA", "by": "BY",
            "jp": "JP", "kr": "KR", "cn": "CN",
            "il": "HE", "arabic": "AR", "ir": "FA",
            "in": "HI", "th": "TH", "vn": "VI",
            "colemak": "EN", "dvorak": "DV",
        }
        const base = raw.split("-")[0].split(":")[0]
        return known[base] || raw.substring(0, 4).toUpperCase()
    }

    // Full display name for a layout
    function fullName(layout) {
        const raw = (layout || "").toLowerCase()
        const names = {
            "us": "US (QWERTY)", "gb": "UK", "fr": "French", "de": "German",
            "es": "Spanish", "it": "Italian", "pt": "Portuguese", "pl": "Polish",
            "ru": "Russian", "ua": "Ukrainian", "jp": "Japanese", "kr": "Korean",
            "cn": "Chinese", "colemak": "Colemak", "dvorak": "Dvorak",
        }
        const base = raw.split("-")[0]
        return names[base] || layout
    }

    implicitWidth: switcherRow.implicitWidth
    implicitHeight: switcherRow.implicitHeight

    RowLayout {
        id: switcherRow
        anchors.fill: parent
        spacing: 4

        MaterialSymbol {
            text: "keyboard"
            iconSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurfaceVariant
            Layout.alignment: Qt.AlignVCenter
        }

        Repeater {
            model: Config.options.keyboard.layouts || ["us"]

            delegate: Item {
                implicitWidth: layoutButton.implicitWidth
                implicitHeight: layoutButton.implicitHeight

                Rectangle {
                    id: layoutButton
                    implicitWidth: labelText.implicitWidth + 12
                    implicitHeight: labelText.implicitHeight + 6
                    radius: Appearance.rounding.small
                    color: isActive ? Appearance.colors.colSecondaryContainer : "transparent"
                    border.width: 1
                    border.color: isActive ? Appearance.colors.colOutline : Appearance.colors.colOutlineVariant

                    property bool isActive: {
                        const curr = HyprlandXkb.currentLayoutName || ""
                        const target = modelData || ""
                        return curr.toLowerCase().includes(target.toLowerCase()) ||
                               target.toLowerCase().includes(curr.toLowerCase())
                    }

                    StyledText {
                        id: labelText
                        anchors.centerIn: parent
                        text: abbrev("", modelData)
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: isActive ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            // Switch to this layout
                            const layout = modelData
                            Qt.callLater(() => {
                                Helpers.runProcess("hyprctl", ["switchxkblayout", layout])
                            })
                        }
                    }

                    StyledToolTip {
                        text: fullName(modelData)
                    }
                }
            }
        }
    }
}
