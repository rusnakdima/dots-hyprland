pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common

// ThemeService - 11 presets + Material You via matugen
// Applies to Quickshell, Hyprland, kitty, GTK/Qt, Zen Browser
Singleton {
    id: root

    readonly property string themesDir: Quickshell.env("HOME") + "/.local/share/dots-themes"
    readonly property string kittyThemePath: Quickshell.env("HOME") + "/.config/kitty/current-theme.conf"

    // GTK/Qt paths
    readonly property string gtkColorsPath3: Quickshell.env("HOME") + "/.config/gtk-3.0/colors.css"
    readonly property string gtkColorsPath4: Quickshell.env("HOME") + "/.config/gtk-4.0/colors.css"
    readonly property string qtColorSchemePath: Quickshell.env("HOME") + "/.local/share/color-schemes/Dots.colors"

    property string currentThemeName: Config.options?.theme?.name ?? "tokyonight"
    property string themeMode: Config.options?.theme?.mode ?? "preset" // "preset" | "auto"
    property string colorScheme: Config.options?.theme?.scheme ?? "dark" // "dark" | "light"
    readonly property bool isAutoMode: themeMode === "auto"
    readonly property bool isDarkMode: colorScheme === "dark"

    // The palette is the single source of truth for all colors
    property var palette: ({
            "background": "#1a1b26",
            "surface0": "#24283b",
            "surface1": "#292e42",
            "surface2": "#414868",
            "text": "#c0caf5",
            "accent": "#7aa2f7",
            "success": "#9ece6a",
            "warning": "#e0af68",
            "error": "#f7768e",
        })

    // Available theme presets
    readonly property var availableThemes: [
        "tokyonight",
        "catppuccin-mocha",
        "catppuccin-latte",
        "dracula",
        "gruvbox-dark",
        "gruvbox-light",
        "nord",
        "nord-light",
        "rose-pine",
        "rose-pine-dawn",
        "kanagawa"
    ]

    // Helper function to shorten the service call
    function getState(path, fallback) {
        return Config.options?.[path] ?? fallback;
    }

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    Component.onCompleted: {
        listThemes();
    }

    // ========================================================================
    // PUBLIC API
    // ========================================================================

    function applyTheme(themeName: string) {
        console.log("[ThemeService] Loading theme:", themeName);
        loadThemeProc._themeName = themeName;
        loadThemeProc._buffer = "";
        loadThemeProc.command = ["cat", themesDir + "/" + themeName + ".json"];
        loadThemeProc.running = true;
    }

    function setPresetMode(themeName: string) {
        console.log("[ThemeService] Switching to preset mode:", themeName);
        themeMode = "preset";
        applyTheme(themeName);
    }

    function setAutoMode() {
        console.log("[ThemeService] Switching to auto (Material You) mode");
        themeMode = "auto";
        const wallpaper = Config.options?.wallpaper?.current ?? "";
        if (wallpaper) {
            runMatugen(wallpaper);
        }
    }

    function setColorScheme(scheme: string) {
        console.log("[ThemeService] Switching color scheme to:", scheme);
        colorScheme = scheme;
        // Re-apply current colors with new scheme
        if (isAutoMode) {
            const wallpaper = Config.options?.wallpaper?.current ?? "";
            if (wallpaper)
                runMatugen(wallpaper);
        } else {
            applyTheme(currentThemeName);
        }
    }

    function toggleDark() {
        const newScheme = isDarkMode ? "light" : "dark";
        setColorScheme(newScheme);
    }

    function runMatugen(wallpaperPath: string) {
        // Check if matugen is installed
        const verCheck = Quickshell.execDetached(["sh", "-c", "command -v matugen >/dev/null && matugen --version || echo 'not_found'"]);
        console.log("[ThemeService] Running matugen on:", wallpaperPath);
        matugenProc._buffer = "";
        matugenProc.command = ["matugen", "image", wallpaperPath, "-m", colorScheme];
        matugenProc.running = true;
    }

    function listThemes() {
        listThemesProc._collected = [];
        listThemesProc.running = true;
    }

    // ========================================================================
    // INTERNAL
    // ========================================================================

    function _applyThemeData(themeName, data) {
        // 1. Update palette
        if (data.palette) {
            root.palette = data.palette;
            _applyColorsToAppearance(data.palette);
        }

        // 2. Save theme name
        currentThemeName = themeName;

        // 3. Apply to Hyprland
        if (data.hyprland) {
            _applyHyprland(data.hyprland);
        }

        // 4. Apply to Kitty
        if (data.terminal) {
            _applyKitty(data.terminal);
        }

        // 5. Apply theme wallpaper
        if (data.wallpaper) {
            _applyWallpaper(data.wallpaper);
        }

        // 6. Apply GTK/Qt colors
        if (data.palette) {
            _applyGtkFromPalette(data.palette);
            _applyQtFromPalette(data.palette);
        }
    }

    function _applyColorsToAppearance(palette) {
        // Update Appearance colors
        if (Appearance?.colors) {
            Appearance.colors.colBackground = palette.background ?? Appearance.colors.colBackground;
            Appearance.colors.colSurface = palette.surface0 ?? Appearance.colors.colSurface;
            Appearance.colors.colAccent = palette.accent ?? Appearance.colors.colAccent;
        }
    }

    function _applyHyprland(hyprlandConfig) {
        if (hyprlandConfig?.windowBorder) {
            Quickshell.execDetached(["sh", "-c",
                `sed -i 's/col.border.*/col.border = ${hyprlandConfig.windowBorder}/' ~/.config/hypr/hyprland.conf 2>/dev/null || true`
            ]);
        }
    }

    function _applyKitty(kittyConfig) {
        if (kittyConfig?.colors) {
            const lines = [];
            lines.push("foreground " + (kittyConfig.colors.foreground || "#ffffff"));
            lines.push("background " + (kittyConfig.colors.background || "#000000"));
            if (kittyConfig.colors.cursor) lines.push("cursor " + kittyConfig.colors.cursor);
            if (kittyConfig.colors.black) {
                lines.push("color0 " + kittyConfig.colors.black);
                lines.push("color8 " + kittyConfig.colors.brightBlack || kittyConfig.colors.black);
            }
            if (kittyConfig.colors.red) {
                lines.push("color1 " + kittyConfig.colors.red);
                lines.push("color9 " + kittyConfig.colors.brightRed || kittyConfig.colors.red);
            }
            if (kittyConfig.colors.green) {
                lines.push("color2 " + kittyConfig.colors.green);
                lines.push("color10 " + kittyConfig.colors.brightGreen || kittyConfig.colors.green);
            }
            if (kittyConfig.colors.yellow) {
                lines.push("color3 " + kittyConfig.colors.yellow);
                lines.push("color11 " + kittyConfig.colors.brightYellow || kittyConfig.colors.yellow);
            }
            if (kittyConfig.colors.blue) {
                lines.push("color4 " + kittyConfig.colors.blue);
                lines.push("color12 " + kittyConfig.colors.brightBlue || kittyConfig.colors.blue);
            }
            if (kittyConfig.colors.magenta) {
                lines.push("color5 " + kittyConfig.colors.magenta);
                lines.push("color13 " + kittyConfig.colors.brightMagenta || kittyConfig.colors.magenta);
            }
            if (kittyConfig.colors.cyan) {
                lines.push("color6 " + kittyConfig.colors.cyan);
                lines.push("color14 " + kittyConfig.colors.brightCyan || kittyConfig.colors.cyan);
            }
            if (kittyConfig.colors.white) {
                lines.push("color7 " + kittyConfig.colors.white);
                lines.push("color15 " + kittyConfig.colors.brightWhite || kittyConfig.colors.white);
            }
            Quickshell.execDetached(["sh", "-c",
                "mkdir -p ~/.config/kitty && printf '%s\\n' " + lines.map(l => "'" + l + "'").join(" ") + " > ~/.config/kitty/current-theme.conf"
            ]);
        }
    }

    function _applyWallpaper(wallpaperPath) {
        if (wallpaperPath) {
            Quickshell.execDetached(["sh", "-c", "gsettings set org.gnome.desktop.background picture-uri 'file://" + wallpaperPath + "' 2>/dev/null || true"]);
        }
    }

    function _applyGtkFromPalette(palette) {
        const css = `
            @define-color theme_bg_color ${palette.background || "#1a1b26"};
            @define-color theme_fg_color ${palette.text || "#c0caf5"};
            @define-color theme_selected_bg_color ${palette.accent || "#7aa2f7"};
            @define-color theme_selected_fg_color ${palette.text || "#c0caf5"};
            @define-color theme_tooltip_bg_color ${palette.surface0 || "#24283b"};
            @define-color theme_tooltip_fg_color ${palette.text || "#c0caf5"};
        `;
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 && printf '%s' '" + css + "' > ~/.config/gtk-3.0/colors.css && printf '%s' '" + css + "' > ~/.config/gtk-4.0/colors.css"
        ]);
    }

    function _applyQtFromPalette(palette) {
        const ini = `[ColorScheme]
Accent=${palette.accent || "#7aa2f7"}
Background=${palette.background || "#1a1b26"}
Foreground=${palette.text || "#c0caf5"}
`;
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p ~/.local/share/color-schemes && printf '%s' '" + ini.replace(/\n/g, "\\n") + "' > ~/.local/share/color-schemes/Dots.colors"
        ]);
    }

    // ========================================================================
    // PROCESSES
    // ========================================================================

    Process {
        id: loadThemeProc
        property string _themeName: ""
        property string _buffer: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    const data = JSON.parse(text);
                    root._applyThemeData(loadThemeProc._themeName, data);
                } catch (e) {
                    console.error("[ThemeService] Failed to parse theme:", e.message);
                }
            }
        }
    }

    Process {
        id: listThemesProc
        property var _collected: []

        command: ["sh", "-c", "ls " + themesDir + "/*.json 2>/dev/null | sed 's/.*[/]//;s/.json$//'"]
        stdout: SplitParser {
            onRead: line => {
                if (line.trim())
                    _collected.push(line.trim());
            }
        }
        onExited: {
            if (_collected.length > 0) {
                // Merge preset themes with any custom ones
                const customThemes = _collected.filter(t => !availableThemes.includes(t));
                // availableThemes is readonly, so we don't modify it
            }
        }
    }

    Process {
        id: matugenProc
        property string _buffer: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    // matugen outputs JSON palette
                    const data = JSON.parse(text);
                    if (data.palette) {
                        root.palette = data.palette;
                        root._applyColorsToAppearance(data.palette);
                    }
                } catch (e) {
                    console.error("[ThemeService] matugen parse error:", e.message);
                }
            }
        }
    }
}
