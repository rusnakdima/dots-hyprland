pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.widgets
import "../"
import QtQuick
import QtQuick.Layouts

DashboardWidgetBlock {
    id: root

    title: "Calendar"

    property int monthShift: 0

    readonly property var viewingDate: {
        var d = new Date()
        var m = d.getMonth() + monthShift
        var y = d.getFullYear()
        y += Math.floor(m / 12)
        m = ((m % 12) + 12) % 12
        return new Date(y, m, 1)
    }

    readonly property var locale: Qt.locale(Config.options.calendar.locale)
    readonly property int todayYear: new Date().getFullYear()
    readonly property int todayMonth: new Date().getMonth()
    readonly property int todayDay: new Date().getDate()

    function _getMonthDays(month, year) {
        var leap = (year % 400 === 0 || (year % 4 === 0 && year % 100 !== 0))
        if ((month <= 7 && month % 2 === 1) || (month >= 8 && month % 2 === 0)) return 31
        if (month === 2 && leap) return 29
        if (month === 2 && !leap) return 28
        return 30
    }

    function _prevMonth() { monthShift-- }
    function _nextMonth() { monthShift++ }
    function _goToday() { monthShift = 0 }

    // Build 6x7 grid: array of { day, date, isCurrentMonth, isToday }
    readonly property var calendarGrid: {
        var year = viewingDate.getFullYear()
        var month = viewingDate.getMonth()
        var daysInMonth = _getMonthDays(month, year)
        var prevMonth = month === 0 ? 11 : month - 1
        var prevYear = month === 0 ? year - 1 : year
        var daysInPrevMonth = _getMonthDays(prevMonth, prevYear)
        var nextMonth = month === 11 ? 0 : month + 1
        var nextYear = month === 11 ? year + 1 : year

        var firstDay = new Date(year, month, 1).getDay()
        // Sunday = 0, no adjustment needed
        var startDay = firstDay

        var grid = []
        var day = 1
        var nextDay = 1

        for (var row = 0; row < 6; row++) {
            var week = []
            for (var col = 0; col < 7; col++) {
                var cellIndex = row * 7 + col
                if (cellIndex < startDay) {
                    // Previous month
                    var pd = daysInPrevMonth - startDay + col + 1
                    var isToday = (prevYear === todayYear && prevMonth === todayMonth && pd === todayDay && monthShift === 0)
                    week.push({
                        day: pd,
                        date: new Date(prevYear, prevMonth, pd),
                        isCurrentMonth: false,
                        isToday: isToday
                    })
                } else if (day <= daysInMonth) {
                    // Current month
                    var isToday = (year === todayYear && month === todayMonth && day === todayDay && monthShift === 0)
                    week.push({
                        day: day,
                        date: new Date(year, month, day),
                        isCurrentMonth: true,
                        isToday: isToday
                    })
                    day++
                } else {
                    // Next month
                    var isToday = (nextYear === todayYear && nextMonth === todayMonth && nextDay === todayDay && monthShift === 0)
                    week.push({
                        day: nextDay,
                        date: new Date(nextYear, nextMonth, nextDay),
                        isCurrentMonth: false,
                        isToday: isToday
                    })
                    nextDay++
                }
            }
            grid.push(week)
        }
        return grid
    }

    // Day-of-week labels (Sun-first)
    readonly property list<var> weekDays: [
        { short: "Su" },
        { short: "Mo" },
        { short: "Tu" },
        { short: "We" },
        { short: "Th" },
        { short: "Fr" },
        { short: "Sa" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 38
        spacing: 4

        // Header: month/year + nav arrows
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            MaterialSymbol {
                text: "chevron_left"
                iconSize: 16
                color: Appearance.colors.colOnSurfaceVariant
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _prevMonth()
                }
            }

            Text {
                Layout.fillWidth: true
                text: viewingDate.toLocaleDateString(root.locale, "MMMM yyyy")
                font.pixelSize: 13
                font.bold: true
                color: Appearance.colors.colOnSurface
                horizontalAlignment: Text.AlignHCenter
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _goToday()
                }
            }

            MaterialSymbol {
                text: "chevron_right"
                iconSize: 16
                color: Appearance.colors.colOnSurfaceVariant
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _nextMonth()
                }
            }
        }

        // Day-of-week header
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: root.weekDays
                delegate: Text {
                    Layout.fillWidth: true
                    text: modelData.short
                    font.pixelSize: 10
                    font.bold: true
                    color: Appearance.colors.colOnSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Day grid (6 rows x 7 cols)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: root.calendarGrid

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    required property var modelData

                    Repeater {
                        model: modelData

                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            required property var modelData
                            property var cell: modelData

                            // Day number
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 22
                                radius: height / 2
                                color: cell.isToday
                                    ? Appearance.colors.colPrimary
                                    : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: cell.day
                                    font.pixelSize: 11
                                    font.bold: cell.isToday || !cell.isCurrentMonth
                                    color: cell.isToday
                                        ? Appearance.colors.colOnPrimary
                                        : cell.isCurrentMonth
                                            ? Appearance.colors.colOnSurface
                                            : Appearance.colors.colOnSurfaceVariant
                                    opacity: cell.isCurrentMonth ? 1.0 : 0.45
                                }
                            }

                            // Event dots (up to 3)
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 4
                                spacing: 1
                                anchors.horizontalCenter: parent.horizontalCenter

                                property var dayEvents: IcsParser.eventsOnDate(cell.date)
                                property int dotCount: Math.min(3, dayEvents.length)

                                Repeater {
                                    model: dotCount

                                    delegate: Rectangle {
                                        width: 3
                                        height: 3
                                        radius: 1.5
                                        color: Appearance.colors.colAccent
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
