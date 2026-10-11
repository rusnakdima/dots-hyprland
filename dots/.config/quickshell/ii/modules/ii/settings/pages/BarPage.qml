pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services
import "../rows/"

// Bar settings: style, position, dimensions, workspaces, elements, resources, util buttons
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    // ================= STYLE =================
    SettingsGroup {
        title: "Style"

        SelectRow {
            label: "Corner style"
            description: "How the bar corners are rendered"
            path: "bar.cornerStyle"
            options: [
                { label: "Hug", value: 0 },
                { label: "Float", value: 1 },
                { label: "Plain", value: 2 }
            ]
        }

        ToggleRow {
            label: "Borderless"
            description: "Disable grouping borders between bar items"
            path: "bar.borderless"
        }

        ToggleRow {
            label: "Bottom"
            description: "Position the bar at the bottom of the screen"
            path: "bar.bottom"
        }

        ToggleRow {
            label: "Show background"
            description: "Render the bar background"
            path: "bar.showBackground"
        }
    }

    // ================= DIMENSIONS =================
    SettingsGroup {
        title: "Dimensions"

        SliderRow {
            label: "Height"
            description: "Height of the bar in pixels"
            path: "bar.height"
            from: 24
            to: 48
            format: v => Math.round(v) + "px"
        }
    }

    // ================= WORKSPACES =================
    SettingsGroup {
        title: "Workspaces"

        SelectRow {
            label: "Style"
            description: "Visual style of workspace buttons"
            path: "bar.workspaces.style"
            options: [
                { label: "Default (pills)", value: "default" },
                { label: "Dots (animated)", value: "dots" },
                { label: "Gnome (stub)", value: "gnome" },
                { label: "Ticks (stub)", value: "ticks" }
            ]
        }

        SelectRow {
            label: "Indicator"
            description: "Indicator type for workspace buttons"
            path: "bar.workspaces.indicatorStyle"
            options: [
                { label: "Dot", value: "dot" },
                { label: "Icon", value: "icon" }
            ]
        }

        ToggleRow {
            label: "Show app icons"
            description: "Display application icons on workspace indicators"
            path: "bar.workspaces.showAppIcons"
        }

        ToggleRow {
            label: "Always show numbers"
            description: "Show workspace numbers even when using icons"
            path: "bar.workspaces.alwaysShowNumbers"
        }

        SliderRow {
            label: "Shown"
            description: "Number of workspace indicators to show"
            path: "bar.workspaces.shown"
            from: 1
            to: 20
            format: v => String(Math.round(v))
        }

        SliderRow {
            label: "Show number delay"
            description: "Delay before showing workspace numbers (ms)"
            path: "bar.workspaces.showNumberDelay"
            from: 0
            to: 1000
            stepSize: 50
            format: v => Math.round(v) + "ms"
        }

        ToggleRow {
            label: "Use Nerd Font"
            description: "Use Nerd Font icons for workspace numbers"
            path: "bar.workspaces.useNerdFont"
        }
    }

    // ================= ELEMENTS =================
    SettingsGroup {
        title: "Elements"

        ToggleRow {
            label: "Sidebar button"
            description: "Show sidebar toggle button"
            path: "bar.elements.sidebarButton"
        }

        ToggleRow {
            label: "Workspaces"
            description: "Show workspace indicators"
            path: "bar.elements.workspaces"
        }

        ToggleRow {
            label: "Notification indicator"
            description: "Show notification unread count"
            path: "bar.elements.notificationIndicator"
        }

        ToggleRow {
            label: "Clock"
            description: "Show clock element"
            path: "bar.elements.clock"
        }

        ToggleRow {
            label: "Battery"
            description: "Show battery status"
            path: "bar.elements.battery"
        }

        ToggleRow {
            label: "Audio"
            description: "Show audio status"
            path: "bar.elements.audio"
        }

        ToggleRow {
            label: "Network"
            description: "Show network status"
            path: "bar.elements.network"
        }

        ToggleRow {
            label: "Weather"
            description: "Show weather information"
            path: "bar.elements.weather"
        }

        ToggleRow {
            label: "System indicators"
            description: "Show CPU, memory and swap indicators"
            path: "bar.elements.systemIndicators"
        }
    }

    // ================= RESOURCES =================
    SettingsGroup {
        title: "Resources"

        ToggleRow {
            label: "Always show CPU"
            description: "Show CPU usage even when low"
            path: "bar.resources.alwaysShowCpu"
        }

        ToggleRow {
            label: "Always show swap"
            description: "Show swap usage even when zero"
            path: "bar.resources.alwaysShowSwap"
        }

        SliderRow {
            label: "Memory warning threshold"
            description: "Memory usage % to trigger warning"
            path: "bar.resources.memoryWarningThreshold"
            from: 0
            to: 100
            format: v => Math.round(v) + "%"
        }

        SliderRow {
            label: "Swap warning threshold"
            description: "Swap usage % to trigger warning"
            path: "bar.resources.swapWarningThreshold"
            from: 0
            to: 100
            format: v => Math.round(v) + "%"
        }
    }

    // ================= UTIL BUTTONS =================
    SettingsGroup {
        title: "Util Buttons"

        ToggleRow {
            label: "Screen snip"
            description: "Show screen snip button"
            path: "bar.utilButtons.showScreenSnip"
        }

        ToggleRow {
            label: "Color picker"
            description: "Show color picker button"
            path: "bar.utilButtons.showColorPicker"
        }

        ToggleRow {
            label: "Mic toggle"
            description: "Show microphone toggle button"
            path: "bar.utilButtons.showMicToggle"
        }

        ToggleRow {
            label: "Keyboard toggle"
            description: "Show keyboard layout toggle button"
            path: "bar.utilButtons.showKeyboardToggle"
        }

        ToggleRow {
            label: "Dark mode toggle"
            description: "Show dark/light mode toggle button"
            path: "bar.utilButtons.showDarkModeToggle"
        }
    }
}
