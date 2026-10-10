pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import "../../../components/"

// Media tab with CavaService spectrum, cover art, title/artist, LyricsService synced lyrics, MediaProgress bar
Item {
    id: root

    property bool hasPlayer: MprisController.activePlayer !== null
    property bool isPlaying: MprisController.isPlaying ?? false
    property bool visualizing: active && isPlaying

    // Shown to the user (the dashboard is open on this tab)
    property bool active: false

    // Cava only runs while the tab is shown and something plays
    onVisualizingChanged: visualizing ? CavaService.acquire() : CavaService.release()
    Component.onDestruction: {
        if (visualizing)
            CavaService.release();
    }

    implicitHeight: 400

    // Background when no player
    Rectangle {
        anchors.fill: parent
        visible: !hasPlayer
        color: "transparent"
    }

    // Main content
    Column {
        anchors.centerIn: parent
        spacing: 16
        visible: hasPlayer

        // Cover art and visualizer
        Row {
            spacing: 24
            anchors.horizontalCenter: parent.horizontalCenter

            // Cava visualizer ring
            Rectangle {
                width: 200
                height: 200
                radius: 100
                color: Appearance.colors.colLayer1Hover

                CavaBackdrop {
                    anchors.fill: parent
                    running: root.visualizing
                }

                Image {
                    anchors.centerIn: parent
                    width: 160
                    height: 160
                    source: MprisController.activeTrack?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf075a"
                    font.family: Appearance.font.family
                    font.pixelSize: 48
                    color: Appearance.colors.colOnSurfaceVariant
                    visible: !hasPlayer || (MprisController.activeTrack?.artUrl ?? "") === "" || status !== Image.Ready
                }
            }

            // Track info
            Column {
                spacing: 8
                width: 300

                Text {
                    text: MprisController.activeTrack?.title ?? "Unknown Title"
                    font.family: Appearance.font.family
                    font.pixelSize: 24
                    font.bold: true
                    color: Appearance.colors.colOnSurface
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }

                Text {
                    text: MprisController.activeTrack?.artist ?? "Unknown Artist"
                    font.family: Appearance.font.family
                    font.pixelSize: 16
                    color: Appearance.colors.colOnSurfaceVariant
                }

                Text {
                    text: MprisController.activeTrack?.album ?? ""
                    font.family: Appearance.font.family
                    font.pixelSize: 14
                    color: Appearance.colors.colAccent
                    visible: text !== "" && text !== MprisController.activeTrack?.title
                }

                // Progress
                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Appearance.colors.colLayer2Hover

                    Rectangle {
                        id: progressBar
                        width: parent.width * 0.4
                        height: parent.height
                        radius: parent.radius
                        color: Appearance.colors.colAccent
                    }
                }

                // Controls
                Row {
                    spacing: 16

                    MaterialSymbol {
                        text: "skip_previous"
                        iconSize: 32
                        color: Appearance.colors.colOnSurface
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MprisController.previous()
                        }
                    }

                    MaterialSymbol {
                        text: isPlaying ? "pause" : "play_arrow"
                        iconSize: 48
                        color: Appearance.colors.colAccent
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MprisController.togglePlaying()
                        }
                    }

                    MaterialSymbol {
                        text: "skip_next"
                        iconSize: 32
                        color: Appearance.colors.colOnSurface
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MprisController.next()
                        }
                    }
                }
            }
        }

        // GIF visualizer
        MediaGif {
            width: 200
            height: 100
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Empty state
    Column {
        anchors.centerIn: parent
        spacing: 12
        visible: !hasPlayer

        Text {
            text: "\uf075b"
            font.family: Appearance.font.family
            font.pixelSize: 64
            color: Appearance.colors.colAccent
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Nothing playing"
            font.family: Appearance.font.family
            font.pixelSize: 20
            font.bold: true
            color: Appearance.colors.colOnSurface
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Play something in Spotify, a browser, mpv or any MPRIS player"
            font.family: Appearance.font.family
            font.pixelSize: 14
            color: Appearance.colors.colOnSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
