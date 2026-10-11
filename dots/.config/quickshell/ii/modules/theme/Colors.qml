pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    // ── Semantic color roles ──────────────────────────────────────
    readonly property color surface:     Appearance.colors.surface
    readonly property color surfaceAlt:  Appearance.colors.surfaceAlt
    readonly property color accent:      Appearance.colors.accent
    readonly property color accentAlt:   Appearance.colors.accentAlt
    readonly property color text:        Appearance.colors.text
    readonly property color textSec:     Appearance.colors.textSec
    readonly property color divider:     Appearance.colors.divider
    readonly property color success:     "#4caf50"
    readonly property color warning:     "#ff9800"
    readonly property color error:       "#f44336"

    // ── Dark/light aware ─────────────────────────────────────────
    readonly property bool dark: Appearance.darkMode

    // ── Elevation shadows ────────────────────────────────────────
    readonly property real elevationLevel: 0
}
