pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common

// Read-only label: value row
SettingRow {
    id: root

    property string value
    resettable: false

    Text {
        Layout.maximumWidth: root.width * 0.6
        text: root.value !== "" ? root.value : "\u{e894}"
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
        font.family: Appearance.font.family
        font.pixelSize: Appearance.font.pixelSize.normal
        color: Appearance.colors.colOnSurfaceVariant
    }
}
