import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colSurfaceContainerHigh
    implicitWidth: rowLayout.implicitWidth + 20
    implicitHeight: rowLayout.implicitHeight + 16
    Layout.fillWidth: true

    property alias title: title.text
    property alias value: value.text
    property alias symbol: symbolShape.text

    RowLayout {
        id: rowLayout
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
            topMargin: 8
            bottomMargin: 8
        }
        spacing: 10

        MaterialSymbol {
            id: symbolShape
            shape: MaterialShape.Shape.Cookie4Sided
            implicitSize: 36
            iconSize: Appearance.font.pixelSize.large
            fill: 1
            color: Appearance.colors.colPrimaryContainer
            colSymbol: Appearance.colors.colPrimary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -2

            StyledText {
                id: value
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSurface
            }

            StyledText {
                id: title
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }
}
