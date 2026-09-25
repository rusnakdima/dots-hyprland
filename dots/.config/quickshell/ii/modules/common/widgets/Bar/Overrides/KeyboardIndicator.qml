/**
 * KeyboardIndicator.qml — Fork-owned keyboard layout indicator for the bar
 *
 * Shows current XKB/fcitx5 layout abbreviation in the bar (e.g. "EN", "RU").
 * Subscribes to the kbdlayoutd DBus service or falls back to HyprlandXkb.
 * Clicking toggles to the next layout (or opens a layout switcher popover).
 *
 * Placement: inserted into BarContent's right-side indicator row,
 * replacing the upstream HyprlandXkbIndicator when keyboard.layouts has
 * more than one entry.
 */

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Loader {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant
    property bool showSwitcherPopover: true

    // Layout abbreviations map: XKB layout code → short label
    property var layoutAbbreviations: {
        // Latin
        "us": "EN", "gb": "EN", "au": "EN", "ca": "EN", "fr": "FR",
        "de": "DE", "es": "ES", "it": "IT", "pt": "PT", "pl": "PL",
        "ru": "RU", "ua": "UA", "jp": "JP", "kr": "KR", "cn": "CN",
        "cz": "CZ", "sk": "SK", "se": "SE", "no": "NO", "dk": "DK",
        "fi": "FI", "nl": "NL", "be": "BE", "ch": "CH", "at": "AT",
        // Variants
        "colemak": "EN", "dvorak": "EN", "workman": "EN",
        "fr-oss": "FR", "de-latin1": "DE",
    }

    // Full layout names from HyprlandXkb
    property string currentLayoutName: HyprlandXkb.currentLayoutName || "us"
    property string currentLayoutCode: HyprlandXkb.currentLayoutCode || "us"

    // Resolve abbreviation from code or name
    function resolveAbbreviation(code, name) {
        const raw = (code || name || "us").toLowerCase()
        // Try code directly
        if (layoutAbbreviations[raw] !== undefined) {
            return layoutAbbreviations[raw]
        }
        // Try base (before hyphen)
        const base = raw.split("-")[0]
        if (layoutAbbreviations[base] !== undefined) {
            return layoutAbbreviations[base]
        }
        // Try first 4 chars (some codes are e.g. "us+colemak")
        const short4 = base.substring(0, 4)
        if (layoutAbbreviations[short4] !== undefined) {
            return layoutAbbreviations[short4]
        }
        // Fallback: uppercase first 2 chars
        return raw.substring(0, 2).toUpperCase()
    }

    active: true
    visible: HyprlandXkb.layoutCodes.length > 0

    sourceComponent: Item {
        implicitWidth: indicatorRow.implicitWidth
        implicitHeight: root.vertical ? null : layoutLabel.implicitHeight

        RowLayout {
            id: indicatorRow
            anchors.fill: parent
            spacing: 4

            MaterialSymbol {
                id: keyboardIcon
                text: "keyboard"
                iconSize: Appearance.font.pixelSize.small
                color: root.color
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                id: layoutLabel
                text: resolveAbbreviation(root.currentLayoutCode, root.currentLayoutName)
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.color
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    // Toggle to next layout
                    const layouts = Config.options.keyboard.layouts || ["us"]
                    if (layouts.length <= 1) return
                    const currentName = root.currentLayoutName
                    const currentIdx = layouts.findIndex(l => l.toLowerCase().includes(currentName.toLowerCase()) || currentName.toLowerCase().includes(l.toLowerCase()))
                    const nextIdx = (currentIdx + 1) % layouts.length
                    const nextLayout = layouts[nextIdx]
                    Qt.callLater(() => {
                        Helpers.runProcess("hyprctl", ["switchxkblayout", "next"])
                    })
                }
            }

            onPressAndHold: {
                // Long press: show layout switcher popover
                if (showSwitcherPopover) {
                    layoutSwitcherPopover.visible = !layoutSwitcherPopover.visible
                }
            }
        }

        // Inline layout switcher popover (simple, no external dependencies)
        Rectangle {
            id: layoutSwitcherPopover
            visible: false
            z: 999
            width: 120
            height: switcherColumn.implicitHeight + 10
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            anchors {
                top: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }

            Column {
                id: switcherColumn
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: Config.options.keyboard.layouts || ["us"]

                    delegate: Rectangle {
                        width: 110
                        height: 28
                        radius: 4
                        color: {
                            const isActive = (root.currentLayoutName.toLowerCase().includes(modelData.toLowerCase()) ||
                                             modelData.toLowerCase().includes(root.currentLayoutName.toLowerCase()))
                            isActive ? Appearance.colors.colSecondaryContainer : "transparent"
                        }
                        border.width: 0

                        StyledText {
                            anchors.centerIn: parent
                            text: resolveAbbreviation("", modelData)
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: isActive ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                const layout = modelData
                                Qt.callLater(() => {
                                    Helpers.runProcess("hyprctl", ["switchxkblayout", layout])
                                })
                                layoutSwitcherPopover.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
