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

    readonly property string gpuIcon: "󰢮"
    property string gpuType: "unknown" // "nvidia", "amd", "intel", "unknown"
    property string gpuName: ""
    property bool gpuSleeping: false   // dGPU runtime-suspended (we don't wake it)
    property int gpuUsage: 0
    property int gpuTemp: 0
    property real gpuMemUsed: 0        // bytes
    property real gpuMemTotal: 0       // bytes
    property real gpuPower: -1         // watts, -1 when unavailable
    property var gpuHistory: []

    // Must match SystemMonitorService.historyLength for consistent history window
    readonly property int historyLength: 60

    // Control: GPU polling only runs while detailed monitoring is active.
    // Set by SystemMonitorService based on popup visibility.
    property bool detailed: false

    // ========================================================================
    // INTERNAL STATE
    // ========================================================================

    QtObject {
        id: internal

        // Sensor paths resolved by SystemMonitorService hardware detection
        property string nvidiaPciPath: ""
        property string amdBusyPath: ""
        property string amdTempPath: ""
        property string amdVramUsedPath: ""
        property string amdVramTotalPath: ""
        property string intelFreqPath: ""
        property string intelFreqMaxPath: ""
    }

    // ========================================================================
    // HELPERS
    // ========================================================================

    function _push(history, value) {
        const next = history.length >= historyLength ? history.slice(1) : history.slice();
        next.push(value);
        return next;
    }

    // Called by SystemMonitorService after hardware detection resolves paths
    function configure(config) {
        if (config.nvidiaPciPath !== undefined)
            internal.nvidiaPciPath = config.nvidiaPciPath;
        if (config.amdBusyPath !== undefined)
            internal.amdBusyPath = config.amdBusyPath;
        if (config.amdTempPath !== undefined)
            internal.amdTempPath = config.amdTempPath;
        if (config.amdVramUsedPath !== undefined)
            internal.amdVramUsedPath = config.amdVramUsedPath;
        if (config.amdVramTotalPath !== undefined)
            internal.amdVramTotalPath = config.amdVramTotalPath;
        if (config.intelFreqPath !== undefined)
            internal.intelFreqPath = config.intelFreqPath;
        if (config.intelFreqMaxPath !== undefined)
            internal.intelFreqMaxPath = config.intelFreqMaxPath;
        if (config.gpuName !== undefined)
            root.gpuName = config.gpuName;
        if (config.gpuType !== undefined)
            root.gpuType = config.gpuType;
    }

    // ========================================================================
    // POLLING (called by internal Timer)
    // ========================================================================

    // Basic polling: reloads GPU files / triggers nvidia-smi every 2 seconds
    function poll() {
        // Only reload when detailed (popup open), same as Cpu
        if (!detailed)
            return;

        switch (gpuType) {
        case "nvidia":
            if (internal.nvidiaPciPath !== "")
                nvidiaPowerFile.reload();
            else if (!updateNvidia.running)
                updateNvidia.running = true;
            break;
        case "amd":
            amdBusyFile.reload();
            break;
        case "intel":
            intelFreqFile.reload();
            break;
        }
    }

    // Detailed polling: reloads slower-changing files
    function pollDetailed() {
        if (!detailed)
            return;

        switch (gpuType) {
        case "nvidia":
            if (internal.nvidiaPciPath !== "")
                nvidiaPowerFile.reload();
            else if (!updateNvidia.running)
                updateNvidia.running = true;
            break;
        case "amd":
            amdBusyFile.reload();
            amdTempFile.reload();
            amdVramUsedFile.reload();
            amdVramTotalFile.reload();
            break;
        case "intel":
            intelFreqFile.reload();
            break;
        }
    }

    onDetailedChanged: {
        if (!detailed) {
            gpuHistory = [];
            return;
        }
        // Start fresh history on next poll
    }

    // ========================================================================
    // POLLING TIMER
    // ========================================================================

    Timer {
        interval: 2000
        running: root.detailed
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    // ========================================================================
    // NVIDIA
    // ========================================================================

    // Reading runtime_status doesn't wake the card; nvidia-smi would, so we only
    // query it when the dGPU is already awake.
    FileView {
        id: nvidiaPowerFile
        path: internal.nvidiaPciPath !== "" ? internal.nvidiaPciPath + "/power/runtime_status" : ""
        onLoaded: {
            const status = text().trim();
            root.gpuSleeping = status === "suspended" || status === "suspending";
            if (root.gpuSleeping) {
                root.gpuUsage = 0;
                if (root.detailed)
                    root.gpuHistory = root._push(root.gpuHistory, 0);
            } else if (!updateNvidia.running) {
                updateNvidia.running = true;
            }
        }
        onLoadFailed: {
            if (!updateNvidia.running)
                updateNvidia.running = true;
        }
    }

    Process {
        id: updateNvidia
        command: ["nvidia-smi", "--query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw", "--format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                const f = data.split(",").map(s => s.trim());
                if (f.length < 6)
                    return;

                root.gpuName = f[0].replace(/^NVIDIA\s+/, "").replace(/^GeForce\s+/, "");
                const usage = parseInt(f[1]);
                const temp = parseInt(f[2]);
                const power = parseFloat(f[5]);

                if (!isNaN(usage)) {
                    root.gpuUsage = usage;
                    if (root.detailed)
                        root.gpuHistory = root._push(root.gpuHistory, usage);
                }
                if (!isNaN(temp))
                    root.gpuTemp = temp;
                root.gpuMemUsed = (parseFloat(f[3]) || 0) * 1048576;
                root.gpuMemTotal = (parseFloat(f[4]) || 0) * 1048576;
                root.gpuPower = isNaN(power) ? -1 : power;
            }
        }
    }

    // ========================================================================
    // AMD
    // ========================================================================

    FileView {
        id: amdBusyFile
        path: internal.amdBusyPath
        onLoaded: {
            const usage = parseInt(text());
            if (isNaN(usage))
                return;
            root.gpuUsage = usage;
            if (root.detailed)
                root.gpuHistory = root._push(root.gpuHistory, usage);
        }
    }

    FileView {
        id: amdTempFile
        path: internal.amdTempPath
        onLoaded: root.gpuTemp = Math.round((parseInt(text()) || 0) / 1000)
    }

    FileView {
        id: amdVramUsedFile
        path: internal.amdVramUsedPath
        onLoaded: root.gpuMemUsed = parseFloat(text()) || 0
    }

    FileView {
        id: amdVramTotalFile
        path: internal.amdVramTotalPath
        onLoaded: root.gpuMemTotal = parseFloat(text()) || 0
    }

    // ========================================================================
    // INTEL (no utilization counter without root; frequency is the best proxy)
    // ========================================================================

    FileView {
        id: intelFreqFile
        path: internal.intelFreqPath
    }

    FileView {
        id: intelFreqMaxFile
        path: internal.intelFreqMaxPath
        onLoaded: {
            const cur = parseInt(intelFreqFile.text());
            const max = parseInt(text());
            if (isNaN(cur) || !(max > 0))
                return;
            const usage = Math.round(cur / max * 100);
            root.gpuUsage = usage;
            if (root.detailed)
                root.gpuHistory = root._push(root.gpuHistory, usage);
        }
    }
}
