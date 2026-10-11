pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services
import "../rows/"

// Background widget settings: clock and weather
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    // ================= WIDGETS =================
    SettingsGroup {
        title: "Widgets"

        ToggleRow {
            label: "Clock widget"
            description: "Show clock widget on the background"
            path: "background.widgets.clock.enable"
        }

        ToggleRow {
            label: "Weather widget"
            description: "Show weather widget on the background"
            path: "background.widgets.weather.enable"
        }
    }

    // ================= CLOCK OPTIONS =================
    SettingsGroup {
        title: "Clock Options"

        SelectRow {
            label: "Clock style"
            description: "Visual style of the clock widget"
            path: "background.widgets.clock.style"
            options: [
                { label: "Cookie", value: "cookie" },
                { label: "Digital", value: "digital" }
            ]
        }

        StepperRow {
            label: "Cookie sides"
            description: "Number of sides on the cookie clock"
            path: "background.widgets.clock.cookie.sides"
            from: 4
            to: 32
        }

        SelectRow {
            label: "Hour hand style"
            description: "Style of the hour hand"
            path: "background.widgets.clock.cookie.hourHandStyle"
            options: [
                { label: "Classic", value: "classic" },
                { label: "Fill", value: "fill" },
                { label: "Hollow", value: "hollow" },
                { label: "Hide", value: "hide" }
            ]
        }
    }
}
