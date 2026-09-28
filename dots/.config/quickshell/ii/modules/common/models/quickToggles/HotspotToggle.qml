import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Hotspot")
    icon: Network.hotspotMaterialSymbol
    toggled: Network.hotspotActive
    mainAction: () => Network.toggleHotspot()
    hasMenu: true
}
