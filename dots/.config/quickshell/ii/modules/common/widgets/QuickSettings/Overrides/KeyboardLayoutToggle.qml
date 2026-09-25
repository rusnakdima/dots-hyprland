// KeyboardLayoutToggle.qml — fork-owned QuickSettings keyboard layout toggle
// Lives in: dots-extra/quickshell/ii/modules/common/widgets/QuickSettings/Overrides/
// Survives setup update: yes (dots-extra/quickshell seam)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * KeyboardLayoutToggle — QuickSettings tile for keyboard layout switching.
 *
 * Shows the current layout abbreviation and cycles through the configured
 * layouts on click. Shows all configured layouts as a compact row of buttons.
 *
 * Integrates with keyboard.layouts from config.json and the HyprlandXkb service.
 */
Item {
    id: root
    implicitWidth: parent?.width ?? 300
    implicitHeight: toggleContent.implicitHeight + 8

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
            "colemak": "CM", "dvorak": "DV",
        }
        const base = raw.split("-")[0].split(":")[0]
        return known[base] || raw.substring(0, 4).toUpperCase()
    }

    function switchToLayout(layout) {
        Helpers.runProcess("hyprctl", ["switchxkblayout", layout])
    }

    ColumnLayout {
        id: toggleContent
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // Header row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: "keyboard"
                iconSize: 16
                color: Appearance.colors.colOnSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: "Keyboard Layout"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurface
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: abbrev(HyprlandXkb.currentLayoutCode, HyprlandXkb.currentLayoutName)
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Appearance.colors.colPrimary
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Layout buttons row
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: Config.options.keyboard.layouts || ["us"]

                delegate: Rectangle {
                    implicitWidth: layoutBtnLabel.implicitWidth + 16
                    implicitHeight: 26
                    radius: 6
                    color: isActive ? Appearance.colors.colSecondaryContainer : Appearance.colors.colSurfaceContainerHighest
                    border.width: isActive ? 1 : 0
                    border.color: Appearance.colors.colOutline

                    property bool isActive: {
                        const curr = HyprlandXkb.currentLayoutName || ""
                        const target = modelData || ""
                        return curr.toLowerCase().includes(target.toLowerCase()) ||
                               target.toLowerCase().includes(curr.toLowerCase())
                    }

                    StyledText {
                        id: layoutBtnLabel
                        anchors.centerIn: parent
                        text: abbrev("", modelData)
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: isActive ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.switchToLayout(modelData)
                        }
                    }
                }
            }
        }
    }

    // Update on HyprlandXkb changes
    Connections {
        target: HyprlandXkb
        function onCurrentLayoutNameChanged() {
            // Force recompute of isActive in delegates
            layoutRepeaterLoop()
        }
    }

    function layoutRepeaterLoop() {
        // Triggers Repeater to re-evaluate delegate bindings
    }
}
