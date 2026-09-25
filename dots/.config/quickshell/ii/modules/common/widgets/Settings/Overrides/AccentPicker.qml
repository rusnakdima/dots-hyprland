/*
 * AccentPicker.qml — fork-owned override for Settings widget
 *
 * Lives in: quickshell/ii/modules/common/widgets/Settings/Overrides/
 *
 * Provides:
 *   - A color input field (hex, e.g. #ff5500) with live preview swatch
 *   - A "Reset to auto" button that clears theme.accent.manual
 *   - Persists to Config.options.theme.accent.manual
 *
 * The override slot is imported as "AccentPicker" in Settings.qml
 * and placed in the Appearance section of the Settings sidebar.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common

Item {
    id: root
    implicitWidth:  layout.implicitWidth  + 24
    implicitHeight: layout.implicitHeight + 24

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        /* Section header */
        Label {
            text: "Accent Color"
            font.weight: Font.Medium
            font.pixelSize: 14
            color: Appearance.m3colors.m3onSurface
        }

        /* Description */
        Label {
            text: "Override the auto-generated accent with a manual hex color."
            font.pixelSize: 12
            color: Appearance.m3colors.m3onSurfaceVariant
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        /* Current accent source badge */
        RowLayout {
            spacing: 6
            Layout.topMargin: 4

            Label {
                text: "Source:"
                font.pixelSize: 12
                color: Appearance.m3colors.m3onSurfaceVariant
            }

            Label {
                id: sourceLabel
                text: {
                    const src = Config.options?.theme?.accent?.source ?? "wallpaper"
                    if (src === "manual") return "Manual"
                    if (src === "auto")   return "Auto"
                    return "Wallpaper"
                }
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Appearance.m3colors.m3primary
            }
        }

        /* Color preview + hex input row */
        RowLayout {
            spacing: 8
            Layout.topMargin: 8

            /* Swatch */
            Rectangle {
                id: swatch
                width:  36
                height: 36
                radius: 8
                color:  previewColor
                border.width: 1
                border.color: Appearance.m3colors.m3outline

                /* Show accent or current primary as fallback */
                property color previewColor: {
                    const manual = Config.options?.theme?.accent?.manual ?? ""
                    if (manual && /^#[0-9a-fA-F]{6}$/.test(manual)) {
                        return manual
                    }
                    return Appearance.m3colors.m3primary ?? "#cbc4cb"
                }
            }

            /* Hex input */
            TextField {
                id: hexInput
                Layout.fillWidth: true
                placeholderText: "#ff5500"
                text: Config.options?.theme?.accent?.manual ?? ""
                validator: RegularExpressionValidator {
                    regularExpression: /^#?[0-9a-fA-F]{0,6}$/
                }
                onTextChanged: {
                    const trimmed = text.trim()
                    const hex = trimmed.startsWith("#") ? trimmed : `#${trimmed}`
                    if (/^#[0-9a-fA-F]{6}$/.test(hex)) {
                        Config.setNestedValue("theme.accent.manual", hex)
                        // Switch source to manual when user types
                        if (Config.options?.theme?.accent?.source !== "manual") {
                            Config.setNestedValue("theme.accent.source", "manual")
                        }
                    }
                }
                Component.onCompleted: {
                    // Sync from config on load
                    text = Config.options?.theme?.accent?.manual ?? ""
                }
            }
        }

        /* Reset button */
        Button {
            id: resetButton
            text: "Reset to auto"
            flat: true
            Layout.topMargin: 4
            onClicked: {
                // Clear manual accent and switch source back to wallpaper
                Config.setNestedValue("theme.accent.manual", "")
                Config.setNestedValue("theme.accent.source", "wallpaper")
                hexInput.text = ""
            }
        }

        /* Separator */
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
            Layout.topMargin: 4
        }

        /* Quick palette presets */
        Label {
            text: "Presets"
            font.pixelSize: 11
            color: Appearance.m3colors.m3onSurfaceVariant
            Layout.topMargin: 6
        }

        RowLayout {
            spacing: 6
            Layout.topMargin: 4

            /* Preset swatches — 6 common Material You accent colors */
            Repeater {
                model: [
                    "#cbc4cb",  // default slate
                    "#f9c1c1",  // rose
                    "#c1d9f9",  // blue
                    "#c1f9c3",  // green
                    "#f9e3c1",  // amber
                    "#e4c1f9",  // violet
                ]
                delegate: Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: modelData
                    border.width: 1
                    border.color: Appearance.m3colors.m3outline

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.setNestedValue("theme.accent.manual", modelData)
                            Config.setNestedValue("theme.accent.source", "manual")
                            hexInput.text = modelData
                        }
                    }
                }
            }
        }

        /* Info note */
        Label {
            text: "Changes apply immediately. Restart Quickshell to persist."
            font.pixelSize: 10
            color: Appearance.m3colors.m3outline
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.topMargin: 4
        }
    }
}
