import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

DashboardWidgetBlock {
    id: root

    title: "Quick Actions"

    // Night light toggle
    readonly property bool nightLightActive: Hyprsunset?.temperatureActive ?? false

    // Bluetooth toggle
    readonly property bool bluetoothEnabled: BluetoothStatus?.enabled ?? false

    // Screen recording state (tracked via external process)
    property bool screenRecordingActive: _recordingProc.running
    property Process _recordingProc: Process {
        command: ["bash", "-c", "pidof -x wf-recorder >/dev/null 2>&1"]
        running: false
    }

    function _runScreenshot(type) {
        const cmds = {
            region: "slurp | xargs -I{} grim -g {} - | wl-copy",
            window: "grim -w $(hyprctl activewindow -j | jq -r '(.pid)') - | wl-copy",
            fullscreen: "grim - | wl-copy"
        }
        Quickshell.execDetached(["bash", "-c", cmds[type] || cmds.fullscreen])
    }

    function _toggleRecording() {
        if (screenRecordingActive) {
            Quickshell.execDetached(["bash", "-c", "pkill -x wf-recorder || killall wf-recorder"])
            _recordingProc.running = false
        } else {
            Quickshell.execDetached(["bash", "-c", "wf-recorder -f ~/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4 &"])
            _recordingProc.running = true
        }
    }

    function _toggleNightLight() {
        Hyprsunset?.toggleTemperature()
    }

    function _toggleBluetooth() {
        if (BluetoothStatus?.available) {
            Quickshell.execDetached(["bash", "-c", "bluetoothctl power " + (bluetoothEnabled ? "off" : "on")])
        }
    }

    // Poll recording state periodically
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: _recordingProc.running = true
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: 10
        anchors.topMargin: 38
        columns: 4
        rows: 2
        columnSpacing: 8
        rowSpacing: 8

        // Screenshot - Region
        ActionButton {
            icon: "content_cut"
            label: "Region"
            onClicked: _runScreenshot("region")
        }

        // Screenshot - Window
        ActionButton {
            icon: "crop_portrait"
            label: "Window"
            onClicked: _runScreenshot("window")
        }

        // Screenshot - Fullscreen
        ActionButton {
            icon: "fullscreen"
            label: "Screen"
            onClicked: _runScreenshot("fullscreen")
        }

        // Screen recording
        ActionButton {
            icon: screenRecordingActive ? "fiber_manual_record" : "videocam"
            label: screenRecordingActive ? "Stop Rec" : "Record"
            accentColor: screenRecordingActive ? Appearance.colors.colError : undefined
            onClicked: _toggleRecording()
        }

        // Night light
        ActionButton {
            icon: nightLightActive ? "nightlight_round" : "nightlight"
            label: nightLightActive ? "Night On" : "Night Off"
            accentColor: nightLightActive ? Appearance.colors.colPrimary : undefined
            onClicked: _toggleNightLight()
        }

        // Bluetooth
        ActionButton {
            icon: bluetoothEnabled ? "bluetooth_connected" : "bluetooth_disabled"
            label: bluetoothEnabled ? "BT On" : "BT Off"
            accentColor: bluetoothEnabled ? Appearance.colors.colPrimary : undefined
            enabled: BluetoothStatus?.available ?? false
            onClicked: _toggleBluetooth()
        }
    }

    component ActionButton: Rectangle {
        id: btn
        required property string icon
        required property string label
        property var accentColor: undefined
        property bool enabled: true
        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Appearance.rounding.normal
        color: !btn.enabled
            ? ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.5)
            : hovered
                ? (accentColor ?? Appearance.colors.colPrimaryContainer)
                : Appearance.colors.colSurfaceContainerHighest

        readonly property bool hovered: ma.containsMouse

        Column {
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: btn.icon
                iconSize: 22
                color: !btn.enabled
                    ? ColorUtils.transparentize(Appearance.colors.colOnSurfaceVariant, 0.5)
                    : (accentColor ?? Appearance.colors.colOnSurfaceVariant)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: btn.label
                font.pixelSize: 10
                color: !btn.enabled
                    ? ColorUtils.transparentize(Appearance.colors.colOnSurfaceVariant, 0.5)
                    : Appearance.colors.colOnSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            enabled: btn.enabled
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }
}
