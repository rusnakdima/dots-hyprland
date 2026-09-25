pragma Singleton
pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    property int clockTick: 0
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockTick++
    }

    property var clock: SystemClock {
        id: clock
        precision: {
            if (Config.options.time.secondPrecision || GlobalStates.screenLocked)
                return SystemClock.Seconds;
            return SystemClock.Minutes;
        }
    }
    property string time: {
        let tick = clockTick;
        let fmt = Config.options.time.format;
        if (!fmt) fmt = "hh:mm";
        if (Config.options.time.secondPrecision)
            fmt = fmt + ":ss";
        return Qt.locale().toString(clock.date, fmt);
    }
    property string shortDate: {
        let tick = clockTick;
        let fmt = Config.options.time.shortDateFormat;
        if (!fmt) fmt = "dd/MM";
        return Qt.locale().toString(clock.date, fmt);
    }
    property string date
    function updateDate() {
        let fmt = Config.options.time.dateWithYearFormat;
        date = Qt.locale().toString(clock.date, fmt || "dd/MM/yyyy");
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateDate()
    }
    Component.onCompleted: updateDate()
    property string longDate: {
        let tick = clockTick;
        let fmt = Config.options.time.dateWithYearFormat;
        if (!fmt) fmt = "dddd, dd/MM";
        return Qt.locale().toString(clock.date, fmt);
    }
    property string collapsedCalendarFormat: Qt.locale().toString(clock.date, "dddd, MMMM dd")
    property string uptime: "0h, 0m"

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            fileUptime.reload();
            const textUptime = fileUptime.text();
            const uptimeSeconds = Number(textUptime.split(" ")[0] ?? 0);

            // Convert seconds to days, hours, and minutes
            const days = Math.floor(uptimeSeconds / 86400);
            const hours = Math.floor((uptimeSeconds % 86400) / 3600);
            const minutes = Math.floor((uptimeSeconds % 3600) / 60);

            // Build the formatted uptime string
            let formatted = "";
            if (days > 0)
                formatted += `${days}d`;
            if (hours > 0)
                formatted += `${formatted ? ", " : ""}${hours}h`;
            if (minutes > 0 || !formatted)
                formatted += `${formatted ? ", " : ""}${minutes}m`;
            uptime = formatted;
            interval = Config.options?.resources?.updateInterval ?? 3000;
        }
    }

    FileView {
        id: fileUptime

        path: "/proc/uptime"
    }
}
