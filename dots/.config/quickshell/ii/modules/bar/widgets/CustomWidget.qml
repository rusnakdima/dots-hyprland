pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.services
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string widgetType: "cpuRam" // "weather" | "networkSpeed" | "cpuRam" | "mediaPlayer"
    property bool compact: false
    property bool showPopup: true

    implicitWidth: contentRow.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: (event) => {
            if (event.button === Qt.RightButton) {
                event.accepted = false
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        Loader {
            active: root.widgetType === "weather" && Config.options.bar.weather.enable
            visible: active
            sourceComponent: weatherContent
        }

        Loader {
            active: root.widgetType === "networkSpeed"
            visible: active
            sourceComponent: networkSpeedContent
        }

        Loader {
            active: root.widgetType === "cpuRam"
            visible: active
            sourceComponent: cpuRamContent
        }

        Loader {
            active: root.widgetType === "mediaPlayer"
            visible: active
            sourceComponent: mediaPlayerContent
        }
    }

    component weatherContent: RowLayout {
        spacing: 4

        MaterialSymbol {
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: root.compact ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: !root.compact
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: Weather.data?.temp ?? "--°"
            Layout.alignment: Qt.AlignVCenter
        }
    }
    // Network speed content component
    component networkSpeedContent: RowLayout {
        spacing: 4

        MaterialSymbol {
            fill: 0
            text: Network.ethernet ? "lan" : Network.materialSymbol
            iconSize: root.compact ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: !root.compact
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: Network.networkName || "N/A"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    component cpuRamContent: RowLayout {
        spacing: 2

        RowLayout {
            spacing: 2
            visible: !root.compact || true

            ClippedFilledCircularProgress {
                id: cpuCircProg
                Layout.alignment: Qt.AlignVCenter
                lineWidth: Appearance.rounding.unsharpen
                value: ResourceUsage.cpuUsage
                implicitSize: 18
                colPrimary: cpuUsageWarning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
                accountForLightBleeding: !cpuUsageWarning
                enableAnimation: false

                Item {
                    anchors.centerIn: parent
                    width: cpuCircProg.implicitSize
                    height: cpuCircProg.implicitSize

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: "planner_review"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: Math.round(ResourceUsage.cpuUsage * 100) + "%"
                Layout.alignment: Qt.AlignVCenter
                visible: !root.compact
            }
        }

        RowLayout {
            spacing: 2
            Layout.leftMargin: root.compact ? 0 : 6

            ClippedFilledCircularProgress {
                id: ramCircProg
                Layout.alignment: Qt.AlignVCenter
                lineWidth: Appearance.rounding.unsharpen
                value: ResourceUsage.memoryUsedPercentage
                implicitSize: 18
                colPrimary: ramUsageWarning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
                accountForLightBleeding: !ramUsageWarning
                enableAnimation: false

                Item {
                    anchors.centerIn: parent
                    width: ramCircProg.implicitSize
                    height: ramCircProg.implicitSize

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: 1
                        text: "memory"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                Layout.alignment: Qt.AlignVCenter
                visible: !root.compact
            }
        }

        readonly property bool cpuUsageWarning: ResourceUsage.cpuUsage * 100 >= Config.options.bar.resources.cpuWarningThreshold
        readonly property bool ramUsageWarning: ResourceUsage.memoryUsedPercentage * 100 >= Config.options.bar.resources.memoryWarningThreshold
    }

    component mediaPlayerContent: RowLayout {
        spacing: 4

        readonly property MprisPlayer activePlayer: MprisController.activePlayer
        readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || ""

        ClippedFilledCircularProgress {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            implicitSize: 18
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: root.compact ? Appearance.font.pixelSize.small : Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        StyledText {
            visible: !root.compact && root.cleanedTitle.length > 0
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: root.cleanedTitle
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 120
            elide: Text.ElideRight
        }

        MouseArea {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 24
            implicitHeight: 24
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

            onPressed: (event) => {
                if (event.button === Qt.MiddleButton) {
                    activePlayer?.togglePlaying()
                } else if (event.button === Qt.LeftButton) {
                    GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "skip_next"
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
        }
    }

    Loader {
        id: popupLoader
        active: root.showPopup && mouseArea.containsMouse && root.widgetType !== "mediaPlayer"
        anchors.centerIn: parent
        sourceComponent: popupContent
    }

    component popupContent: StyledPopup {
        hoverTarget: mouseArea

        contentItem: Item {
            implicitWidth: popupColumn.implicitWidth
            implicitHeight: popupColumn.implicitHeight

            Column {
                id: popupColumn
                spacing: 8
                anchors.centerIn: parent

                Column {
                    visible: root.widgetType === "weather"
                    spacing: 4

                    Row {
                        spacing: 8
                        anchors.horizontalCenter: parent.horizontalCenter

                        MaterialSymbol {
                            fill: 0
                            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                            iconSize: 36
                            color: Appearance.colors.colOnLayer1
                        }

                        Column {
                            StyledText {
                                text: Weather.data?.temp ?? "--°"
                                font.pixelSize: Appearance.font.pixelSize.xxLarge
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: Weather.data?.condition ?? "--"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Weather.data?.location ?? "--"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }
                }

                Column {
                    visible: root.widgetType === "networkSpeed"
                    spacing: 4

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Network.ethernet ? "Ethernet" : Network.essid ?? "--"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }

                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            StyledText {
                                text: "↓"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: formatSpeed(Network.downloadSpeed)
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        Column {
                            StyledText {
                                text: "↑"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: formatSpeed(Network.uploadSpeed)
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }

                Column {
                    visible: root.widgetType === "cpuRam"
                    spacing: 4

                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            StyledText {
                                text: "CPU"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Math.round(ResourceUsage.cpuUsage * 100) + "%"
                                font.pixelSize: Appearance.font.pixelSize.xxLarge
                                color: cpuUsageWarning ? Appearance.colors.colError : Appearance.colors.colOnLayer1
                            }
                        }

                        Column {
                            StyledText {
                                text: "RAM"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                                font.pixelSize: Appearance.font.pixelSize.xxLarge
                                color: ramUsageWarning ? Appearance.colors.colError : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }

        readonly property bool cpuUsageWarning: ResourceUsage.cpuUsage * 100 >= Config.options.bar.resources.cpuWarningThreshold
        readonly property bool ramUsageWarning: ResourceUsage.memoryUsedPercentage * 100 >= Config.options.bar.resources.memoryWarningThreshold

        function formatSpeed(bytesPerSec) {
            if (bytesPerSec >= 1024 * 1024) {
                return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
            } else if (bytesPerSec >= 1024) {
                return (bytesPerSec / 1024).toFixed(1) + " KB/s"
            }
            return bytesPerSec.toFixed(0) + " B/s"
        }
    }
}
