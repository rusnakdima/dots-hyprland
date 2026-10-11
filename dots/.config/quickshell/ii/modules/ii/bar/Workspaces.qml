pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common.widgets

/**
 * Workspaces — displays workspace buttons in the bar.
 *
 * Reads workspace state from HyprlandData (hyprctl polling, no HyprlandMonitor needed).
 * Works with HYPRLAND_IPC=OFF.
 *
 * Supports styles: "default" (numbered pills), "dots" (animated blob circles).
 * Styles "gnome" and "ticks" are stubbed (console.warn + fallback to "default").
 */
Item {
    id: root

    // --- Screen / monitor ---
    property var screen: root.QsWindow.window?.screen
    readonly property string monitorName: screen?.name ?? ""

    // --- Workspace state from HyprlandData ---
    readonly property int activeId: HyprlandData.activeWorkspace?.id ?? 1
    readonly property var occupied: HyprlandData.workspaces // array of workspace objects

    // --- Special workspace (from monitors list) ---
    // Uses QML binding expression referencing HyprlandData.monitors directly for reactivity
    readonly property bool specialActive: (HyprlandData.monitors.some
        ? HyprlandData.monitors.some(m => m.name === monitorName && !!m.specialWorkspace?.name)
        : false)
    readonly property string specialName: (() => {
        var found = HyprlandData.monitors.find
            ? HyprlandData.monitors.find(m => m.name === monitorName && !!m.specialWorkspace?.name)
            : null;
        return found?.specialWorkspace?.name?.replace("special:", "") ?? "";
    })()

    // --- Config ---
    readonly property int shown: Config.options?.bar?.workspaces?.shown ?? 10
    readonly property string style: Config.options?.bar?.workspaces?.style ?? "default"
    readonly property string indicatorStyle: Config.options?.bar?.workspaces?.indicatorStyle ?? "dot"
    readonly property bool alwaysShowNumbers: Config.options?.bar?.workspaces?.alwaysShowNumbers ?? false
    // indicatorStyle "dot" shows circles/dots; "icon" shows app icons (placeholder — falls back to dot)
    readonly property bool useIconIndicators: indicatorStyle === "icon"

    // --- Which style to render ---
    readonly property string effectiveStyle: {
        if (style === "gnome" || style === "ticks") {
            console.warn("[Workspaces] Style '" + style + "' not yet implemented, falling back to 'default'");
            return "default";
        }
        return style;
    }

    // --- Helpers ---
    function isOccupied(wsId) {
        return HyprlandData.workspaces.some(ws => ws.id === wsId);
    }

    function isActive(wsId) {
        return activeId === wsId;
    }

    // --- Hyprland dispatch helpers ---
    function dispatchWorkspace(wsId) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsId)]);
    }

    function moveToWorkspace(wsId) {
        Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", String(wsId)]);
    }

    // --- Layout ---
    RowLayout {
        anchors.fill: parent
        spacing: 4

        // Workspace buttons
        Row {
            id: wsRow
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                id: wsRepeater
                model: root.shown

                delegate: wsButton
            }
        }

        // Special workspace badge
        Loader {
            active: root.specialActive
            anchors.verticalCenter: parent.verticalCenter
            visible: active
            sourceComponent: specialBadge
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }
    }

    // ─── Button component ───────────────────────────────────────────────────

    component wsButton: Item {
        id: btn
        property int wsId: index + 1  // workspaces 1..shown

        width: 28
        height: root.height

        // The actual visual representation (switched per style)
        Loader {
            anchors.fill: parent
            sourceComponent: root.effectiveStyle === "dots" ? dotButton : defaultButton
        }

        // Default style: numbered pill
        component defaultButton: Item {
            Rectangle {
                id: pill
                anchors.fill: parent
                radius: 4
                color: btn.isActive
                    ? (Appearance?.colors?.colPrimary ?? "#7c6faf")
                    : btn.isOccupied
                        ? (Appearance?.colors?.colSurfaceContainer ?? "#3a3a4a")
                        : "transparent"
                border.width: btn.isOccupied && !btn.isActive ? 1 : 0
                border.color: Appearance?.colors?.colOutline ?? "#5a5a6a"

                Behavior on color {
                    ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }

            Text {
                anchors.centerIn: parent
                text: btn.wsId
                color: btn.isActive
                    ? (Appearance?.colors?.colOnPrimary ?? "#ffffff")
                    : btn.isOccupied
                        ? (Appearance?.colors?.colOnSurface ?? "#c0caf5")
                        : (Appearance?.colors?.colOnSurfaceVariant ?? "#6a6a7a")
                font.pixelSize: 12
                font.weight: btn.isActive ? Font.Bold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Dots style: circle + animated blob
        component dotButton: Item {
            // Blob layer: connects active to occupied
            Rectangle {
                id: blob
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                height: 8
                radius: 4
                color: Appearance?.colors?.colPrimary ?? "#7c6faf"
                opacity: (btn.isActive || btn.isOccupied) ? 0.4 : 0.0
                visible: opacity > 0 || btn.isActive || btn.isOccupied

                // Spread blob toward active dot
                x: {
                    if (btn.isActive) return 0;
                    // Find distance to active in row
                    var activeIndex = root.activeId - 1;
                    if (activeIndex < 0 || activeIndex >= root.shown) return 0;
                    var delta = btn.index - activeIndex;
                    var spread = Math.abs(delta) * 32; // 28 button + 4 spacing
                    return delta > 0 ? -spread : spread;
                }
                width: {
                    if (btn.isActive) return 12;
                    var activeIndex = root.activeId - 1;
                    if (activeIndex < 0 || activeIndex >= root.shown) return 12;
                    var delta = Math.abs(btn.index - activeIndex);
                    return 12 + delta * 32;
                }

                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on width { NumberAnimation { duration: 200 } }
                Behavior on x { NumberAnimation { duration: 200 } }
            }

            // Dot circle
            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: btn.isActive ? 14 : 8
                height: btn.isActive ? 14 : 8
                radius: width / 2
                color: btn.isActive
                    ? (Appearance?.colors?.colPrimary ?? "#7c6faf")
                    : btn.isOccupied
                        ? (Appearance?.colors?.colSecondary ?? "#6a6a8a")
                        : (Appearance?.colors?.colOutline ?? "#5a5a6a")

                Behavior on width { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // Click + hover handling
        MouseArea {
            id: btnMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                if (mouse.button === Qt.RightButton) {
                    root.moveToWorkspace(btn.wsId);
                } else {
                    root.dispatchWorkspace(btn.wsId);
                }
            }
        }

        // Hover tooltip (StyledToolTip checks parent.hovered, we use extraVisibleCondition with btnMouseArea.containsMouse)
        StyledToolTip {
            extraVisibleCondition: btnMouseArea.containsMouse
            text: "Workspace " + btn.wsId + (btn.isActive ? " (active)" : btn.isOccupied ? " (occupied)" : "")
        }

        // Derived helpers
        readonly property bool isActive: root.isActive(btn.wsId)
        readonly property bool isOccupied: root.isOccupied(btn.wsId)
    }

    // ─── Special workspace badge ────────────────────────────────────────────

    component specialBadge: Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: 20
            height: 14
            radius: 3
            color: Appearance?.colors?.colTertiary ?? "#8a6faf"
            Text {
                anchors.centerIn: parent
                text: root.specialName || "✦"
                color: Appearance?.colors?.colOnTertiary ?? "#ffffff"
                font.pixelSize: 10
            }
        }
    }

    // ─── Scroll navigation ──────────────────────────────────────────────────

    MouseArea {
        id: scrollArea
        anchors.fill: parent
        property int scrollCount: 0
        onWheel: {
            if (wheel.angleDelta.y > 0) {
                dispatchWorkspace(root.activeId - 1);
            } else {
                dispatchWorkspace(root.activeId + 1);
            }
        }
        cursorShape: Qt.PointingHandCursor
    }

    // ─── HyprlandData refresh wiring ────────────────────────────────────────

    Connections {
        target: HyprlandData
        function onWindowListChanged() { root.sync() }
    }

    // Force a re-evaluation when HyprlandData changes
    // (HyprlandData emits by updating its properties; we use Connections above)
    function sync() {
        // Trigger reactive recomputation by accessing properties
        // QML's property binding will handle the rest
    }

    // Initial sync
    Component.onCompleted: {
        HyprlandData.updateAll();
    }
}
