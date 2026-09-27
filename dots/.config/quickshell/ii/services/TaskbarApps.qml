pragma Singleton

import qs.modules.common
import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    function isPinned(appId) {
        return Config.options.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    property list<var> apps: {
        var map = new Map();

        // Pinned apps
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Ignored apps
        const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        // Open windows
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                pinned: false,
                toplevels: []
            }));
            map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
        }

        var values = [];

        for (const [key, value] of map) {
            values.push(appEntryComp.createObject(null, { appId: key, toplevels: value.toplevels, pinned: value.pinned }));
        }

        return values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }

    // ─── Debounced titles ───
    // kitty emits many rapid title-change events when windows open/close,
    // creating a subscription storm. Coalesce them so consumers are notified
    // once per debounce window via `debouncedTitles` / `titlesChanged`.

    /** Map of appId → debounced title */
    property var debouncedTitles: ({})

    /** Internal: pending titles keyed by appId */
    property var _pendingTitles: ({})

    /** Debounce window for kitty title storms, in ms */
    readonly property int _titleDebounceMs: 200

    /** Emitted after a kitty title debounce settles */
    signal titlesChanged

    Timer {
        id: titleDebounceTimer
        interval: root._titleDebounceMs
        repeat: false
        onTriggered: root._commitPendingTitles()
    }

    Instantiator {
        model: ToplevelManager.toplevels

        delegate: Connections {
            required property var modelData
            target: modelData

            Component.onCompleted: root._primeDebouncedTitle(modelData)
            Component.onDestruction: root._forgetToplevel(modelData)

            function onTitleChanged() {
                root._onTitleChange(modelData.appId, modelData.title)
            }
        }
    }

    function _primeDebouncedTitle(toplevel) {
        if (!toplevel || root.debouncedTitles[toplevel.appId] !== undefined) return
        const next = Object.assign({}, root.debouncedTitles)
        next[toplevel.appId] = toplevel.title
        root.debouncedTitles = next
    }

    function _forgetToplevel(toplevel) {
        if (!toplevel) return
        const appId = toplevel.appId
        // Another window of the same app may still be open — keep its title
        if (ToplevelManager.toplevels.values.some(t => t?.appId === appId)) return
        const next = Object.assign({}, root.debouncedTitles)
        delete next[appId]
        root.debouncedTitles = next
        delete root._pendingTitles[appId]
    }

    function _onTitleChange(appId, newTitle) {
        // Skip non-kitty apps — only debounce the noisy kitty title storm
        if (!appId.toLowerCase().includes("kitty")) return
        root._pendingTitles[appId] = newTitle
        titleDebounceTimer.restart()
    }

    function _commitPendingTitles() {
        const pending = root._pendingTitles
        if (Object.keys(pending).length === 0) return
        const next = Object.assign({}, root.debouncedTitles)
        for (const appId of Object.keys(pending)) {
            next[appId] = pending[appId]
        }
        root._pendingTitles = {}
        root.debouncedTitles = next
        root.titlesChanged()
    }
}
