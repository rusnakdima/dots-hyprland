pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

DashboardWidgetBlock {
    id: root

    title: "Notes"

    property string notesContent: StateService.get("dashboard.widgets.notes.content", "")
    property bool _suppressSave: false

    // Debounced save to StateService
    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!root._suppressSave) {
                StateService.set("dashboard.widgets.notes.content", root.notesContent)
            }
        }
    }

    function _onTextChanged(newText) {
        if (root._suppressSave) return
        root.notesContent = newText
        saveTimer.restart()
    }

    function _clearNotes() {
        root._suppressSave = true
        root.notesContent = ""
        notesTextArea.text = ""
        root._suppressSave = false
        StateService.set("dashboard.widgets.notes.content", "")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 38
        spacing: 6

        // Header row with clear button
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Item { Layout.fillWidth: true }

            MaterialSymbol {
                text: "delete"
                iconSize: 16
                color: Appearance.colors.colOnSurfaceVariant
                visible: root.notesContent.length > 0
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _clearNotes()
                }
            }
        }

        // Text area with placeholder
        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: notesTextArea.width
            contentHeight: notesTextArea.height
            boundsBehavior: Flickable.StopAtBounds

            TextArea {
                id: notesTextArea
                width: root.width - 16
                height: Math.max(flick.height, implicitHeight)
                text: root.notesContent
                wrapMode: TextArea.Wrap
                placeholderText: "Write something..."
                font.pixelSize: 12
                font.family: Appearance.font.family
                color: Appearance.colors.colOnSurface
                background: Rectangle { color: "transparent" }
                padding: 4
                leftPadding: 4
                rightPadding: 4
                onTextChanged: root._onTextChanged(text)
            }
        }
    }
}
