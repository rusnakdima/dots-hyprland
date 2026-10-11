import QtQuick

/**
 * Shared animation info component for icon animations.
 * Used by start-here icons and other animated elements.
 */
QtObject {
    property bool paused: false
    property int loops: 1
    signal restart()
}
