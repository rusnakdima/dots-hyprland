import qs
import qs.modules.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell

Item {
    id: root
    property bool vertical: false
    readonly property bool isMaterial: Config.options.bar.cornerStyle === 3 || Config.options.bar.cornerStyle === 4

    implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : avatar.width + (root.isMaterial ? 0 : 8)
    implicitHeight: vertical ? avatar.height + 8 : Appearance.sizes.barHeight

    // Try to load user avatar from ~/.face
    property string avatarPath: {
        const home = Directories.home;
        const facePath = home + "/.face";
        // Check if file exists via FileUtils
        return FileUtils.exists(facePath) ? facePath : "";
    }

    // Avatar image or icon
    Rectangle {
        id: avatar
        anchors.centerIn: parent
        width: root.isMaterial ? 32 : 24
        height: root.isMaterial ? 32 : 24
        radius: width / 2
        color: Appearance.colors.colPrimaryContainer

        // Show face image if available
        Image {
            id: avatarImage
            anchors.fill: parent
            radius: parent.radius
            visible: root.avatarPath !== ""
            source: "file://" + root.avatarPath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        // Fallback icon
        MaterialSymbol {
            anchors.centerIn: parent
            text: "person"
            iconSize: root.isMaterial ? 20 : 16
            color: Appearance.colors.colOnPrimaryContainer
            visible: root.avatarPath === ""
        }

        // Hover scale
        transform: Scale {
            id: avatarScale
            origin.x: avatar.width / 2
            origin.y: avatar.height / 2
            xScale: clickArea.pressed ? 0.92 : (clickArea.containsMouse ? 1.1 : 1)
            yScale: xScale
        }

        Behavior on transform {
            NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 }
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (popup.active && popup.item) popup.item.close()
            else popup.active = true
        }
    }

    Loader {
        id: popup
        active: false
        sourceComponent: AvatarPopup {
            anchor {
                window: root.QsWindow.window
                item: root
                gravity: Config.options.bar.vertical
                    ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
                    : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
                edges: Config.options.bar.vertical
                    ? (Config.options.bar.bottom ? Edges.Left : Edges.Right)
                    : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
            }
            onPopupClosed: popup.active = false
        }
    }
}
