pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.ii.settings
import "../../components/"

// Search results overlay for settings pages
Item {
    id: root

    property string query
    readonly property var results: SettingsService.indexing ? [] : SettingsService.search(query)
    readonly property int boxSize: Math.round(Appearance.font.pixelSize.iconSmall * 2)

    signal activated

    function move(delta: int) {
        if (results.length === 0)
            return;
        listView.currentIndex = Math.max(0, Math.min(results.length - 1, listView.currentIndex + delta));
        listView.positionViewAtIndex(listView.currentIndex, ListView.Contain);
    }

    function activateCurrent() {
        if (listView.currentIndex >= 0 && listView.currentIndex < results.length) {
            SettingsService.reveal(results[listView.currentIndex]);
            activated();
        }
    }

    onResultsChanged: listView.currentIndex = 0

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.roundedMd

        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: Appearance.sizes.spacing
            clip: true
            model: root.results
            spacing: Math.round(Appearance.sizes.spacing / 3)
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false

            delegate: Rectangle {
                id: item

                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                readonly property string context: modelData.kind === "page" ? modelData.description
                    : modelData.kind === "group" ? modelData.pageLabel + " · section"
                    : modelData.pageLabel + (modelData.group !== "" ? " › " + modelData.group : "")

                width: listView.width
                implicitHeight: row.implicitHeight + Appearance.sizes.spacing * 2
                radius: Appearance.rounding.roundedMd
                color: current ? Qt.alpha(Appearance.colors.colAccent, 0.15)
                    : itemMouse.containsMouse ? Appearance.colors.colLayer1Hover
                    : "transparent"

                RowLayout {
                    id: row
                    anchors.fill: parent
                    anchors.margins: Appearance.sizes.spacing
                    spacing: Appearance.sizes.spacing + Appearance.sizes.spacing

                    Rectangle {
                        Layout.preferredWidth: root.boxSize
                        Layout.preferredHeight: root.boxSize
                        radius: Appearance.rounding.roundedMd
                        color: current ? Appearance.colors.colAccent : Appearance.colors.colLayer1Hover

                        Text {
                            anchors.centerIn: parent
                            text: item.modelData.icon
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: current ? Appearance.colors.colOnAccent : Appearance.colors.colOnSurfaceVariant
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: item.modelData.label
                            elide: Text.ElideRight
                            font.family: Appearance.font.family
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.bold: item.modelData.kind !== "row"
                            color: current ? Appearance.colors.colAccent : Appearance.colors.colOnSurface
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: item.context
                            elide: Text.ElideRight
                            font.family: Appearance.font.family
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        listView.currentIndex = item.index;
                        root.activateCurrent();
                    }
                }
            }
        }

        // Empty state
        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Appearance.sizes.spacing * 4
            visible: root.results.length === 0 && query !== ""

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "\u{e8b6}"
                font.family: "Material Symbols Rounded"
                font.pixelSize: Appearance.font.pixelSize.iconLarge
                color: Appearance.colors.colOnSurfaceVariant
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: SettingsService.indexing ? "Searching…" : "No settings match \u201c" + root.query.trim() + "\u201d"
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
