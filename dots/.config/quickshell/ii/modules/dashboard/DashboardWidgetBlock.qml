import qs.modules.common
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""

    color: Appearance.colors.colSurfaceContainerHigh
    radius: Appearance.rounding.large

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
            text: root.title
            font.pixelSize: 14
            font.bold: true
            color: Appearance.colors.colOnSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
