import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

DashboardWidgetBlock {
    id: root

    title: "System Stats"

    // Disk usage polled locally: ResourceUsage exposes cpu/mem/swap but no disk props.
    property real _diskFraction: 0

    function _clamp01(v) {
        return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0
    }

    function _gb(kb) {
        const v = Number(kb)
        return (isFinite(v) ? v : 0) / 1048576
    }

    readonly property real _cpuFraction: _clamp01(ResourceUsage?.cpuUsage ?? 0)
    readonly property real _memFraction: _clamp01(ResourceUsage?.memoryUsedPercentage ?? 0)
    readonly property string _memText: _gb(ResourceUsage?.memoryUsed).toFixed(1) + " / " + _gb(ResourceUsage?.memoryTotal).toFixed(1) + " GB"
    readonly property string _netText: "↓ " + (ResourceUsage?.downloadSpeedFormatted ?? "--") + "   ↑ " + (ResourceUsage?.uploadSpeedFormatted ?? "--")

    component StatRow: ColumnLayout {
        id: statRow
        required property string label
        required property string value
        property real fraction: 0
        property bool showBar: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: statRow.label
                font.pixelSize: 11
                color: Appearance.colors.colOnSurfaceVariant
                Layout.fillWidth: true
            }
            Text {
                text: statRow.value
                font.pixelSize: 11
                color: Appearance.colors.colOnSurface
                horizontalAlignment: Text.AlignRight
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            visible: statRow.showBar
            radius: 2
            color: Appearance.colors.colSecondaryContainer

            Rectangle {
                width: parent.width * statRow.fraction
                height: parent.height
                radius: 2
                color: Appearance.colors.colPrimary
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 38 // clear the block title (12 margin + title line + 8 spacing)
        spacing: 8

        StatRow {
            Layout.fillWidth: true
            label: "CPU"
            value: (root._cpuFraction * 100).toFixed(1) + "%"
            fraction: root._cpuFraction
        }
        StatRow {
            Layout.fillWidth: true
            label: "RAM"
            value: root._memText
            fraction: root._memFraction
        }
        StatRow {
            Layout.fillWidth: true
            label: "Disk"
            value: (root._diskFraction * 100).toFixed(1) + "%"
            fraction: root._diskFraction
        }
        StatRow {
            Layout.fillWidth: true
            label: "Net"
            value: root._netText
            showBar: false
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -kP / | awk 'NR==2 {print $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = parseFloat(text);
                if (!isNaN(pct))
                    root._diskFraction = root._clamp01(pct / 100);
            }
        }
    }
}
