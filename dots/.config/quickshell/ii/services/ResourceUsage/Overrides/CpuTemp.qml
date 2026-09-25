/**
 * CpuTemp.qml — fork override for ResourceUsage.qml
 *
 * Adds CPU temperature reading from hwmon.
 * Requires read access to /sys/class/hwmon/.
 *
 * Config key: Config.options.indicators.cpuTemp (bool, default false)
 *
 * https://github.com/end-4/dots-hyprland/issues/3603
 */

import QtQuick
import Quickshell
import Quickshell.Io

ResourceUsage {
    // CPU temperature in °C, -1 = unavailable
    property real cpuTemp: -1
    property string cpuTempFormatted: cpuTemp < 0 ? "--" : (cpuTemp + "°C")

    // Poll hwmon files every 2s when enabled
    Timer {
        id: cpuTempTimer
        interval: 2000
        running: Config.options?.indicators?.cpuTemp ?? false
        repeat: true
        onTriggered: {
            fileHwmon.reload()
            _parseCpuTemp()
        }
    }

    // Try hwmon0 through hwmon3 — CPU temp is typically hwmon0 or hwmon1
    FileView {
        id: fileHwmon0
        path: "/sys/class/hwmon/hwmon0/temp1_input"
        visible: false
    }
    FileView {
        id: fileHwmon1
        path: "/sys/class/hwmon/hwmon1/temp1_input"
        visible: false
    }
    FileView {
        id: fileHwmon2
        path: "/sys/class/hwmon/hwmon2/temp1_input"
        visible: false
    }
    FileView {
        id: fileHwmon3
        path: "/sys/class/hwmon/hwmon3/temp1_input"
        visible: false
    }

    // Dummy FileView for polling — we cycle through the above
    property var _hwmonFiles: [fileHwmon0, fileHwmon1, fileHwmon2, fileHwmon3]
    property int _hwmonIndex: 0

    function _parseCpuTemp() {
        // Try each hwmon until we find a valid temperature
        const files = _hwmonFiles
        for (let i = 0; i < files.length; i++) {
            const f = files[i]
            try {
                const text = f.text().trim()
                const tempMillidegrees = parseInt(text, 10)
                if (!isNaN(tempMillidegrees) && tempMillidegrees > 0) {
                    cpuTemp = Math.round(tempMillidegrees / 1000.0)
                    return
                }
            } catch (e) {
                // File didn't exist or couldn't be read — try next
            }
        }
        cpuTemp = -1
    }
}
