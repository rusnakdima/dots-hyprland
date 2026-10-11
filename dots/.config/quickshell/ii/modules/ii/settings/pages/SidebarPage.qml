pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.services
import "../rows/"

// Sidebar settings: translator, AI, booru, corner open
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    // ================= TRANSLATOR =================
    SettingsGroup {
        title: "Translator"

        ToggleRow {
            label: "Enable"
            description: "Enable screen text translation"
            path: "sidebar.translator.enable"
        }

        SliderRow {
            label: "Delay"
            description: "Delay before sending translation request (reduces rate limits)"
            path: "sidebar.translator.delay"
            from: 0
            to: 2000
            stepSize: 100
            format: v => Math.round(v) + "ms"
        }
    }

    // ================= AI =================
    SettingsGroup {
        title: "AI"

        ToggleRow {
            label: "Text fade in"
            description: "Animate text as it appears in AI responses"
            path: "sidebar.ai.textFadeIn"
        }
    }

    // ================= BOORU =================
    SettingsGroup {
        title: "Booru"

        ToggleRow {
            label: "Allow NSFW"
            description: "Allow NSFW content in booru image search"
            path: "sidebar.booru.allowNsfw"
        }

        SelectRow {
            label: "Default provider"
            description: "Image board source for booru search"
            path: "sidebar.booru.defaultProvider"
            options: [
                { label: "Yande.re", value: "yandere" },
                { label: "Danbooru", value: "danbooru" },
                { label: "Konachan", value: "konachan" },
                { label: "Zerochan", value: "zerochan" }
            ]
        }
    }

    // ================= CORNER OPEN =================
    SettingsGroup {
        title: "Corner Open"

        ToggleRow {
            label: "Enable"
            description: "Open sidebar by hovering the top-right or bottom-right screen corner"
            path: "sidebar.cornerOpen.enable"
        }

        ToggleRow {
            label: "Bottom"
            description: "Use bottom corners instead of top corners"
            path: "sidebar.cornerOpen.bottom"
        }

        ToggleRow {
            label: "Value scroll"
            description: "Use scroll gesture to adjust values in panels"
            path: "sidebar.cornerOpen.valueScroll"
        }

        SliderRow {
            label: "Corner region width"
            description: "Width of the active corner region"
            path: "sidebar.cornerOpen.cornerRegionWidth"
            from: 50
            to: 500
            format: v => Math.round(v) + "px"
        }

        SliderRow {
            label: "Corner region height"
            description: "Height of the active corner region"
            path: "sidebar.cornerOpen.cornerRegionHeight"
            from: 5
            to: 100
            format: v => Math.round(v) + "px"
        }
    }
}
