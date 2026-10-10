pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

// Group of bar items. In the "islands" bar style it floats on its own, styled
// like the popups (translucent + border); in the other styles the bar draws
// the background and the group is just a row
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    readonly property bool framed: Config.options.bar.style === "islands"
    readonly property int sidePadding: framed ? Appearance.sizes.spacing : 0

    implicitWidth: row.implicitWidth + sidePadding * 2
    implicitHeight: Appearance.sizes.barHeight
    radius: height / 2
    color: framed ? Appearance.colors.colBackgroundSurfaceContainer : "transparent"
    border.width: framed ? 1 : 0
    border.color: Appearance.colors.colLayer1Hover

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: root.sidePadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.sizes.spacing
    }
}
