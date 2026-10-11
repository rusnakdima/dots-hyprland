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
    id: mirrorWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "black"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Default position: bottom-right corner
    property int winX: screen ? (screen.width - 320 - 20) : 100
    property int winY: screen ? (screen.height - 300 - 20) : 100
    property int winWidth: 320
    property int winHeight: 300
    property bool isFlipped: true

    // Load saved position from StateService
    Component.onCompleted: loadPosition()
    Component.onDestruction: savePosition()

    function loadPosition() {
        if (!screen) return;
        var savedX = StateService.get("mirrorWindow.x", -1);
        var savedY = StateService.get("mirrorWindow.y", -1);
        var savedW = StateService.get("mirrorWindow.width", -1);
        var savedH = StateService.get("mirrorWindow.height", -1);
        var savedFlip = StateService.get("mirrorWindow.flipped", true);

        if (savedX >= 0 && savedY >= 0) {
            winX = savedX;
            winY = savedY;
        }
        if (savedW > 0 && savedH > 0) {
            winWidth = savedW;
            winHeight = savedH;
        }
        isFlipped = savedFlip;
    }

    function savePosition() {
        StateService.set("mirrorWindow.x", winX);
        StateService.set("mirrorWindow.y", winY);
        StateService.set("mirrorWindow.width", winWidth);
        StateService.set("mirrorWindow.height", winHeight);
        StateService.set("mirrorWindow.flipped", isFlipped);
    }

    visible: _internal.cameraReady
    onVisibleChanged: {
        if (visible) {
            _internal.startCamera();
        } else {
            _internal.stopCamera();
        }
    }

    // Public API to check if mirror is active
    property bool isActive: visible && _internal.cameraReady

    // Toggle visibility
    function toggle() {
        visible = !visible;
    }

    Item {
        id: _internal

        property bool cameraReady: false
        property bool cameraUnplugged: false
        property string cameraDevice: "/dev/video0"

        // Probe for available camera device
        Process {
            id: probeProc
            command: ["bash", "-c",
                "for dev in /dev/video*; do " +
                "  if [ -c \"$dev\" ]; then echo \"$dev\"; break; fi; " +
                "done"
            ]
            running: true
            onExited: {
                var output = stdout.trim();
                if (output.length > 0 && output.startsWith("/dev/video")) {
                    _internal.cameraDevice = output;
                    _internal.cameraReady = true;
                    _internal.cameraUnplugged = false;
                } else {
                    _internal.cameraReady = false;
                    _internal.cameraUnplugged = true;
                }
            }
        }

        // mpv camera process
        Process {
            id: cameraProc
            command: []
            onExited: {
                if (_internal.cameraUnplugged) return;
                if (mirrorWindow.visible && _internal.cameraReady) {
                    Qt.callLater(() => _internal.startCamera());
                }
            }
        }

        function startCamera() {
            if (!_internal.cameraReady) {
                probeProc.running = true;
                return;
            }

            // Get the wayland window ID
            // For PanelWindow, we use the Qt window's internal wayland surface handle
            var win = mirrorWindow.window;
            if (!win) {
                console.warn("MirrorWindow: no window available");
                return;
            }
            var wid = win.winId();
            var widHex = "0x" + wid.toString(16);

            cameraProc.command = ["bash", "-c",
                "mpv " +
                "--no-audio " +
                "--no-border " +
                "--no-keepaspect " +
                "--hwdec=auto " +
                "--profile=low-latency " +
                "--wid=" + widHex + " " +
                "'" + _internal.cameraDevice + "' " +
                "2>/dev/null &"
            ];
            cameraProc.running = true;
        }

        function stopCamera() {
            if (cameraProc.running) {
                cameraProc.running = false;
                Quickshell.execDetached(["bash", "-c",
                    "pkill -f 'mpv.*" + _internal.cameraDevice + "' 2>/dev/null || true"
                ]);
            }
        }
    }

    // Control overlay
    Item {
        anchors.fill: parent
        visible: true

        // Top-right controls (revealed on hover)
        Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 8
            opacity: _hoveringControls ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            property bool _hoveringControls: flipMouseArea.containsMouse || closeMouseArea.containsMouse

            // Flip button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: flipMouseArea.containsMouse ? Appearance.colors.colSurfaceContainerHighest : "transparent"

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "flip"
                    iconSize: 16
                    color: Appearance.colors.colOnSurface
                }

                MouseArea {
                    id: flipMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        isFlipped = !isFlipped;
                        savePosition();
                    }
                }
            }

            // Close button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: closeMouseArea.containsMouse ? Appearance.colors.colErrorContainer : "transparent"

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 16
                    color: closeMouseArea.containsMouse ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSurface
                }

                MouseArea {
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        savePosition();
                        mirrorWindow.visible = false;
                        _internal.stopCamera();
                    }
                }
            }
        }

        // Hover area to reveal controls
        MouseArea {
            id: hoverRevealArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }

        // Bottom info bar (on hover)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28
            color: Qt.rgba(0, 0, 0, 0.6)
            opacity: hoverRevealArea.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "videocam"
                    iconSize: 14
                    color: "white"
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: _internal.cameraDevice + " — " + (isFlipped ? "Mirrored" : "Normal")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: "white"
                }
            }
        }
    }

    // Camera disconnected overlay
    Item {
        anchors.fill: parent
        visible: _internal.cameraUnplugged

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.8)

            Column {
                anchors.centerIn: parent
                spacing: 12

                MaterialSymbol {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "videocam_off"
                    iconSize: 48
                    color: Appearance.colors.colError
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Camera disconnected"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: "white"
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Close and reconnect camera"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                _internal.stopCamera();
                mirrorWindow.visible = false;
            }
        }
    }

    // Auto-retry when camera is reconnected
    Timer {
        id: retryTimer
        interval: 3000
        running: _internal.cameraUnplugged && mirrorWindow.visible
        onTriggered: probeProc.running = true
    }

    // Keyboard handling - Item can receive Keys events
    Item {
        id: keyboardHandler
        anchors.fill: parent
        focus: true
        visible: false

        Keys.onEscapePressed: {
            savePosition();
            mirrorWindow.visible = false;
            _internal.stopCamera();
        }
    }
}
