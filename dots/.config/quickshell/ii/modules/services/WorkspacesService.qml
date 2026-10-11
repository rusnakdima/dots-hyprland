pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * WorkspacesService — reads per-monitor workspace blocks from the Hyprland
 * runtime state file and exposes them to bar/panel QML components.
 *
 * State is written by conf/workspaces.lua via write_json() to:
 *   $XDG_RUNTIME_DIR/dots-workspaces.json
 *
 * Schema per monitor entry:
 *   { "base": 100, "filled": [100, 101, 103], "monitor": "DP-1" }
 *
 * Usage in a component:
 *   WorkspacesService.baseFor("DP-1")   // → 100
 *   WorkspacesService.ownerOf(103)       // → monitor entry or null
 */
Singleton {
    id: root

    /* Block size: each monitor gets a block of 100 workspace IDs. */
    readonly property int blockSize: 100

    /* Max workspaces per block (blockSize - 1, since IDs start at base). */
    readonly property int maxPerBlock: 99

    /* JSON state file written by the Hyprland Lua side. */
    readonly property string stateFile: {
        var xdg = StandardPaths.home + "/.local/share"
        // XDG_RUNTIME_DIR fallback
        try {
            xdg = Env.getenv("XDG_RUNTIME_DIR") || "/tmp"
        } catch (e) {}
        return xdg + "/dots-workspaces.json"
    }

    /* Parsed state: array of monitor entries { base, filled, monitor }. */
    property var monitors: []

    /* Debounce: coalesce rapid file changes from Hyprland events. */
    Timer {
        id: debounceTimer
        interval: 400
        repeat: false
        onTriggered: reload()
    }

    function reload() {
        try {
            monitors = JSON.parse(FileIO.read(stateFile))
        } catch (e) {
            monitors = []
        }
    }

    /* Watch the runtime JSON for changes. */
    FileView {
        id: stateView
        path: Qt.resolvedUrl(root.stateFile)
        watchChanges: true
        onFileChanged: debounceTimer.restart()
        Component.onCompleted: reload()
    }

    /* Return the base workspace ID for a monitor, or -1 if unknown. */
    function baseFor(monitorName) {
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].monitor === monitorName) {
                return monitors[i].base
            }
        }
        return -1
    }

    /* Return the monitor entry whose block contains workspaceId, or null. */
    function ownerOf(workspaceId) {
        for (var i = 0; i < monitors.length; i++) {
            var entry = monitors[i]
            if (workspaceId >= entry.base && workspaceId < entry.base + blockSize) {
                return entry
            }
        }
        return null
    }

    /* Return all workspace IDs in a monitor's block. */
    function filledFor(monitorName) {
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].monitor === monitorName) {
                return monitors[i].filled || []
            }
        }
        return []
    }

    /* True if workspaceId is within monitorName's block. */
    function inBlock(workspaceId, monitorName) {
        var entry = ownerOf(workspaceId)
        return entry !== null && entry.monitor === monitorName
    }
}
