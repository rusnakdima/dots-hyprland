pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common

Item {
    id: root

    // ========================================================================
    // PROPERTIES (exported)
    // ========================================================================

    readonly property string cpuIcon: "󰻠"
    property string cpuName: ""
    property int cpuUsage: 0
    property int cpuTemp: 0
    property var coreUsages: []   // per-thread usage, 0-100
    property real cpuFreq: 0      // GHz (average over all threads)
    property real loadAvg: 0
    property var cpuHistory: []

    // Must match SystemMonitorService.historyLength for consistent history window
    readonly property int historyLength: 60

    // Control: expensive collectors (CPU temp) only run while detailed monitoring
    // is active. Set by SystemMonitorService based on popup visibility.
    property bool detailed: false

    // ========================================================================
    // INTERNAL STATE
    // ========================================================================

    QtObject {
        id: internal

        property var prevCpu: []          // [{ total, idle }] index 0 = aggregate
        property string cpuTempPath: ""   // resolved by SystemMonitorService hw detection
    }

    // ========================================================================
    // HELPERS
    // ========================================================================

    function _push(history, value) {
        const next = history.length >= historyLength ? history.slice(1) : history.slice();
        next.push(value);
        return next;
    }

    function _cleanCpuName(name) {
        // "11th Gen Intel(R) Core(TM) i7-11800H @ 2.30GHz" -> "Core i7-11800H"
        // "AMD Ryzen 7 5800X 8-Core Processor"              -> "Ryzen 7 5800X"
        return name.replace(/\(R\)|\(TM\)|\bCPU\b|@.*$|\d+-Core Processor/gi, "")
                  .replace(/^\d+\w\w Gen /i, "")
                  .replace(/^(Intel|AMD)\s+/i, "")
                  .replace(/\s+/g, " ")
                  .trim();
    }

    // ========================================================================
    // POLLING (called by SystemMonitorService timer)
    // ========================================================================

    // Called by SystemMonitorService._pollDetailed() via Cpu polling timer
    function poll() {
        statFile.reload();
        if (internal.cpuTempPath !== "")
            cpuTempFile.reload();
    }

    // Called by SystemMonitorService._pollDetailed() for less-frequent data
    function pollDetailed() {
        cpuinfoFile.reload();
        loadavgFile.reload();
    }

    onDetailedChanged: {
        if (!detailed) {
            // Samples taken minutes apart would render as a continuous line /
            // a long-window CPU average, so start fresh on the next open
            cpuHistory = [];
        }
    }

    // ========================================================================
    // POLLING TIMER
    // ========================================================================

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    // ========================================================================
    // FILES: STAT (CPU usage)
    // ========================================================================

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const lines = text().split("\n");
            const prev = internal.prevCpu;
            const next = [];
            const usages = [];

            for (const line of lines) {
                if (!line.startsWith("cpu"))
                    break;
                const f = line.split(/\s+/);
                let total = 0;
                for (let i = 1; i <= 8; i++)
                    total += parseInt(f[i]) || 0;
                const idle = (parseInt(f[4]) || 0) + (parseInt(f[5]) || 0);
                const idx = next.length;
                next.push({ total, idle });

                const p = prev[idx];
                const dt = p ? total - p.total : 0;
                usages.push(dt > 0 ? Math.max(0, Math.min(100, Math.round((1 - (idle - p.idle) / dt) * 100))) : 0);
            }

            internal.prevCpu = next;
            if (prev.length === 0)
                return;

            root.cpuUsage = usages[0];
            root.coreUsages = usages.slice(1);
            root.cpuHistory = _push(root.cpuHistory, usages[0]);
        }
    }

    // ========================================================================
    // FILES: CPU TEMPERATURE
    // ========================================================================

    FileView {
        id: cpuTempFile
        path: internal.cpuTempPath
        onLoaded: {
            const t = parseInt(text());
            if (!isNaN(t))
                root.cpuTemp = Math.round(t / 1000);
        }
    }

    // ========================================================================
    // FILES: CPUINFO (name, frequency)
    // ========================================================================

    FileView {
        id: cpuinfoFile
        path: "/proc/cpuinfo"
        onLoaded: {
            const data = text();
            if (root.cpuName === "") {
                const m = data.match(/^model name\s*:\s*(.+)$/m);
                if (m)
                    root.cpuName = root._cleanCpuName(m[1]);
            }
            const re = /^cpu MHz\s*:\s*([\d.]+)/gm;
            let sum = 0, count = 0, m;
            while ((m = re.exec(data)) !== null) {
                sum += parseFloat(m[1]);
                count++;
            }
            if (count > 0)
                root.cpuFreq = sum / count / 1000;
        }
    }

    // ========================================================================
    // FILES: LOAD AVG
    // ========================================================================

    FileView {
        id: loadavgFile
        path: "/proc/loadavg"
        onLoaded: root.loadAvg = parseFloat(text().split(" ")[0]) || 0
    }
}
