pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell

/**
 * Audio service stub — Quickshell.Services.Pipewire is not installed.
 * Provides no-op audio controls so the shell can still load.
 * Audio controls will be non-functional until Pipewire is available.
 */

Singleton {
    id: root

    // Public API — stub values
    property bool ready: false
    property var sink: null
    property var source: null
    readonly property real hardMaxValue: 2.00
    property string audioTheme: Config.options.sounds.theme
    property real value: 0

    // Lists — empty stubs
    readonly property list<var> outputAppNodes: []
    readonly property list<var> inputAppNodes: []
    readonly property list<var> outputDevices: []
    readonly property list<var> inputDevices: []

    // Signals
    signal sinkProtectionTriggered(string reason)

    // Controls — no-ops
    function toggleMute() {}
    function toggleMicMute() {}
    function incrementVolume() {}
    function decrementVolume() {}
    function setDefaultSink(node) {}
    function setDefaultSource(node) {}

    function friendlyDeviceName(node) { return "Unknown"; }
    function appNodeDisplayName(node) { return "Unknown"; }

    function playSystemSound(soundName) {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", ogaPath]);
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", oggPath]);
    }
}
