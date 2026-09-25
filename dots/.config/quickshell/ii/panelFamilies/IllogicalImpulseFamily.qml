import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.ii.background
import qs.modules.ii.bar
import qs.modules.ii.cheatsheet
import qs.modules.ii.dashboard
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.wallpaperSelector

// Root Item applies global opacity to ALL panels via QML property inheritance
Item {
    // Reactive binding: re-evaluates when Config.options changes (via configReloaded)
    opacity: Config.options?.appearance?.globalOpacity ?? 0.9

    // Force opacity binding re-evaluation whenever config is reloaded from disk.
    // JsonObject nested property mutations don't emit Qt property change signals,
    // so we rely on configReloaded (emitted after FileView reload) to tell us to rebind.
    Connections {
        target: Config
        function onConfigReloaded() {
            // Force QML to re-evaluate the opacity binding by reassigning.
            // The binding reads Config.options.appearance.globalOpacity reactively.
            opacity = Config.options?.appearance?.globalOpacity ?? 0.9;
        }
    }

    Scope {
        // Bar directly instantiated (bypasses LazyLoader/PanelLoader crash)
        Bar {}
        PanelLoader { component: Background {} }
        PanelLoader { component: Cheatsheet {} }
        PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
        PanelLoader { component: Lock {} }
        PanelLoader { component: MediaControls {} }
        PanelLoader { component: NotificationPopup {} }
        PanelLoader { component: OnScreenDisplay {} }
        PanelLoader { component: OnScreenKeyboard {} }
        PanelLoader { component: Overlay {} }
        PanelLoader { component: Overview {} }
        PanelLoader { component: Dashboard {} }
        PanelLoader { component: Polkit {} }
        PanelLoader { component: RegionSelector {} }
        PanelLoader { component: ScreenCorners {} }
        PanelLoader { component: ScreenTranslator {} }
        PanelLoader { component: SessionScreen {} }
        PanelLoader { component: SidebarLeft {} }
        PanelLoader { component: SidebarRight {} }
        PanelLoader { extraCondition: Config.options.bar.vertical; component: VerticalBar {} }
        PanelLoader { component: WallpaperSelector {} }
    }
}
