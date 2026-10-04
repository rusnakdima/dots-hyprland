import qs.modules.common.models.quickToggles
import qs.modules.common.widgets
import qs.services
import QtQuick

QuickToggleModel {
    id: root

    name: Translation.tr("Keyboard color")
    tooltipText: Translation.tr("Keyboard backlight color | Right-click to pick")
    icon: "keyboard"
    toggled: {
        const c = KeyboardBacklight.currentRgb
        return (c[0] > 0 || c[1] > 0 || c[2] > 0)
    }

    hasMenu: true

    mainAction: () => {
        if (root.toggled) {
            // Turn off
            KeyboardBacklight.apply([0, 0, 0])
        } else {
            // Restore last non-off color
            KeyboardBacklight.apply(KeyboardBacklight.lastAppliedNonOff)
        }
    }
}
