pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import "../../../components/"

// System widget with SystemMonitorService data rendered as Sparkline graphs
Item {
    id: root

    property var config: ({})

    readonly property bool hasGpu: SystemMonitorService.gpuType !== "unknown"

    // Heavy collectors (GPU, disk) only run while visible
    onVisibleChanged: visible ? SystemMonitorService.acquire() : SystemMonitorService.release()
    Component.onDestruction: {
        if (visible)
            SystemMonitorService.release();
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Header
        Row {
            spacing: 12

            Column {
                spacing: 2

                Text {
                    text: SystemMonitorService.hostname
                    font.family: Appearance.font.family
                    font.bold: true
                    font.pixelSize: 16
                    color: Appearance.colors.colOnSurface
                }

                Text {
                    text: SystemMonitorService.kernel
                    font.family: Appearance.font.family
                    font.pixelSize: 10
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            Rectangle {
                height: 32
                width: 1
                color: Appearance.colors.colOutlineVariant
            }

            Row {
                spacing: 6

                Text {
                    text: "\uf0598 " + SystemMonitorService.uptime
                    font.family: Appearance.font.family
                    font.pixelSize: 11
                    color: Appearance.colors.colAccent
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: SystemMonitorService.cpuName
                    font.family: Appearance.font.family
                    font.pixelSize: 11
                    color: Appearance.colors.colOnSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Metrics grid
        GridLayout {
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            // CPU
            Rectangle {
                width: 210
                height: 110
                radius: Appearance.rounding.roundedMd
                color: Appearance.colors.colLayer1Hover

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Row {
                        spacing: 6

                        Text {
                            text: SystemMonitorService.cpuIcon
                            font.family: Appearance.font.family
                            font.pixelSize: 14
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Text {
                            text: "CPU"
                            font.family: Appearance.font.family
                            font.pixelSize: 12
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Text {
                            text: SystemMonitorService.cpuTemp > 0 ? SystemMonitorService.cpuTemp + "°C" : ""
                            font.family: Appearance.font.family
                            font.pixelSize: 10
                            color: SystemMonitorService.tempColor(SystemMonitorService.cpuTemp)
                        }
                    }

                    Sparkline {
                        width: 170
                        height: 36
                        values: SystemMonitorService.cpuHistory
                        maxValue: 100
                        color: SystemMonitorService.usageColor(SystemMonitorService.cpuUsage)
                    }

                    Text {
                        text: SystemMonitorService.cpuUsage + "%"
                        font.family: Appearance.font.family
                        font.pixelSize: 20
                        font.bold: true
                        color: SystemMonitorService.usageColor(SystemMonitorService.cpuUsage)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Memory
            Rectangle {
                width: 210
                height: 110
                radius: Appearance.rounding.roundedMd
                color: Appearance.colors.colLayer1Hover

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Row {
                        spacing: 6

                        Text {
                            text: "\ue323"
                            font.family: Appearance.font.family
                            font.pixelSize: 14
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Text {
                            text: "Memory"
                            font.family: Appearance.font.family
                            font.pixelSize: 12
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }

                    Sparkline {
                        width: 170
                        height: 36
                        values: SystemMonitorService.memHistory
                        maxValue: 100
                        color: Appearance.colors.colAccent
                    }

                    Text {
                        text: SystemMonitorService.memUsage + "%"
                        font.family: Appearance.font.family
                        font.pixelSize: 20
                        font.bold: true
                        color: SystemMonitorService.usageColor(SystemMonitorService.memUsage)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: SystemMonitorService.formatBytes(SystemMonitorService.memUsed) + " / " + SystemMonitorService.formatBytes(SystemMonitorService.memTotal)
                        font.family: Appearance.font.family
                        font.pixelSize: 9
                        color: Appearance.colors.colOnSurfaceVariant
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // GPU (if available)
            Rectangle {
                width: 210
                height: 110
                radius: Appearance.rounding.roundedMd
                color: Appearance.colors.colLayer1Hover
                visible: hasGpu

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Row {
                        spacing: 6

                        Text {
                            text: SystemMonitorService.gpuIcon
                            font.family: Appearance.font.family
                            font.pixelSize: 14
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Text {
                            text: SystemMonitorService.gpuName
                            font.family: Appearance.font.family
                            font.pixelSize: 12
                            color: Appearance.colors.colOnSurfaceVariant
                            elide: Text.ElideRight
                        }
                    }

                    Sparkline {
                        width: 170
                        height: 36
                        values: SystemMonitorService.gpuHistory
                        maxValue: 100
                        color: Appearance.colors.colSuccess
                    }

                    Text {
                        text: SystemMonitorService.gpuUsage + "%"
                        font.family: Appearance.font.family
                        font.pixelSize: 20
                        font.bold: true
                        color: Appearance.colors.colSuccess
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Network
            Rectangle {
                width: 210
                height: 110
                radius: Appearance.rounding.roundedMd
                color: Appearance.colors.colLayer1Hover

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Row {
                        spacing: 6

                        Text {
                            text: "\uf01e"
                            font.family: Appearance.font.family
                            font.pixelSize: 14
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Text {
                            text: SystemMonitorService.netInterface || "Network"
                            font.family: Appearance.font.family
                            font.pixelSize: 12
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }

                    Row {
                        spacing: 20
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            Text {
                                text: "\uf019"
                                font.family: Appearance.font.family
                                font.pixelSize: 11
                                color: Appearance.colors.colSuccess
                            }
                            Text {
                                text: SystemMonitorService.formatSpeed(SystemMonitorService.netDown)
                                font.family: Appearance.font.family
                                font.pixelSize: 12
                                color: Appearance.colors.colSuccess
                            }
                        }

                        Column {
                            Text {
                                text: "\uf01b"
                                font.family: Appearance.font.family
                                font.pixelSize: 11
                                color: Appearance.colors.colWarning
                            }
                            Text {
                                text: SystemMonitorService.formatSpeed(SystemMonitorService.netUp)
                                font.family: Appearance.font.family
                                font.pixelSize: 12
                                color: Appearance.colors.colWarning
                            }
                        }
                    }
                }
            }
        }
    }
}
