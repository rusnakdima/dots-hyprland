pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
            memoryUsageHistory = memoryUsageHistory.slice() // reassign so bindings notify
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
            swapUsageHistory = swapUsageHistory.slice() // reassign so bindings notify
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
            cpuUsageHistory = cpuUsageHistory.slice() // reassign so bindings notify
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
    }

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                const maxMhz = parseFloat(outputCollector.text)
                root.maxAvailableCpuString = isNaN(maxMhz) ? "--" : (maxMhz / 1000).toFixed(0) + " GHz"
            }
        }
    }

    // ─── Network speed (gated by Config.options.indicators.netSpeed, default disabled) ───
    property real downloadSpeed: 0  // bytes/s
    property real uploadSpeed: 0    // bytes/s

    property string downloadSpeedFormatted: _formatSpeed(downloadSpeed)
    property string uploadSpeedFormatted: _formatSpeed(uploadSpeed)

    // Track previous byte counts and timestamp for delta calculation
    property var _prevRxBytes: ({})
    property var _prevTxBytes: ({})
    property int _prevTimestamp: 0

    function _formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) {
            return bytesPerSec.toFixed(0) + " B/s"
        } else if (bytesPerSec < 1024 * 1024) {
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        } else {
            return (bytesPerSec / (1024 * 1024)).toFixed(2) + " MB/s"
        }
    }

    Timer {
        id: netSpeedTimer
        interval: (Config.options?.indicators?.netSpeedInterval ?? 2000)
        running: Config.options?.indicators?.netSpeed ?? false
        repeat: true
        onTriggered: {
            root._reloadNetFiles()
            root._updateNetSpeed()
        }
    }

    // FileViews for each tracked interface — pairs kept together with the iface
    // name so the update loop can never index past the available files.
    // printErrors is false because most machines lack some of these interfaces.
    property var _netFiles: [
        _netFileRx0, _netFileTx0,
        _netFileRx1, _netFileTx1,
        _netFileRx2, _netFileTx2,
        _netFileRx3, _netFileTx3,
    ]

    FileView { id: _netFileRx0; printErrors: false; path: "/sys/class/net/eth0/statistics/rx_bytes" }
    FileView { id: _netFileTx0; printErrors: false; path: "/sys/class/net/eth0/statistics/tx_bytes" }
    FileView { id: _netFileRx1; printErrors: false; path: "/sys/class/net/wlan0/statistics/rx_bytes" }
    FileView { id: _netFileTx1; printErrors: false; path: "/sys/class/net/wlan0/statistics/tx_bytes" }
    FileView { id: _netFileRx2; printErrors: false; path: "/sys/class/net/enp0s0/statistics/rx_bytes" }
    FileView { id: _netFileTx2; printErrors: false; path: "/sys/class/net/enp0s0/statistics/tx_bytes" }
    FileView { id: _netFileRx3; printErrors: false; path: "/sys/class/net/wlp3s0/statistics/rx_bytes" }
    FileView { id: _netFileTx3; printErrors: false; path: "/sys/class/net/wlp3s0/statistics/tx_bytes" }

    function _reloadNetFiles() {
        for (const f of _netFiles) {
            f.reload()
        }
    }

    function _readNetStat(fileView) {
        try {
            const text = fileView.text().trim()
            return parseInt(text, 10) || 0
        } catch (e) {
            return 0
        }
    }

    function _updateNetSpeed() {
        const ifaces = [
            ["eth0", _netFileRx0, _netFileTx0],
            ["wlan0", _netFileRx1, _netFileTx1],
            ["enp0s0", _netFileRx2, _netFileTx2],
            ["wlp3s0", _netFileRx3, _netFileTx3],
        ]

        let totalRx = 0
        let totalTx = 0
        const now = Date.now()
        const interval = ((Config.options?.indicators?.netSpeedInterval ?? 2000) / 1000.0)

        for (const [iface, rxFile, txFile] of ifaces) {
            const rx = _readNetStat(rxFile)
            const tx = _readNetStat(txFile)

            if (_prevRxBytes[iface] !== undefined && _prevTimestamp > 0 && interval > 0) {
                totalRx += Math.max(0, rx - _prevRxBytes[iface])
                totalTx += Math.max(0, tx - _prevTxBytes[iface])
            }

            _prevRxBytes[iface] = rx
            _prevTxBytes[iface] = tx
        }

        _prevTimestamp = now

        if (interval > 0) {
            downloadSpeed = totalRx / interval
            uploadSpeed = totalTx / interval
        }
    }

    // ─── CPU temperature (gated by Config.options.indicators.cpuTemp, default disabled) ───
    // CPU temperature in °C, -1 = unavailable
    property real cpuTemp: -1
    property string cpuTempFormatted: cpuTemp < 0 ? "--" : (cpuTemp + "°C")

    Timer {
        id: cpuTempTimer
        interval: 2000
        running: Config.options?.indicators?.cpuTemp ?? false
        repeat: true
        onTriggered: {
            root._reloadHwmonFiles()
            root._parseCpuTemp()
        }
    }

    // Try hwmon0 through hwmon3 — CPU temp is typically hwmon0 or hwmon1
    FileView { id: fileHwmon0; printErrors: false; path: "/sys/class/hwmon/hwmon0/temp1_input" }
    FileView { id: fileHwmon1; printErrors: false; path: "/sys/class/hwmon/hwmon1/temp1_input" }
    FileView { id: fileHwmon2; printErrors: false; path: "/sys/class/hwmon/hwmon2/temp1_input" }
    FileView { id: fileHwmon3; printErrors: false; path: "/sys/class/hwmon/hwmon3/temp1_input" }

    property var _hwmonFiles: [fileHwmon0, fileHwmon1, fileHwmon2, fileHwmon3]

    function _reloadHwmonFiles() {
        for (const f of _hwmonFiles) {
            f.reload()
        }
    }

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
