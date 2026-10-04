/*
 * AppearanceConfig.qml — Settings page for appearance controls
 *
 * Provides:
 *   - Global opacity slider (10–100%)
 *   - Opacity exclusions list
 *   - Background transparency slider (0–50%)
 *   - Content transparency slider (0–90%)
 *   - Accent color picker
 *   - Keyboard backlight RGB (delegates to KeyboardBacklight service)
 *   - Live preview rectangle
 *
 * Note: these config keys must be applied by widgets that render panels.
 * appearance.globalOpacity multiplies all panel background opacity.
 * appearance.opacityExcludedPanels lists panels to keep at 100% opacity.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.services
ContentPage {

    function trimmedHome(): string {
        return CF.FileUtils.trimFileProtocol(Directories.home);
    }
    forceWidth: true

    // ─── Helpers ──────────────────────────────────────────────────────────────

    // Returns true if two [r,g,b] channel lists are equal (each 0..4)
    function isCurrentColor(current, preset) {
        if (!Array.isArray(current) || !Array.isArray(preset)) return false
        return current[0] === preset[0] && current[1] === preset[1] && current[2] === preset[2]
    }

    // ─── Dark Mode ───────────────────────────────────────────────────────────

    ContentSection {
        icon: "dark_mode"
        title: Translation.tr("Theme")

        ConfigSwitch {
            buttonIcon: "dark_mode"
            text: Translation.tr("Dark mode (fcitx theme)")
            checked: Config.options.appearance?.darkMode ?? false
            onCheckedChanged: {
                if (!Config.options.appearance) Config.options.appearance = {};
                Config.options.appearance.darkMode = checked;
            }
        }
    }

    // ─── JSON read/write helpers ───────────────────────────────────────────────

    function getGlobalOpacity(): double {
        try {
            let cfgPath = trimmedHome() + "/.config/illogical-impulse/config.json";
            let { exitCode, stdout } = Quickshell.execSync(["python3", "-c", "import json; d=json.load(open('" + cfgPath + "')); print(d.get('appearance',{}).get('globalOpacity',0.9))"]);
            if (exitCode !== 0) return 0.90;
            let val = parseFloat(stdout.trim());
            return isNaN(val) ? 0.90 : val;
        } catch (e) { return 0.90; }
    }

    function setGlobalOpacity(val: real): bool {
        let parsed = Math.max(0.1, Math.min(1.0, parseFloat(val)));
        // Config.setNestedValue updates in-memory and schedules a debounced write.
        // After the debounce (50ms), onFileChanged fires → fileReloadTimer (50ms)
        // → reload from disk → configReloaded fires → IllogicalImpulseFamily
        // Connections handler re-evaluates the opacity binding.
        try { Config.setNestedValue("appearance.globalOpacity", parsed); } catch (e) {}
        return true;
    }

    property real globalOpacityValue: 0.90

    Component.onCompleted: {
        globalOpacityValue = Config.options?.appearance?.globalOpacity ?? 0.9;
    }

    // ─── Opacity section ─────────────────────────────────────────────────────

    ContentSection {
        icon: "opacity"
        title: Translation.tr("Opacity")

        ConfigRow {
            StyledText {
                text: Translation.tr("Global opacity")
                font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
            }

            Slider {
                id: globalOpacitySlider
                from: 0.1
                to: 1.0
                stepSize: 0.01
                value: globalOpacityValue
                onValueChanged: {
                    if (Math.abs(value - globalOpacityValue) > 0.001) {
                        globalOpacityValue = value;
                        setGlobalOpacity(value);
                    }
                }
                Layout.preferredWidth: 200
            }

            StyledText {
                text: Math.round(globalOpacitySlider.value * 100) + "%"
                font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }

    // ─── Opacity exclusions ─────────────────────────────────────────────────

    ContentSection {
        icon: "visibility_off"
        title: Translation.tr("Opacity exclusions")

        StyledText {
            text: Translation.tr("Panels to keep at 100% opacity, separated by commas (requires reload)")
            font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
            color: Appearance.colors.colOnSurfaceVariant
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        TextField {
            id: opacityExcludeField
            Layout.fillWidth: true
            placeholderText: "Bar, Dock, SidebarLeft, SidebarRight, ..."
            text: (Config.options?.appearance?.opacityExcludedPanels ?? []).join(", ")
            onTextChanged: {
                const list = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                try { Config.setNestedValue("appearance.opacityExcludedPanels", list); } catch (e) {}
            }
        }

        StyledText {
            text: Translation.tr("Available: Bar, Background, Cheatsheet, Dock, Lock, MediaControls, NotificationPopup, OnScreenDisplay, OnScreenKeyboard, Overlay, Overview, Dashboard, Polkit, RegionSelector, ScreenCorners, ScreenTranslator, SessionScreen, SidebarLeft, SidebarRight, VerticalBar, WallpaperSelector")
            font.pixelSize: 11
            color: Appearance.colors.colOutline
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.topMargin: 4
        }
    }

    // ─── Transparency coefficients ───────────────────────────────────────────

    ContentSection {
        icon: "blur_on"
        title: Translation.tr("Transparency coefficients")

        ConfigRow {
            StyledText {
                text: Translation.tr("Background")
                font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
            }

            Slider {
                id: bgSlider
                from: 0.0
                to: 0.5
                stepSize: 0.01
                value: Config.options.appearance.transparency.backgroundTransparency
                onValueChanged: {
                    if (Math.abs(value - Config.options.appearance.transparency.backgroundTransparency) > 0.001) {
                        try { Config.setNestedValue("appearance.transparency.backgroundTransparency", value); } catch (e) {}
                    }
                }
                Layout.preferredWidth: 200
            }

            StyledText {
                text: Math.round(bgSlider.value * 100) + "%"
                font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        ConfigRow {
            StyledText {
                text: Translation.tr("Content")
                font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
            }

            Slider {
                id: contentSlider
                from: 0.0
                to: 0.9
                stepSize: 0.01
                value: Config.options.appearance.transparency.contentTransparency
                onValueChanged: {
                    if (Math.abs(value - Config.options.appearance.transparency.contentTransparency) > 0.001) {
                        try { Config.setNestedValue("appearance.transparency.contentTransparency", value); } catch (e) {}
                    }
                }
                Layout.preferredWidth: 200
            }

            StyledText {
                text: Math.round(contentSlider.value * 100) + "%"
                font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }

    // ─── Accent color ───────────────────────────────────────────────────────

    ContentSection {
        icon: "palette"
        title: Translation.tr("Accent color")

        // Inline AccentPicker content (no module qmldir available)
        StyledText {
            text: Translation.tr("Manual accent color (overrides auto)")
            font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
            color: Appearance.colors.colOnSurfaceVariant
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: 8
            Layout.topMargin: 8

            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: accentPreviewColor
                border.width: 1
                border.color: Appearance.m3colors.m3outline

                property color accentPreviewColor: {
                    const manual = Config.options?.theme?.accent?.manual ?? ""
                    if (manual && /^#[0-9a-fA-F]{6}$/.test(manual)) {
                        return manual
                    }
                    return Appearance.m3colors.m3primary ?? "#cbc4cb"
                }
            }

            TextField {
                id: accentHexInput
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
                        if (Config.options?.theme?.accent?.source !== "manual") {
                            Config.setNestedValue("theme.accent.source", "manual")
                        }
                    }
                }
                Component.onCompleted: {
                    text = Config.options?.theme?.accent?.manual ?? ""
                }
            }
        }

        RowLayout {
            spacing: 6
            Layout.topMargin: 6

            readonly property var accentPresets: [
                "#cbc4cb", "#f9c1c1", "#c1d9f9", "#c1f9c3", "#f9e3c1", "#e4c1f9",
            ]

            Repeater {
                model: accentPresets
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
                            accentHexInput.text = modelData
                        }
                    }
                }
            }
        }

        StyledText {
            text: "Source: " + (Config.options?.theme?.accent?.source === "manual" ? "Manual" : Config.options?.theme?.accent?.source === "auto" ? "Auto" : "Wallpaper")
            font.pixelSize: 11
            color: Appearance.colors.colOutline
            Layout.topMargin: 4
        }
    }

    // ─── Live preview ─────────────────────────────────────────────────────────

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 88
        Layout.topMargin: 8
        radius: Appearance.rounding.m3containerMedium
        color: Appearance.m3colors.m3surfaceContainerHigh

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Background layer preview — tracks slider value directly (not reactive config binding)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 4
                color: Appearance.m3colors.m3surfaceContainerHighest
                opacity: 1.0 - bgSlider.value
            }

            // Content layer preview — tracks slider value directly
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 4
                color: Appearance.m3colors.m3surfaceContainerHighest
                opacity: (1.0 - contentSlider.value) * 0.8
            }
        }

        // Preview label
        StyledText {
            anchors.centerIn: parent
            text: Translation.tr("Preview")
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font?.pixelSize?.labelSmall ?? 12
        }
    }

    // ─── Keyboard backlight color ───────────────────────────────────────────

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Keyboard backlight")

        // Per-channel intensity 0..4 (hardware max_brightness = 4).
        // Channels are quantized; show actual achievable colors only.
        ColumnLayout {
            id: kbdRgbColumn
            spacing: 10
            Layout.fillWidth: true

            StyledText {
                text: Translation.tr("Single global color (hardware quantized, 0–4 per channel)")
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
            }

            // Preset color grid — sourced from KeyboardBacklight service
            Flow {
                id: presetFlow
                spacing: 8
                Layout.fillWidth: true

                Repeater {
                    model: KeyboardBacklight.presets

                    delegate: Rectangle {
                        required property var modelData
                        width: 34
                        height: 34
                        radius: 8
                        color: Qt.rgba(
                            modelData.c[0] / 4.0,
                            modelData.c[1] / 4.0,
                            modelData.c[2] / 4.0,
                            1
                        )
                        border.width: isCurrentColor(KeyboardBacklight.currentRgb, modelData.c) ? 2 : 1
                        border.color: border.width > 1
                            ? Appearance.colors.colOnSurface
                            : Appearance.m3colors.m3outline
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: KeyboardBacklight.apply(modelData.c)
                        }
                    }
                }
            }

            // Per-channel custom sliders
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "brush"
                    text: Translation.tr("Red")
                    value: KeyboardBacklight.currentRgb[0] ?? 4
                    from: 0; to: 4
                    stepSize: 1
                    onValueChanged: {
                        const cur = KeyboardBacklight.currentRgb.slice();
                        cur[0] = value;
                        KeyboardBacklight.apply(cur);
                    }
                }
                ConfigSpinBox {
                    icon: "brush"
                    text: Translation.tr("Green")
                    value: KeyboardBacklight.currentRgb[1] ?? 4
                    from: 0; to: 4
                    stepSize: 1
                    onValueChanged: {
                        const cur = KeyboardBacklight.currentRgb.slice();
                        cur[1] = value;
                        KeyboardBacklight.apply(cur);
                    }
                }
                ConfigSpinBox {
                    icon: "brush"
                    text: Translation.tr("Blue")
                    value: KeyboardBacklight.currentRgb[2] ?? 4
                    from: 0; to: 4
                    stepSize: 1
                    onValueChanged: {
                        const cur = KeyboardBacklight.currentRgb.slice();
                        cur[2] = value;
                        KeyboardBacklight.apply(cur);
                    }
                }
            }
        }
    }
}
