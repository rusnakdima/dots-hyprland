pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Controls RGB keyboard backlight via /sys/class/leds/rgb:kbd_backlight/multi_intensity.
 * Per-channel intensity 0..4 (hardware max_brightness = 4).
 * Shared by Settings → Appearance and the sidebarRight keyboard-color toggle.
 */
Singleton {
    id: root

    // ─── State ──────────────────────────────────────────────────────────────

    // Current applied color [r, g, b] each 0..4
    // Initialized from config; persists via onCurrentRgbChanged
    property list<int> currentRgb: Config.options?.keyboard?.rgb ?? [4, 4, 4]

    // Last non-off color applied via apply() — used for toggle-on.
    // Plain property (not binding) so it is always overridable by apply().
    property list<int> lastAppliedNonOff: [4, 4, 4]

    // ─── Presets ─────────────────────────────────────────────────────────────

    readonly property list<var> presets: [
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

    // ─── Sysfs path ──────────────────────────────────────────────────────────

    readonly property string sysfsPath: "/sys/class/leds/rgb:kbd_backlight/multi_intensity"

    // ─── Apply ───────────────────────────────────────────────────────────────

    Process {
        id: kbdWriteProc
        stdout: StdioCollector { }
    }

    /**
     * Apply an RGB color (3-element array [r,g,b], each 0..4).
     * Writes to sysfs via bash pipeline (echo|tee), persists to Config,
     * and tracks lastAppliedNonOff.
     */
    function apply(channels) {
        const c = channels.slice()
        for (let i = 0; i < 3; i++) {
            if (typeof c[i] !== "number") c[i] = 4
            c[i] = Math.max(0, Math.min(4, Math.round(c[i])))
        }

        // Track last non-off color for toggle-on
        if (c[0] > 0 || c[1] > 0 || c[2] > 0) {
            root.lastAppliedNonOff = c
        }

        // Update in-memory state immediately (Config debounce handles disk dedup)
        root.currentRgb = c

        // Write via bash pipeline so the shell waits for the write to complete
        // before the process exits.  No sudo needed — udev rule sets group=input.
        const rgbStr = c.join(" ")
        kbdWriteProc.command = [
            "bash", "-c",
            `printf '%s\\n' '${rgbStr}' | tee '${sysfsPath}' > /dev/null`
        ]
        kbdWriteProc.running = true
    }

    // ─── Persist ─────────────────────────────────────────────────────────────

    // Persist to Config whenever currentRgb changes.
    // Config.setNestedValue is debounced (Config.qml readWriteDelay=50ms) so
    // rapid calls from the same apply() session are deduplicated automatically.
    onCurrentRgbChanged: {
        Config.setNestedValue("keyboard.rgb", currentRgb)
    }

    // ─── IPC handler ─────────────────────────────────────────────────────────

    IpcHandler {
        target: "kbdBacklight"

        function apply(r: int, g: int, b: int) {
            root.apply([r, g, b])
        }

        function get() {
            return root.currentRgb
        }

        function listPresets() {
            return root.presets
        }

        function setEnabled(enabled: bool) {
            if (enabled) {
                root.apply(root.lastAppliedNonOff)
            } else {
                root.apply([0, 0, 0])
            }
        }
    }
}
