//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}

    // Guard: prevent double-cycle on startup. Using a deferred flag because
    // both Component.onCompleted and Config.configReloaded fire on startup.
    property bool _startupCycleDone: false

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()

        // Deferred cycle + barOpen toggle to restore bar on fresh start.
        // Direct call fails because Config.options isn't ready in onCompleted.
        // barOpen toggle forces LazyLoader to re-evaluate after family switch.
        // Guard is set INSIDE deferred call to definitely prevent configReloaded race.
        Qt.callLater(() => {
            root._startupCycleDone = true
            root.cyclePanelFamily()
            GlobalStates.barOpen = false
            GlobalStates.barOpen = true
        })
    }

    // Also cycle the bar on config reload — Component.onCompleted doesn't fire on reload,
    // so we use the Config.configReloaded signal to restore the bar after any config change.
    Connections {
        target: Config
        function onConfigReloaded() {
            if (root._startupCycleDone) {
                console.log("[shell] Config changed, cycling panel family to restore bar")
                root.cyclePanelFamily()
            }
        }
    }

    // Panel families
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        const nextFamily = families[nextIndex]
        // Only write to config if the value is actually changing (avoids restart loops on startup)
        if (Config.options.panelFamily !== nextFamily) {
            Config.options.panelFamily = nextFamily
        }
        // Toggle barOpen to force bar LazyLoader to re-evaluate after family switch
        GlobalStates.barOpen = false
        GlobalStates.barOpen = true
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    PanelFamilyLoader {
        identifier: "waffle"
        component: WaffleFamily {}
    }

    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}
