pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io

/*
 * IcsParser — parses an ICS calendar file and returns structured event objects.
 *
 * Reads: ~/.config/ii/calendar.ics
 *
 * Supports:
 *   - VEVENT components
 *   - DTSTART / DTEND (date-only all-day or date-time with TZID)
 *   - SUMMARY / DESCRIPTION
 *   - RRULE for recurring events (recurrence expanded up to `maxDays` ahead)
 *
 * Returns array of event objects:
 *   { start: Date, end: Date, summary: string, description: string, isAllDay: bool }
 */
Singleton {
    id: root

    property string icsPath: StandardPaths.home + "/.config/ii/calendar.ics"
    property int   maxDays: 365 * 2  // how far ahead to expand recurring events

    FileView {
        id: fileView
        path: root.icsPath
        watchChanges: true
        onLoaded: root._parse(content)
        onLoadFailed: root._events = []
    }

    // ── Public API ───────────────────────────────────────────────────

    /* The parsed event array. Refreshes automatically when the file changes. */
    property var events: []

    /* All events happening on the given date (local time). */
    function eventsOnDate(date) {
        var d = new Date(date)
        d.setHours(0, 0, 0, 0)
        var endOfDay = new Date(d)
        endOfDay.setHours(23, 59, 59, 999)
        return events.filter(function(e) {
            return e.start <= endOfDay && e.end >= d
        })
    }

    // ── Private ─────────────────────────────────────────────────────

    function _parse(ics) {
        if (!ics || typeof ics !== "string") {
            root.events = []
            return
        }

        var lines = _ unfoldLines(ics)
        var components = _splitComponents(lines)
        var result = []

        for (var i = 0; i < components.length; i++) {
            var evs = _parseComponent(components[i])
            for (var j = 0; j < evs.length; j++) {
                result.push(evs[j])
            }
        }

        // Sort by start date
        result.sort(function(a, b) { return a.start - b.start })
        root.events = result
    }

    /* Unfold continuation lines (lines starting with space/tab → append to previous). */
    function _unfoldLines(text) {
        return text.replace(/\r\n?/g, "\n").split("\n")
    }

    /* Split into individual component blocks (BEGIN:VEVENT … END:VEVENT). */
    function _splitComponents(lines) {
        var blocks = []
        var current = []
        var inComponent = false

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            var upper = line.toUpperCase()

            if (upper === "BEGIN:VEVENT") {
                inComponent = true
                current = []
            } else if (upper === "END:VEVENT") {
                if (inComponent) blocks.push(current.slice())
                inComponent = false
            }

            if (inComponent) current.push(line)
        }
        return blocks
    }

    /* Parse a single VEVENT block into one or more event objects (unrolling RRULE). */
    function _parseComponent(lines) {
        var raw = {}
        for (var i = 0; i < lines.length; i++) {
            var idx = lines[i].indexOf(":")
            if (idx < 0) continue
            var keyPart = lines[i].slice(0, idx)
            var value   = lines[i].slice(idx + 1)

            // Handle parameters on the key (e.g. DTSTART;VALUE=DATE:20251011)
            var key = keyPart.split(";")[0].toUpperCase()

            if (raw[key] !== undefined) {
                // Prefer the first occurrence
                continue
            }
            raw[key] = value
        }

        var startRaw = raw["DTSTART"]
        var endRaw   = raw["DTEND"]
        var summary  = raw["SUMMARY"] || ""
        var desc     = raw["DESCRIPTION"] || ""
        var rruleRaw = raw["RRULE"]

        if (!startRaw) return []

        var startDt = _parseDateTime(startRaw)
        var endDt   = endRaw ? _parseDateTime(endRaw) : new Date(startDt.getTime() + 3600 * 1000)

        var isAllDay = startRaw.indexOf("T") < 0

        var events = []
        if (rruleRaw) {
            var rule = _parseRRule(rruleRaw)
            var occurrences = _expandRRule(startDt, endDt, rule)
            for (var k = 0; k < occurrences.length; k++) {
                events.push({
                    start:       occurrences[k].start,
                    end:         occurrences[k].end,
                    summary:     summary,
                    description: desc,
                    isAllDay:    isAllDay
                })
            }
        } else {
            events.push({
                start:       startDt,
                end:         endDt,
                summary:     summary,
                description: desc,
                isAllDay:    isAllDay
            })
        }
        return events
    }

    /* Parse ICS date or datetime string into a JS Date.
     * Handles VALUE=DATE (all-day) and VALUE=DATETIME (with optional TZID).
     */
    function _parseDateTime(raw) {
        // Strip VALUE= type prefix
        var s = raw.replace(/^[^:]+:/, "")
        s = s.trim()

        // All-day: DATE value, e.g. 20251011 or 20251011T000000Z
        if (s.length === 8) {
            // Pure date: YYYYMMDD — interpret as local midnight
            var y = parseInt(s.slice(0, 4))
            var m = parseInt(s.slice(4, 6)) - 1
            var d = parseInt(s.slice(6, 8))
            return new Date(y, m, d, 0, 0, 0, 0)
        }

        // Datetime: YYYYMMDDTHHMMSS or YYYYMMDDTHHMMSSZ
        var year   = parseInt(s.slice(0, 4))
        var month  = parseInt(s.slice(4, 6)) - 1
        var day    = parseInt(s.slice(6, 8))
        var hour   = parseInt(s.slice(9, 11)) || 0
        var minute = parseInt(s.slice(11, 13)) || 0
        var second = parseInt(s.slice(13, 15)) || 0

        var dt = new Date(year, month, day, hour, minute, second, 0)

        // UTC marker
        if (s.slice(-1) === "Z") {
            dt = new Date(dt.getTime() + dt.getTimezoneOffset() * 60000)
        }

        return dt
    }

    /* Parse an RRULE string into a plain object.
     * Supports: FREQ (DAILY/WEEKLY), INTERVAL, COUNT, UNTIL, BYDAY.
     */
    function _parseRRule(rrule) {
        var rule = {}
        var parts = rrule.split(";")
        for (var i = 0; i < parts.length; i++) {
            var idx = parts[i].indexOf("=")
            if (idx < 0) continue
            var k = parts[i].slice(0, idx).toUpperCase()
            var v = parts[i].slice(idx + 1)
            rule[k] = v
        }
        return rule
    }

    /* Expand a parsed RRULE into a list of { start, end } occurrences up to maxDays. */
    function _expandRRule(startDt, endDt, rule) {
        var freq    = rule["FREQ"] || "DAILY"
        var interval = parseInt(rule["INTERVAL"]) || 1
        var count   = parseInt(rule["COUNT"]) || 0
        var untilStr = rule["UNTIL"]
        var until   = untilStr ? _parseDateTime(untilStr) : new Date(startDt.getTime() + root.maxDays * 86400000)

        // Normalize until to midnight local for comparison
        var endBound = new Date(until)
        endBound.setHours(23, 59, 59, 999)

        var occurrences = []
        var current = new Date(startDt)
        var duration = endDt.getTime() - startDt.getTime()
        var byDay = rule["BYDAY"] ? rule["BYDAY"].split(",") : null
        var dayMap = { SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6 }

        var n = 0
        while (current <= endBound && (count === 0 || n < count) && n < 2000) {
            if (byDay) {
                var dow = current.getDay()
                var match = byDay.some(function(d) { return dayMap[d] === dow })
                if (match) {
                    occurrences.push({
                        start: new Date(current),
                        end:   new Date(current.getTime() + duration)
                    })
                    n++
                }
            } else {
                occurrences.push({
                    start: new Date(current),
                    end:   new Date(current.getTime() + duration)
                })
                n++
            }

            switch (freq) {
                case "DAILY":
                    current.setDate(current.getDate() + interval)
                    break
                case "WEEKLY":
                    current.setDate(current.getDate() + 7 * interval)
                    break
                case "MONTHLY":
                    current.setMonth(current.getMonth() + interval)
                    break
                case "YEARLY":
                    current.setFullYear(current.getFullYear() + interval)
                    break
                default:
                    current.setDate(current.getDate() + interval)
            }
        }

        return occurrences
    }
}
