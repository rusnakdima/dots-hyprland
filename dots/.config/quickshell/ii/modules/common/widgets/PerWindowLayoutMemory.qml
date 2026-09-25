/**
 * PerWindowLayoutMemory.qml — Fork-owned per-window keyboard layout memory
 *
 * When `keyboard.per_window_memory = true`, subscribes to Hyprland window
 * focus events and restores the previously-used layout for each window class.
 *
 * On focus-out: saves current layout + window class to a cache file.
 * On focus-in: reads cache and applies the remembered layout if present.
 *
 * Requires: HyprlandXkb service, hyprctl
 */

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    visible: false  // Headless component — runs in background

    // Cache file stored in XDG_STATE_HOME or ~/.local/state
    readonly property string cacheDir: {
        const xdgState = Helpers.env("XDG_STATE_HOME") || "";
        return xdgState ? `${xdgState}/kbdlayout-memory` : `${Helpers.env("HOME")}/.local/state/kbdlayout-memory`
    }
    readonly property string cacheFile: `${root.cacheDir}/window-layout-memory.json`

    // Polling state to detect layout changes
    property string lastLayout: ""
    property string lastWindowClass: ""
    property var memory: ({})  // { "Firefox": "us", "kitty": "colemak" }

    // Debounce rapid focus events
    property int _debounceMs: 150
    property Timer _focusDebounce: Timer { interval: root._debounceMs; repeat: false; }

    function getWindowClass(windowInfo) {
        // windowInfo may be a string or object depending on event source
        if (typeof windowInfo === "string") return windowInfo
        if (typeof windowInfo === "object" && windowInfo !== null) {
            return windowInfo["class"] || windowInfo["appId"] || ""
        }
        return ""
    }

    // Load memory from cache file
    function loadMemory() {
        const file = Helpers.file(cacheFile)
        if (file.exists) {
            try {
                const content = file.read()
                root.memory = JSON.parse(content)
            } catch (e) {
                root.memory = {}
            }
        }
    }

    // Save memory to cache file
    function saveMemory() {
        Helpers.runProcess("bash", ["-c", `mkdir -p "${root.cacheDir}" && echo '${JSON.stringify(root.memory)}' > "${root.cacheFile}"`])
    }

    // Save current layout for a window class
    function saveForClass(windowClass, layout) {
        if (!Config.options.keyboard.per_window_memory) return
        if (!windowClass || !layout) return
        root.memory[windowClass] = layout
        root.saveMemory()
    }

    // Get remembered layout for a window class
    function getForClass(windowClass) {
        if (!Config.options.keyboard.per_window_memory) return ""
        if (!windowClass) return ""
        return root.memory[windowClass] || ""
    }

    // Apply a layout by name
    function applyLayout(layoutName) {
        if (!layoutName) return
        Helpers.runProcess("hyprctl", ["switchxkblayout", layoutName])
    }

    // Load memory on startup
    Component.onCompleted: {
        root.loadMemory()
        root.lastLayout = HyprlandXkb.currentLayoutName || "us"
    }

    // Watch for Hyprland window focus changes
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            // Focus changes emit "window" events in Hyprland protocol
            if (!Config.options.keyboard.per_window_memory) return
            if (root._focusDebounce.running) return
            root._focusDebounce.restart()

            // Poll focused window after debounce
            root._focusDebounce.triggered.connect(() => {
                _checkFocusedWindow()
            })
        }
    }

    // Also watch via ToplevelManager for app switching
    Connections {
        target: ToplevelManager

        function onToplevelFocused(toplevel) {
            if (!Config.options.keyboard.per_window_memory) return
            const appId = toplevel?.appId || ""
            const remembered = root.getForClass(appId)
            if (remembered) {
                root.applyLayout(remembered)
            }
        }
    }

    // Watch for layout changes to save them on focus-out
    Connections {
        target: HyprlandXkb

        function onCurrentLayoutNameChanged() {
            if (!Config.options.keyboard.per_window_memory) return
            const current = HyprlandXkb.currentLayoutName || ""
            if (current && root.lastWindowClass) {
                root.saveForClass(root.lastWindowClass, current)
            }
        }
    }

    // Poll to detect focused window (backup for raw event misses)
    property Timer _pollTimer: Timer {
        interval: 1000
        repeat: true
        running: Config.options.keyboard.per_window_memory
        onTriggered: root._checkFocusedWindow()
    }

    function _checkFocusedWindow() {
        // Get active window via hyprctl
        const proc = Helpers.runProcess("hyprctl", ["-j", "activewindow"])
        let windowClass = ""
        try {
            const output = proc?.stdout || ""
            const data = JSON.parse(output)
            windowClass = data["class"] || ""
        } catch (e) {
            // Fallback: try to read directly
        }

        if (!windowClass) return

        // If window changed, restore its layout
        if (windowClass !== root.lastWindowClass) {
            const prevClass = root.lastWindowClass
            const prevLayout = HyprlandXkb.currentLayoutName || ""

            // Save previous window's layout before switching
            if (prevClass && prevLayout) {
                root.saveForClass(prevClass, prevLayout)
            }

            root.lastWindowClass = windowClass

            // Restore this window's layout
            const remembered = root.getForClass(windowClass)
            if (remembered) {
                root.applyLayout(remembered)
            }
        }
    }
}
