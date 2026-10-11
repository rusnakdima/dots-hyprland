pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.services

/*
 * DashboardConfigOverlay — config mode UI for the dashboard canvas.
 *
 * Visible only when configMode is true.
 *
 * Layout:
 *   - Left sidebar: list of widget types to add
 *   - Right panel: property editor for the selected widget (x, y, w, h)
 *   - Semi-transparent backdrop covering the canvas
 */
Item {
    id: root

    property bool configMode: false
    property var  selectedWidget: null

    /* Available widget type definitions */
    readonly property var widgetTypes: [
        { type: "Calendar",    icon: "calendar_month",   description: "Calendar events" },
        { type: "Notes",       icon: "edit_note",         description: "Sticky notes" },
        { type: "WorldClock",  icon: "public",             description: "World clocks" },
        { type: "Visualizer", icon: "equalizer",          description: "Audio visualizer" },
        { type: "Resources",  icon: "pie_chart",          description: "System resources" },
        { type: "Timers",     icon: "timer",              description: "Timers and stopwatch" },
        { type: "CustomText", icon: "text_fields",         description: "Custom text block" },
        { type: "Media",      icon: "play_circle",        description: "Media player" },
        { type: "System",      icon: "computer",           description: "System stats" },
        { type: "Weather",    icon: "cloud",              description: "Weather widget" }
    ]

    // ── Visibility ─────────────────────────────────────────────────

    visible: configMode

    // ── Backdrop ───────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: ColorUtils.transparentize(Appearance.colors.colScrim, 0.6)
        radius: Appearance.rounding.large

        MouseArea {
            anchors.fill: parent
            onClicked: { /* click backdrop → deselect */ root.selectedWidget = null }
        }
    }

    // ── Layout ─────────────────────────────────────────────────────

    Row {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ── Left: widget type picker ───────────────────────────────

        Rectangle {
            id: pickerPanel
            width: 200
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Appearance.colors.colSurfaceContainerHigh
            radius: Appearance.rounding.normal

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Add Widget"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    color: Appearance.colors.colOnSurface
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.colors.colOutlineVariant
                }

                ListView {
                    id: typeList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.widgetTypes
                    spacing: 4
                    clip: true

                    delegate: Rectangle {
                        id: typeDelegate
                        required property var modelData

                        width:  typeList.width
                        height: 52
                        radius: Appearance.rounding.small
                        color: typeMouse.containsMouse
                            ? Appearance.colors.colPrimaryContainer
                            : Appearance.colors.colSurfaceContainerHighest

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            spacing: 10

                            MaterialSymbol {
                                text: modelData.icon || "widgets"
                                iconSize: 20
                                color: typeMouse.containsMouse
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colOnSurfaceVariant
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.type
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.bold: true
                                    color: typeMouse.containsMouse
                                        ? Appearance.colors.colOnPrimaryContainer
                                        : Appearance.colors.colOnSurface
                                }

                                Text {
                                    text: modelData.description || ""
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colOnSurfaceVariant
                                }
                            }
                        }

                        MouseArea {
                            id: typeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: _addWidget(modelData.type)
                        }
                    }
                }
            }
        }

        // ── Right: property editor ─────────────────────────────────

        Rectangle {
            id: editorPanel
            width: 240
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Appearance.colors.colSurfaceContainerHigh
            radius: Appearance.rounding.normal
            visible: root.selectedWidget !== null

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Header
                Row {
                    Layout.fillWidth: true

                    Text {
                        text: root.selectedWidget?.type ?? ""
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.bold: true
                        color: Appearance.colors.colOnSurface
                    }

                    Item { Layout.fillWidth: true }

                    MaterialSymbol {
                        text: "close"
                        iconSize: 18
                        color: Appearance.colors.colOnSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selectedWidget = null
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.colors.colOutlineVariant
                }

                // Position / size editors
                GridLayout {
                    id: propGrid
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    Layout.fillWidth: true

                    // X
                    Text {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                        Layout.alignment: Qt.AlignVCenter
                        text: "X"
                    }
                    SpinBox {
                        id: editX
                        Layout.fillWidth: true
                        from: 0
                        to: 9999
                        stepSize: 10
                        value: root.selectedWidget?.x ?? 0
                        onValueChanged: _updateSelected("x", value)
                    }

                    // Y
                    Text {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                        Layout.alignment: Qt.AlignVCenter
                        text: "Y"
                    }
                    SpinBox {
                        id: editY
                        Layout.fillWidth: true
                        from: 0
                        to: 9999
                        stepSize: 10
                        value: root.selectedWidget?.y ?? 0
                        onValueChanged: _updateSelected("y", value)
                    }

                    // Width
                    Text {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                        Layout.alignment: Qt.AlignVCenter
                        text: "W"
                    }
                    SpinBox {
                        id: editWidth
                        Layout.fillWidth: true
                        from: 100
                        to: 1200
                        stepSize: 20
                        value: root.selectedWidget?.width ?? 280
                        onValueChanged: _updateSelected("width", value)
                    }

                    // Height
                    Text {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                        Layout.alignment: Qt.AlignVCenter
                        text: "H"
                    }
                    SpinBox {
                        id: editHeight
                        Layout.fillWidth: true
                        from: 60
                        to: 800
                        stepSize: 20
                        value: root.selectedWidget?.height ?? 180
                        onValueChanged: _updateSelected("height", value)
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.colors.colOutlineVariant
                }

                // Delete button
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colErrorContainer

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialSymbol {
                            text: "delete"
                            iconSize: 16
                            color: Appearance.colors.colOnErrorContainer
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Remove Widget"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnErrorContainer
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: _deleteSelected()
                    }
                }

                Item { Layout.fillHeight: true; Layout.fillWidth: true }
            }
        }

        // Placeholder when nothing selected
        Rectangle {
            id: emptyPanel
            width: 240
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: ColorUtils.transparentize(
                Appearance.colors.colSurfaceContainerHigh, 0.3)
            radius: Appearance.rounding.normal
            visible: root.selectedWidget === null

            Text {
                anchors.centerIn: parent
                width: parent.width - 24
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: "Select a widget to edit its position and size"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }

    // ── Helpers ─────────────────────────────────────────────────────

    /* Add a new widget of the given type at a default position. */
    function _addWidget(type) {
        var list = StateService.get("dashboard.widgets", [])

        // Compute a default position (offset from last widget or 0,0)
        var defaultX = 20
        var defaultY = 20
        if (list.length > 0) {
            var last = list[list.length - 1]
            defaultX = (last.x || 0) + (last.width || 280) + 16
            defaultY = last.y || 0
        }

        var newEntry = {
            type:   type,
            x:      defaultX,
            y:      defaultY,
            width:  280,
            height: 180,
            config: {}
        }

        list.push(newEntry)
        StateService.set("dashboard.widgets", list)
        root.selectedWidget = newEntry
    }

    /* Update a single property on the currently selected widget. */
    function _updateSelected(prop, value) {
        if (!root.selectedWidget) return

        var list = StateService.get("dashboard.widgets", [])
        var idx = list.indexOf(root.selectedWidget)
        if (idx < 0) return

        // Clone to trigger reactivity
        var updated = JSON.parse(JSON.stringify(list[idx]))
        updated[prop] = value
        list[idx] = updated
        StateService.set("dashboard.widgets", list)

        // Re-bind selectedWidget to the updated entry
        root.selectedWidget = list[idx]
    }

    /* Delete the currently selected widget. */
    function _deleteSelected() {
        if (!root.selectedWidget) return
        var list = StateService.get("dashboard.widgets", [])
        var idx = list.indexOf(root.selectedWidget)
        if (idx < 0) return

        list.splice(idx, 1)
        StateService.set("dashboard.widgets", list)
        root.selectedWidget = null
    }
}
