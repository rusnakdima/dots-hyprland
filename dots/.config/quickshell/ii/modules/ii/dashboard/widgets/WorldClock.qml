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

    // Timezone offset map in hours (handles common timezones)
    property var timezoneOffsets: {
        return {
            "America/New_York": -5,
            "America/Chicago": -6,
            "America/Denver": -7,
            "America/Los_Angeles": -8,
            "America/Anchorage": -9,
            "Pacific/Honolulu": -10,
            "Europe/London": 0,
            "Europe/Paris": 1,
            "Europe/Berlin": 1,
            "Europe/Moscow": 3,
            "Asia/Dubai": 4,
            "Asia/Kolkata": 5.5,
            "Asia/Bangkok": 7,
            "Asia/Shanghai": 8,
            "Asia/Tokyo": 9,
            "Asia/Seoul": 9,
            "Australia/Sydney": 11,
            "Pacific/Auckland": 13
        }
    }

    // Get timezone offset in hours
    function getTimezoneOffset(timezone) {
        // Check our map first
        if (timezoneOffsets[timezone] !== undefined) {
            return timezoneOffsets[timezone]
        }

        // For unknown timezones, try to parse from name
        // Format is typically "Region/City"
        const parts = timezone.split('/')
        if (parts.length >= 2) {
            const city = parts[parts.length - 1].toLowerCase()
            // Try common city mappings
            const cityOffsets = {
                "new_york": -5, "los_angeles": -8, "chicago": -6, "denver": -7,
                "london": 0, "paris": 1, "berlin": 1, "tokyo": 9,
                "shanghai": 8, "sydney": 11, "dubai": 4, "mumbai": 5.5,
                "kolkata": 5.5, "hong_kong": 8, "singapore": 8, "seoul": 9
            }
            if (cityOffsets[city] !== undefined) {
                return cityOffsets[city]
            }
        }

        return 0 // Default to UTC
    }

    // Get configured timezones or use defaults
    property var timezones: Config.options.dashboard?.widgetTypes?.worldClock?.timezones
        ?? ["America/New_York", "Europe/London"]

    // Update time every second
    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockUpdate()
    }

    property date currentTime: new Date()

    function clockUpdate() {
        currentTime = new Date()
    }

    // Get local timezone offset
    function getLocalOffset() {
        // Local offset in minutes, convert to hours
        return -currentTime.getTimezoneOffset() / 60
    }

    // Format time for a specific timezone
    function formatTime(date, offsetHours) {
        const totalMinutes = date.getUTCHours() * 60 + date.getUTCMinutes()
        const localTotalMinutes = totalMinutes + getLocalOffset() * 60
        const targetMinutes = localTotalMinutes + offsetHours * 60

        // Normalize to 0-1439 range
        let normalizedMinutes = targetMinutes % (24 * 60)
        if (normalizedMinutes < 0) normalizedMinutes += 24 * 60

        const hours = Math.floor(normalizedMinutes / 60)
        const minutes = normalizedMinutes % 60

        return String(hours).padStart(2, '0') + ":" + String(minutes).padStart(2, '0')
    }

    // Format date for a specific timezone
    function formatDate(date, offsetHours) {
        const totalMinutes = date.getUTCFullYear() * 525600 +
                             (date.getUTCMonth() * 43200) +
                             (date.getUTCDate() * 1440) +
                             date.getUTCHours() * 60 +
                             date.getUTCMinutes()
        const targetMinutes = totalMinutes + offsetHours * 60

        // Calculate target date components
        let totalDays = Math.floor(targetMinutes / 1440)
        let mins = targetMinutes % 1440
        if (mins < 0) {
            totalDays -= 1
            mins += 1440
        }

        // Simple date calculation from epoch
        const d = new Date(0)
        d.setUTCDate(1)
        d.setUTCMonth(0)

        // Approximate year
        let year = 1970
        let month = 0
        let day = 1

        // Days per month
        const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

        while (totalDays > 365) {
            const isLeap = (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0
            const daysInYear = isLeap ? 366 : 365
            if (totalDays >= daysInYear) {
                totalDays -= daysInYear
                year++
            } else {
                break
            }
        }

        // Adjust for leap year
        if ((year % 4 === 0 && year % 100 !== 0) || year % 400 === 0) {
            daysInMonth[1] = 29
        }

        while (totalDays > daysInMonth[month]) {
            totalDays -= daysInMonth[month]
            month++
        }

        day = totalDays + 1

        const weekday = new Date(Date.UTC(year, month, day)).getUTCDay()
        const weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        return weekdayNames[weekday] + ", " + monthNames[month] + " " + day
    }

    // Get timezone display name
    function getTimezoneName(timezone) {
        try {
            const parts = timezone.split('/')
            const city = parts[parts.length - 1].replace(/_/g, ' ')
            return city
        } catch (e) {
            return timezone
        }
    }

    // Get UTC offset string
    function getUtcOffset(offsetHours) {
        const sign = offsetHours >= 0 ? '+' : ''
        const hours = Math.floor(Math.abs(offsetHours))
        const mins = (Math.abs(offsetHours) % 1) * 60
        if (mins === 0) {
            return 'UTC' + sign + hours
        }
        return 'UTC' + sign + hours + ':' + String(Math.round(mins)).padStart(2, '0')
    }

    // Check if this is the local timezone
    function isLocalTimezone(timezone) {
        try {
            // Assume "Local" timezone - we always show local first
            return false
        } catch (e) {
            return false
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        anchors.topMargin: 38
        spacing: 8

        // Local time (always shown first)
        ClockCard {
            timezoneName: "Local"
            time: {
                const h = currentTime.getHours()
                const m = currentTime.getMinutes()
                return String(h).padStart(2, '0') + ":" + String(m).padStart(2, '0')
            }
            date: {
                const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                return days[currentTime.getDay()] + ", " + months[currentTime.getMonth()] + " " + currentTime.getDate()
            }
            utcOffset: "UTC" + (getLocalOffset() >= 0 ? '+' : '') + getLocalOffset()
            isLocal: true
        }

        // Additional configured timezones
        Repeater {
            model: root.timezones.length

            delegate: ClockCard {
                timezoneName: getTimezoneName(root.timezones[index])
                time: formatTime(root.currentTime, getTimezoneOffset(root.timezones[index]))
                date: formatDate(root.currentTime, getTimezoneOffset(root.timezones[index]))
                utcOffset: getUtcOffset(getTimezoneOffset(root.timezones[index]))
                isLocal: false
            }
        }
    }

    component ClockCard: Rectangle {
        id: clockCard
        required property string timezoneName
        required property string time
        required property string date
        required property string utcOffset
        property bool isLocal: false

        width: parent ? parent.width : 180
        height: 70
        radius: Appearance.rounding.normal
        color: isLocal ? Appearance.colors.colSurfaceContainerHighest : Appearance.colors.colLayer1

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            Row {
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: clockCard.timezoneName
                    font.family: Appearance.font.family
                    font.pixelSize: 11
                    font.bold: true
                    color: isLocal ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                }

                Text {
                    text: clockCard.utcOffset
                    font.family: Appearance.font.monospace
                    font.pixelSize: 9
                    color: Appearance.colors.colOnSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: clockCard.time
                font.family: Appearance.font.monospace
                font.pixelSize: 26
                font.bold: true
                color: Appearance.colors.colOnSurface
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: clockCard.date
                font.family: Appearance.font.family
                font.pixelSize: 10
                color: Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
