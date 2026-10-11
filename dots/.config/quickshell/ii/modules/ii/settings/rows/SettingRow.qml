pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.services
import "../../../components/"

// Base row for settings: label + description on left, control on right.
// Resets to default when modified. Flashing for search-reveal animation.
Rectangle {
    id: root

    property string label
    property string description
    property color descriptionColor: Appearance.colors.colOnSurfaceVariant
    property string path

    readonly property bool isSettingRow: true
    property bool first: true
    property bool last: true

    default property alias trailing: trailingRow.data
    property alias below: belowSlot.data
    property bool belowVisible: true
    property alias leading: leadingRow.data

    readonly property bool hovered: rowHover.hovered
    readonly property color controlColor: hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer0
    property bool resettable: true
    readonly property bool modified: resettable && path !== "" && !StateService.isDefault(path)
    readonly property int rowPadding: Appearance.sizes.spacing * 2
    readonly property int minLabelWidth: Appearance.font.pixelSize.normal * 11
    readonly property bool stacked: trailingRow.implicitWidth > 0
        && content.width - trailingRow.implicitWidth
        - (leadingRow.visible ? leadingRow.implicitWidth + Appearance.sizes.spacing : 0)
        - Appearance.sizes.spacing * 2 < minLabelWidth

    signal resetRequested

    function flash() {
        flashAnim.restart();
    }

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + rowPadding * 2

    color: hovered ? Appearance.m3colors.m3surfaceContainerHigh : Appearance.m3colors.m3surfaceContainerLow
    topLeftRadius: first ? Appearance.rounding.roundedLg : Appearance.rounding.roundedXs
    topRightRadius: first ? Appearance.rounding.roundedLg : Appearance.rounding.roundedXs
    bottomLeftRadius: last ? Appearance.rounding.roundedLg : Appearance.rounding.roundedXs
    bottomRightRadius: last ? Appearance.rounding.roundedLg : Appearance.rounding.roundedXs

    opacity: enabled ? 1 : 0.4

    HoverHandler {
        id: rowHover
    }

    Rectangle {
        id: flashOverlay
        anchors.fill: parent
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: Qt.alpha(Appearance.colors.colAccent, 0.15)
        border.width: 1
        border.color: Qt.alpha(Appearance.colors.colAccent, 0.6)
        opacity: 0

        SequentialAnimation {
            id: flashAnim

            NumberAnimation {
                target: flashOverlay
                property: "opacity"
                to: 1
                duration: Appearance.animation.duration
            }
            NumberAnimation {
                target: flashOverlay
                property: "opacity"
                to: 0.3
                duration: Appearance.animation.durationLong
            }
            NumberAnimation {
                target: flashOverlay
                property: "opacity"
                to: 1
                duration: Appearance.animation.duration
            }
            PauseAnimation {
                duration: Appearance.animation.durationLong
            }
            NumberAnimation {
                target: flashOverlay
                property: "opacity"
                to: 0
                duration: Appearance.animation.durationLong * 2
            }
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: root.rowPadding
        spacing: Appearance.sizes.spacing

        RowLayout {
            id: headerRow
            width: parent.width
            spacing: Appearance.sizes.spacing

            RowLayout {
                id: leadingRow
                visible: children.length > 0
                Layout.rightMargin: Appearance.sizes.spacing
                spacing: Appearance.sizes.spacing
            }

            Column {
                Layout.fillWidth: true
                spacing: Math.round(Appearance.sizes.spacing / 3)

                Text {
                    width: parent.width
                    text: root.label
                    elide: Text.ElideRight
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.bold: true
                    color: Appearance.colors.colOnSurface
                }

                Text {
                    width: parent.width
                    visible: root.description !== ""
                    text: root.description
                    wrapMode: Text.WordWrap
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.descriptionColor
                }
            }

            // Reset button
            Text {
                id: resetButton
                visible: root.modified
                text: "\u{e8ba}"
                font.family: "Material Symbols Rounded"
                font.pixelSize: Appearance.font.pixelSize.iconSmall
                color: resetMouse.containsMouse ? Appearance.colors.colAccent : Appearance.colors.colOnSurfaceVariant
                opacity: rowHover.hovered ? 1 : 0.5

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.durationShort
                    }
                }

                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    anchors.margins: -Appearance.sizes.spacing
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        StateService.reset(root.path);
                        root.resetRequested();
                    }
                }
            }

            RowLayout {
                id: trailingRow
                parent: root.stacked ? stackedSlot : headerRow
                spacing: Appearance.sizes.spacing
            }
        }

        RowLayout {
            id: stackedSlot
            width: parent.width
            visible: root.stacked
        }

        Item {
            id: belowSlot
            width: parent.width
            visible: root.belowVisible && children.length > 0
            implicitHeight: childrenRect.height
        }
    }
}
