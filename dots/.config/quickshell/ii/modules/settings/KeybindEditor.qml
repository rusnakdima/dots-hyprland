/*
 * KeybindEditor.qml — Visual keybind editor with key capture
 *
 * Lives in: dots-extra/quickshell/ii/modules/settings/
 *
 * Provides:
 *   - Visual key input (capture key combination)
 *   - Dispatcher dropdown
 *   - Argument input
 *   - Description field
 *   - Conflict detection
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root

    // ─── Properties ────────────────────────────────────────────────────────

    property var existingBind: null
    property string bindKey: existingBind?.key || ""
    property int bindModmask: existingBind?.modmask ?? 0
    property string bindDispatcher: existingBind?.dispatcher || "exec"
    property string bindArg: existingBind?.arg || ""
    property string bindDescription: existingBind?.description || ""

    // Key capture state
    property bool capturing: false
    property string capturedKey: ""
    property int capturedModmask: 0

    // Current modifiers display
    property bool modSuper: bindModmask & 64
    property bool modCtrl: bindModmask & 4
    property bool modAlt: bindModmask & 8
    property bool modShift: bindModmask & 1

    // Signal when saved
    signal saved(var bindObj)
    signal cancelled

    // ─── Modmask Helpers ─────────────────────────────────────────────────

    function modmaskToString(mask) {
        const mods = [];
        if (mask & 1) mods.push("Shift");
        if (mask & 2) mods.push("Caps");
        if (mask & 4) mods.push("Ctrl");
        if (mask & 8) mods.push("Alt");
        if (mask & 16) mods.push("Mod2");
        if (mask & 32) mods.push("Mod3");
        if (mask & 64) mods.push("Super");
        if (mask & 128) mods.push("Mod5");
        return mods;
    }

    function modmaskFromBool() {
        let mask = 0;
        if (modSuper) mask |= 64;
        if (modCtrl) mask |= 4;
        if (modAlt) mask |= 8;
        if (modShift) mask |= 1;
        return mask;
    }

    function formatBindKey() {
        const parts = modmaskToString(bindModmask);
        if (bindKey) parts.push(bindKey.toUpperCase());
        return parts.join("+");
    }

    // ─── Conflict Detection ──────────────────────────────────────────────

    function checkConflicts() {
        if (!bindKey) return [];

        const conflicts = [];
        let allBinds = [];

        try {
            const { exitCode, stdout } = Quickshell.execSync(["hyprctl", "binds", "-j"]);
            if (exitCode === 0 && stdout && stdout.trim()) {
                allBinds = JSON.parse(stdout.trim()) || [];
            }
        } catch (e) {
            // Conflict detection is best-effort
        }

        const bindKeyUpper = bindKey.toUpperCase();

        for (let i = 0; i < allBinds.length; i++) {
            const other = allBinds[i];
            if (existingBind && other.description === existingBind.description) continue;
            if (!other.key || other.key.toUpperCase() !== bindKeyUpper) continue;

            const otherMods = other.modmask ?? 0;
            const ourMods = bindModmask;

            // Check for overlapping mods
            if (otherMods !== 0 && ourMods !== 0) {
                const overlap = (otherMods & ourMods) !== 0;
                if (overlap) {
                    conflicts.push(other);
                }
            } else if (otherMods === 0 && ourMods === 0) {
                // Both have no modifiers - direct conflict
                conflicts.push(other);
            }
        }
        return conflicts;
    }

    // ─── Common Dispatchers ───────────────────────────────────────────────

    property var commonDispatchers: [
        { display: "exec", desc: "Execute command" },
        { display: "workspace", desc: "Switch workspace" },
        { display: "movetoworkspace", desc: "Move window to workspace" },
        { display: "fullscreen", desc: "Toggle fullscreen" },
        { display: "pseudo", desc: "Toggle pseudo" },
        { display: "split", desc: "Toggle split" },
        { display: "exit", desc: "Exit Hyprland" },
        { display: "execfluid", desc: "Execute fluid animation" },
        { display: "killactive", desc: "Close window" },
        { display: "focuswindow", desc: "Focus window" },
        { display: "movetoworkspace", desc: "Move window" },
        { display: "submap", desc: "Enter submap" },
        { display: "exitsubmap", desc: "Exit submap" },
        { display: "togglefloating", desc: "Toggle floating" },
        { display: "centerwindow", desc: "Center window" },
        { display: "pin", desc: "Pin window" },
        { display: "group", desc: "Group window" },
    ]

    // ─── Layout ───────────────────────────────────────────────────────────

    implicitWidth: 500
    implicitHeight: contentColumn.implicitHeight + 60

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header
        RowLayout {
            spacing: 8
            Layout.fillWidth: true

            MaterialSymbol {
                iconSize: 24
                text: existingBind ? "edit" : "add"
                color: Appearance.m3colors.m3Primary
            }

            StyledText {
                text: existingBind ?
                    Translation.tr("Edit Keybind") :
                    Translation.tr("Add Keybind")
                font.pixelSize: Appearance.font.pixelSize.title
                font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }
        }

        // Description
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true

            StyledText {
                text: Translation.tr("Description")
                font.pixelSize: Appearance.font.pixelSize.label
                color: Appearance.colors.colOnSurfaceVariant
            }

            TextField {
                id: descField
                Layout.fillWidth: true
                placeholderText: Translation.tr("e.g. Open terminal")
                text: bindDescription
                onTextChanged: bindDescription = text
            }
        }

        // Key capture
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true

            StyledText {
                text: Translation.tr("Key Combination")
                font.pixelSize: Appearance.font.pixelSize.label
                color: Appearance.colors.colOnSurfaceVariant
            }

            // Key display area
            Rectangle {
                id: keyCaptureArea
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: 12
                color: capturing ?
                    Appearance.m3colors.m3PrimaryContainer :
                    Appearance.m3colors.m3SurfaceContainerHigh
                border.color: capturing ?
                    Appearance.m3colors.m3Primary :
                    Appearance.colors.colOutline
                border.width: capturing ? 2 : 1
                property bool containsMouse: ma.containsMouse || ma2.containsMouse

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        capturing = !capturing;
                        if (capturing) keyCaptureArea.forceActiveFocus();
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    // Modifier toggles
                    Repeater {
                        model: [
                            { label: "Super", bit: 64, active: modSuper },
                            { label: "Ctrl", bit: 4, active: modCtrl },
                            { label: "Alt", bit: 8, active: modAlt },
                            { label: "Shift", bit: 1, active: modShift },
                        ]

                        delegate: RippleButton {
                            implicitWidth: 60
                            implicitHeight: 32
                            buttonRadius: 8
                            color: modelData.active ?
                                Appearance.m3colors.m3PrimaryContainer :
                                Appearance.m3colors.m3SurfaceContainerLow
                            onClicked: {
                                bindModmask = bindModmask ^ modelData.bit;
                                updateModifiersFromMask();
                            }

                            contentItem: StyledText {
                                text: modelData.label
                                font.pixelSize: Appearance.font.pixelSize.labelSmall
                                color: modelData.active ?
                                    Appearance.colors.colOnPrimaryContainer :
                                    Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 24
                        color: Appearance.colors.colOutline
                    }

                    // Key keys
                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: modmaskToString(bindModmask)

                            delegate: KeyboardKey {
                                key: modelData
                                pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                    }

                    Loader {
                        active: bindKey !== ""
                        sourceComponent: KeyboardKey {
                            key: bindKey.toUpperCase()
                            pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }

                    Loader {
                        active: bindKey === "" && !capturing
                        sourceComponent: RowLayout {
                            spacing: 8

                            MaterialSymbol {
                                iconSize: 18
                                text: "keyboard"
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            StyledText {
                                text: Translation.tr("Click to capture key")
                                font.pixelSize: Appearance.font.pixelSize.body
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }

                    Loader {
                        active: capturing
                        sourceComponent: RowLayout {
                            spacing: 8

                            MaterialSymbol {
                                iconSize: 18
                                text: "keyboard"
                                color: Appearance.m3colors.m3Primary
                            }

                            StyledText {
                                text: Translation.tr("Press a key...")
                                font.pixelSize: Appearance.font.pixelSize.body
                                color: Appearance.m3colors.m3Primary
                            }
                        }
                    }
                }
            }

            // Clear key button
            RippleButton {
                Layout.alignment: Qt.AlignRight
                implicitWidth: 100
                implicitHeight: 28
                buttonRadius: 8
                color: "transparent"
                visible: bindKey !== ""
                onClicked: {
                    bindKey = "";
                    bindModmask = 0;
                    updateModifiersFromMask();
                }

                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        iconSize: 14
                        text: "close"
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    StyledText {
                        text: Translation.tr("Clear")
                        font.pixelSize: Appearance.font.pixelSize.labelSmall
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }

        // Key capture handler
        Loader {
            active: capturing
            sourceComponent: Item {
                // Invisible focus grabber for key capture
                Rectangle {
                    anchors.fill: keyCaptureArea
                    color: "transparent"
                    focus: true

                    Keys.onPressed: (event) => {
                        if (!capturing) return;

                        // Ignore modifier-only presses
                        const ignoredKeys = [
                            Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta,
                            Qt.Key_Super_L, Qt.Key_Super_R,
                            Qt.Key_Hyper_L, Qt.Key_Hyper_R,
                            Qt.Key_Menu,
                        ];

                        if (ignoredKeys.includes(event.key)) {
                            // Toggle modifier state
                            if (event.key === Qt.Key_Shift) bindModmask = bindModmask ^ 1;
                            else if (event.key === Qt.Key_Control) bindModmask = bindModmask ^ 4;
                            else if (event.key === Qt.Key_Alt) bindModmask = bindModmask ^ 8;
                            else if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                                bindModmask = bindModmask ^ 64;
                            }
                            updateModifiersFromMask();
                            event.accepted = true;
                            return;
                        }

                        // Get the key name
                        let keyName = "";
                        if (event.key >= Qt.Key_Space && event.key <= Qt.Key_AsciiTilde) {
                            keyName = event.text.toUpperCase();
                            if (keyName.length === 0) keyName = event.key.toString();
                        } else {
                            keyName = event.key.toString().replace("Qt.Key_", "");
                        }

                        // Clean up common key names
                        const keyMap = {
                            "Return": "RETURN",
                            "Enter": "ENTER",
                            "Escape": "ESC",
                            "Backspace": "BACKSPACE",
                            "Tab": "TAB",
                            "Space": "SPACE",
                            "Delete": "DELETE",
                            "Insert": "INSERT",
                            "Home": "HOME",
                            "End": "END",
                            "PageUp": "PGUP",
                            "PageDown": "PGDOWN",
                            "Left": "LEFT",
                            "Right": "RIGHT",
                            "Up": "UP",
                            "Down": "DOWN",
                            "F1": "F1", "F2": "F2", "F3": "F3", "F4": "F4",
                            "F5": "F5", "F6": "F6", "F7": "F7", "F8": "F8",
                            "F9": "F9", "F10": "F10", "F11": "F11", "F12": "F12",
                        };

                        if (keyMap[keyName]) keyName = keyMap[keyName];

                        bindKey = keyName;
                        capturing = false;
                        updateModifiersFromMask();
                        event.accepted = true;
                    }
                }
            }
        }

        // Dispatcher
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true

            StyledText {
                text: Translation.tr("Action")
                font.pixelSize: Appearance.font.pixelSize.label
                color: Appearance.colors.colOnSurfaceVariant
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                ComboBox {
                    id: dispatcherCombo
                    Layout.preferredWidth: 180
                    model: commonDispatchers.map(d => d.display)
                    currentIndex: {
                        const idx = commonDispatchers.findIndex(d => d.display === bindDispatcher);
                        return idx >= 0 ? idx : 0;
                    }
                    onActivated: (index) => {
                        bindDispatcher = commonDispatchers[index].display;
                    }

                    contentItem: StyledText {
                        text: dispatcherCombo.currentText
                        leftPadding: 12
                    }
                }

                TextField {
                    id: argField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Argument (e.g. kitty, 1)")
                    text: bindArg
                    onTextChanged: bindArg = text
                }
            }
        }

        // Conflict warning
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: conflictLabel.implicitHeight + 24
            radius: 12
            color: Appearance.m3colors.m3ErrorContainer
            visible: conflicts.length > 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                MaterialSymbol {
                    iconSize: 20
                    text: "warning"
                    color: Appearance.m3colors.m3OnErrorContainer
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    StyledText {
                        id: conflictLabel
                        text: Translation.tr("Conflicts with:")
                        font.pixelSize: Appearance.font.pixelSize.label
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3OnErrorContainer
                    }

                    Repeater {
                        model: conflicts

                        delegate: StyledText {
                            text: modelData.description || formatBindKeyForConflict(modelData)
                            font.pixelSize: Appearance.font.pixelSize.labelSmall
                            color: Appearance.m3colors.m3OnErrorContainer
                        }
                    }
                }
            }
        }

        property var conflicts: []

        onBindKeyChanged: {
            root.conflicts = checkConflicts();
        }
        onBindModmaskChanged: {
            root.conflicts = checkConflicts();
        }

        function formatBindKeyForConflict(bind) {
            const parts = modmaskToString(bind.modmask ?? 0);
            if (bind.key) parts.push(bind.key.toUpperCase());
            return parts.join("+");
        }

        function updateModifiersFromMask() {
            modSuper = bindModmask & 64;
            modCtrl = bindModmask & 4;
            modAlt = bindModmask & 8;
            modShift = bindModmask & 1;
        }

        // Buttons
        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: 100
                implicitHeight: 40
                buttonRadius: 20
                color: "transparent"
                border.color: Appearance.colors.colOutline
                border.width: 1
                onClicked: cancelled()

                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol {
                        iconSize: 18
                        text: "close"
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    StyledText {
                        text: Translation.tr("Cancel")
                        font.pixelSize: Appearance.font.pixelSize.label
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }

            RippleButton {
                implicitWidth: 100
                implicitHeight: 40
                buttonRadius: 20
                color: bindKey ? Appearance.m3colors.m3Primary : Appearance.m3colors.m3SurfaceContainerHigh
                enabled: bindKey !== ""
                onClicked: {
                    const bindObj = {
                        key: bindKey,
                        modmask: bindModmask,
                        dispatcher: bindDispatcher,
                        arg: bindArg,
                        description: bindDescription || formatBindKey(),
                    };
                    saved(bindObj);
                }

                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol {
                        iconSize: 18
                        text: "check"
                        color: bindKey ? Appearance.m3colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                    }

                    StyledText {
                        text: Translation.tr("Save")
                        font.pixelSize: Appearance.font.pixelSize.label
                        color: bindKey ? Appearance.m3colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }
    }
}
