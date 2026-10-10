pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

// Small labeled value (icon + label over a bold value) for detail grids,
// like the weather's humidity, wind or UV
Rectangle {
    id: tile

    required property string icon
    required property string label
    required property string value
    property color accent: Appearance.colors.colAccent

    Layout.fillWidth: true
    implicitHeight: tileColumn.implicitHeight + Appearance.sizes.spacing * 2
    radius: Appearance.rounding.roundedSm
    color: Qt.alpha(Appearance.colors.colLayer1Hover, 0.5)

    ColumnLayout {
        id: tileColumn
        anchors.fill: parent
        anchors.margins: Appearance.sizes.spacing
        anchors.leftMargin: Appearance.sizes.spacing * 2
        spacing: 0

        RowLayout {
            spacing: Appearance.sizes.spacing

            Text {
                text: tile.icon
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.pixelSize.sm
                color: tile.accent
            }

            Text {
                text: tile.label
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.pixelSize.sm
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        Text {
            Layout.fillWidth: true
            text: tile.value
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.pixelSize.md
            font.bold: true
            color: Appearance.colors.colOnSurface
            elide: Text.ElideRight
        }
    }
}
