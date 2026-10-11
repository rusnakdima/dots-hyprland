pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var config: ({})
    property bool active: true

    // Get configured style or use default
    property string style: Config.options.dashboard?.widgetTypes?.visualizer?.style ?? "bars"

    // Cava service control
    property bool visualizing: active && hasAudio
    property bool hasAudio: CavaService?.values?.length > 0

    onVisualizingChanged: visualizing ? CavaService.acquire() : CavaService.release()
    Component.onDestruction: {
        if (visualizing)
            CavaService.release()
    }

    // Number of bars to display
    readonly property int barCount: 24
    readonly property int usedBands: 32

    // Get bar heights from cava values
    property var barHeights: {
        const values = CavaService?.values ?? []
        const heights = []
        for (let i = 0; i < barCount; i++) {
            const from = Math.floor(i * usedBands / barCount)
            const to = Math.max(from + 1, Math.floor((i + 1) * usedBands / barCount))
            let maxVal = 0
            for (let j = from; j < to && j < values.length; j++) {
                if (values[j] > maxVal) maxVal = values[j]
            }
            heights.push(Math.pow(maxVal, 0.6))
        }
        return heights
    }

    // Fallback gradient colors for bars
    property color barColorLow: Appearance.colors.colPrimary
    property color barColorHigh: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.3)

    // Main content
    Column {
        anchors.fill: parent
        anchors.margins: 10
        anchors.topMargin: 38
        spacing: 4

        // Style selector / indicator
        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: style === "bars" ? "Bars" : (style === "mirror" ? "Mirror" : "Aurora")
                font.family: Appearance.font.family
                font.pixelSize: 10
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        // Visualizer area
        Item {
            width: parent.width
            height: style === "mirror" ? 40 : 60

            // Bars style
            Row {
                anchors.fill: parent
                anchors.leftMargin: 2
                anchors.rightMargin: 2
                spacing: 2
                visible: style === "bars"

                Repeater {
                    model: barCount

                    delegate: Rectangle {
                        required property int index
                        property real targetHeight: (root.barHeights[index] ?? 0) * parent.height
                        property real currentHeight: targetHeight

                        width: (parent.width - (barCount - 1) * 2) / barCount
                        height: currentHeight
                        anchors.bottom: parent.bottom
                        radius: 1

                        color: {
                            const ratio = index / barCount
                            return ColorUtils.mix(barColorLow, barColorHigh, ratio)
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: Appearance.animation.durationShort
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            // Mirror style
            Item {
                anchors.fill: parent
                visible: style === "mirror"

                Row {
                    id: mirrorTopRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: 2
                    spacing: 2

                    Repeater {
                        model: Math.floor(barCount / 2)

                        delegate: Rectangle {
                            required property int index
                            property real targetHeight: (root.barHeights[index] ?? 0) * (mirrorTopRow.height)
                            property real currentHeight: targetHeight

                            width: (mirrorTopRow.width - (Math.floor(barCount / 2) - 1) * 2) / Math.floor(barCount / 2)
                            height: currentHeight
                            anchors.bottom: parent.bottom
                            radius: 1

                            color: {
                                const ratio = index / (barCount / 2)
                                return ColorUtils.mix(barColorLow, barColorHigh, ratio)
                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: Appearance.animation.durationShort
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                Row {
                    id: mirrorBottomRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: 2
                    spacing: 2

                    Repeater {
                        model: Math.floor(barCount / 2)

                        delegate: Rectangle {
                            required property int index
                            property real targetHeight: (root.barHeights[root.barCount - 1 - index] ?? 0) * (mirrorBottomRow.height)
                            property real currentHeight: targetHeight

                            width: (mirrorBottomRow.width - (Math.floor(barCount / 2) - 1) * 2) / Math.floor(barCount / 2)
                            height: currentHeight
                            anchors.top: parent.top
                            radius: 1

                            color: {
                                const ratio = index / (barCount / 2)
                                return ColorUtils.mix(barColorLow, barColorHigh, ratio)
                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: Appearance.animation.durationShort
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }

            // Aurora style (organic flowing bars with rounded ends)
            Row {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                visible: style === "aurora"

                Repeater {
                    model: barCount

                    delegate: Rectangle {
                        required property int index
                        property real targetHeight: (root.barHeights[index] ?? 0) * parent.height
                        property real currentHeight: targetHeight

                        width: (parent.width - (barCount - 1) * 3) / barCount
                        height: currentHeight
                        anchors.verticalCenter: parent.verticalCenter
                        radius: width / 2

                        color: {
                            const ratio = index / barCount
                            return ColorUtils.mix(barColorLow, barColorHigh, ratio)
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: Appearance.animation.durationMedium
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }
    }

    // No audio state
    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        anchors.topMargin: 38
        visible: !hasAudio || CavaService?.values?.length === 0
        radius: Appearance.rounding.normal
        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.5)

        Column {
            anchors.centerIn: parent
            spacing: 8

            MaterialSymbol {
                text: "graphic_eq"
                iconSize: 32
                color: Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "No audio"
                font.family: Appearance.font.family
                font.pixelSize: 12
                color: Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
