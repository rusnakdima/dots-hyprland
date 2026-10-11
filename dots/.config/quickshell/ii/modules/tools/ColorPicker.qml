pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.config

Item {
    id: colorPicker

    // Start the color picking process
    function start() {
        pickerProc.command = ["bash", "-c",
            "POS=$(slurp -p 2>/dev/null); " +
            "if [ -z \"$POS\" ]; then exit 1; fi; " +
            "grim -g \"$POS\" -t ppm - 2>/dev/null | " +
            "convert - -format '%hex' txt:- 2>/dev/null | sed -n '1p'"
        ];
        pickerProc.running = true;
    }

    Process {
        id: pickerProc
        command: []
        running: false
        onExited: {
            if (exitCode !== 0) {
                console.warn("Color picker cancelled or failed");
                return;
            }
            parseColorOutput(stdout);
            colorPopup.visible = true;
        }
    }

    property string currentHex: "#000000"
    property string currentRgb: "rgb(0, 0, 0)"
    property string currentOklch: "oklch(0.0 0.0 0.0)"

    function parseColorOutput(output) {
        var hex = output.trim();
        // hex like "#ff0000"
        if (!hex || hex.length < 7) return;
        currentHex = hex;

        // Parse RGB values
        var r = parseInt(hex.slice(1, 3), 16);
        var g = parseInt(hex.slice(3, 5), 16);
        var b = parseInt(hex.slice(5, 7), 16);
        currentRgb = "rgb(" + r + ", " + g + ", " + b + ")";

        // Convert to OKLCH
        var rNorm = r / 255;
        var gNorm = g / 255;
        var bNorm = b / 255;
        var oklch = rgbToOklch(rNorm, gNorm, bNorm);
        currentOklch = "oklch(" +
            oklch[0].toFixed(3) + " " +
            oklch[1].toFixed(3) + " " +
            oklch[2].toFixed(1) + ")";
    }

    // RGB to OKLCH conversion
    function rgbToOklch(r, g, b) {
        // RGB to linear RGB
        var rLin = r > 0.04045 ? Math.pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
        var gLin = g > 0.04045 ? Math.pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
        var bLin = b > 0.04045 ? Math.pow((b + 0.055) / 1.055, 2.4) : b / 12.92;

        // Linear RGB to XYZ
        var x = 0.4124564 * rLin + 0.3575761 * gLin + 0.1804375 * bLin;
        var y = 0.2126729 * rLin + 0.7151522 * gLin + 0.0721750 * bLin;
        var z = 0.0193339 * rLin + 0.1191920 * gLin + 0.9503041 * bLin;

        // XYZ to OKLab
        var l_ = Math.cbrt(0.8189330101 * x + 0.3618667424 * y - 0.1288597137 * z);
        var m_ = Math.cbrt(0.0329845436 * x + 0.9293118715 * y + 0.0361456387 * z);
        var s_ = Math.cbrt(0.0482003018 * x + 0.2643662691 * y + 0.6338517070 * z);

        var L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
        var a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
        var b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;

        // OKLab to OKLCH
        var C = Math.sqrt(a * a + b_ * b_);
        var H = Math.atan2(b_, a) * 180 / Math.PI;
        if (H < 0) H += 360;

        return [L, C, H];
    }

    function copyValue(val) {
        Quickshell.execDetached(["bash", "-c",
            "echo -n '" + val + "' | wl-copy; " +
            "notify-send 'Copied' '" + val + "' -a 'Shell' -t 1500"
        ]);
    }

    // Color popup window
    PanelWindow {
        id: colorPopup
        visible: false

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        // Dismiss on click outside
        MouseArea {
            anchors.fill: parent
            onClicked: colorPopup.visible = false
        }

        // Popup card
        Rectangle {
            anchors.centerIn: parent
            width: contentLayout.implicitWidth + 32
            height: contentLayout.implicitHeight + 32
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.medium
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: contentLayout
                anchors.centerIn: parent
                spacing: 8

                // Color preview swatch
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 240
                    Layout.preferredHeight: 48
                    radius: Appearance.rounding.small
                    color: colorPicker.currentHex
                    border.width: 1
                    border.color: Appearance.colors.colOutlineVariant
                }

                // Hex row
                ClickableRow {
                    label: "HEX"
                    value: colorPicker.currentHex
                    onCopy: colorPicker.copyValue(colorPicker.currentHex)
                }

                // RGB row
                ClickableRow {
                    label: "RGB"
                    value: colorPicker.currentRgb
                    onCopy: colorPicker.copyValue(colorPicker.currentRgb)
                }

                // OKLCH row
                ClickableRow {
                    label: "OKLCH"
                    value: colorPicker.currentOklch
                    onCopy: colorPicker.copyValue(colorPicker.currentOklch)
                }
            }
        }

        Keys.onEscapePressed: colorPopup.visible = false
    }

    // ClickableRow sub-component
    component ClickableRow: Rectangle {
        required property string label
        required property string value
        required property var onCopy

        Layout.preferredWidth: 240
        Layout.preferredHeight: 32
        radius: Appearance.rounding.small
        color: rowMouseArea.containsMouse ? Appearance.colors.colSurfaceContainerHighest : "transparent"
        cursorShape: Qt.PointingHandCursor

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            StyledText {
                Layout.preferredWidth: 44
                text: label
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                text: value
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurface
            }
        }

        MouseArea {
            id: rowMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: onCopy()
        }
    }
}
