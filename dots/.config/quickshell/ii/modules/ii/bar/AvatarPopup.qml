pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

PopupWindow {
    id: root

    signal popupClosed()

    readonly property real cardWidth: 300
    readonly property string avatarPath: {
        const home = Directories.home;
        const facePath = home + "/.face";
        return FileUtils.exists(facePath) ? facePath : "";
    }
    readonly property string displayName: Config.options.profile.displayName !== "" ? Config.options.profile.displayName : SystemInfo.username
    readonly property string description: Config.options.profile.descriptionText === "::distro::" ? SystemInfo.distroName : Config.options.profile.descriptionText
    property bool closing: false
    readonly property bool barVertical: Config.options.bar.vertical
    readonly property string barEdge: {
        if (!barVertical) return Config.options.bar.bottom ? "bottom" : "top"
        return Config.options.bar.bottom ? "right" : "left"
    }
    readonly property real bounceRoom: 24

    color: "transparent"
    implicitWidth: root.cardWidth + Appearance.sizes.elevationMargin * 2 + (barVertical ? bounceRoom : 0)
    implicitHeight: card.implicitHeight + Appearance.sizes.elevationMargin * 2 + (barVertical ? 0 : bounceRoom)

    function open() {
        root.visible = true
        closeAnim.stop()
        openAnim.restart()
    }

    function close() {
        if (root.closing) return
        root.closing = true
        openAnim.stop()
        closeAnim.restart()
    }

    Component.onCompleted: {
        GlobalFocusGrab.addDismissable(root)
        root.open()
    }
    Component.onDestruction: GlobalFocusGrab.removeDismissable(root)

    Connections {
        target: GlobalFocusGrab
        function onDismissed() { root.close() }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: cardScale
            property: root.barVertical ? "xScale" : "yScale"
            to: 1
            duration: 500
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
        NumberAnimation {
            target: cardScale
            property: root.barVertical ? "yScale" : "xScale"
            to: 1
            duration: Appearance.animationCurves.expressiveDefaultSpatialDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 1
            duration: Appearance.animationCurves.expressiveEffectsDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
        SequentialAnimation {
            PauseAnimation { duration: 90 }
            ParallelAnimation {
                NumberAnimation {
                    target: content
                    property: "opacity"
                    to: 1
                    duration: Appearance.animationCurves.expressiveEffectsDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
                NumberAnimation {
                    target: contentShift
                    properties: "x,y"
                    to: 0
                    duration: Appearance.animationCurves.expressiveDefaultSpatialDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                }
            }
        }
    }

    ParallelAnimation {
        id: closeAnim
        onFinished: {
            root.visible = false
            root.popupClosed()
        }
        NumberAnimation {
            target: cardScale
            property: root.barVertical ? "xScale" : "yScale"
            to: 0.4
            duration: 220
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
        }
        NumberAnimation {
            target: cardScale
            property: root.barVertical ? "yScale" : "xScale"
            to: 0.85
            duration: 220
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
        }
        NumberAnimation {
            target: content
            property: "opacity"
            to: 0
            duration: 120
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()

        StyledRectangularShadow {
            target: card
            opacity: card.opacity
        }

        Rectangle {
            id: card
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + (root.barEdge === "right" ? root.bounceRoom : 0)
                rightMargin: Appearance.sizes.elevationMargin + (root.barEdge === "left" ? root.bounceRoom : 0)
                topMargin: Appearance.sizes.elevationMargin + (root.barEdge === "bottom" ? root.bounceRoom : 0)
                bottomMargin: Appearance.sizes.elevationMargin + (root.barEdge === "top" ? root.bounceRoom : 0)
            }
            implicitHeight: content.implicitHeight + 16 * 2
            radius: 16
            color: Appearance.colors.colUiPopupBackground
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            opacity: 0
            transform: Scale {
                id: cardScale
                origin.x: root.barEdge === "left" ? 0 : root.barEdge === "right" ? card.width : card.width / 2
                origin.y: root.barEdge === "top" ? 0 : root.barEdge === "bottom" ? card.height : card.height / 2
                xScale: root.barVertical ? 0.4 : 0.8
                yScale: root.barVertical ? 0.8 : 0.4
            }

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 16
                }
                spacing: 12
                opacity: 0
                transform: Translate {
                    id: contentShift
                    x: root.barEdge === "left" ? -16 : root.barEdge === "right" ? 16 : 0
                    y: root.barEdge === "top" ? -16 : root.barEdge === "bottom" ? 16 : 0
                }

                RowLayout {
                    spacing: 14

                    // Avatar
                    Rectangle {
                        width: 64
                        height: 64
                        radius: 32
                        color: Appearance.colors.colPrimaryContainer

                        Image {
                            id: popupAvatarImage
                            anchors.fill: parent
                            radius: parent.radius
                            visible: root.avatarPath !== ""
                            source: "file://" + root.avatarPath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "person"
                            iconSize: 28
                            color: Appearance.colors.colOnPrimaryContainer
                            visible: root.avatarPath === ""
                        }
                    }

                    ColumnLayout {
                        spacing: 2

                        StyledText {
                            text: root.displayName
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurface
                        }
                        StyledText {
                            text: root.description
                            visible: text.length > 0
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            text: Translation.tr("Up • %1").arg(DateTime.uptime)
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }
    }
}
