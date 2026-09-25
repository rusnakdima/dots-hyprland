/*
 * AppearanceConfig.qml — Settings page for appearance controls
 *
 * Lives in: dots-extra/quickshell/ii/modules/settings/
 *
 * Provides:
 *   - Global opacity slider (10–100%)
 *   - Background transparency slider (0–50%)
 *   - Content transparency slider (0–90%)
 *   - Live preview rectangle
 *
 * Note: these config keys must be applied by widgets that render panels.
 * appearance.globalOpacity multiplies all panel background opacity.
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
    forceWidth: true

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
            let cfgPath = Directories.config.replace(/^file:\/\//, "") + "/illogical-impulse/config.json";
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

    // ─── Live preview ─────────────────────────────────────────────────────────

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 100
        Layout.topMargin: 16
        radius: Appearance.rounding.m3containerMedium
        color: Appearance.m3colors.m3surfaceContainerHigh

        // Outer opacity reflects globalOpacity
        opacity: globalOpacityValue

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
}
