import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Overview — workspace overview panel.
 * Stub implementation when Hyprland IPC is disabled (HYPRLAND_IPC=OFF).
 * Shows but is non-functional.
 */
Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false

    PanelWindow {
        id: panelWindow
        property string searchingText: ""
        property var monitor: null
        property bool monitorIsFocused: false
        visible: GlobalStates.overviewOpen

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.overviewOpen ? columnLayout : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    searchWidget.disableExpandAnimation();
                    overviewScope.dontAutoCancelSearch = false;
                    GlobalFocusGrab.dismiss();
                } else {
                    if (!overviewScope.dontAutoCancelSearch) {
                        searchWidget.cancelSearch();
                    }
                    GlobalFocusGrab.addDismissable(panelWindow);
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.overviewOpen = false;
            }
        }
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        function setSearchingText(text) {
            searchWidget.setSearchingText(text);
            searchWidget.focusFirstItem();
        }

        Column {
            id: columnLayout
            visible: GlobalStates.overviewOpen
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            spacing: -8

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.overviewOpen = false;
                }
            }

            SearchWidget {
                id: searchWidget
                anchors.horizontalCenter: parent.horizontalCenter
                Synchronizer on searchingText {
                    property alias source: panelWindow.searchingText
                }
            }

            Loader {
                id: overviewLoader
                anchors.horizontalCenter: parent.horizontalCenter
                active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true)
                sourceComponent: OverviewWidget {
                    screen: panelWindow.screen
                    visible: (panelWindow.searchingText == "")
                }
            }

            // TileLayout disabled: TileLayout.qml has QML syntax error in committed repo (head 470f03e8)
            // TileLayout block removed to allow shell to load
            // TODO: re-enable when TileLayout.qml is fixed upstream
        }
    }

    // Tile mode state (disabled - depends on broken TileLayout.qml)
    // property bool tileModeActive: false

    // IPC handlers for tiling (disabled - depends on broken TileLayout.qml)
    // IpcHandler {
    //     target: "tile"
    //     function toggle() { overviewScope.tileModeActive = !overviewScope.tileModeActive; }
    //     function enable() { overviewScope.tileModeActive = true; }
    //     function disable() { overviewScope.tileModeActive = false; }
    //     function cycleLayout() { if (!overviewScope.tileModeActive) overviewScope.tileModeActive = true; tileLayout.cycleLayout(); }
    //     function setLayout(layout) { if (!overviewScope.tileModeActive) overviewScope.tileModeActive = true; tileLayout.applyLayout(layout); }
    // }

    // Connections {
    //     target: WindowHistory
    //     ...
    // }

    property var altTabMRUList: []
    property int altTabIndex: 0

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.clipboard);
        GlobalStates.overviewOpen = true;
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.emojis);
        GlobalStates.overviewOpen = true;
    }

    IpcHandler {
        target: "search"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function workspacesToggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"

        onPressed: {
            GlobalStates.overviewOpen = false;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis();
        }
    }

    // Window tiling shortcuts
    GlobalShortcut {
        name: "tileLayoutToggle"
        description: "Toggle tile layout mode"

        onPressed: {
            overviewScope.tileModeActive = !overviewScope.tileModeActive;
            if (overviewScope.tileModeActive) {
                tileLayout.applyTiling();
            }
        }
    }

    GlobalShortcut {
        name: "tileLayoutCycle"
        description: "Cycle through tile layouts"

        onPressed: {
            if (!overviewScope.tileModeActive) {
                overviewScope.tileModeActive = true;
            }
            tileLayout.cycleLayout();
        }
    }

    GlobalShortcut {
        name: "tileFocusNext"
        description: "Focus next tiled window"

        onPressed: {
            if (!overviewScope.tileModeActive) return;
            tileLayout.focusNextTile();
        }
    }

    GlobalShortcut {
        name: "tileFocusPrev"
        description: "Focus previous tiled window"

        onPressed: {
            if (!overviewScope.tileModeActive) return;
            tileLayout.focusPreviousTile();
        }
    }

    // Alt+Tab MRU switching
    GlobalShortcut {
        name: "windowMRU"
        description: "Alt+Tab window switching (MRU order)"

        onPressed: {
            if (!overviewScope.altTabActive) {
                // Initialize MRU list
                overviewScope.altTabMRUList = WindowHistory.getMRUList(10);
                overviewScope.altTabIndex = 0;
                overviewScope.altTabActive = true;
            }
            // Move to next window
            overviewScope.altTabIndex = (overviewScope.altTabIndex + 1) % Math.max(1, overviewScope.altTabMRUList.length);
            const win = overviewScope.altTabMRUList[overviewScope.altTabIndex];
            if (win?.address) {
                WindowHistory.switchToWindow(win.address);
            }
        }

        onReleased: {
            overviewScope.altTabActive = false;
        }
    }

    GlobalShortcut {
        name: "windowMRUReverse"
        description: "Alt+Shift+Tab window switching (reverse MRU order)"

        onPressed: {
            if (!overviewScope.altTabActive) {
                overviewScope.altTabMRUList = WindowHistory.getMRUList(10);
                overviewScope.altTabIndex = overviewScope.altTabMRUList.length - 1;
                overviewScope.altTabActive = true;
            }
            overviewScope.altTabIndex = Math.max(0, overviewScope.altTabIndex - 1);
            const win = overviewScope.altTabMRUList[overviewScope.altTabIndex];
            if (win?.address) {
                WindowHistory.switchToWindow(win.address);
            }
        }

        onReleased: {
            overviewScope.altTabActive = false;
        }
    }
}
