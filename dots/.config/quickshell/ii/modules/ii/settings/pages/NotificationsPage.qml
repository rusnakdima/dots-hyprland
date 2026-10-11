pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.services
import "../rows/"

// Notifications settings: popup, monitor, groups, unread
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    // ================= POPUP =================
    SettingsGroup {
        title: "Popup"

        SliderRow {
            label: "Timeout"
            description: "How long a notification popup stays on screen"
            path: "notifications.timeout"
            from: 1000
            to: 30000
            stepSize: 500
            format: v => (v / 1000).toFixed(1) + "s"
        }

        ToggleRow {
            label: "Enable"
            description: "Show notification popups"
            path: "notifications.popup.enable"
        }

        SliderRow {
            label: "Spacing"
            description: "Gap between stacked notification popups"
            path: "notifications.popup.spacing"
            from: 0
            to: 24
            format: v => Math.round(v) + "px"
        }

        SliderRow {
            label: "Max popup height"
            description: "Maximum height of notification popups (0 = unlimited)"
            path: "notifications.popup.maxPopupHeight"
            from: 0
            to: 800
            format: v => v === 0 ? "Unlimited" : Math.round(v) + "px"
        }
    }

    // ================= MONITOR =================
    SettingsGroup {
        title: "Monitor"

        SelectRow {
            label: "Monitor name"
            description: "Show notifications on specific monitor (leave empty for active)"
            path: "notifications.monitor.name"
            options: [
                { label: "Active monitor", value: "" },
                { label: "eDP-1", value: "eDP-1" },
                { label: "HDMI-1", value: "HDMI-1" },
                { label: "DP-1", value: "DP-1" }
            ]
        }
    }

    // ================= GROUPS =================
    SettingsGroup {
        title: "Groups"

        SliderRow {
            label: "Collapsed max height"
            description: "Maximum height of collapsed notification groups"
            path: "notifications.group.collapsedMaxHeight"
            from: 40
            to: 200
            format: v => Math.round(v) + "px"
        }

        SliderRow {
            label: "Expanded top spacing"
            description: "Spacing above expanded notification groups"
            path: "notifications.group.expandedTopSpacing"
            from: 0
            to: 30
            format: v => Math.round(v) + "px"
        }

        SliderRow {
            label: "Expanded image spacing"
            description: "Spacing for images in expanded notification groups"
            path: "notifications.group.expandedImageSpacing"
            from: 0
            to: 60
            format: v => Math.round(v) + "px"
        }
    }

    // ================= UNREAD =================
    SettingsGroup {
        title: "Unread"

        ToggleRow {
            label: "Increment when inhibited"
            description: "Count notifications even when Do Not Disturb is active"
            path: "notifications.unread.incrementWhenInhibited"
        }
    }
}
