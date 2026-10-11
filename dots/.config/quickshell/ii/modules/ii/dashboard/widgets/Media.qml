pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import "../../../components/"

// Media widget with CavaService spectrum, cover art, title/artist, and playback controls
Item {
    id: root

    property var config: ({})

    property bool hasPlayer: MprisController.activePlayer !== null
    property bool isPlaying: MprisController.isPlaying ?? false
    property bool visualizing: hasPlayer && isPlaying

    // Cava only runs while something plays
    onVisualizingChanged: visualizing ? CavaService.acquire() : CavaService.release()
    Component.onDestruction: {
        if (visualizing)
            CavaService.release();
    }

    // Background when no player
    Rectangle {
        anchors.fill: parent
        visible: !hasPlayer
        color: "transparent"
    }

    // Main content - fills widget space
    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        visible: hasPlayer

        // Cover art and visualizer row
        Row {
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            // Cava visualizer ring
            Rectangle {
                width: 120
                height: 120
                radius: 60
                color: Appearance.colors.colLayer1Hover

                CavaBackdrop {
                    anchors.fill: parent
                    running: root.visualizing
                }

                Image {
                    anchors.centerIn: parent
                    width: 96
                    height: 96
                    source: MprisController.activeTrack?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf075a"
                    font.family: Appearance.font.family
                    font.pixelSize: 32
                    color: Appearance.colors.colOnSurfaceVariant
                    visible: !hasPlayer || (MprisController.activeTrack?.artUrl ?? "") === "" || status !== Image.Ready
                }
            }

            // Track info
            Column {
                spacing: 4
                width: 220

                Text {
                    text: MprisController.activeTrack?.title ?? "Unknown Title"
                    font.family: Appearance.font.family
                    font.pixelSize: 16
                    font.bold: true
                    color: Appearance.colors.colOnSurface
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }

                Text {
                    text: MprisController.activeTrack?.artist ?? "Unknown Artist"
                    font.family: Appearance.font.family
                    font.pixelSize: 13
                    color: Appearance.colors.colOnSurfaceVariant
                }

                Text {
                    text: MprisController.activeTrack?.album ?? ""
                    font.family: Appearance.font.family
                    font.pixelSize: 11
                    color: Appearance.colors.colAccent
                    visible: text !== "" && text !== MprisController.activeTrack?.title
                }

                // Progress
                Rectangle {
                    width: parent.width
                    height: 3
                    radius: 1.5
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
                    spacing: 8

                    MaterialSymbol {
                        text: "skip_previous"
                        iconSize: 24
                        color: Appearance.colors.colOnSurface
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MprisController.previous()
                        }
                    }

                    MaterialSymbol {
                        text: isPlaying ? "pause" : "play_arrow"
                        iconSize: 32
                        color: Appearance.colors.colAccent
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MprisController.togglePlaying()
                        }
                    }

                    MaterialSymbol {
                        text: "skip_next"
                        iconSize: 24
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
            height: 60
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Empty state
    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: !hasPlayer

        Text {
            text: "\uf075b"
            font.family: Appearance.font.family
            font.pixelSize: 48
            color: Appearance.colors.colAccent
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Nothing playing"
            font.family: Appearance.font.family
            font.pixelSize: 14
            font.bold: true
            color: Appearance.colors.colOnSurface
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Play something in Spotify, a browser, mpv or any MPRIS player"
            font.family: Appearance.font.family
            font.pixelSize: 11
            color: Appearance.colors.colOnSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
