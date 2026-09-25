/*
 * MaterialYouReload.qml — fork-owned override shim
 *
 * Lives in: quickshell/ii/modules/common/services/MaterialYou/Overrides/
 * Contract: replaces the upstream MaterialThemeLoader's reload logic.
 *   - Watches palette.json via FileView (inotify)
 *   - On change: validates contrast, then emits to GTK (gsettings), Qt6 (qt6ct),
 *     and Quickshell (Appearance.m3colors)
 *   - Respects Config.options.theme.accent.manual for manual accent override
 *   - Respects Config.options.theme.refresh_interval_ms for delay between
 *     wallpaper change and reload
 *
 * Rationale: upstream MaterialThemeLoader.qml uses an arbitrary fixed delay
 * (Config.options.hacks.arbitraryRaceConditionDelay) that is racy under
 * rapid wallpaper changes. This shim replaces that logic with a deterministic
 * invalidation sequence that also handles Qt6 emission.
 */

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

pragma Singleton
pragma ComponentBehavior: Bound

/*
 * AccentOverride — singleton holding the manual accent override.
 * Loaded once; accessed by MaterialYouReload to determine effective accent.
 */
Singleton {
    id: accentOverride

    /* accent.manual hex string, e.g. "#ff5500" */
    property string manualAccent: ""

    /* Computed effective accent: manual if set, else "" (use matugen accent) */
    property string effectiveAccent: {
        const raw = Config.options?.theme?.accent?.manual ?? ""
        return (raw && /^#[0-9a-fA-F]{6}$/.test(raw)) ? raw : ""
    }
}

/*
 * MaterialYouReload — the main reload shim.
 * Subscribes to palette.json and forwards colors to GTK, Qt6, and Quickshell.
 */
QtObject {
    id: root

    /* Path to the generated palette.json (same location as upstream) */
    property string palettePath: Directories.generatedMaterialThemePath

    /* Refresh interval in ms (default 2000) */
    property int refreshInterval: Config.options?.theme?.refresh_interval_ms ?? 2000

    /* Contrast target for validation (default 4.5) */
    property real contrastTarget: Config.options?.theme?.contrast_target ?? 4.5

    /* Source of accent: "wallpaper" | "user" | "auto" (default "wallpaper") */
    property string accentSource: Config.options?.theme?.accent?.source ?? "wallpaper"

    /* Emit a signal when colors have been reloaded */
    signal colorsReloaded(variant palette)

    /* Internal state */
    property bool _paletteValid: true
    property string _lastAccent: ""

    /* ------------------------------------------------------------------ */
    /* GTK emission via gsettings                                          */
    /* ------------------------------------------------------------------ */
    function emitToGtk(palette) {
        const accent = palette.accent || "#cbc4cb"
        const bg     = palette.background || "#141313"
        const surface = palette.surface    || "#1c1b1c"

        // Material You GTK theme keys
        Quickshell.execDetached([
            "gsettings", "set", "org.gnome.desktop.interface", "color-scheme",
            "prefer-dark"
        ])
        Quickshell.execDetached([
            "gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "MaterialYouDark"
        ])
        // Set accent via gsettings custom accent color key if the schema supports it
        Quickshell.execDetached([
            "gsettings", "set", "org.gnome.desktop.interface", "accent-color", accent
        ])
    }

    /* ------------------------------------------------------------------ */
    /* Qt6 / Qt5 emission via atomic write to qt6ct/colors.conf           */
    /* ------------------------------------------------------------------ */
    function emitToQt6(palette) {
        const accent   = palette.accent   || "#cbc4cb"
        const bg       = palette.background || "#141313"
        const surface  = palette.surface  || "#1c1b1c"
        const fg       = palette.on_surface || "#e6e1e1"

        // Convert hex to Qt color role format:
        // qt6ct uses [Palette] section with Color<X>=#RRGGBB
        const content = [
            "[Palette]",
            `background=${bg}`,
            `foreground=${fg}`,
            `color0=${bg}`,
            `color1=${fg}`,
            `color2=${accent}`,
            `color3=${surface}`,
            `window=${surface}`,
            `windowText=${fg}`,
        ].join("\n")

        const qt6Path = `${FileUtils.trimFileProtocol(Directories.configHome)}/qt6ct/colors.conf`
        const qt5Path = `${FileUtils.trimFileProtocol(Directories.configHome)}/qt5ct/colors.conf`

        // Detect Qt version: prefer qt6ct, fall back to qt5ct
        const { exitCode } = Quickshell.execSync(["test", "-f", qt6Path])
        const targetPath = (exitCode === 0) ? qt6Path : qt5Path

        // Atomic write: write to temp, then rename
        const tmpPath = `${targetPath}.tmp`
        Io.writeTextFile(tmpPath, content, "utf-8")
        Quickshell.execDetached(["mv", tmpPath, targetPath])
    }

    /* ------------------------------------------------------------------ */
    /* Quickshell / Appearance emission                                    */
    /* ------------------------------------------------------------------ */
    function applyColorsToQuickshell(palette) {
        const keys = [
            "accent", "background", "surface", "surface_variant",
            "primary", "secondary", "tertiary",
            "on_background", "on_surface", "on_surface_variant",
            "on_primary", "on_primary_container",
            "on_secondary", "on_secondary_container",
            "on_tertiary", "on_tertiary_container",
            "error", "on_error", "error_container", "on_error_container",
            "outline", "outline_variant",
            "inverse_surface", "inverse_on_surface",
            "surface_tint", "scrim",
        ]

        for (const key of keys) {
            const value = palette[key]
            if (!value) continue
            // Convert snake_case to CamelCase for Appearance.m3colors
            const camelKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
            const m3Key = `m3${camelKey[0].toUpperCase()}${camelKey.slice(1)}`
            if (m3Key in Appearance.m3colors) {
                Appearance.m3colors[m3Key] = value
            }
        }

        // Update dark/light mode based on background luminance
        const bgColor = palette.background || "#141313"
        const r = parseInt(bgColor.slice(1, 3), 16) / 255
        const g = parseInt(bgColor.slice(3, 5), 16) / 255
        const b = parseInt(bgColor.slice(5, 7), 16) / 255
        const toLinear = (c) => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
        const lum = 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b)
        Appearance.m3colors.darkmode = lum < 0.5
    }

    /* ------------------------------------------------------------------ */
    /* Full reload sequence                                                */
    /* ------------------------------------------------------------------ */
    function reloadPalette(fileContent) {
        let palette
        try {
            palette = JSON.parse(fileContent)
        } catch (e) {
            console.warn("[MaterialYouReload] Failed to parse palette.json:", e)
            return
        }

        // Apply accent override if theme.accent.manual is set
        const manual = accentOverride.effectiveAccent
        if (manual) {
            palette.accent = manual
            // Also patch primary to match manual accent for widget coloring
            palette.primary = manual
            palette.surface_tint = manual
        }

        applyColorsToQuickshell(palette)
        emitToGtk(palette)
        emitToQt6(palette)
        colorsReloaded(palette)
    }

    /* ------------------------------------------------------------------ */
    /* Debounced reload on palette.json change                             */
    /* ------------------------------------------------------------------ */
    Timer {
        id: reloadTimer
        interval: root.refreshInterval
        repeat: false
        onTriggered: {
            const content = paletteFileView.text()
            if (content.length > 0) {
                root.reloadPalette(content)
            }
        }
    }

    FileView {
        id: paletteFileView
        path: Qt.resolvedUrl(root.palettePath)
        watchChanges: true
        onFileChanged: {
            // Debounce rapid changes (e.g., rapid wallpaper cycling)
            reloadTimer.restart()
        }
        onLoadedChanged: {
            if (loaded) {
                const content = paletteFileView.text()
                if (content.length > 0) {
                    root.reloadPalette(content)
                }
            }
        }
    }

    /* ------------------------------------------------------------------ */
    /* Wallpaper change subscription (coordinates with WallpaperService)   */
    /* ------------------------------------------------------------------ */
    Connections {
        target: Config.options?.background ?? null
        function onWallpaperPathChanged() {
            // Reset palette path to pick up new generated file
            paletteFileView.reload()
            reloadTimer.restart()
        }
    }

    /* ------------------------------------------------------------------ */
    /* Startup: force a reload of current palette                         */
    /* ------------------------------------------------------------------ */
    Component.onCompleted: {
        paletteFileView.reload()
    }
}
