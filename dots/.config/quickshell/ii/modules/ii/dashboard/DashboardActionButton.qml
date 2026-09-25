import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    signal clicked()

    color: Appearance.colors.colSurfaceContainerHighest
    radius: Appearance.rounding.normal
    implicitWidth: 75
    implicitHeight: 60

    Column {
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: root.icon
            iconSize: 24
            color: Appearance.colors.colOnSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.label
            font.pixelSize: 11
            color: Appearance.colors.colOnSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            root.color = Appearance.colors.colPrimaryContainer
        }
        onExited: {
            root.color = Appearance.colors.colSurfaceContainerHighest
        }
        onClicked: {
            root.clicked()
        }
    }
}
