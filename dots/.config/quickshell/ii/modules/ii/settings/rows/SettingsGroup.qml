pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common

// Titled stack of SettingRows with large radius only at the ends of the group
ColumnLayout {
    id: root

    property string title
    default property alias rows: rowsLayout.data

    readonly property var _visibleRows: Array.from(rowsLayout.children).filter(c => c.visible && c.isSettingRow === true)

    on_VisibleRowsChanged: {
        _visibleRows.forEach((row, i) => {
            row.first = i === 0;
            row.last = i === _visibleRows.length - 1;
        });
    }

    Layout.fillWidth: true
    spacing: Appearance.sizes.spacing

    Text {
        visible: root.title !== ""
        Layout.leftMargin: Appearance.sizes.spacing
        Layout.bottomMargin: Appearance.sizes.spacing / 2
        text: root.title.toUpperCase()
        font.family: Appearance.font.family
        font.pixelSize: Appearance.font.pixelSize.smallest
        font.bold: true
        font.letterSpacing: 1
        color: Appearance.colors.colAccent
    }

    ColumnLayout {
        id: rowsLayout
        Layout.fillWidth: true
        spacing: Math.round(Appearance.sizes.spacing / 3)
    }
}
