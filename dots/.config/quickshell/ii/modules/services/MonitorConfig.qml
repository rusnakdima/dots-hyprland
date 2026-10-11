pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

/**
 * Manages monitor configurations and profiles.
 * Provides save/load of monitor setups and auto-detect on hotplug.
 */
Singleton {
    id: root

    property var profiles: ({})
    property string activeProfile: "default"
    property var currentMonitorConfig: ({})
    readonly property var screens: Quickshell.screens

    signal profileChanged(profileName: string)
    signal monitorsChanged()
    signal configurationApplied()

    function load() {
        loadProfiles();
        detectCurrentConfig();
    }

    function loadProfiles() {
        const configDir = `${Directories.config}/monitor-profiles`;
        const profilesFile = `${configDir}/profiles.json`;

        readProfilesProc.path = profilesFile;
        readProfilesProc.running = true;
    }

    Process {
        id: readProfilesProc
        property string path

        command: ["test", "-f", path]
        onExited: {
            if (exitCode === 0) {
                loadProc.path = path;
                loadProc.running = true;
            } else {
                // No profiles file yet, initialize with defaults
                root.profiles = { "default": root.getDefaultProfile() };
                saveProfiles();
            }
        }
    }

    Process {
        id: loadProc
        property string path

        command: ["cat", path]
        stdout: StdioCollector {
            id: profilesCollector
            onStreamFinished: {
                try {
                    root.profiles = JSON.parse(profilesCollector.text);
                } catch (e) {
                    console.warn("[MonitorConfig] Failed to parse profiles:", e);
                    root.profiles = { "default": root.getDefaultProfile() };
                }
            }
        }
    }

    function saveProfiles() {
        const configDir = `${Directories.config}/monitor-profiles`;
        const profilesFile = `${configDir}/profiles.json`;

        saveProc.directory = configDir;
        saveProc.content = JSON.stringify(root.profiles, null, 2);
        saveProc.fileName = profilesFile;
        saveProc.running = true;
    }

    Process {
        id: saveProc
        property string directory
        property string content
        property string fileName

        command: ["mkdir", "-p", directory]
        onExited: {
            writeProc.content = saveProc.content;
            writeProc.fileName = saveProc.fileName;
            writeProc.running = true;
        }
    }

    Process {
        id: writeProc
        property string content
        property string fileName

        command: ["tee", fileName]
        onStarted: {
            writeProc.write(content);
        }
    }

    function getDefaultProfile() {
        return {
            name: "default",
            monitors: [],
            timestamp: Date.now()
        };
    }

    function detectCurrentConfig() {
        getMonitorsProc.running = true;
    }

    Process {
        id: getMonitorsProc

        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                try {
                    const monitors = JSON.parse(monitorsCollector.text);
                    root.currentMonitorConfig = {
                        monitors: monitors.map(m => ({
                            name: m.name,
                            width: m.width,
                            height: m.height,
                            x: m.x,
                            y: m.y,
                            scale: m.scale,
                            transform: m.transform,
                            refreshRate: m.refreshRate,
                            enabled: m.disabled ? false : true
                        })),
                        timestamp: Date.now()
                    };
                    root.monitorsChanged();
                } catch (e) {
                    console.warn("[MonitorConfig] Failed to parse monitors:", e);
                }
            }
        }
    }

    function saveProfile(name: string) {
        const profile = {
            name: name,
            monitors: root.currentMonitorConfig.monitors.map(m => ({
                name: m.name,
                width: m.width,
                height: m.height,
                x: m.x,
                y: m.y,
                scale: m.scale,
                transform: m.transform,
                refreshRate: m.refreshRate,
                enabled: m.enabled
            })),
            timestamp: Date.now()
        };
        root.profiles[name] = profile;
        root.activeProfile = name;
        saveProfiles();
        root.profileChanged(name);
    }

    function deleteProfile(name: string) {
        if (name === "default") return;
        delete root.profiles[name];
        if (root.activeProfile === name) {
            root.activeProfile = "default";
        }
        saveProfiles();
        root.profileChanged(root.activeProfile);
    }

    function applyProfile(name: string) {
        const profile = root.profiles[name];
        if (!profile) {
            console.warn("[MonitorConfig] Profile not found:", name);
            return;
        }

        root.activeProfile = name;
        applyMonitorConfig(profile.monitors);
        root.profileChanged(name);
    }

    function applyMonitorConfig(config) {
        let batch = "";

        for (let i = 0; i < config.length; i++) {
            const m = config[i];
            const monitorName = m.name;

            if (!m.enabled) {
                batch += `hyprctl keyword monitor "${monitorName}",disable; `;
                continue;
            }

            const mode = `${m.width}x${m.height}@${m.refreshRate}`;
            const pos = `${m.x},${m.y}`;
            const scale = m.scale;
            const transform = m.transform !== undefined ? m.transform : 0;

            batch += `hyprctl keyword monitor "${monitorName}",${mode},${pos},${scale},${transform},disable; `;
        }

        if (batch.length > 0) {
            Quickshell.execDetached(["bash", "-c", batch]);
        }

        root.configurationApplied();
    }

    function enableMonitor(name: string) {
        Quickshell.execDetached(["bash", "-c",
            `hyprctl keyword monitor "${name}",enable`]);
    }

    function disableMonitor(name: string) {
        Quickshell.execDetached(["bash", "-c",
            `hyprctl keyword monitor "${name}",disable`]);
    }

    function setMonitorPosition(name: string, x: int, y: int) {
        Quickshell.execDetached(["bash", "-c",
            `hyprctl dispatch movemonitor "${name}" ${x} ${y}`]);
    }

    function setMonitorScale(name: string, scale: real) {
        Quickshell.execDetached(["bash", "-c",
            `hyprctl keyword monitor "${name}",scale ${scale}`]);
    }

    function setMonitorResolution(name: string, width: int, height: int, refreshRate: real) {
        Quickshell.execDetached(["bash", "-c",
            `hyprctl keyword monitor "${name}",${width}x${height}@${refreshRate}`]);
    }

    function getMonitorByName(name: string) {
        return root.screens.find(s => s.name === name);
    }

    function getMonitorConfig(monitorName: string) {
        return root.currentMonitorConfig.monitors.find(m => m.name === monitorName);
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "monitor" || event.name === "configreloaded") {
                Qt.callLater(() => root.detectCurrentConfig());
            }
        }
    }

    Component.onCompleted: {
        load();
    }

    IpcHandler {
        target: "monitorConfig"

        function applyProfile(name: string): void {
            root.applyProfile(name);
        }

        function saveProfile(name: string): void {
            root.saveProfile(name);
        }

        function deleteProfile(name: string): void {
            root.deleteProfile(name);
        }

        function getProfiles(): object {
            return root.profiles;
        }

        function getCurrentConfig(): object {
            return root.currentMonitorConfig;
        }

        function getActiveProfile(): string {
            return root.activeProfile;
        }
    }
}
