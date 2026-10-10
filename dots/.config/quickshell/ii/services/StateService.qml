pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * StateService — single source of truth for all Quickshell UI state.
 *
 * Architecture:
 *   - Reads state from ~/.config/quickshell/ii/state.json (user state)
 *   - Falls back to defaults from ~/.config/quickshell/ii/defaults.json
 *   - All writes go through StateService.set() — no file writes directly from QML
 *   - Debounces writes by 300ms to coalesce rapid changes
 *   - Watches the file for external changes (CLI edits, lyne update)
 */
Singleton {
    id: root

    property string statePath:     StandardPaths.home + "/.config/quickshell/ii/state.json"
    property string defaultsPath:  StandardPaths.home + "/.config/quickshell/ii/defaults.json"

    // ── Runtime state ────────────────────────────────────────────────
    property var  state:     ({})   // the user-state object
    property var  defaults:  ({})   // the defaults object
    property int  revision: 0      // bumped on every mutation
    property bool ready:    false   // true after first load

    // ── Debounce timer ───────────────────────────────────────────────
    property int writeDelay: 300    // ms

    // ── Lifecycle ────────────────────────────────────────────────────

    FileView {
        id: defaultsView
        path: root.defaultsPath
        watchChanges: false
        onLoaded: {
            root.defaults = _parseJson(content) || {}
        }
        onLoadFailed: {
            root.defaults = {}
        }
    }

    FileView {
        id: stateView
        path: root.statePath
        watchChanges: true
        onLoaded: {
            root.state = _parseJson(content) || {}
            root.ready = true
            root._bump()
        }
        onLoadFailed: {
            // First run — state file doesn't exist yet; start empty
            root.state = {}
            root.ready = true
            root._bump()
        }
        onFileChanged: {
            // External change (e.g. lyne CLI wrote the file)
            // Skip our own echo by comparing the last content we wrote
            var fresh = _parseJson(stateView.content) || {}
            if (JSON.stringify(fresh) !== JSON.stringify(root.state)) {
                root.state = fresh
                root._bump()
            }
        }
        onAdapterUpdated: {
            root._debouncedWrite()
        }
    }

    Timer {
        id: writeTimer
        interval: root.writeDelay
        repeat: false
        onTriggered: {
            stateView.writeAdapter()
        }
    }

    // ── Public API ───────────────────────────────────────────────────

    /* Read a value by dot-notation path.
     * Falls back to defaults if not in state.
     * Falls back to the provided fallback if neither has the key.
     *
     * get("bar.height", 48)  →  reads state.bar.height, else defaults.bar.height, else 48
     */
    function get(path, fallback) {
        var val = _getPath(root.state, path)
        if (val !== undefined) return val

        val = _getPath(root.defaults, path)
        if (val !== undefined) return val

        return fallback
    }

    /* Write a value by dot-notation path.
     * Debounces the file write by writeDelay ms.
     */
    function set(path, value) {
        _setPath(root.state, path, value)
        root._bump()
        root._debouncedWrite()
    }

    /* Reset a path to its default value.
     * Removes the key from state if it matches the default.
     */
    function reset(path) {
        var def = _getPath(root.defaults, path)
        if (def === undefined) {
            // No default — remove from state
            _delPath(root.state, path)
        } else {
            _setPath(root.state, path, def)
        }
        root._bump()
        root._debouncedWrite()
    }

    /* Returns true when the current value equals the default. */
    function isDefault(path) {
        var current = _getPath(root.state, path)
        var def     = _getPath(root.defaults, path)
        return current === def
    }

    /* Returns true when the path has no user override (not in state). */
    function isUnset(path) {
        return _getPath(root.state, path) === undefined
    }

    // Emitted on first load and whenever state changes
    signal stateLoaded

    // ── Private helpers ──────────────────────────────────────────────

    function _bump() {
        root.revision++
        root.stateLoaded()
    }

    function _debouncedWrite() {
        writeTimer.restart()
    }

    /* Parse JSON safely. Returns null on failure. */
    function _parseJson(text) {
        try {
            return JSON.parse(text)
        } catch (e) {
            return null
        }
    }

    /* Get value at dot-notation path from an object.
     * e.g. _getPath(obj, "bar.height") → obj.bar.height
     */
    function _getPath(obj, path) {
        if (!obj || typeof obj !== "object") return undefined
        var keys = path.split(".")
        var cur = obj
        for (var i = 0; i < keys.length; i++) {
            if (cur === undefined || cur === null) return undefined
            cur = cur[keys[i]]
        }
        return cur
    }

    /* Set value at dot-notation path on an object.
     * Creates intermediate objects as needed.
     */
    function _setPath(obj, path, value) {
        if (!obj || typeof obj !== "object") return
        var keys = path.split(".")
        var cur = obj
        for (var i = 0; i < keys.length - 1; i++) {
            if (typeof cur[keys[i]] !== "object" || cur[keys[i]] === null) {
                cur[keys[i]] = {}
            }
            cur = cur[keys[i]]
        }
        cur[keys[keys.length - 1]] = value
    }

    /* Delete key at dot-notation path from an object.
     * Removes intermediate empty objects too.
     */
    function _delPath(obj, path) {
        if (!obj || typeof obj !== "object") return
        var keys = path.split(".")
        var cur = obj
        for (var i = 0; i < keys.length - 1; i++) {
            if (!cur || typeof cur[keys[i]] !== "object") return
            cur = cur[keys[i]]
        }
        if (cur) {
            delete cur[keys[keys.length - 1]]
        }
    }
}
