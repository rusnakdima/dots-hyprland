import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

DashboardWidgetBlock {
    id: root

    title: "Weather"

    // Service is ready only after a successful fetch (refineData sets lastRefresh).
    readonly property bool hasData: !!Weather.data?.lastRefresh
    readonly property string hintText: (Weather.city ?? "").trim() === "" ? "Set location in Settings → Services" : "Waiting for weather data…"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 38 // clear the block title (12 margin + title line + 8 spacing)
        spacing: 6

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.hasData

            Text {
                anchors.centerIn: parent
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: root.hintText
                font.pixelSize: 11
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        // Current conditions
        RowLayout {
            Layout.fillWidth: true
            visible: root.hasData
            spacing: 10

            MaterialSymbol {
                fill: 0
                text: Icons.getWeatherIcon(Weather.data?.wCode) ?? "cloud"
                iconSize: 38
                color: Appearance.colors.colOnSurface
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: Weather.data?.temp ?? "--°"
                    font.pixelSize: 24
                    font.bold: true
                    color: Appearance.colors.colOnSurface
                }
                Text {
                    text: Weather.data?.city ?? ""
                    font.pixelSize: 11
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }

        // 3-day forecast
        Repeater {
            model: Weather.data?.forecast ?? []

            delegate: RowLayout {
                Layout.fillWidth: true
                required property var modelData
                spacing: 6

                Text {
                    text: modelData.dayName
                    font.pixelSize: 11
                    color: Appearance.colors.colOnSurfaceVariant
                    Layout.preferredWidth: 30
                }
                MaterialSymbol {
                    fill: 0
                    text: Icons.getWeatherIcon(modelData.code) ?? "cloud"
                    iconSize: 16
                    color: Appearance.colors.colOnSurfaceVariant
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: modelData.hi
                    font.pixelSize: 11
                    color: Appearance.colors.colOnSurface
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: modelData.lo
                    font.pixelSize: 11
                    color: Appearance.colors.colOnSurfaceVariant
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
