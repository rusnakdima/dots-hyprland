pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.services
import "../rows/"

// Appearance settings: dark mode, fonts, transparency, wallpaper theming, palette
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    // ================= APPEARANCE =================
    SettingsGroup {
        title: "Appearance"

        ToggleRow {
            label: "Dark mode"
            description: "Applies dark theme to fcitx5 and compatible apps"
            path: "appearance.darkMode"
        }
    }

    // ================= FONTS =================
    SettingsGroup {
        title: "Fonts"

        TextFieldRow {
            label: "Main font"
            description: "Primary UI font family"
            path: "appearance.fonts.main"
            placeholder: "Google Sans Flex"
        }

        TextFieldRow {
            label: "Numbers font"
            description: "Font for numbers and dates"
            path: "appearance.fonts.numbers"
            placeholder: "Google Sans Flex"
        }

        TextFieldRow {
            label: "Icon nerd font"
            description: "Font for nerdfont icons"
            path: "appearance.fonts.iconNerd"
            placeholder: "JetBrains Mono NF"
        }

        TextFieldRow {
            label: "Monospace font"
            description: "Font for code and monospace content"
            path: "appearance.fonts.monospace"
            placeholder: "JetBrains Mono NF"
        }

        TextFieldRow {
            label: "Reading font"
            description: "Font optimized for reading"
            path: "appearance.fonts.reading"
            placeholder: "Readex Pro"
        }

        TextFieldRow {
            label: "Expressive font"
            description: "Font for expressive/decorative text"
            path: "appearance.fonts.expressive"
            placeholder: "Space Grotesk"
        }
    }

    // ================= TRANSPARENCY =================
    SettingsGroup {
        title: "Transparency"

        ToggleRow {
            label: "Enable transparency"
            description: "Apply transparency effects to panels"
            path: "appearance.transparency.enable"
        }

        ToggleRow {
            label: "Automatic"
            description: "Use system transparency settings"
            path: "appearance.transparency.automatic"
        }

        SliderRow {
            label: "Background transparency"
            description: "Transparency level for panel backgrounds"
            path: "appearance.transparency.backgroundTransparency"
            from: 0
            to: 0.5
            stepSize: 0.01
            format: v => Math.round(v * 100) + "%"
        }

        SliderRow {
            label: "Content transparency"
            description: "Transparency level for panel content"
            path: "appearance.transparency.contentTransparency"
            from: 0
            to: 0.9
            stepSize: 0.01
            format: v => Math.round(v * 100) + "%"
        }
    }

    // ================= WALLPAPER THEMING =================
    SettingsGroup {
        title: "Wallpaper Theming"

        ToggleRow {
            label: "Apply to apps and shell"
            description: "Apply wallpaper colors to application chrome and shell elements"
            path: "appearance.wallpaperTheming.enableAppsAndShell"
        }

        ToggleRow {
            label: "Apply to Qt apps"
            description: "Apply wallpaper colors to Qt application themes"
            path: "appearance.wallpaperTheming.enableQtApps"
        }

        ToggleRow {
            label: "Apply to terminal"
            description: "Apply wallpaper colors to terminal themes"
            path: "appearance.wallpaperTheming.enableTerminal"
        }
    }

    // ================= PALETTE =================
    SettingsGroup {
        title: "Palette"

        SelectRow {
            label: "Palette type"
            description: "Color scheme generation method"
            path: "appearance.palette.type"
            options: [
                { label: "Auto", value: "auto" },
                { label: "Content", value: "scheme-content" },
                { label: "Expressive", value: "scheme-expressive" },
                { label: "Fidelity", value: "scheme-fidelity" },
                { label: "Fruit Salad", value: "scheme-fruit-salad" },
                { label: "Monochrome", value: "scheme-monochrome" },
                { label: "Neutral", value: "scheme-neutral" },
                { label: "Rainbow", value: "scheme-rainbow" },
                { label: "Tonal Spot", value: "scheme-tonal-spot" }
            ]
        }

        TextFieldRow {
            label: "Accent color"
            description: "Manual accent color (hex, e.g. #ff5500)"
            path: "appearance.palette.accentColor"
            placeholder: "#ff5500"
        }
    }
}
