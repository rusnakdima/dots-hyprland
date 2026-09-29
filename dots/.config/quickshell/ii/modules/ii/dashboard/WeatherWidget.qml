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

        // Current conditions row: temp + details
        RowLayout {
            Layout.fillWidth: true
            visible: root.hasData
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "H: " + (Weather.data?.forecast?.[0]?.hi ?? "--")
                    font.pixelSize: 10
                    color: Appearance.colors.colOnSurfaceVariant
                }
                Text {
                    text: "L: " + (Weather.data?.forecast?.[0]?.lo ?? "--")
                    font.pixelSize: 10
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                horizontalAlignment: Text.AlignHCenter

                Text {
                    text: "Humidity"
                    font.pixelSize: 9
                    color: Appearance.colors.colOnSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: Weather.data?.humidity ?? "--"
                    font.pixelSize: 11
                    color: Appearance.colors.colOnSurface
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                horizontalAlignment: Text.AlignRight

                Text {
                    text: "Wind"
                    font.pixelSize: 9
                    color: Appearance.colors.colOnSurfaceVariant
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: Weather.data?.wind ?? "--"
                    font.pixelSize: 11
                    color: Appearance.colors.colOnSurface
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // 3-day forecast
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Forecast"
                font.pixelSize: 10
                font.bold: true
                color: Appearance.colors.colOnSurfaceVariant
                Layout.preferredWidth: 55
            }
        }

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
