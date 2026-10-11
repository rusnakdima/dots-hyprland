pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.services.metrics

Singleton {
    id: root

    // ========================================================================
    // SETTINGS
    // ========================================================================

    readonly property int interval: 2000
    readonly property int historyLength: 60 // samples (2 minutes at 2s)

    // Expensive collectors (GPU, disk) only run while at least one
    // monitor popup is open. Popups call acquire()/release() on visibility.
    property int _watchers: 0
    readonly property bool detailed: _watchers > 0

    function acquire() {
        _watchers++;
    }

    function release() {
        _watchers = Math.max(0, _watchers - 1);
    }

    onDetailedChanged: {
        if (!detailed) {
            Cpu.detailed = false;
            Gpu.detailed = false;
            return;
        }
        Disk.detailed = true;
        Cpu.detailed = true;
        Gpu.detailed = true;
        root._pollDetailed();
    }

    // ========================================================================
    // SYSTEM INFO
    // ========================================================================

    readonly property string hostname: hostnameFile.text().trim()
    readonly property string kernel: kernelFile.text().trim()
    property string uptime: "0m" // e.g. "2d 5h" or "3h 12m"

    // ========================================================================
    // CPU (delegated to Cpu module)
    // ========================================================================

    readonly property string cpuIcon: Cpu.cpuIcon
    property alias cpuName: Cpu.cpuName
    property alias cpuUsage: Cpu.cpuUsage
    property alias cpuTemp: Cpu.cpuTemp
    property alias coreUsages: Cpu.coreUsages
    property alias cpuFreq: Cpu.cpuFreq
    property alias loadAvg: Cpu.loadAvg
    property alias cpuHistory: Cpu.cpuHistory

    Cpu {
        id: cpuMonitor
        cpuTempPath: internal.cpuTempPath
    }

    // ========================================================================
    // GPU (delegated to Gpu module)
    // ========================================================================

    readonly property string gpuIcon: Gpu.gpuIcon
    property alias gpuType: Gpu.gpuType
    property alias gpuName: Gpu.gpuName
    property alias gpuSleeping: Gpu.gpuSleeping
    property alias gpuUsage: Gpu.gpuUsage
    property alias gpuTemp: Gpu.gpuTemp
    property alias gpuMemUsed: Gpu.gpuMemUsed
    property alias gpuMemTotal: Gpu.gpuMemTotal
    property alias gpuPower: Gpu.gpuPower
    property alias gpuHistory: Gpu.gpuHistory

    Gpu {
        id: gpuMonitor
    }

    // ========================================================================
    // MEMORY
    // ========================================================================

    property alias memUsage: Memory.memUsage
    property alias memUsed: Memory.memUsed
    property alias memTotal: Memory.memTotal
    property alias swapUsed: Memory.swapUsed
    property alias swapTotal: Memory.swapTotal
    property alias memHistory: Memory.memHistory

    Memory {}

    // ========================================================================
    // DISK (delegated to Disk module)
    // ========================================================================

    property alias disks: Disk.disks

    Disk {}

    // ========================================================================
    // NETWORK
    // ========================================================================

    property string netInterface: ""
    property real netDown: 0      // bytes/s
    property real netUp: 0        // bytes/s
    property real netDownTotal: 0 // bytes since shell start
    property real netUpTotal: 0
    property var netDownHistory: []
    property var netUpHistory: []

    // ========================================================================
    // HELPERS
    // ========================================================================

    function formatBytes(bytes) {
        return StringUtils.formatBytes(bytes, "", true);
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1048576)
            return (bytesPerSec / 1048576).toFixed(1) + " MB/s";
        if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(0) + " KB/s";
        return Math.round(bytesPerSec) + " B/s";
    }

    function formatGiB(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    function usageColor(usage) {
        if (usage >= 90)
            return Appearance.colors.colError;
        if (usage >= 70)
            return Appearance.colors.colWarning;
        return Appearance.colors.colAccent;
    }

    function tempColor(temp) {
        if (temp >= 85)
            return Appearance.colors.colError;
        if (temp >= 70)
            return Appearance.colors.colWarning;
        return Appearance.colors.colSuccess;
    }

    function _push(history, value) {
        const next = history.length >= historyLength ? history.slice(1) : history.slice();
        next.push(value);
        return next;
    }

    // ========================================================================
    // INTERNAL STATE
    // ========================================================================

    QtObject {
        id: internal

        property real prevRx: -1
        property real prevTx: -1
        property real prevNetTime: 0

        // Sensor paths resolved at startup
        property string cpuTempPath: ""
    }

    // ========================================================================
    // TIMERS
    // ========================================================================

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            Memory.poll();
            netFile.reload();
            uptimeFile.reload();

            if (root.detailed)
                root._pollDetailed();
        }
    }

    function _pollDetailed() {
        Cpu.pollDetailed();
        Gpu.pollDetailed();
    }

    // ========================================================================
    // HARDWARE DETECTION (runs once)
    // ========================================================================

    Process {
        running: true
        command: ["sh", "-c", `
            for h in /sys/class/hwmon/hwmon*; do
                case "$(cat "$h/name" 2>/dev/null)" in
                    coretemp|k10temp|zenpower|cpu_thermal) echo "cpuTemp=$h/temp1_input"; break ;;
                esac
            done
            for z in /sys/class/thermal/thermal_zone*; do
                case "$(cat "$z/type" 2>/dev/null)" in
                    x86_pkg_temp|TCPU|cpu*) echo "cpuTempFallback=$z/temp"; break ;;
                esac
            done

            if command -v nvidia-smi >/dev/null 2>&1; then
                echo "gpu=nvidia"
                for d in /sys/bus/pci/devices/*; do
                    [ "$(cat "$d/vendor" 2>/dev/null)" = "0x10de" ] || continue
                    case "$(cat "$d/class" 2>/dev/null)" in
                        0x03*) echo "nvidiaPci=$d"; break ;;
                    esac
                done
            elif busy=$(ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1) && [ -n "$busy" ]; then
                d=\${busy%/gpu_busy_percent}
                echo "gpu=amd"
                echo "amdBusy=$busy"
                echo "amdTemp=$(ls "$d"/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)"
                echo "amdVramUsed=$d/mem_info_vram_used"
                echo "amdVramTotal=$d/mem_info_vram_total"
                echo "gpuName=$(cat "$d/product_name" 2>/dev/null || echo "AMD Radeon")"
            elif freq=$(ls /sys/class/drm/card*/gt_act_freq_mhz 2>/dev/null | head -1) && [ -n "$freq" ]; then
                echo "gpu=intel"
                echo "intelFreq=$freq"
                echo "intelFreqMax=\${freq%/gt_act_freq_mhz}/gt_RP0_freq_mhz"
                echo "gpuName=Intel Graphics"
            fi
        `]
        stdout: SplitParser {
            onRead: line => {
                const i = line.indexOf("=");
                if (i < 0)
                    return;
                const key = line.slice(0, i);
                const value = line.slice(i + 1).trim();

                switch (key) {
                case "cpuTemp":
                    internal.cpuTempPath = value;
                    break;
                case "cpuTempFallback":
                    if (internal.cpuTempPath === "")
                        internal.cpuTempPath = value;
                    break;
                case "gpu":
                    gpuMonitor.configure({ gpuType: value });
                    console.log("[SystemMonitor] Detected GPU type:", value);
                    break;
                case "gpuName":
                    gpuMonitor.configure({ gpuName: value });
                    break;
                case "nvidiaPci":
                    gpuMonitor.configure({ nvidiaPciPath: value });
                    break;
                case "amdBusy":
                    gpuMonitor.configure({ amdBusyPath: value });
                    break;
                case "amdTemp":
                    gpuMonitor.configure({ amdTempPath: value });
                    break;
                case "amdVramUsed":
                    gpuMonitor.configure({ amdVramUsedPath: value });
                    break;
                case "amdVramTotal":
                    gpuMonitor.configure({ amdVramTotalPath: value });
                    break;
                case "intelFreq":
                    gpuMonitor.configure({ intelFreqPath: value });
                    break;
                case "intelFreqMax":
                    gpuMonitor.configure({ intelFreqMaxPath: value });
                    break;
                }
            }
        }
    }

    // ========================================================================
    // STATIC FILES
    // ========================================================================

    FileView {
        id: hostnameFile
        path: "/proc/sys/kernel/hostname"
    }

    FileView {
        id: kernelFile
        path: "/proc/sys/kernel/osrelease"
    }

    // ========================================================================
    // NETWORK
    // ========================================================================

    FileView {
        id: netFile
        path: "/proc/net/dev"
        onLoaded: {
            const now = Date.now();
            let rx = 0, tx = 0, busiest = "", busiestBytes = -1;

            for (const line of text().split("\n").slice(2)) {
                const sep = line.indexOf(":");
                if (sep < 0)
                    continue;
                const name = line.slice(0, sep).trim();
                if (/^(lo|docker|veth|br-|virbr|vnet)/.test(name))
                    continue;
                const f = line.slice(sep + 1).trim().split(/\s+/);
                const r = parseFloat(f[0]) || 0;
                const t = parseFloat(f[8]) || 0;
                rx += r;
                tx += t;
                if (r + t > busiestBytes) {
                    busiestBytes = r + t;
                    busiest = name;
                }
            }

            root.netInterface = busiest;

            if (internal.prevRx >= 0) {
                const secs = Math.max(0.001, (now - internal.prevNetTime) / 1000);
                const dRx = Math.max(0, rx - internal.prevRx);
                const dTx = Math.max(0, tx - internal.prevTx);
                root.netDown = dRx / secs;
                root.netUp = dTx / secs;
                root.netDownTotal += dRx;
                root.netUpTotal += dTx;
                root.netDownHistory = root._push(root.netDownHistory, root.netDown);
                root.netUpHistory = root._push(root.netUpHistory, root.netUp);
            }

            internal.prevRx = rx;
            internal.prevTx = tx;
            internal.prevNetTime = now;
        }
    }

    // ========================================================================
    // UPTIME
    // ========================================================================

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const total = parseInt(text());
            if (isNaN(total))
                return;

            const days = Math.floor(total / 86400);
            const hours = Math.floor((total % 86400) / 3600);
            const minutes = Math.floor((total % 3600) / 60);

            if (days > 0)
                root.uptime = days + "d " + hours + "h";
            else if (hours > 0)
                root.uptime = hours + "h " + minutes + "m";
            else
                root.uptime = minutes + "m";
        }
    }

}
