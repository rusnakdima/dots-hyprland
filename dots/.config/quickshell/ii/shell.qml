//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "modules/common"
import "modules/settings"
import "modules/ii/settings"
import "panelFamilies"
import "services"

ShellRoot {
    // Settings IPC handler singleton — loaded via `import "modules/settings"` above
    // (IpcHandler registered automatically when singleton module is imported)

    id: root

    // Guard against startup race: Component.onCompleted and Config.configReloaded
    // both fire on startup, causing double-cycle. Only cycle after both have fired.
    property bool _startupCycleDone: false

    function cyclePanelFamily() {
        const families = ["ii"];
        const currentIndex = families.indexOf(Config.options.panelFamily);
        const nextIndex = (currentIndex + 1) % families.length;
        const nextFamily = families[nextIndex];
        // Only write if actually changing to avoid unnecessary config reload
        if (Config.options.panelFamily !== nextFamily)
            Config.options.panelFamily = nextFamily;

        // Toggle barOpen to force LazyLoader re-evaluation
        GlobalStates.barOpen = false;
        GlobalStates.barOpen = true;
    }

    Component.onCompleted: {
        // Updates.load() // disabled - causes freeze on checkupdates

        // Force SettingsIpcHandler singleton instantiation (registers settingsui IPC target)
        if (SettingsIpcHandler.objectName !== "")
            console.debug("settingsui IPC loaded");

        Qt.callLater(() => {
            root._startupCycleDone = true;
            root.cyclePanelFamily();
            GlobalStates.barOpen = false;
            GlobalStates.barOpen = true;
            MaterialThemeLoader.reapplyTheme();
            Hyprsunset.load();
            FirstRunExperience.load();
            ConflictKiller.load();
            Cliphist.refresh();
            Wallpapers.load();
        }, 100);
    }

    // Stuff for every panel family
    ReloadPopup {
    }

    // Settings window — loaded lazily so it doesn't consume resources until opened
    LazyLoader {
        active: true
        component: SettingsWindow {}
    }

    // Global shortcut for settings window toggle (Super+I)
    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggle settings window"
        onPressed: SettingsService.toggle()
    }

    Connections {
        function onConfigReloaded() {
            if (root._startupCycleDone)
                root.cyclePanelFamily();

        }

        target: Config
    }

    PanelFamilyLoader {
        identifier: "ii"

        component: IllogicalImpulseFamily {
        }

    }

    // Panel families
    // Note: waffle is disabled - only ii is used
    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true

        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }

}
