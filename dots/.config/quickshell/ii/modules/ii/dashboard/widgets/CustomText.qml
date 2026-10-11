pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// Free-form label widget with configurable text, font, color, and alignment.
// No background — transparent by default.
Item {
    id: root

    // Default size
    implicitWidth: 200
    implicitHeight: 80

    // Config — set by WidgetLoader via Qt.binding
    property var config: ({})

    // Config properties with defaults
    property string text: config?.text ?? "Custom Text"
    property int fontSize: config?.fontSize ?? 16
    property color fontColor: config?.fontColor ?? Appearance.colors.colOnSurface
    property bool bold: config?.bold ?? false
    // "left" | "center" | "right"
    property string alignment: config?.alignment ?? "center"

    // Resolved horizontal alignment
    readonly property int horizAlign: {
        switch (alignment) {
            case "left": return Text.AlignLeft
            case "right": return Text.AlignRight
            default: return Text.AlignHCenter
        }
    }

    // Background is intentionally transparent

    Text {
        id: label
        anchors.fill: parent
        anchors.leftMargin: parent.width > 0 ? 8 : 0
        anchors.rightMargin: parent.width > 0 ? 8 : 0
        text: root.text
        font {
            pixelSize: root.fontSize
            bold: root.bold
            family: Appearance.font.family
        }
        color: root.fontColor
        horizontalAlignment: root.horizAlign
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        maximumLineCount: 0  // no limit
    }
}
