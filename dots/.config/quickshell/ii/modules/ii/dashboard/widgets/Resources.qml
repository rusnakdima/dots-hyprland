pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DashboardWidgetBlock {
    id: root

    title: "Resources"

    // Default size
    implicitWidth: 280
    implicitHeight: 200

    // Expandable - shows 2 rows by default, more when expanded
    property bool expanded: false

    // Heavy collectors only run while visible
    onVisibleChanged: visible ? SystemMonitorService.acquire() : SystemMonitorService.release()
    Component.onDestruction: {
        if (visible)
            SystemMonitorService.release()
    }

    readonly property bool hasGpu: SystemMonitorService.gpuType !== "unknown"

    // Disk usage polled locally (ResourceUsage doesn't expose disk)
    property real _diskFraction: 0

    function _clamp01(v) {
        return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0
    }

    function _gb(kb) {
        const v = Number(kb)
        return (isFinite(v) ? v : 0) / 1048576
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: _diskProc.running = true
    }

    Process {
        id: _diskProc
        command: ["bash", "-c", "df -kP / | awk 'NR==2 {print $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = parseFloat(text)
                if (!isNaN(pct))
                    root._diskFraction = root._clamp01(pct / 100)
            }
        }
    }

    // Metric row component
    component MetricRow: ColumnLayout {
        id: metricRow
        required property string label
        required property string value
        required property real fraction
        property color barColor: Appearance.colors.colPrimary
        property var historyValues: []
        property bool showSparkline: true
        property int sparklinePoints: 40

        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: metricRow.label
                font.pixelSize: 11
                color: Appearance.colors.colOnSurfaceVariant
                Layout.fillWidth: true
            }

            Text {
                text: metricRow.value
                font.pixelSize: 11
                color: Appearance.colors.colOnSurface
                horizontalAlignment: Text.AlignRight
            }
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: 2
            color: Appearance.colors.colSecondaryContainer

            Rectangle {
                width: parent.width * metricRow.fraction
                height: parent.height
                radius: 2
                color: metricRow.barColor
            }
        }

        // Mini sparkline
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: metricRow.showSparkline ? 28 : 0
            Layout.topMargin: 2
            visible: metricRow.showSparkline && metricRow.historyValues.length > 1
            color: "transparent"
            clip: true

            Sparkline {
                anchors.fill: parent
                values: metricRow.historyValues
                maxValue: 100
                lineWidth: 1.5
                color: metricRow.barColor
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 38
        spacing: 8

        // CPU row
        MetricRow {
            Layout.fillWidth: true
            label: "CPU"
            value: Math.round((ResourceUsage?.cpuUsage ?? 0) * 100) + "%"
            fraction: root._clamp01(ResourceUsage?.cpuUsage ?? 0)
            barColor: SystemMonitorService.usageColor?.(Math.round((ResourceUsage?.cpuUsage ?? 0) * 100)) ?? Appearance.colors.colPrimary
            historyValues: ResourceUsage?.cpuUsageHistory?.slice(-40) ?? []
        }

        // Memory row
        MetricRow {
            Layout.fillWidth: true
            label: "RAM"
            value: _gb(ResourceUsage?.memoryUsed).toFixed(1) + " / " + _gb(ResourceUsage?.memoryTotal).toFixed(1) + " GB"
            fraction: root._clamp01(ResourceUsage?.memoryUsedPercentage ?? 0)
            barColor: Appearance.colors.colAccent
            historyValues: ResourceUsage?.memoryUsageHistory?.slice(-40) ?? []
        }

        // Disk row (expanded only)
        MetricRow {
            Layout.fillWidth: true
            label: "Disk"
            value: (root._diskFraction * 100).toFixed(1) + "%"
            fraction: root._diskFraction
            barColor: Appearance.colors.colTertiary
            showSparkline: false
            visible: root.expanded
        }

        // GPU row (expanded only, if available)
        MetricRow {
            Layout.fillWidth: true
            label: "GPU"
            value: SystemMonitorService.gpuUsage !== undefined ? SystemMonitorService.gpuUsage + "%" : "--"
            fraction: SystemMonitorService.gpuUsage !== undefined ? SystemMonitorService.gpuUsage / 100 : 0
            barColor: Appearance.colors.colSuccess
            historyValues: SystemMonitorService.gpuHistory?.slice(-40) ?? []
            showSparkline: SystemMonitorService.gpuHistory !== undefined
            visible: root.expanded && root.hasGpu
        }

        // Network row (expanded only)
        MetricRow {
            Layout.fillWidth: true
            label: "Net"
            value: "↓ " + (ResourceUsage?.downloadSpeedFormatted ?? "--") + "   ↑ " + (ResourceUsage?.uploadSpeedFormatted ?? "--")
            fraction: 0
            showSparkline: false
            visible: root.expanded
        }

        // Expand/collapse hint
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: root.expanded ? "▲ Less" : "▼ More"
                font.pixelSize: 10
                color: Appearance.colors.colOnSurfaceVariant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }
    }
}
