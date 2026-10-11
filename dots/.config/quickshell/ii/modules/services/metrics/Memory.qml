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

    property int memUsage: 0
    property real memUsed: 0     // bytes
    property real memTotal: 0    // bytes
    property real swapUsed: 0    // bytes
    property real swapTotal: 0  // bytes
    property var memHistory: []

    // Must match SystemMonitorService.historyLength for consistent history window
    readonly property int historyLength: 60

    // ========================================================================
    // HELPERS
    // ========================================================================

    function _push(history, value) {
        const next = history.length >= historyLength ? history.slice(1) : history.slice();
        next.push(value);
        return next;
    }

    // ========================================================================
    // POLLING
    // ========================================================================

    // Called by SystemMonitorService timer
    function poll() {
        meminfoFile.reload();
    }

    // ========================================================================
    // FILE: MEMINFO
    // ========================================================================

    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            const kb = key => {
                const m = data.match(new RegExp("^" + key + ":\\s*(\\d+)", "m"));
                return m ? parseInt(m[1]) * 1024 : 0;
            };

            const total = kb("MemTotal");
            if (total <= 0)
                return;

            root.memTotal = total;
            root.memUsed = total - kb("MemAvailable");
            root.memUsage = Math.round(root.memUsed / total * 100);
            root.swapTotal = kb("SwapTotal");
            root.swapUsed = root.swapTotal - kb("SwapFree");
            root.memHistory = _push(root.memHistory, root.memUsage);
        }
    }
}
