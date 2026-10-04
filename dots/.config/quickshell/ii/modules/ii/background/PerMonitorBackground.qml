pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions as CF
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Per-monitor wallpaper management.
 * Provides different wallpaper support per monitor with profile management.
 */
Singleton {
    id: root

    property var wallpaperPaths: ({})
    property var thumbnailPaths: ({})
    property var monitorProfiles: ({})

    signal wallpaperChanged(monitorName: string, path: string)
    signal profileChanged(profileName: string)

    function getWallpaperPath(monitorName: string): string {
        return root.wallpaperPaths[monitorName] || Config.options.background.wallpaperPath || "";
    }

    function getThumbnailPath(monitorName: string): string {
        return root.thumbnailPaths[monitorName] || Config.options.background.thumbnailPath || "";
    }

    function getVideoWallpaperPath(monitorName: string): bool {
        const path = root.getWallpaperPath(monitorName);
        return path.endsWith(".mp4") || path.endsWith(".webm") || path.endsWith(".mkv") ||
               path.endsWith(".avi") || path.endsWith(".mov");
    }

    function getEffectiveWallpaperPath(monitorName: string): string {
        const path = root.getWallpaperPath(monitorName);
        const isVideo = root.getVideoWallpaperPath(monitorName);
        return isVideo ? root.getThumbnailPath(monitorName) : path;
    }

    function setWallpaperPath(monitorName: string, path: string) {
        root.wallpaperPaths[monitorName] = path;
        root.saveWallpaperPaths();
        root.wallpaperChanged(monitorName, path);
    }

    function setThumbnailPath(monitorName: string, path: string) {
        root.thumbnailPaths[monitorName] = path;
        root.saveThumbnailPaths();
    }

    function applyWallpaper(monitorName: string, path: string, darkMode: bool) {
        if (!path || path.length === 0) return;

        const hyprlandMonitor = Hyprland.monitorFor({ name: monitorName });
        if (!hyprlandMonitor) {
            console.warn("[PerMonitorBackground] Hyprland monitor not found:", monitorName);
            return;
        }

        root.setWallpaperPath(monitorName, path);

        const isVideo = root.getVideoWallpaperPath(monitorName);

        if (isVideo) {
            root.applyVideoWallpaper(monitorName, path);
        } else {
            root.applyStaticWallpaper(monitorName, path, darkMode);
        }

        root.wallpaperChanged(monitorName, path);
    }

    function applyStaticWallpaper(monitorName: string, path: string, darkMode: bool) {
        const switchScriptPath = Directories.wallpaperSwitchScriptPath;
        const mode = darkMode ? "dark" : "light";

        Process {
            id: hyprpaperProc
            command: ["bash", "-c", `hyprpaperctl wallpaper "${path}" 2>/dev/null || hyprpaper "${monitorName}", "${path}" 2>/dev/null || (sleep 0.3 && wpaperd --set "${path}" 2>/dev/null) || true`]
        }

        Quickshell.execDetached([
            switchScriptPath,
            "--mode", mode,
            "--image", path
        ]);
    }

    function applyVideoWallpaper(monitorName: string, path: string) {
        const videoOpts = "no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample";

        Quickshell.execDetached([
            "mpvpaper",
            "-o", videoOpts,
            monitorName,
            path
        ]);
    }

    function applyWallpaperToAll(path: string, darkMode: bool) {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            const screen = screens[i];
            root.applyWallpaper(screen.name, path, darkMode);
        }
    }

    function killVideoWallpapers() {
        Quickshell.execDetached(["pkill", "-f", "mpvpaper"]);
    }

    function saveWallpaperPaths() {
        if (!Config || !Config.options) return;

        Config.options.background.perMonitorWallpapers = root.wallpaperPaths;
        Config.save();
    }

    function saveThumbnailPaths() {
        if (!Config || !Config.options) return;

        Config.options.background.perMonitorThumbnails = root.thumbnailPaths;
        Config.save();
    }

    function loadWallpaperPaths() {
        if (!Config || !Config.options) return;

        const savedPaths = Config.options.background?.perMonitorWallpapers;
        if (savedPaths && typeof savedPaths === "object") {
            root.wallpaperPaths = savedPaths;
        }

        const savedThumbnails = Config.options.background?.perMonitorThumbnails;
        if (savedThumbnails && typeof savedThumbnails === "object") {
            root.thumbnailPaths = savedThumbnails;
        }
    }

    function saveProfile(profileName: string) {
        const profile = {
            wallpaperPaths: { ...root.wallpaperPaths },
            thumbnailPaths: { ...root.thumbnailPaths },
            timestamp: Date.now()
        };
        root.monitorProfiles[profileName] = profile;
        root.saveProfiles();
        root.profileChanged(profileName);
    }

    function loadProfile(profileName: string) {
        const profile = root.monitorProfiles[profileName];
        if (!profile) {
            console.warn("[PerMonitorBackground] Profile not found:", profileName);
            return false;
        }

        if (profile.wallpaperPaths) {
            root.wallpaperPaths = profile.wallpaperPaths;
            root.saveWallpaperPaths();
        }

        if (profile.thumbnailPaths) {
            root.thumbnailPaths = profile.thumbnailPaths;
            root.saveThumbnailPaths();
        }

        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            const screen = screens[i];
            const wallpaperPath = root.wallpaperPaths[screen.name];
            if (wallpaperPath) {
                root.applyWallpaper(screen.name, wallpaperPath, Appearance.m3colors.darkmode);
            }
        }

        root.profileChanged(profileName);
        return true;
    }

    function deleteProfile(profileName: string) {
        delete root.monitorProfiles[profileName];
        root.saveProfiles();
    }

    function listProfiles(): array {
        return Object.keys(root.monitorProfiles);
    }

    function saveProfiles() {
        if (!Config || !Config.options) return;

        Config.options.background.monitorProfiles = root.monitorProfiles;
        Config.save();
    }

    function loadProfiles() {
        if (!Config || !Config.options) return;

        const savedProfiles = Config.options.background?.monitorProfiles;
        if (savedProfiles && typeof savedProfiles === "object") {
            root.monitorProfiles = savedProfiles;
        }
    }

    function detectConnectedMonitors(): list {
        const screens = Quickshell.screens;
        return screens.map(screen => ({
            name: screen.name,
            width: screen.width,
            height: screen.height,
            x: screen.x,
            y: screen.y,
            scale: screen.scale
        }));
    }

    function autoApplyForNewMonitor(screen) {
        if (root.wallpaperPaths[screen.name]) {
            return;
        }

        const defaultPath = Config.options.background.wallpaperPath;
        if (defaultPath) {
            root.applyWallpaper(screen.name, defaultPath, Appearance.m3colors.darkmode);
        }
    }

    Connections {
        target: Quickshell

        function onScreenAdded(screen) {
            root.autoApplyForNewMonitor(screen);
        }
    }

    Component.onCompleted: {
        root.loadWallpaperPaths();
        root.loadProfiles();
    }
}
