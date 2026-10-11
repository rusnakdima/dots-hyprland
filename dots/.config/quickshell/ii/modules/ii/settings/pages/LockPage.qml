pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.services
import "../rows/"

// Lock screen settings: hyprlock, blur, clock, security
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    // ================= STYLE =================
    SettingsGroup {
        title: "Style"

        ToggleRow {
            label: "Use Hyprlock"
            description: "Use Hyprland's hyprlock for the lock screen"
            path: "lock.useHyprlock"
        }

        ToggleRow {
            label: "Center clock"
            description: "Position the clock in the center of the lock screen"
            path: "lock.centerClock"
        }

        ToggleRow {
            label: "Show locked text"
            description: "Show 'Locked' indicator below the clock"
            path: "lock.showLockedText"
        }

        ToggleRow {
            label: "Material shape chars"
            description: "Use Material Design style shape characters"
            path: "lock.materialShapeChars"
        }
    }

    // ================= BLUR =================
    SettingsGroup {
        title: "Blur"

        ToggleRow {
            label: "Enable blur"
            description: "Apply blur effect to the lock screen background"
            path: "lock.blur.enable"
        }

        SliderRow {
            label: "Blur radius"
            description: "Blur intensity radius"
            path: "lock.blur.radius"
            from: 0
            to: 200
            format: v => Math.round(v) + "px"
        }

        SliderRow {
            label: "Extra zoom"
            description: "Wallpaper zoom factor for blur background"
            path: "lock.blur.extraZoom"
            from: 1.0
            to: 1.5
            stepSize: 0.05
            format: v => v.toFixed(2) + "x"
        }
    }

    // ================= SECURITY =================
    SettingsGroup {
        title: "Security"

        ToggleRow {
            label: "Unlock keyring"
            description: "Unlock the system keyring on lock screen unlock"
            path: "lock.security.unlockKeyring"
        }

        ToggleRow {
            label: "Require password to power"
            description: "Require password authentication before system power actions"
            path: "lock.security.requirePasswordToPower"
        }
    }
}
