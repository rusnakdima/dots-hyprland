// PerMonitorGamma.qml — fork-owned override for QuickSettings
// Per-monitor gamma / colour temperature adjustment via hyprsunset
// Lives in: dots-extra/quickshell/ii/modules/common/widgets/QuickSettings/Overrides/
// Survives setup update: yes (dots-extra/quickshell seam)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions

/**
 * PerMonitorGamma — QuickSettings tile for per-monitor gamma.
 *
 * Each monitor gets its own temperature slider. Uses hyprsunset >= 0.55
 * with the `monitor <name> temperature <K>` sub-command so that only the
 * targeted monitor is affected.
 *
 * Usage:
 *   hyprctl hyprsunset monitor "DP-1" temperature 4500
 *
 * Temperature range: 1000 K (warm) – 10000 K (cool), default 6500 K.
 */
Item {
    id: root
    width: parent.width
    height: 80

    /** Per-monitor temperature map: monitorName → temperature */
    property var monitorTemperatures: ({})

    /** List of monitor names discovered from Hyprland */
    property var monitors: []

    /** Currently selected monitor index */
    property int selectedMonitorIndex: 0

    /** Cache for current temperature of selectedMonitor */
    property int currentTemperature: 6500

    /** Temperature range */
    readonly property int minTemp: 1000
    readonly property int maxTemp: 10000
    readonly property int defaultTemp: 6500

    // ── UI ───────────────────────────────────────────────────────────────────

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        // Header row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Gamma"
                font.pointSize: 13
                font.weight: Font.Medium
                color: Theme.linkColor
            }

            Label {
                text: monitors.length > 0 ? monitors[selectedMonitorIndex] : "—"
                font.pointSize: 11
                color: Theme.textColor
                opacity: 0.7
            }

            Item { Layout.fillWidth: true }

            Label {
                text: `${currentTemperature} K`
                font.pointSize: 11
                font.family: "JetBrains Mono NF, monospace"
                color: Theme.textColor
            }
        }

        // Slider row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "🌙"
                font.pointSize: 12
            }

            Slider {
                id: tempSlider
                Layout.fillWidth: true
                from: root.minTemp
                to: root.maxTemp
                value: currentTemperature
                stepSize: 100
                live: true

                onMoved: {
                    root.currentTemperature = Math.round(value / 100) * 100
                    applyTemperature()
                }
            }

            Label {
                text: "☀️"
                font.pointSize: 12
            }
        }

        // Monitor selector row
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Label {
                text: "Monitor:"
                font.pointSize: 10
                color: Theme.textColor
                opacity: 0.6
            }

            Repeater {
                model: monitors.length

                Button {
                    text: monitors[index]
                    font.pointSize: 9
                    padding: "4,2"
                    checked: index === root.selectedMonitorIndex

                    onClicked: {
                        root.selectedMonitorIndex = index
                        root.currentTemperature = root.monitorTemperatures[monitors[index]] || root.defaultTemp
                        tempSlider.value = root.currentTemperature
                    }
                }
            }
        }
    }

    // ── Hyprsunset IPC ───────────────────────────────────────────────────────

    /**
     * Apply the current temperature to the selected monitor via hyprsunset.
     * Requires hyprsunset >= 0.55 with monitor support.
     */
    function applyTemperature() {
        if (monitors.length === 0) return
        const monitor = monitors[root.selectedMonitorIndex]
        if (!monitor) return

        const temp = root.currentTemperature
        const args = ["hyprsunset", "monitor", monitor, "temperature", String(temp)]

        process.start("hyprctl", args)

        // Cache value
        root.monitorTemperatures[monitor] = temp
    }

    /** Reset the selected monitor to default (6500 K / no filter). */
    function resetTemperature() {
        root.currentTemperature = root.defaultTemp
        tempSlider.value = root.defaultTemp
        applyTemperature()
    }

    // ── Monitor discovery ────────────────────────────────────────────────────

    Component.onCompleted: refreshMonitors()

    function refreshMonitors() {
        // Query monitors from Hyprland via hyprctl
        const proc = process.new()
        proc.stdout = StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const names = data.map(m => m.name)
                    root.monitors = names
                    for (const name of names) {
                        if (root.monitorTemperatures[name] === undefined) {
                            root.monitorTemperatures[name] = root.defaultTemp
                        }
                    }
                    if (names.length > 0 && root.selectedMonitorIndex >= names.length) {
                        root.selectedMonitorIndex = 0
                    }
                    if (root.monitors.length > 0) {
                        root.currentTemperature = root.monitorTemperatures[root.monitors[root.selectedMonitorIndex]] || root.defaultTemp
                        tempSlider.value = root.currentTemperature
                    }
                } catch (e) {
                    console.error("[PerMonitorGamma] Failed to parse monitors:", e)
                }
            }
        }
        proc.start("hyprctl", ["monitors", "-j"])
    }

    // ── Refresh on config reload ─────────────────────────────────────────────

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                refreshMonitors()
            }
        }
    }
}
