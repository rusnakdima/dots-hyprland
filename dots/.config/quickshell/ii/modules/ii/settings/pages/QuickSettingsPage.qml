pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.services
import "../rows/"

// Quick Settings panel visibility settings
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    // ================= SLIDER VISIBILITY =================
    SettingsGroup {
        title: "Slider Visibility"

        ToggleRow {
            label: "Show volume"
            description: "Show volume slider in quick settings panel"
            path: "sidebar.quickSliders.showVolume"
        }

        ToggleRow {
            label: "Show brightness"
            description: "Show brightness slider in quick settings panel"
            path: "sidebar.quickSliders.showBrightness"
        }

        ToggleRow {
            label: "Show clipboard"
            description: "Show clipboard history in quick settings panel"
            path: "sidebar.quickSliders.showClipboard"
        }

        ToggleRow {
            label: "Show microphone"
            description: "Show microphone level slider in quick settings panel"
            path: "sidebar.quickSliders.showMic"
        }
    }
}
