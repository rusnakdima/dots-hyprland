pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.config

PanelWindow {
    id: screenrecordTool

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    visible: false
    exclusionMode: ExclusionMode.Ignore

    // Public API
    property bool isRecording: _internal.isRecording
    property string elapsedTime: _internal.elapsedTime
    property bool binaryAvailable: _internal.binaryAvailable

    // Open the recording overlay
    function open() {
        visible = true;
        _internal.start();
    }

    function close() {
        visible = false;
        _internal.stop();
    }

    QtObject {
        id: _internal

        property bool isRecording: false
        property string elapsedTime: "00:00"
        property bool binaryAvailable: false

        // Ensure Videos directory exists
        Process {
            id: ensureVideosProc
            command: ["bash", "-c", "mkdir -p ~/Videos"]
        }

        // Check if wl-screenrecord is available
        Process {
            id: checkProc
            command: ["bash", "-c", "command -v wl-screenrecord >/dev/null 2>&1 && echo yes || echo no"]
            running: true
            onExited: {
                binaryAvailable = (stdout && stdout.trim() === "yes");
            }
        }

        // Recording process
        Process {
            id: recordProc
            command: []
            running: false
            onExited: {
                isRecording = false;
                elapsedTimer.running = false;
                elapsedTimer.seconds = 0;
                elapsedTime = "00:00";
            }
        }

        Timer {
            id: elapsedTimer
            interval: 1000
            repeat: true
            running: _internal.isRecording
            property int seconds: 0
            onTriggered: {
                seconds++;
                var h = Math.floor(seconds / 3600);
                var m = Math.floor((seconds % 3600) / 60);
                var s = seconds % 60;
                var pad = v => v < 10 ? "0" + v : String(v);
                elapsedTime = h > 0 ? pad(h) + ":" + pad(m) + ":" + pad(s) : pad(m) + ":" + pad(s);
            }
        }

        function start() {
            if (!binaryAvailable) {
                console.warn("wl-screenrecord not found. Install wl-screenrecord first.");
                Quickshell.execDetached(["bash", "-c",
                    "notify-send 'Screen Recorder' 'wl-screenrecord not found. Install it with: pacman -S wl-screenrecord' -a 'Shell'"
                ]);
                return;
            }

            ensureVideosProc.running = true;
            var timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
            var outputPath = Quickshell.env("HOME") + "/Videos/screenrecord-" + timestamp + ".webm";

            recordProc.command = ["bash", "-c",
                "trap 'kill -INT $! 2>/dev/null; wait $! 2>/dev/null' INT TERM; " +
                "wl-screenrecord --output '" + outputPath + "' & " +
                "PID=$!; sleep 86400 & " +
                "wait $PID 2>/dev/null"
            ];
            recordProc.running = true;
            isRecording = true;
            elapsedTimer.seconds = 0;
            elapsedTimer.running = true;

            Quickshell.execDetached(["bash", "-c",
                "notify-send 'Screen Recorder' 'Recording started' -a 'Shell' -t 2000"
            ]);
        }

        function stop() {
            if (recordProc.running) {
                recordProc.running = false;
                Quickshell.execDetached(["bash", "-c",
                    "kill -INT $(pgrep -f wl-screenrecord) 2>/dev/null; " +
                    "sleep 0.5; " +
                    "ls ~/Videos/screenrecord-*.webm 2>/dev/null | tail -1 | xargs -I{} " +
                    "notify-send 'Screen Recorder' 'Recording saved: $(basename {})' -a 'Shell'"
                ]);
            }
        }
    }

    // Dimmer overlay
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: visible ? 0.5 : 0
        Behavior on opacity {
            NumberAnimation { duration: Config.animDuration > 0 ? Config.animDuration : 150 }
        }
        visible: opacity > 0
    }

    // Recording indicator in center
    Rectangle {
        anchors.centerIn: parent
        width: recordingColumnLayout.width + 40
        height: recordingColumnLayout.height + 40
        radius: Appearance.rounding.medium
        color: Appearance.m3colors.m3surfaceContainer
        border.width: 1
        border.color: Appearance.colors.colError
        visible: _internal.isRecording

        ColumnLayout {
            id: recordingColumnLayout
            anchors.centerIn: parent
            spacing: 8

            // Pulsing red dot
            Rectangle {
                id: pulseDot
                Layout.alignment: Qt.AlignHCenter
                width: 16
                height: 16
                radius: 8
                color: Appearance.colors.colError

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.3; duration: 500 }
                    NumberAnimation { from: 0.3; to: 1; duration: 500 }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Recording"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colError
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: _internal.elapsedTime
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: Appearance.colors.colOnSurface
            }

            // Stop button
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                width: 80
                height: 36
                radius: Appearance.rounding.full
                color: Appearance.colors.colError
                cursorShape: Qt.PointingHandCursor

                StyledText {
                    anchors.centerIn: parent
                    text: "Stop"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnError
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        _internal.stop();
                        screenrecordTool.visible = false;
                    }
                }
            }
        }
    }

    // Not recording - show start prompt
    Item {
        anchors.centerIn: parent
        visible: !_internal.isRecording && !_internal.binaryAvailable

        Rectangle {
            anchors.fill: parent
            width: installColumnLayout.width + 40
            height: installColumnLayout.height + 40
            radius: Appearance.rounding.medium
            color: Appearance.m3colors.m3surfaceContainer

            ColumnLayout {
                id: installColumnLayout
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "error"
                    iconSize: 32
                    color: Appearance.colors.colError
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "wl-screenrecord not installed"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Run: pacman -S wl-screenrecord"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }
    }

    Keys.onEscapePressed: {
        if (_internal.isRecording) {
            _internal.stop();
        }
        screenrecordTool.visible = false;
    }

    // Auto-close when not recording and no binary
    onVisibleChanged: {
        if (visible && !_internal.binaryAvailable) {
            // Show hint for 3 seconds then close
            Qt.callLater(() => {
                timerAutoClose.start();
            });
        }
    }

    Timer {
        id: timerAutoClose
        interval: 3000
        running: false
        onTriggered: {
            if (!_internal.binaryAvailable) {
                screenrecordTool.visible = false;
            }
        }
    }
}
