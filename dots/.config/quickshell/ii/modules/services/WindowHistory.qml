pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

/**
 * Tracks window focus history for Alt+Tab style switching.
 * Maintains MRU (most recently used) ordering.
 */
Singleton {
    id: root

    property var history: []
    property int maxHistorySize: 20
    property var currentWindow: null
    property bool enabled: true

    // Window history for MRU switching
    property var windowHistory: []
    property var windowHistoryAddresses: []

    /**
     * Record a window as recently focused.
     * Moves window to front of MRU list.
     */
    function recordWindowFocus(window) {
        if (!window || !enabled) return;

        const address = window.address;
        if (!address) return;

        // Remove if already exists
        const existingIndex = root.windowHistoryAddresses.indexOf(address);
        if (existingIndex !== -1) {
            root.windowHistory.splice(existingIndex, 1);
            root.windowHistoryAddresses.splice(existingIndex, 1);
        }

        // Add to front
        root.windowHistory.unshift(window);
        root.windowHistoryAddresses.unshift(address);

        // Trim to max size
        while (root.windowHistory.length > root.maxHistorySize) {
            root.windowHistory.pop();
            root.windowHistoryAddresses.pop();
        }

        root.currentWindow = window;
    }

    /**
     * Get the most recently used window that is not the current one.
     */
    function getMRU(excludeCurrent) {
        if (excludeCurrent === undefined) excludeCurrent = true;
        if (excludeCurrent && root.windowHistory.length > 1) {
            return root.windowHistory[1];
        }
        return root.windowHistory[0] || null;
    }

    /**
     * Get list of windows in MRU order for Alt+Tab UI.
     */
    function getMRUList(maxItems) {
        if (maxItems === undefined) maxItems = 10;
        return root.windowHistory.slice(0, maxItems);
    }

    /**
     * Switch to a specific window by address.
     */
    function switchToWindow(address) {
        if (!address) return;
        Hyprland.dispatch(`hl.dsp.focus({window = "address:${address}"})`);
    }

    /**
     * Switch to next in MRU list (Alt+Tab behavior).
     */
    function switchToNext() {
        const next = getMRU(true);
        if (next) {
            switchToWindow(next.address);
        }
    }

    /**
     * Switch to previous in MRU list (Alt+Shift+Tab behavior).
     */
    function switchToPrevious() {
        if (root.windowHistory.length < 2) return;
        // Previous = second item when current is first
        const prev = root.windowHistory[1] || root.windowHistory[0];
        if (prev) {
            switchToWindow(prev.address);
        }
    }

    /**
     * Clear history.
     */
    function clearHistory() {
        root.windowHistory = [];
        root.windowHistoryAddresses = [];
        root.currentWindow = null;
    }

    /**
     * Remove a window from history (e.g., when closed).
     */
    function removeWindow(address) {
        const index = root.windowHistoryAddresses.indexOf(address);
        if (index !== -1) {
            root.windowHistory.splice(index, 1);
            root.windowHistoryAddresses.splice(index, 1);
        }
    }

    // Listen for window focus changes via HyprlandData
    Connections {
        target: HyprlandData

        function onWindowListChanged() {
            // Sync: remove closed windows from history
            const currentAddresses = HyprlandData.addresses;
            for (let i = root.windowHistoryAddresses.length - 1; i >= 0; i--) {
                if (!currentAddresses.includes(root.windowHistoryAddresses[i])) {
                    root.windowHistory.splice(i, 1);
                    root.windowHistoryAddresses.splice(i, 1);
                }
            }
        }
    }
}
