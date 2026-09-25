/**
 * IconOverflow.qml — fork-owned override for NotificationListView
 *
 * Patches the notification list's icon layout so that when many utility
 * icons (notifications) are displayed, they wrap to the next row instead
 * of overlapping.
 *
 * Override seam: modules/common/widgets/NotificationListView/Overrides/IconOverflow.qml
 * Survives setup update: yes (Overrides/ seam)
 */

pragma ComponentBehavior: Bound

import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

/**
 * FlowGrid replaces the flat ListView with a wrapping grid.
 * After MAX_ICONS_PER_ROW icons, the next icon wraps to a new row.
 */
Item {
    id: root

    /** Maximum icons before wrapping to next row */
    property int maxIconsPerRow: 4

    /** Spacing between items */
    property int spacing: 3

    property list<var> notifications: []

    // ── Flow layout ───────────────────────────────────────────────────────
    // Items are arranged left-to-right; when maxIconsPerRow is reached,
    // subsequent items move to the next "row".
    // We emulate a wrapping grid using a Column of Rows.

    property var rows: computeRows(notifications)

    function computeRows(items) {
        const result = []
        for (let i = 0; i < items.length; i += maxIconsPerRow) {
            result.push(items.slice(i, i + maxIconsPerRow))
        }
        return result
    }

    Column {
        anchors.fill: parent
        spacing: root.spacing

       Repeater {
            model: root.rows

            Row {
                spacing: root.spacing

                // Each row gets up to maxIconsPerRow notification groups
                Repeater {
                    model: modelData

                    delegate: NotificationGroup {
                        required property int index
                        required property var modelData
                        popup: root.popup
                        width: (root.width - (root.maxIconsPerRow - 1) * root.spacing) / root.maxIconsPerRow
                        notificationGroup: popup ?
                            Notifications.popupGroupsByAppName[modelData] :
                            Notifications.groupsByAppName[modelData]
                    }
                }
            }
        }
    }

    // ── Re-wire model changes ─────────────────────────────────────────────
    // NotificationListView passes the ScriptModel via the `values` property.
    // When the model changes, recompute rows.
    Binding {
        target: root
        property: "notifications"
        value: root.popup ? Notifications.popupAppNameList : Notifications.appNameList
        restoreType: Binding.RestoreNone
    }
}
