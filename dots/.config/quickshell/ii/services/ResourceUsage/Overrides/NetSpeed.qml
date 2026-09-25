/**
 * NetSpeed.qml — fork override for ResourceUsage.qml
 *
 * Adds network upload/download speed indicators.
 * Reads /sys/class/net/<iface>/statistics/rx_bytes and tx_bytes deltas.
 *
 * Config keys:
 *   Config.options.indicators.netSpeed (bool, default false)
 *   Config.options.indicators.netSpeedInterval (int, ms, default 2000)
 *
 * https://github.com/end-4/dots-hyprland/issues/3603
 */

import QtQuick
import Quickshell
import Quickshell.Io

ResourceUsage {
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

    // Reload all interface stat files on interval
    Timer {
        id: netSpeedTimer
        interval: (Config.options?.indicators?.netSpeedInterval ?? 2000)
        running: Config.options?.indicators?.netSpeed ?? false
        repeat: true
        onTriggered: {
            _reloadNetFiles()
            _updateNetSpeed()
        }
    }

    // FileViews for each interface — dynamically named
    // We use a fixed set and filter to non-loopback in the update
    property var _netFiles: [
        _netFileRx0, _netFileTx0,
        _netFileRx1, _netFileTx1,
        _netFileRx2, _netFileTx2,
    ]

    FileView { id: _netFileRx0; path: "/sys/class/net/eth0/statistics/rx_bytes"; visible: false }
    FileView { id: _netFileTx0; path: "/sys/class/net/eth0/statistics/tx_bytes"; visible: false }
    FileView { id: _netFileRx1; path: "/sys/class/net/wlan0/statistics/rx_bytes"; visible: false }
    FileView { id: _netFileTx1; path: "/sys/class/net/wlan0/statistics/tx_bytes"; visible: false }
    FileView { id: _netFileRx2; path: "/sys/class/net/enp0s0/statistics/rx_bytes"; visible: false }
    FileView { id: _netFileTx2; path: "/sys/class/net/enp0s0/statistics/tx_bytes"; visible: false }

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
        const ifaces = ["eth0", "wlan0", "enp0s0", "wlp3s0"]
        const statsMap = [
            [_netFileRx0, _netFileTx0],
            [_netFileRx1, _netFileTx1],
            [_netFileRx2, _netFileTx2],
        ]

        let totalRx = 0
        let totalTx = 0
        const now = Date.now()
        const interval = ((Config.options?.indicators?.netSpeedInterval ?? 2000) / 1000.0)

        for (let i = 0; i < ifaces.length; i++) {
            const rxFile = statsMap[i][0]
            const txFile = statsMap[i][1]
            const iface = ifaces[i]

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
}
