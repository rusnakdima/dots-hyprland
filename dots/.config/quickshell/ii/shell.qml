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
        // Updates.load() // disabled - causes freeze on checkupdates

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

    // Panel families
    // Note: waffle is disabled - only ii is used
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

}

