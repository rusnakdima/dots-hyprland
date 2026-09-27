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

    function trimmedHome(): string {
        return CF.FileUtils.trimFileProtocol(Directories.home);
    }
    forceWidth: true

    // ─── Keyboard backlight RGB state & IPC ─────────────────────────────────

    // Current keyboard color (per-channel 0..4)
    property list<int> kbdRgbCurrent: [4, 4, 4]

    property string kbdSysfsPath: "/sys/class/leds/rgb:kbd_backlight"

    function applyKbdRgb(channels, skipConfigWrite) {
        const c = channels.slice();
        for (let i = 0; i < 3; i++) {
            if (typeof c[i] !== "number") c[i] = 4;
            c[i] = Math.max(0, Math.min(4, Math.round(c[i])));
        }
        kbdRgbCurrent = c;
        if (!skipConfigWrite) Config.setNestedValue("keyboard.rgb", c);
        // Feed stdin via write(): sudo tee with sysfs file as argument
        kbdRgbProcess.command = ["sudo", "-n", "tee", sysfsExecutor()];
        kbdRgbProcess.stdinEnabled = true;
        kbdRgbProcess.running = true;
        pendingKbdChannels = c;
    }

    function sysfsExecutor() {
        return kbdSysfsPath + "/multi_intensity";
    }

    property var pendingKbdChannels: null
    Process {
        id: kbdRgbProcess
        stdout: StdioCollector { }
        onRunningChanged: {
            if (running && pendingKbdChannels) {
                write(pendingKbdChannels.join(" ") + "\n");
                stdinEnabled = false;
                pendingKbdChannels = null;
            }
        }
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
        // Read current keyboard RGB from config (hardware holds last written value)
        const stored = Config.options?.keyboard?.rgb;
        if (Array.isArray(stored) && stored.length === 3) {
            kbdRgbCurrent = [Math.round(stored[0]), Math.round(stored[1]), Math.round(stored[2])];
        }
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

    // ─── Keyboard backlight color ───────────────────────────────────────────

    ContentSection {
        icon: "keyboard_full_2"
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

            // Preset color grid: every useful quantized combination (skip duplicates
            // like 0,1,1 vs 1,1,1 since no scaling — max=4 gives 4 levels per channel,
            // 64 total combos minus 1 off-state; show the common presets plus custom sliders below).
            Flow {
                id: presetFlow
                spacing: 8
                Layout.fillWidth: true

                // Curated quantized palette (values are 0..4 per channel)
                readonly property var presets: [
                    { c: [0,0,0],  name: "Off" },
                    { c: [4,4,4],  name: "White" },
                    { c: [4,0,0],  name: "Red" },
                    { c: [0,4,0],  name: "Green" },
                    { c: [0,0,4],  name: "Blue" },
                    { c: [4,4,0],  name: "Yellow" },
                    { c: [0,4,4],  name: "Cyan" },
                    { c: [4,0,4],  name: "Magenta" },
                    { c: [4,2,0],  name: "Orange" },
                    { c: [2,0,4],  name: "Purple" },
                    { c: [0,4,2],  name: "Teal" },
                    { c: [4,1,1],  name: "Soft red" },
                    { c: [1,4,1],  name: "Soft green" },
                    { c: [1,1,4],  name: "Soft blue" },
                    { c: [4,2,2],  name: "Coral" },
                    { c: [2,4,4],  name: "Ice" },
                ]

                Repeater {
                    model: presetFlow.presets

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
                        border.width: root.kbdRgbCurrent === modelData.c ? 2 : 1
                        border.color: border.width > 1
                            ? Appearance.colors.colOnSurface
                            : Appearance.m3colors.m3outline
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyKbdRgb(modelData.c)
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
                    value: root.kbdRgbCurrent[0] ?? 4
                    from: 0; to: 4
                    stepSize: 1
                    onValueChanged: {
                        const cur = root.kbdRgbCurrent.slice();
                        cur[0] = value;
                        root.applyKbdRgb(cur, true);
                    }
                }
                ConfigSpinBox {
                    icon: "brush"
                    text: Translation.tr("Green")
                    value: root.kbdRgbCurrent[1] ?? 4
                    from: 0; to: 4
                    stepSize: 1
                    onValueChanged: {
                        const cur = root.kbdRgbCurrent.slice();
                        cur[1] = value;
                        root.applyKbdRgb(cur, true);
                    }
                }
                ConfigSpinBox {
                    icon: "brush"
                    text: Translation.tr("Blue")
                    value: root.kbdRgbCurrent[2] ?? 4
                    from: 0; to: 4
                    stepSize: 1
                    onValueChanged: {
                        const cur = root.kbdRgbCurrent.slice();
                        cur[2] = value;
                        root.applyKbdRgb(cur, true);
                    }
                }
            }
        }
    }
}
