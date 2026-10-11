pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.services

/*
 * DashboardCanvas — main widget canvas.
 *
 * A Flickable surface that positions dashboard widgets at absolute (x, y)
 * coordinates. Supports config mode for repositioning and adding/removing widgets.
 */
Item {
    id: root

    /* Bound from Dashboard.qml / parent scope */
    property bool configMode: false

    /* Currently selected widget entry object (or null) */
    property var selectedWidget: null

    // ── Background ─────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colBackgroundSurfaceContainer
        radius: Appearance.rounding.large
    }

    // ── Scrollable canvas ─────────────────────────────────────────

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 16

        /* Content size grows with widget extents */
        contentWidth:  Math.max(_canvasWidth,  root.width  - 32)
        contentHeight: Math.max(_canvasHeight, root.height - 32)

        interactive: contentHeight > height || contentWidth > width
        clip: true

        /* Track the bounding box of all widgets */
        readonly property real _canvasWidth: {
            var maxX = 0
            var list = StateService.get("dashboard.widgets", [])
            for (var i = 0; i < list.length; i++) {
                var w = list[i]
                maxX = Math.max(maxX, (w.x || 0) + (w.width || 280))
            }
            return maxX
        }

        readonly property real _canvasHeight: {
            var maxY = 0
            var list = StateService.get("dashboard.widgets", [])
            for (var i = 0; i < list.length; i++) {
                var w = list[i]
                maxY = Math.max(maxY, (w.y || 0) + (w.height || 180))
            }
            return maxY
        }

        // Anchor the widget layer at top-left so positions are absolute
        Item {
            id: widgetLayer
            x: 0
            y: 0
            width:  flick.contentWidth
            height: flick.contentHeight

            WidgetLoader {
                id: widgetLoader
                anchors.fill: parent
                configMode: root.configMode
                selectedWidget: root.selectedWidget

                onSelectedWidgetChanged: {
                    root.selectedWidget = selectedWidget
                }
            }
        }
    }

    // ── Config overlay ─────────────────────────────────────────────

    DashboardConfigOverlay {
        id: configOverlay
        anchors.fill: parent
        configMode: root.configMode
        selectedWidget: root.selectedWidget

        onSelectedWidgetChanged: {
            root.selectedWidget = selectedWidget
        }
    }
}
