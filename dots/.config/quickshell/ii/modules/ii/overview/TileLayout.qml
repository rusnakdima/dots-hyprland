pragma ComponentBehavior: Bound
import qs
import qs.modules.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

/**
 * TileLayout - Window tiling widget for the overview
 *
 * Provides preset tiling layouts:
 * - Half: 2 windows side by side (left/right)
 * - Thirds: 3 windows (2 stacked on left, 1 on right)
 * - Quad: 4 windows in a 2x2 grid
 *
 * Usage:
 *   TileLayout {
 *       screen: panelWindow.screen
 *       active: GlobalStates.overviewOpen && tileModeActive
 *   }
 */
Item {
    id: root

    property var screen
    property bool active: false
    property var monitor: Hyprland.monitorFor(screen)
    property var monitorData: HyprlandData.monitors.find(m => m.id === monitor?.id)
    property string currentLayout: "half" // "half", "thirds", "quad"
    property var layoutOrder: ["half", "thirds", "quad"]
    property int layoutIndex: 0
    property real padding: 10
    property bool tileModeActive: false

    // Monitor geometry
    property real monitorWidth: {
        if (!monitorData) return screen?.width ?? 1920;
        const t = monitorData.transform & 1;
        return (t ? monitorData.height : monitorData.width) - monitorData.reserved[0] - monitorData.reserved[2];
    }
    property real monitorHeight: {
        if (!monitorData) return screen?.height ?? 1080;
        const t = monitorData.transform & 1;
        return (t ? monitorData.width : monitorData.height) - monitorData.reserved[1] - monitorData.reserved[3];
    }

    // Current workspace windows (excluding special workspaces, floating, fullscreen)
    property var workspaceWindows: {
        const ws = HyprlandData.activeWorkspace;
        if (!ws) return [];
        return HyprlandData.windowList.filter(w =>
            w.workspace?.id === ws.id && !w.floating && !w.fullscreen
        );
    }

    property int maxTilesForLayout: {
        switch (currentLayout) {
            case "half": return 2;
            case "thirds": return 3;
            case "quad": return 4;
            default: return 2;
        }
    }

    // Tile dimensions based on layout
    property real tileWidth: {
        switch (currentLayout) {
            case "half":
                return (monitorWidth - padding * 3) / 2;
            case "thirds":
            case "quad":
                return (monitorWidth - padding * 3) / 2;
            default:
                return (monitorWidth - padding * 3) / 2;
        }
    }
    property real tileHeight: {
        switch (currentLayout) {
            case "half":
                return monitorHeight - padding * 2;
            case "thirds":
                return (monitorHeight - padding * 3) / 2;
            case "quad":
                return (monitorHeight - padding * 3) / 2;
            default:
                return monitorHeight - padding * 2;
        }
    }

    implicitWidth: monitorWidth + padding * 2
    implicitHeight: monitorHeight + padding * 2

    visible: active && tileModeActive

    /**
     * Calculate position for a tile at given index
     */
    function getTileGeometry(index, layout, winCount) {
        const maxTiles = maxTilesForLayout;
        const count = Math.min(winCount, maxTiles);
        const gap = padding;

        switch (layout) {
            case "half":
                if (count === 1) {
                    return { x: gap, y: gap, width: monitorWidth - gap * 2, height: monitorHeight - gap * 2 };
                }
                if (index === 0) {
                    return { x: gap, y: gap, width: tileWidth, height: monitorHeight - gap * 2 };
                } else {
                    return { x: tileWidth + gap * 2, y: gap, width: tileWidth, height: monitorHeight - gap * 2 };
                }

            case "thirds":
                if (count === 1) {
                    return { x: gap, y: gap, width: monitorWidth - gap * 2, height: monitorHeight - gap * 2 };
                } else if (count === 2) {
                    if (index === 0) {
                        return { x: gap, y: gap, width: tileWidth, height: monitorHeight - gap * 2 };
                    } else {
                        return { x: tileWidth + gap * 2, y: gap, width: tileWidth, height: monitorHeight - gap * 2 };
                    }
                } else {
                    // 3 windows: 2 stacked left, 1 right
                    if (index === 0) {
                        return { x: gap, y: gap, width: tileWidth, height: tileHeight };
                    } else if (index === 1) {
                        return { x: gap, y: tileHeight + gap * 2, width: tileWidth, height: tileHeight };
                    } else {
                        return { x: tileWidth + gap * 2, y: gap, width: tileWidth, height: monitorHeight - gap * 2 };
                    }
                }

            case "quad":
                if (count === 1) {
                    return { x: gap, y: gap, width: monitorWidth - gap * 2, height: monitorHeight - gap * 2 };
                } else if (count === 2) {
                    if (index === 0) {
                        return { x: gap, y: gap, width: monitorWidth - gap * 2, height: (monitorHeight - gap * 3) / 2 };
                    } else {
                        return { x: gap, y: (monitorHeight - gap * 3) / 2 + gap * 2, width: monitorWidth - gap * 2, height: (monitorHeight - gap * 3) / 2 };
                    }
                } else {
                    // 2x2 grid
                    const col = index % 2;
                    const row = Math.floor(index / 2);
                    return {
                        x: gap + col * (tileWidth + gap),
                        y: gap + row * (tileHeight + gap),
                        width: tileWidth,
                        height: tileHeight
                    };
                }

            default:
                return { x: gap, y: gap, width: monitorWidth - gap * 2, height: monitorHeight - gap * 2 };
        }
    }

    /**
     * Apply a specific layout
     */
    function applyLayout(layout: string) {
        currentLayout = layout;
        layoutIndex = layoutOrder.indexOf(layout);
        applyTiling();
    }

    /**
     * Cycle to next layout
     */
    function cycleLayout() {
        layoutIndex = (layoutIndex + 1) % layoutOrder.length;
        currentLayout = layoutOrder[layoutIndex];
        applyTiling();
    }

    /**
     * Apply current tiling layout to windows
     */
    function applyTiling() {
        if (!active) return;

        const windows = workspaceWindows.slice(0, maxTilesForLayout);
        windows.forEach((window, index) => {
            if (!window?.address) return;

            const geom = getTileGeometry(index, currentLayout, windows.length);
            const percentX = geom.x;
            const percentY = geom.y;
            const percentW = geom.width;
            const percentH = geom.height;

            // Dispatch tile commands for each window
            Hyprland.dispatch(
                `hl.dsp.window.move({ x = "${Math.round(percentX)}", y = "${Math.round(percentY)}", window = "address:${window.address}" }); ` +
                `hl.dsp.window.resize({ width = "${Math.round(percentW)}", height = "${Math.round(percentH)}", window = "address:${window.address}" })`
            );
        });
    }

    /**
     * Tile active window with another window
     */
    function tileActiveWith(targetAddress: string) {
        const activeWin = WindowHistory.getMRU(false);
        if (!activeWin?.address || !targetAddress) return;

        const wsWindows = workspaceWindows;
        const count = Math.min(wsWindows.length, maxTilesForLayout);
        if (count < 2) return;

        // Find target window index
        const targetIndex = wsWindows.findIndex(w => w.address === targetAddress);
        const activeIndex = wsWindows.findIndex(w => w.address === activeWin.address);

        // Swap positions or place active next to target
        if (targetIndex >= 0 && activeIndex >= 0) {
            const targetGeom = getTileGeometry(targetIndex, currentLayout, count);

            // Move active window to target's position
            Hyprland.dispatch(
                `hl.dsp.window.move({ x = "${Math.round(targetGeom.x)}", y = "${Math.round(targetGeom.y)}", window = "address:${activeWin.address}" }); ` +
                `hl.dsp.window.resize({ width = "${Math.round(targetGeom.width)}", height = "${Math.round(targetGeom.height)}", window = "address:${activeWin.address}" })`
            );
        }
    }

    /**
     * Enter tile mode - show tiling controls
     */
    function enterTileMode() {
        tileModeActive = true;
        applyTiling();
    }

    /**
     * Exit tile mode
     */
    function exitTileMode() {
        tileModeActive = false;
    }

    /**
     * Toggle tile mode
     */
    function toggleTileMode() {
        if (tileModeActive) {
            exitTileMode();
        } else {
            enterTileMode();
        }
    }

    // Layout indicator overlay
    Rectangle {
        id: tileOverlay
        anchors.fill: parent
        color: "transparent"
        visible: root.tileModeActive

        // Layout selector at top-right
        Row {
            anchors {
                top: parent.top
                right: parent.right
                margins: root.padding
            }
            spacing: 8

            TileLayoutButton {
                label: "½"
                tooltip: "Half split"
                active: root.currentLayout === "half"
                onClicked: root.applyLayout("half")
            }
            TileLayoutButton {
                label: "⅓"
                tooltip: "Thirds"
                active: root.currentLayout === "thirds"
                onClicked: root.applyLayout("thirds")
            }
            TileLayoutButton {
                label: "⊞"
                tooltip: "Quad"
                active: root.currentLayout === "quad"
                onClicked: root.applyLayout("quad")
            }
            TileLayoutButton {
                label: "⟳"
                tooltip: "Cycle layout"
                active: false
                onClicked: root.cycleLayout()
            }
        }

        // Tile indicators
        Repeater {
            model: Math.min(workspaceWindows.length, maxTilesForLayout)

            Rectangle {
                required property int index
                property var window: workspaceWindows[index]
                property var geom: root.getTileGeometry(index, root.currentLayout, Math.min(workspaceWindows.length, maxTilesForLayout))

                x: geom.x + root.padding
                y: geom.y + root.padding
                width: geom.width
                height: geom.height
                color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHigh, 0.6)
                border.width: 2
                border.color: Appearance.colors.colOutline
                radius: Appearance.rounding.medium

                // Window class label
                StyledText {
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: 6
                    }
                    text: window?.class || "Window"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // Click to focus
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (window?.address) {
                            Hyprland.dispatch(`hl.dsp.focus({window = "address:${window.address}"})`);
                        }
                    }
                    onPressed: (mouse) => {
                        if (mouse.modifiers & Qt.AltModifier) {
                            // Alt+Click: tile active window to this position
                            root.tileActiveWith(window.address);
                        }
                    }
                }
            }
        }
    }

    /**
     * Focus next tile
     */
    function focusNextTile() {
        const count = Math.min(workspaceWindows.length, maxTilesForLayout);
        if (count < 2) return;

        const currentIdx = workspaceWindows.findIndex(w => w.address === WindowHistory.currentWindow?.address);
        const nextIdx = (currentIdx + 1) % count;
        const nextWindow = workspaceWindows[nextIdx];
        if (nextWindow?.address) {
            WindowHistory.switchToWindow(nextWindow.address);
        }
    }

    /**
     * Focus previous tile
     */
    function focusPreviousTile() {
        const count = Math.min(workspaceWindows.length, maxTilesForLayout);
        if (count < 2) return;

        const currentIdx = workspaceWindows.findIndex(w => w.address === WindowHistory.currentWindow?.address);
        const prevIdx = (currentIdx - 1 + count) % count;
        const prevWindow = workspaceWindows[prevIdx];
        if (prevWindow?.address) {
            WindowHistory.switchToWindow(prevWindow.address);
        }
    }
}

// Tile layout button component
component TileLayoutButton: Rectangle {
    property string label: ""
    property string tooltip: ""
    property bool active: false
    signal clicked()

    width: 36
    height: 36
    color: active ?
        ColorUtils.transparentize(Appearance.colors.colPrimary, 0.25) :
        ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHigh, 0.7)
    border.width: active ? 2 : 1
    border.color: active ? Appearance.colors.colPrimary : Appearance.colors.colOutline
    radius: Appearance.rounding.small

    StyledText {
        anchors.centerIn: parent
        text: label
        font.pixelSize: Appearance.font.pixelSize.body
        color: active ? Appearance.colors.colPrimary : Appearance.colors.colOnSurface
        horizontalAlignment: Text.AlignHCenter
    }

    StyledToolTip {
        text: tooltip
    }

    MouseArea {
        anchors.fill: parent
        onClicked: clicked()
    }
}
