pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * LockClockOnly — minimal dimmed clock shown on non-main monitors when locked.
 * Opacity 0.5 so the desktop wallpaper is still vaguely visible behind it.
 * Used by LockScreen.qml on monitors that are not the focused/locked monitor.
 */
Item {
    id: root
    opacity: 0.5

    property string timeText: {
        var now = new Date()
        return now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
    }
    property string dateText: {
        var now = new Date()
        return now.toLocaleDateString(Qt.locale(), Locale.LongFormat)
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            timeText = new Date().toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
            dateText = new Date().toLocaleDateString(Qt.locale(), LongFormat)
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: root.timeText
            color: Appearance?.colors?.colOnSurface ?? "#ffffff"
            font.pixelSize: 64
            font.weight: Font.Light
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.dateText
            color: Appearance?.colors?.colOnSurfaceVariant ?? "#aaaaaa"
            font.pixelSize: 24
            font.weight: Font.Normal
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
