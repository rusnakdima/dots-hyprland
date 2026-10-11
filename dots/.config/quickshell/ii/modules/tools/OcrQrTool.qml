pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.config

Item {
    id: ocrQrTool

    // Start the OCR/QR scanning process
    function start() {
        // Step 1: Get region with slurp
        captureProc.command = ["bash", "-c",
            "REGION=$(slurp -r 2>/dev/null); " +
            "if [ -z \"$REGION\" ]; then exit 1; fi; " +
            "TEMP=$(mktemp /tmp/ocr-qr-XXXXXX.png); " +
            "grim -g \"$REGION\" \"$TEMP\" 2>/dev/null; " +
            "echo \"$TEMP\""
        ];
        captureProc.running = true;
    }

    Process {
        id: captureProc
        command: []
        running: false
        onExited: {
            if (exitCode !== 0) {
                console.warn("OCR/QR: Region selection cancelled");
                return;
            }
            var tempFile = stdout.trim();
            runOcrQr(tempFile);
        }
    }

    property string ocrText: ""
    property string qrText: ""
    property bool isProcessing: false
    property bool hasResults: false
    property string errorMessage: ""

    function runOcrQr(tempFile) {
        isProcessing = true;
        errorMessage = "";

        // Run OCR and QR in parallel, then combine results
        ocrQrProc.command = ["bash", "-c",
            "TEMP='" + tempFile + "'; " +
            "OCR=$(tesseract \"$TEMP\" stdout -l eng 2>/dev/null | tr -d '\\0' | sed '/^$/d'); " +
            "QR=$(zbarimg \"$TEMP\" 2>/dev/null | grep -oP '(?<=data:).*' | tr -d '\\n'); " +
            "rm -f \"$TEMP\"; " +
            "echo \"OCR_RESULT:\"; " +
            "echo \"$OCR\"; " +
            "echo \"QR_RESULT:\"; " +
            "echo \"$QR\""
        ];
        ocrQrProc.running = true;
    }

    Process {
        id: ocrQrProc
        command: []
        running: false
        onExited: {
            isProcessing = false;
            parseResults(stdout);
        }
    }

    function parseResults(output) {
        var lines = output.split("\n");
        var inOcr = false;
        var inQr = false;
        var ocrLines = [];
        var qrLines = [];

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "OCR_RESULT:") {
                inOcr = true;
                inQr = false;
            } else if (line === "QR_RESULT:") {
                inOcr = false;
                inQr = true;
            } else if (inOcr && line.length > 0) {
                ocrLines.push(line);
            } else if (inQr && line.length > 0) {
                qrLines.push(line);
            }
        }

        ocrText = ocrLines.join("\n").trim();
        qrText = qrLines.join("").trim();

        if (ocrText.length === 0 && qrText.length === 0) {
            errorMessage = "No text or QR code detected in the selected region.";
        }

        hasResults = ocrText.length > 0 || qrText.length > 0;
        if (hasResults) {
            resultsPopup.visible = true;
        } else if (errorMessage.length > 0) {
            errorPopup.visible = true;
            errorDismissTimer.start();
        }
    }

    function copyAll() {
        var allText = "";
        if (ocrText.length > 0) allText += ocrText;
        if (qrText.length > 0) {
            if (allText.length > 0) allText += "\n\n";
            allText += qrText;
        }
        Quickshell.execDetached(["bash", "-c",
            "echo -n '" + allText.replace(/'/g, "'\\''") + "' | wl-copy; " +
            "notify-send 'Copied' 'Text copied to clipboard' -a 'Shell' -t 1500"
        ]);
    }

    function copyOcr() {
        Quickshell.execDetached(["bash", "-c",
            "echo -n '" + ocrText.replace(/'/g, "'\\''") + "' | wl-copy; " +
            "notify-send 'OCR Copied' 'Text copied to clipboard' -a 'Shell' -t 1500"
        ]);
    }

    function copyQr() {
        Quickshell.execDetached(["bash", "-c",
            "echo -n '" + qrText.replace(/'/g, "'\\''") + "' | wl-copy; " +
            "notify-send 'QR Copied' 'Code copied to clipboard' -a 'Shell' -t 1500"
        ]);
    }

    // Results popup
    PanelWindow {
        id: resultsPopup
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

        // Dismiss on click
        MouseArea {
            anchors.fill: parent
            onClicked: resultsPopup.visible = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(500, parent.width - 40)
            height: Math.min(400, parent.height - 40)
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.medium
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Title
                RowLayout {
                    Layout.preferredHeight: 32
                    spacing: 8

                    MaterialSymbol {
                        text: "document_scanner"
                        iconSize: 20
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: "OCR / QR Results"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurface
                    }

                    Item { Layout.fillWidth: true }

                    // Close button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: "transparent"
                        cursorShape: Qt.PointingHandCursor

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 16
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: resultsPopup.visible = false
                        }
                    }
                }

                // Content
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 12

                        // OCR Section
                        Rectangle {
                            Layout.fillWidth: true
                            visible: ocrText.length > 0
                            color: Appearance.colors.colSurfaceContainerHigh
                            radius: Appearance.rounding.small

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.preferredHeight: 24
                                    spacing: 8

                                    StyledText {
                                        text: "Text (OCR)"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnSurfaceVariant
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Copy OCR button
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: "transparent"
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                        color: ocrCopyMouseArea.containsMouse ? Appearance.colors.colSurfaceContainerHighest : "transparent"

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "copy"
                                            iconSize: 14
                                            color: Appearance.colors.colOnSurfaceVariant
                                        }

                                        MouseArea {
                                            id: ocrCopyMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: ocrQrTool.copyOcr()
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: ocrQrTool.ocrText
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurface
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        // QR/Barcode Section
                        Rectangle {
                            Layout.fillWidth: true
                            visible: qrText.length > 0
                            color: Appearance.colors.colSurfaceContainerHigh
                            radius: Appearance.rounding.small

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.preferredHeight: 24
                                    spacing: 8

                                    StyledText {
                                        text: "QR / Barcode"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnSurfaceVariant
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Copy QR button
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: "transparent"
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                        color: qrCopyMouseArea.containsMouse ? Appearance.colors.colSurfaceContainerHighest : "transparent"

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "copy"
                                            iconSize: 14
                                            color: Appearance.colors.colOnSurfaceVariant
                                        }

                                        MouseArea {
                                            id: qrCopyMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: ocrQrTool.copyQr()
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: ocrQrTool.qrText
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurface
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }

                // Copy All button
                Rectangle {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimary
                    cursorShape: Qt.PointingHandCursor
                    visible: hasResults

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialSymbol {
                            text: "content_copy"
                            iconSize: 16
                            color: Appearance.colors.colOnPrimary
                        }

                        StyledText {
                            text: "Copy All"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: ocrQrTool.copyAll()
                    }
                }
            }
        }

        Keys.onEscapePressed: resultsPopup.visible = false
    }

    // Error/no-results popup
    PanelWindow {
        id: errorPopup
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

        MouseArea {
            anchors.fill: parent
            onClicked: errorPopup.visible = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: 160
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.medium
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "search_off"
                    iconSize: 40
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: ocrQrTool.errorMessage.length > 0 ? ocrQrTool.errorMessage : "Nothing detected"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurface
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Press Esc or click to dismiss"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }

        Keys.onEscapePressed: errorPopup.visible = false
    }

    Timer {
        id: errorDismissTimer
        interval: 3000
        running: false
        onTriggered: {
            if (!hasResults) {
                errorPopup.visible = false;
            }
        }
    }
}
