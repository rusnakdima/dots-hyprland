pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import "../../../components/"

// Weather widget with WeatherService current + 7-day forecast and HolidayService calendar holidays
Item {
    id: root

    property var config: ({})

    readonly property var current: WeatherService.current
    readonly property var today: WeatherService.daily[0] ?? null

    onVisibleChanged: {
        if (visible)
            WeatherService.refresh(false);
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Current conditions card
        Rectangle {
            width: parent.width
            height: 160
            radius: Appearance.rounding.roundedLg
            color: Appearance.colors.colLayer1Hover

            Column {
                anchors.centerIn: parent
                spacing: 8

                // Location
                Row {
                    spacing: 6
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: "\uf034e"
                        font.family: Appearance.font.family
                        font.pixelSize: 14
                        color: Appearance.colors.colAccent
                    }

                    Text {
                        text: WeatherService.location || "Loading..."
                        font.family: Appearance.font.family
                        font.pixelSize: 12
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    Text {
                        text: WeatherService.lastUpdate > 0 ? "Updated " + Qt.formatTime(new Date(WeatherService.lastUpdate), "hh:mm") : ""
                        font.family: Appearance.font.family
                        font.pixelSize: 10
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                // Conditions
                Row {
                    spacing: 16
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Weather icon and temp
                    Row {
                        spacing: 12
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: current ? WeatherService.icon(current.code, current.isDay) : "\uf00d"
                            font.family: Appearance.font.family
                            font.pixelSize: 54
                            color: Appearance.colors.colAccent
                        }

                        Column {
                            spacing: 2

                            Text {
                                text: (current?.temp ?? 0) + "°"
                                font.family: Appearance.font.family
                                font.pixelSize: 36
                                font.bold: true
                                color: Appearance.colors.colOnSurface
                            }

                            Text {
                                text: current ? WeatherService.description(current.code) : ""
                                font.family: Appearance.font.family
                                font.pixelSize: 13
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            Text {
                                text: "Feels " + (current?.feelsLike ?? 0) + "°"
                                font.family: Appearance.font.family
                                font.pixelSize: 11
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }

                    // Details
                    GridLayout {
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 4

                        DetailTile {
                            icon: "\uf058e"
                            label: "Humidity"
                            value: (current?.humidity ?? 0) + "%"
                        }

                        DetailTile {
                            icon: "\uf059d"
                            label: "Wind"
                            value: (current?.wind ?? 0) + " km/h"
                        }

                        DetailTile {
                            icon: "\uf0599"
                            label: "UV"
                            value: (current?.uv ?? 0) + ""
                        }

                        DetailTile {
                            icon: "\uf059c"
                            label: "Sunrise"
                            value: today ? WeatherService.formatTime(today.sunrise) : ""
                            accent: Appearance.colors.colWarning
                        }

                        DetailTile {
                            icon: "\uf059b"
                            label: "Sunset"
                            value: today ? WeatherService.formatTime(today.sunset) : ""
                            accent: Appearance.colors.colWarning
                        }

                        DetailTile {
                            icon: "\uf005d"
                            label: "High/Low"
                            value: (today?.max ?? 0) + "° / " + (today?.min ?? 0) + "°"
                        }
                    }
                }
            }
        }

        // 7-day forecast
        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: WeatherService.daily.slice(0, 7)

                Rectangle {
                    width: 66
                    height: 100
                    radius: Appearance.rounding.roundedMd
                    color: Appearance.colors.colLayer1Hover

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: {
                                const d = new Date(modelData.date);
                                return d.toLocaleDateString(Qt.locale(), "ddd");
                            }
                            font.family: Appearance.font.family
                            font.pixelSize: 11
                            color: Appearance.colors.colOnSurfaceVariant
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: WeatherService.icon(modelData.code, true)
                            font.family: Appearance.font.family
                            font.pixelSize: 20
                            color: Appearance.colors.colAccent
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: modelData.max + "°"
                            font.family: Appearance.font.family
                            font.pixelSize: 12
                            font.bold: true
                            color: Appearance.colors.colOnSurface
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: modelData.min + "°"
                            font.family: Appearance.font.family
                            font.pixelSize: 11
                            color: Appearance.colors.colOnSurfaceVariant
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        if (modelData.precipProb > 0) {
                            Text {
                                text: modelData.precipProb + "%"
                                font.family: Appearance.font.family
                                font.pixelSize: 9
                                color: Appearance.colors.colAccent
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }

        // Holiday
        Text {
            text: {
                const today = new Date();
                const holiday = HolidayService.holiday(today.getFullYear(), today.getMonth() + 1, today.getDate());
                return holiday ? "\uf073 " + holiday.name : "";
            }
            font.family: Appearance.font.family
            font.pixelSize: 12
            color: Appearance.colors.colAccent
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Loading/error state
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        visible: !WeatherService.available

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "\uf05aa"
                font.family: Appearance.font.family
                font.pixelSize: 40
                color: Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: WeatherService.error || "Weather unavailable"
                font.family: Appearance.font.family
                font.pixelSize: 12
                color: Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }

            MaterialSymbol {
                text: "refresh"
                iconSize: 20
                color: Appearance.colors.colAccent
                anchors.horizontalCenter: parent.horizontalCenter
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WeatherService.refresh(true)
                }
            }
        }
    }
}
