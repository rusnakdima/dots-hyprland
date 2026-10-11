import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    required property string icon
    required property string label
    spacing: 4

    MaterialSymbol {
        text: root.icon
        color: Appearance.colors.colOnSurfaceVariant
        iconSize: Appearance.font.pixelSize.large
    }
    StyledText {
        text: root.label
        color: Appearance.colors.colOnSurfaceVariant
    }
    Item { Layout.fillWidth: true }
}
