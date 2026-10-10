pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common

// Pill with mutually exclusive options ({ label, icon }); the selection
// indicator slides between them
Rectangle {
    id: root

    required property var options
    property int currentIndex: 0

    signal selected(int index)

    readonly property real segmentWidth: (width - Appearance.sizes.spacing) / Math.max(1, options.length)

    Layout.fillWidth: true
    implicitHeight: Appearance.font.pixelSize.sm * 2
    radius: Appearance.rounding.roundedLg
    color: Appearance.colors.colLayer1Hover

    // Selection indicator
    Rectangle {
        x: Appearance.sizes.spacing / 2 + root.currentIndex * root.segmentWidth
        y: Appearance.sizes.spacing / 2
        width: root.segmentWidth
        height: root.height - Appearance.sizes.spacing
        radius: Appearance.rounding.roundedMd
        color: Appearance.colors.colAccent

        Behavior on x {
            NumberAnimation {
                duration: Appearance.animation.durationMedium
                easing.type: Easing.OutQuad
            }
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: Appearance.sizes.spacing / 2

        Repeater {
            model: root.options

            Item {
                id: segment

                required property var modelData
                required property int index
                readonly property bool active: index === root.currentIndex

                width: root.segmentWidth
                height: parent.height

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Appearance.sizes.spacing

                    Text {
                        visible: (segment.modelData.icon ?? "") !== ""
                        text: segment.modelData.icon ?? ""
                        font.family: Appearance.font.family
                        font.pixelSize: Appearance.font.pixelSize.md
                        color: segment.active ? Appearance.colors.colOnAccent : Appearance.colors.colOnSurfaceVariant
                    }

                    Text {
                        text: segment.modelData.label
                        font.family: Appearance.font.family
                        font.pixelSize: Appearance.font.pixelSize.sm
                        font.bold: segment.active
                        color: segment.active ? Appearance.colors.colOnAccent : segmentMouse.containsMouse ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant

                        Behavior on color {
                            enabled: !Appearance.animation.themeTransitioning
                            ColorAnimation {
                                duration: Appearance.animation.durationShort
                            }
                        }
                    }
                }

                MouseArea {
                    id: segmentMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: segment.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (!segment.active)
                            root.selected(segment.index);
                    }
                }
            }
        }
    }
}
