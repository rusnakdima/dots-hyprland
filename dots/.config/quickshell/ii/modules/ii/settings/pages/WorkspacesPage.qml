pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.services
import "../rows/"

// Workspace display settings
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    // ================= DISPLAY =================
    SettingsGroup {
        title: "Display"

        SliderRow {
            label: "Shown"
            description: "Number of workspace indicators to display"
            path: "bar.workspaces.shown"
            from: 1
            to: 20
            format: v => String(Math.round(v))
        }

        ToggleRow {
            label: "Show app icons"
            description: "Display icons of apps running on each workspace"
            path: "bar.workspaces.showAppIcons"
        }

        ToggleRow {
            label: "Monochrome icons"
            description: "Tint workspace app icons with the accent color"
            path: "bar.workspaces.monochromeIcons"
        }
    }

    // ================= NUMBERS =================
    SettingsGroup {
        title: "Numbers"

        ToggleRow {
            label: "Always show numbers"
            description: "Show workspace numbers even when the workspace has open windows"
            path: "bar.workspaces.alwaysShowNumbers"
        }

        SliderRow {
            label: "Show number delay"
            description: "Milliseconds to wait before showing workspace numbers on Super hold"
            path: "bar.workspaces.showNumberDelay"
            from: 0
            to: 1000
            stepSize: 50
            format: v => Math.round(v) + "ms"
        }

        TextFieldRow {
            label: "Number map"
            description: "Characters to show instead of numbers (JSON array, e.g. [\"a\",\"b\"])"
            path: "bar.workspaces.numberMap"
            placeholder: '["1", "2"]'
        }

        ToggleRow {
            label: "Use Nerd Font"
            description: "Render workspace numbers using Nerd Font icons"
            path: "bar.workspaces.useNerdFont"
        }
    }
}
