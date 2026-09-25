/**
 * KittyTitleDebounce.qml — Debounce kitty title change events by 200 ms
 *
 * Quickshell TaskbarApps subscribes to toplevel title changes. kitty emits
 * many rapid title-change events when windows are opened/closed, creating a
 * subscription storm that causes visible UI lag. This override wraps the
 * ToplevelManager title observer with a 200 ms debounce timer so that rapid
 * events are coalesced before the UI is notified.
 *
 * Override seam: services/TaskbarApps/Overrides/KittyTitleDebounce.qml
 */

pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * Debounced title emitter for kitty toplevels.
 * Listen to `debouncedTitles` instead of reading titles directly from
 * ToplevelManager for kitty windows.
 */
QtObject {
    id: root

    /** Map of appId → debounced title string */
    property var debouncedTitles: ({})

    /** Internal: pending updates keyed by appId */
    property var _pending: ({})

    /** 200 ms debounce window */
    readonly property int debounceMs: 200

    /** Signal emitted after debounce settles */
    signal titlesChanged

    // Watch all toplevel additions / removals
    Connections {
        target: ToplevelManager

        function onToplevelAdded(toplevel) {
            // Prime debounced state
            if (!root.debouncedTitles[toplevel.appId]) {
                root.debouncedTitles[toplevel.appId] = toplevel.title
            }
            _watchTitle(toplevel)
        }

        function onToplevelRemoved(toplevel) {
            _cancelPending(toplevel.appId)
            delete root.debouncedTitles[toplevel.appId]
            delete root._pending[toplevel.appId]
        }
    }

    function _watchTitle(toplevel) {
        // Directly updating title is cheap; debounce only the UI-facing signal
        toplevel.titleChanged.connect(() => _onTitleChange(toplevel.appId, toplevel.title))
    }

    function _onTitleChange(appId, newTitle) {
        // Skip non-kitty apps — only debounce the noisy kitty title storm
        if (!appId.toLowerCase().includes("kitty")) return

        _cancelPending(appId)
        root._pending[appId] = newTitle

        // Fire single-shot timer: if no further changes within 200 ms,
        // commit the pending title to debouncedTitles and signal UI
        const timer = new QmlTimer(root)
        timer.interval = debounceMs
        timer.repeat = false
        timer.triggered.connect(() => {
            if (root._pending[appId] !== undefined) {
                root.debouncedTitles[appId] = root._pending[appId]
                delete root._pending[appId]
                root.titlesChanged()
            }
            timer.destroy()
        })
        timer.start()
    }

    function _cancelPending(appId) {
        // Cancelling is handled by the timer self-destructing on re-arm;
        // the map entry is overwritten by the next _onTitleChange call.
        delete root._pending[appId]
    }
}
