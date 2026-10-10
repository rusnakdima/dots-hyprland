import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

// Thin vertical separator between items of a BarIsland
Rectangle {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: 1
    implicitHeight: Appearance.sizes.barHeight - Appearance.sizes.spacing * 2
    color: Appearance.colors.colOutlineVariant
}
