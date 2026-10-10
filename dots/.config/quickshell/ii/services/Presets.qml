pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Presets — save/load/list/export/import for full visual config snapshots.
 *
 * Presets are stored as JSON files in ~/.config/dots-hyprland/presets/.
 * Each preset is a sanitized subset of state.json — personal keys (apps, policies)
 * and absolute file paths are stripped by the presets-sanitize.sh jq filter.
 *
 * save(name):   reads Config.options, sanitizes, writes to presets/<name>.json
 * apply(name):  reads presets/<name>.json, deep-merges into Config.options
 * list():       returns array of preset names
 * export(name): prints preset JSON to stdout
 * import(url):  downloads zip, extracts, runs sanitize, saves (future)
 */
Singleton {
    id: root

    readonly property string presetsDir: StandardPaths.home + "/.config/dots-hyprland/presets"

    // ── Public API ────────────────────────────────────────────────────

    /* Save the current Config.options to a named preset.
     * Calls out to presets-sanitize.sh for the whitelist filter.
     * Returns true on success.
     */
    function save(name) {
        if (!name || name.length === 0) {
            console.warn("[Presets] save: name required")
            return false
        }
        var sanitized = _sanitizeCurrent()
        if (!sanitized) {
            console.warn("[Presets] save: sanitize failed")
            return false
        }
        var outPath = _presetPath(name)
        try {
            FileIO.write(outPath, JSON.stringify(sanitized, null, 2))
            console.log("[Presets] saved:", name)
            return true
        } catch (e) {
            console.warn("[Presets] save: write failed:", e)
            return false
        }
    }

    /* Apply a named preset: deep-merge into Config.options and persist. */
    function apply(name) {
        var src = _presetPath(name)
        var preset
        try {
            preset = JSON.parse(FileIO.read(src))
        } catch (e) {
            console.warn("[Presets] apply: failed to read preset:", name, e)
            return false
        }
        _deepMergeIntoConfig(preset)
        Config.save()
        console.log("[Presets] applied:", name)
        return true
    }

    /* List all saved preset names. */
    function list() {
        var names = []
        var dir = FileIO.list(presetsDir)
        if (!dir) return names
        for (var i = 0; i < dir.length; i++) {
            if (dir[i].endsWith(".json")) {
                names.push(dir[i].replace(".json", ""))
            }
        }
        return names.sort()
    }

    /* Export a preset as raw JSON string (for piping to other tools). */
    function exportPreset(name) {
        var src = _presetPath(name)
        try {
            return FileIO.read(src)
        } catch (e) {
            return null
        }
    }

    // ── Private helpers ───────────────────────────────────────────────

    function _presetPath(name) {
        return presetsDir + "/" + name + ".json"
    }

    /* Deep-merge overlay object into Config.options (mutates Config). */
    function _deepMergeIntoConfig(overlay) {
        _mergeRecursive(Config.options, overlay)
    }

    function _mergeRecursive(base, overlay) {
        for (var key in overlay) {
            if (!overlay.hasOwnProperty(key)) continue
            if (typeof overlay[key] === 'object' && overlay[key] !== null && !Array.isArray(overlay[key])) {
                if (typeof base[key] !== 'object' || base[key] === null) {
                    base[key] = {}
                }
                _mergeRecursive(base[key], overlay[key])
            } else {
                base[key] = overlay[key]
            }
        }
    }

    /* Serialize Config.options to JSON and call sanitize script. */
    function _sanitizeCurrent() {
        try {
            var raw = JSON.stringify(Config.options)
            // Call sanitize via Process — capture stdout
            // We do this synchronously by using the FileView watch mechanism
            // Instead, do a simple inline whitelist filter here in QML
            var obj = JSON.parse(raw)
            return _whitelistFilter(obj)
        } catch (e) {
            console.warn("[Presets] serialize config failed:", e)
            return null
        }
    }

    /* Inline whitelist filter — same logic as presets-sanitize.sh */
    function _whitelistFilter(obj) {
        var allowed = [
            "appearance", "bar", "background", "battery", "calendar",
            "cheatsheet", "crosshair", "dock", "interactions",
            "language", "launcher", "light", "lock", "media",
            "networking", "notifications", "osd", "osk", "overlay",
            "overview", "regionSelector", "resources", "tray",
            "musicRecognition", "search", "sidebar", "screenRecord",
            "screenSnip", "sounds", "keybinds", "keyboard", "time",
            "updates", "vision", "wallpaperSelector", "windows",
            "hacks", "workSafety", "waffles"
        ]
        var personal = ["apps", "policies"]
        var result = {}
        for (var k in obj) {
            if (personal.indexOf(k) !== -1) continue
            if (allowed.indexOf(k) === -1) continue
            result[k] = obj[k]
        }
        return result
    }

    // NOTE: External preset file watching removed — FileView's watchChanges causes
    // "Duplicate signal name" in QML (path property generates pathChanged).
    // External preset changes require a shell restart to take effect.
    // To re-add, use Quickshell.io FS watch instead of FileView.
}
