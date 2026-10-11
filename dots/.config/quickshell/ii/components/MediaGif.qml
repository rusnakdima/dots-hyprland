pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.services

// The dashboard's GIF visualizer, moving only while something plays
AnimatedImage {
    property bool showGif: DashboardService.showGif ?? false
    property bool hasPlayer: MprisService.hasPlayer ?? false
    property bool isPlaying: MprisService.isPlaying ?? false

    visible: showGif && hasPlayer
    source: showGif ? (DashboardService.gifSource ?? "") : ""
    playing: visible && isPlaying
    fillMode: AnimatedImage.PreserveAspectFit
    asynchronous: true
}
