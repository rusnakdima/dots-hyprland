pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.services

/*
 * WidgetLoader — loads and positions dashboard widgets from StateService.
 *
 * Each widget entry has the shape:
 *   { type: string, x: number, y: number, width: number, height: number, config: object }
 *
 * type maps to a QML file under widgets/<Type>.qml
 * (e.g. "calendar" → "widgets/CalendarWidget.qml")
 *
 * configMode: when true, a delete button is shown on each widget.
 */
Item {
    id: root

    /* Bound from DashboardCanvas */
    property bool configMode: false
    property var selectedWidget: null

    /* The widget list from persistent state */
    property var widgets: StateService.get("dashboard.widgets", [])

    /* Maps type string → component file URL */
    function widgetUrl(type) {
        return Qt.resolvedUrl("widgets/" + type + ".qml")
    }

    /* List of known available widget types for the picker */
    readonly property var availableTypes: [
        "Calendar",
        "Notes",
        "WorldClock",
        "Visualizer",
        "Resources",
        "Timers",
        "CustomText",
        "Media",
        "System",
        "Weather"
    ]

    // ── Widget instances ───────────────────────────────────────────

    /* A positioned widget item backed by a Loader */
    component WidgetInstance: Item {
        id: inst

        required property var widgetEntry   // the raw object from state
        property int    index: 0

        property bool selected: root.selectedWidget === inst.widgetEntry

        x:      widgetEntry.x ?? 0
        y:      widgetEntry.y ?? 0
        width:  widgetEntry.width  ?? 280
        height: widgetEntry.height ?? 180

        // Loader defers until the URL is valid
        Loader {
            id: loader
            anchors.fill: parent
            active: !!root.widgetUrl(inst.widgetEntry.type)
            source: root.widgetUrl(inst.widgetEntry.type)
            asynchronous: true

            property var widgetConfig: inst.widgetEntry.config ?? {}

            onLoaded: {
                if (item) {
                    item.config = Qt.binding(function() { return loader.widgetConfig })
                }
            }
        }

        // Widget border when selected in config mode
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            visible: inst.selected && root.configMode
            color: "transparent"
            border.width: 2
            border.color: Appearance.colors.colPrimary
            radius: Appearance.rounding.large
            z: 10
        }

        // Click to select widget in config mode
        MouseArea {
            anchors.fill: parent
            enabled: root.configMode
            onClicked: root.selectedWidget = inst.widgetEntry
        }

        // Delete button (top-right, shown in config mode)
        Rectangle {
            id: deleteBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            width: 24
            height: 24
            radius: 12
            color: Appearance.colors.colError
            visible: root.configMode
            z: 20

            MaterialSymbol {
                text: "close"
                iconSize: 14
                color: Appearance.colors.colOnError
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Remove this widget from state
                    var list = StateService.get("dashboard.widgets", [])
                    list.splice(inst.index, 1)
                    StateService.set("dashboard.widgets", list)
                    if (root.selectedWidget === inst.widgetEntry) {
                        root.selectedWidget = null
                    }
                }
            }
        }
    }

    // ── Render all widgets ─────────────────────────────────────────

    /* The widgets are positioned absolutely; parent Flickable handles scrolling */
    Repeater {
        id: repeater
        model: root.widgets

        delegate: WidgetInstance {
            widgetEntry: modelData
            index: model.index
        }
    }
}
