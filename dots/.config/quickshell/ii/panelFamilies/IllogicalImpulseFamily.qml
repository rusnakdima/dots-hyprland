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

// Root Item no longer applies global opacity directly.
// Each child panel wrapper computes its own opacity (allows per-panel exclusion).
Item {
    id: rootItem

    function globalOpacity() {
        return Config.options?.appearance?.globalOpacity ?? 0.9;
    }

    function isPanelExcluded(panelName) {
        const excluded = Config.options?.appearance?.opacityExcludedPanels ?? [];
        return excluded.includes(panelName);
    }

    function panelOpacity(panelName) {
        return isPanelExcluded(panelName) ? 1.0 : globalOpacity();
    }

    Connections {
        target: Config
        function onConfigReloaded() {
            if (!rootItem._startupCycleDone) return;
            // Re-bind all panel wrappers to re-evaluate opacity
            // Using Qt.binding() to re-establish the declarative binding after config reload
            barWrapper.opacity = Qt.binding(() => panelOpacity("Bar"));
            backgroundWrapper.opacity = Qt.binding(() => panelOpacity("Background"));
            cheatsheetWrapper.opacity = Qt.binding(() => panelOpacity("Cheatsheet"));
            dockWrapper.opacity = Qt.binding(() => panelOpacity("Dock"));
            lockWrapper.opacity = Qt.binding(() => panelOpacity("Lock"));
            mediaControlsWrapper.opacity = Qt.binding(() => panelOpacity("MediaControls"));
            notificationPopupWrapper.opacity = Qt.binding(() => panelOpacity("NotificationPopup"));
            onScreenDisplayWrapper.opacity = Qt.binding(() => panelOpacity("OnScreenDisplay"));
            onScreenKeyboardWrapper.opacity = Qt.binding(() => panelOpacity("OnScreenKeyboard"));
            overlayWrapper.opacity = Qt.binding(() => panelOpacity("Overlay"));
            overviewWrapper.opacity = Qt.binding(() => panelOpacity("Overview"));
            dashboardWrapper.opacity = Qt.binding(() => panelOpacity("Dashboard"));
            polkitWrapper.opacity = Qt.binding(() => panelOpacity("Polkit"));
            regionSelectorWrapper.opacity = Qt.binding(() => panelOpacity("RegionSelector"));
            screenCornersWrapper.opacity = Qt.binding(() => panelOpacity("ScreenCorners"));
            screenTranslatorWrapper.opacity = Qt.binding(() => panelOpacity("ScreenTranslator"));
            sessionScreenWrapper.opacity = Qt.binding(() => panelOpacity("SessionScreen"));
            sidebarLeftWrapper.opacity = Qt.binding(() => panelOpacity("SidebarLeft"));
            sidebarRightWrapper.opacity = Qt.binding(() => panelOpacity("SidebarRight"));
            verticalBarWrapper.opacity = Qt.binding(() => panelOpacity("VerticalBar"));
            wallpaperSelectorWrapper.opacity = Qt.binding(() => panelOpacity("WallpaperSelector"));
        }
    }

    Scope {
        Item { id: barWrapper; property string panelName: "Bar"; opacity: panelOpacity("Bar"); Bar {} }
        Item { id: backgroundWrapper; property string panelName: "Background"; opacity: panelOpacity("Background"); PanelLoader { component: Background {} } }
        Item { id: cheatsheetWrapper; property string panelName: "Cheatsheet"; opacity: panelOpacity("Cheatsheet"); PanelLoader { component: Cheatsheet {} } }
        Item { id: dockWrapper; property string panelName: "Dock"; opacity: panelOpacity("Dock"); PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} } }
        Item { id: lockWrapper; property string panelName: "Lock"; opacity: panelOpacity("Lock"); PanelLoader { component: Lock {} } }
        Item { id: mediaControlsWrapper; property string panelName: "MediaControls"; opacity: panelOpacity("MediaControls"); PanelLoader { component: MediaControls {} } }
        Item { id: notificationPopupWrapper; property string panelName: "NotificationPopup"; opacity: panelOpacity("NotificationPopup"); PanelLoader { component: NotificationPopup {} } }
        Item { id: onScreenDisplayWrapper; property string panelName: "OnScreenDisplay"; opacity: panelOpacity("OnScreenDisplay"); PanelLoader { component: OnScreenDisplay {} } }
        Item { id: onScreenKeyboardWrapper; property string panelName: "OnScreenKeyboard"; opacity: panelOpacity("OnScreenKeyboard"); PanelLoader { component: OnScreenKeyboard {} } }
        Item { id: overlayWrapper; property string panelName: "Overlay"; opacity: panelOpacity("Overlay"); PanelLoader { component: Overlay {} } }
        Item { id: overviewWrapper; property string panelName: "Overview"; opacity: panelOpacity("Overview"); PanelLoader { component: Overview {} } }
        Item { id: dashboardWrapper; property string panelName: "Dashboard"; opacity: panelOpacity("Dashboard"); PanelLoader { component: Dashboard {} } }
        Item { id: polkitWrapper; property string panelName: "Polkit"; opacity: panelOpacity("Polkit"); PanelLoader { component: Polkit {} } }
        Item { id: regionSelectorWrapper; property string panelName: "RegionSelector"; opacity: panelOpacity("RegionSelector"); PanelLoader { component: RegionSelector {} } }
        Item { id: screenCornersWrapper; property string panelName: "ScreenCorners"; opacity: panelOpacity("ScreenCorners"); PanelLoader { component: ScreenCorners {} } }
        Item { id: screenTranslatorWrapper; property string panelName: "ScreenTranslator"; opacity: panelOpacity("ScreenTranslator"); PanelLoader { component: ScreenTranslator {} } }
        Item { id: sessionScreenWrapper; property string panelName: "SessionScreen"; opacity: panelOpacity("SessionScreen"); PanelLoader { component: SessionScreen {} } }
        Item { id: sidebarLeftWrapper; property string panelName: "SidebarLeft"; opacity: panelOpacity("SidebarLeft"); PanelLoader { component: SidebarLeft {} } }
        Item { id: sidebarRightWrapper; property string panelName: "SidebarRight"; opacity: panelOpacity("SidebarRight"); PanelLoader { component: SidebarRight {} } }
        Item { id: verticalBarWrapper; property string panelName: "VerticalBar"; opacity: panelOpacity("VerticalBar"); PanelLoader { extraCondition: Config.options.bar.vertical; component: VerticalBar {} } }
        Item { id: wallpaperSelectorWrapper; property string panelName: "WallpaperSelector"; opacity: panelOpacity("WallpaperSelector"); PanelLoader { component: WallpaperSelector {} } }
    }
}
