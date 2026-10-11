import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    readonly property string description: {
        if (!WeatherService.current) return "";
        return WeatherService.description(WeatherService.current.code);
    }

    ColumnLayout {
        id: mainLayout
        implicitWidth: 340
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heroLayout.implicitHeight + 32
            radius: Appearance.rounding.large
            bottomLeftRadius: Appearance.rounding.small
            bottomRightRadius: Appearance.rounding.small
            color: Appearance.colors.colPrimaryContainer

            ColumnLayout {
                id: heroLayout
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 0

                        RowLayout {
                            spacing: 4

                            MaterialSymbol {
                                text: "location_on"
                                fill: 1
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnPrimaryContainer
                            }

                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: WeatherService.location || ""
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }

                        StyledText {
                            text: WeatherService.current ? WeatherService.current.temp + "°" : "--°"
                            font.family: Appearance.font.family.expressive
                            font.pixelSize: 64
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.description
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                        }

                        StyledText {
                            visible: WeatherService.current?.feelsLike !== undefined
                            text: Translation.tr("Feels like %1°").arg(WeatherService.current?.feelsLike ?? "--")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.75
                        }
                    }

                    MaterialShapeWrappedMaterialSymbol {
                        Layout.alignment: Qt.AlignTop
                        shape: MaterialShape.Shape.Sunny
                        text: WeatherService.current ? WeatherService.icon(WeatherService.current.code, WeatherService.current.isDay) : "cloud"
                        fill: 1
                        iconSize: 44
                        implicitSize: 92
                        color: Appearance.colors.colPrimary
                        colSymbol: Appearance.colors.colOnPrimary
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    SunChip {
                        icon: "wb_twilight"
                        label: WeatherService.sunrise || "--"
                    }

                    SunChip {
                        icon: "bedtime"
                        label: WeatherService.sunset || "--"
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 4
            columnSpacing: 4
            uniformCellWidths: true

            WeatherCard {
                title: Translation.tr("Wind")
                symbol: "air"
                value: WeatherService.current ? `${WeatherService.current.wind} m/s` : "--"
            }
            WeatherCard {
                title: Translation.tr("Humidity")
                symbol: "humidity_low"
                value: WeatherService.current ? `${WeatherService.current.humidity}%` : "--"
            }
            WeatherCard {
                title: Translation.tr("UV Index")
                symbol: "wb_sunny"
                value: WeatherService.current?.uv !== undefined ? `${WeatherService.current.uv}` : "--"
            }
            WeatherCard {
                title: Translation.tr("Precipitation")
                symbol: "rainy_light"
                value: WeatherService.current?.precip !== undefined ? `${WeatherService.current.precip} mm` : "--"
            }
        }
    }

    component SunChip: Rectangle {
        id: chip
        required property string icon
        required property string label
        implicitWidth: chipRow.implicitWidth + 20
        implicitHeight: chipRow.implicitHeight + 10
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                text: chip.icon
                fill: 1
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnPrimary
            }

            StyledText {
                text: chip.label
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colOnPrimary
            }
        }
    }
}
