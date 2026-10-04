pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.overlay

/*
 * Picture-in-Picture window for video players
 * Floats above other windows, draggable, resizable, always on top
 */
StyledOverlayWidget {
    id: root

    required property var modelData
    property string identifier: "pip"
    title: "Picture in Picture"
    property string materialSymbol: "pip"

    // PiP specific defaults
    property real defaultWidth: 320
    property real defaultHeight: 180
    property real minimumWidth: 160
    property real minimumHeight: 90

    // Size persistence
    Component.onCompleted: {
        const saved = persistentStateEntry;
        if (!saved.width || !saved.height) {
            persistentStateEntry.width = defaultWidth;
            persistentStateEntry.height = defaultHeight;
        }
    }

    // Close button minimizes to regular player instead
    function close() {
        root.visible = false;
        MprisController.pipActive = false;
    }

    // Override save to ensure minimum size
    function savePosition(xPos, yPos, width, height) {
        persistentStateEntry.x = Math.round(xPos ?? root.x);
        persistentStateEntry.y = Math.round(yPos ?? root.y);
        persistentStateEntry.width = Math.round(Math.max(width ?? contentContainer.implicitWidth, minimumWidth));
        persistentStateEntry.height = Math.round(Math.max(height ?? contentContainer.implicitHeight, minimumHeight));
    }

    contentItem: Item {
        id: pipContent
        implicitWidth: videoLoader.implicitWidth
        implicitHeight: videoLoader.implicitHeight

        // Video player placeholder - actual video rendering handled by MprisController
        Rectangle {
            id: videoLoader
            color: "#000"
            implicitWidth: persistentStateEntry.width || root.defaultWidth
            implicitHeight: persistentStateEntry.height || root.defaultHeight
            radius: root.contentRadius

            property string playerName: MprisController.activePlayer?.identity ?? ""
            property bool isPlaying: MprisController.isPlaying

            // Player identity badge
            Row {
                anchors {
                    left: parent.left
                    top: parent.top
                    margins: 6
                }
                spacing: 4
                visible: videoLoader.playerName !== ""

                Rectangle {
                    radius: 4
                    color: ColorUtils.transparentize("#000", 0.5)
                    anchors.margins: 4

                    StyledText {
                        text: videoLoader.playerName
                        color: "#fff"
                        font.pixelSize: 10
                        anchors.centerIn: parent
                    }
                }
            }

            // Playback indicator
            Rectangle {
                anchors.centerIn: parent
                radius: width / 2
                color: ColorUtils.transparentize("#000", 0.6)
                visible: !videoLoader.isPlaying
                implicitWidth: 48
                implicitHeight: 48

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "pause"
                    iconSize: 24
                    color: "#fff"
                }
            }
        }
    }
}
