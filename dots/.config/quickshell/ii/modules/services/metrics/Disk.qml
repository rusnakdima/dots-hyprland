pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ========================================================================
    // PROPERTIES (exported)
    // ========================================================================

    property var disks: [] // [{ mount, used, total, usage }]

    // Control: expensive disk collector only runs while detailed monitoring
    // is active. Set by SystemMonitorService based on popup visibility.
    property bool detailed: false

    // ========================================================================
    // POLLING (called by internal timer)
    // ========================================================================

    function poll() {
        if (!detailed)
            return;
        updateDisk.running = true;
    }

    onDetailedChanged: {
        if (!detailed) {
            disks = [];
            return;
        }
        poll();
    }

    // ========================================================================
    // POLLING TIMER
    // ========================================================================

    Timer {
        interval: 30000
        running: root.detailed
        repeat: true
        onTriggered: root.poll()
    }

    // ========================================================================
    // PROCESS: DISK USAGE
    // ========================================================================

    Process {
        id: updateDisk
        running: false
        command: ["df", "-B1", "--output=source,target,size,used", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay", "-x", "squashfs"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Keep "/" plus "/home" when it lives on another device
                const rows = text.trim().split("\n").slice(1).map(l => l.trim().split(/\s+/));
                const rootFs = rows.find(r => r[1] === "/");
                const home = rows.find(r => r[1] === "/home");
                const result = [];

                for (const r of [rootFs, home]) {
                    if (!r || (r === home && rootFs && home[0] === rootFs[0]))
                        continue;
                    const total = parseFloat(r[2]);
                    const used = parseFloat(r[3]);
                    if (total > 0)
                        result.push({ mount: r[1], used, total, usage: Math.round(used / total * 100) });
                }
                root.disks = result;
            }
        }
    }
}
