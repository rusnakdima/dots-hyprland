pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

/*
 * Workspaces — bar component showing workspace buttons for the current monitor.
 *
 * Reads workspace state from WorkspacesService singleton.
 * Each workspace in the monitor's block is rendered as a button.
 * Workspaces from other blocks ("guests") are rendered differently (dimmed).
 *
 * Usage in a bar:
 *   Workspaces { id: wsComponent; anchors.fill: parent }
 */
Item {
    id: root

    /* The screen this workspace bar belongs to. Set by the parent bar. */
    property var parentScreen: null

    /* Monitor object for this screen. */
    property var monitor: parentScreen ? Hyprland.monitorFor(parentScreen) : null

    /* Monitor name string. */
    readonly property string monitorName: monitor?.name ?? ""

    /* Base workspace ID for this monitor's block. */
    property int base: WorkspacesService.baseFor(monitorName)

    /* All workspaces that belong to this monitor's block. */
    property var filled: WorkspacesService.filledFor(monitorName)

    /* Workspaces that belong to other monitor blocks (shown dimmed). */
    property var guests: Hyprland.workspaces.values.filter(w => !WorkspacesService.inBlock(w.id, root.monitorName))

    /* Number of visible workspace slots to render (1..base+9). */
    readonly property int slotCount: maxWs - minWs + 1
    readonly property int minWs: base > 0 ? base + 1 : 1
    readonly property int maxWs: base > 0 ? base + 9 : 9

    /* Compute which workspace IDs are active on this monitor.
     * Hyprland.workspaces is a Map<workspaceId, workspaceObject>.
     * Filter to those whose monitor property matches our monitorName. */
    function workspacesOnThisMonitor() {
        if (!monitorName) return []
        return Hyprland.workspaces.values.filter(w =>
            (w.monitor === monitorName) &&
            (w.id >= (base > 0 ? base : 0)) &&
            (base <= 0 || w.id < base + WorkspacesService.blockSize)
        )
    }

    /* Workspace IDs currently active on this monitor. */
    property var activeIds: {
        var ids = []
        var list = workspacesOnThisMonitor()
        for (var i = 0; i < list.length; i++) {
            ids.push(list[i].id)
        }
        return ids
    }

    /* Switch to a workspace. */
    function switchTo(wsId) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsId)])
    }

    /* Move focused window to a workspace. */
    function moveTo(wsId) {
        Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", String(wsId)])
    }

    /* Row of workspace buttons. */
    Row {
        id: wsRow
        anchors.fill: root
        spacing: 4

        // Render slots 1..9 of the current block
        // plus any "guest" workspaces from other blocks
        Repeater {
            model: slotCount
            delegate: wsButton
        }
    }

    component wsButton: Item {
        id: btn
        property int wsId: root.base > 0 ? root.base + index + 1 : index + 1
        property bool isActive: root.activeIds.indexOf(wsId) !== -1
        property bool isOccupied: root.filled.indexOf(wsId) !== -1

        width: 28
        height: root.height

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 4
            color: btn.isActive
                ? (Appearance?.colors?.colPrimary ?? "#7c6faf")
                : btn.isOccupied
                    ? (Appearance?.colors?.colSurfaceContainer ?? "#3a3a4a")
                    : "transparent"
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        Text {
            anchors.centerIn: parent
            text: btn.wsId % 10  // show 1-9 for display, full ID internally
            color: btn.isActive
                ? (Appearance?.colors?.colOnPrimary ?? "#ffffff")
                : (Appearance?.colors?.colOnSurface ?? "#c0caf5")
            font.pixelSize: 13
            font.weight: btn.isActive ? Font.Bold : Font.Normal
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                if (mouse.button === Qt.RightButton) {
                    moveTo(btn.wsId)
                } else {
                    switchTo(btn.wsId)
                }
            }
        }
    }

    /* Guest workspaces from other blocks (dimmed). */
    Row {
        id: guestRow
        anchors.left: wsRow.right
        anchors.leftMargin: 8
        spacing: 4
        height: root.height

        Repeater {
            model: root.guests.length
            delegate: guestButton
        }
    }

    component guestButton: Item {
        id: gbtn
        property var ws: root.guests[index]
        property int wsId: ws?.id ?? -1

        width: 22
        height: root.height

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: "transparent"
            border.width: 1
            border.color: Appearance?.colors?.colOutline ?? "#5a5a6a"
            opacity: 0.5
        }

        Text {
            anchors.centerIn: parent
            text: gbtn.wsId
            color: Appearance?.colors?.colOnSurface ?? "#888899"
            font.pixelSize: 11
            opacity: 0.5
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: switchTo(gbtn.wsId)
        }
    }
}
