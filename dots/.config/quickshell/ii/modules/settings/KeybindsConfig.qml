/*
 * KeybindsConfig.qml — Settings page for Hyprland keybinds
 *
 * Lives in: dots-extra/quickshell/ii/modules/settings/
 *
 * Provides:
 *   - ListView of all Hyprland keybinds (from hyprctl binds -j)
 *   - Toggle switch per keybind to enable/disable
 *   - + Add button → inline form to create custom binds
 *   - Delete button on custom binds only
 *   - Double-click to edit a custom bind
 *
 * IPC: calls settingsui.setKeybindEnabled(desc, enabled)
 *                settingsui.addKeybind(bindObj)
 *                settingsui.deleteKeybind(desc)
 *                settingsui.listKeybinds()
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.services

ContentPage {
    forceWidth: true

    // ─── Load keybinds using Quickshell.execSync (works in Settings context) ───
    Component.onCompleted: {
        try {
            const { exitCode, stdout } = Quickshell.execSync(["bash", "-c", "XDG_RUNTIME_DIR=/run/user/1000 hyprctl binds -j"]);
            if (exitCode === 0 && stdout && stdout.trim()) {
                const parsed = JSON.parse(stdout.trim());
                if (Array.isArray(parsed)) {
                    keybinds = parsed;
                    console.log("[KeybindsConfig] Loaded", keybinds.length, "keybinds via execSync")
                } else {
                    console.warn("[KeybindsConfig] hyprctl returned non-array:", typeof parsed)
                    keybinds = [];
                }
            } else {
                console.warn("[KeybindsConfig] hyprctl failed or returned empty. exitCode:", exitCode, "stdout length:", stdout?.length)
                keybinds = [];
            }
        } catch (e) {
            console.warn("[KeybindsConfig] execSync error:", e.message || e)
            keybinds = [];
        }
        refreshKeybinds();
    }

    // ─── Helpers ────────────────────────────────────────────────────────────

    function formatModifiers(mods) {
        if (!mods || mods.length === 0) return "";
        return mods.join("+");
    }

    function formatBindDesc(bind) {
        if (!bind) return "";
        let mods = formatModifiers(bind.modifiers);
        let key = bind.key || "";
        return mods ? mods + "+" + key : key;
    }

    function isCustomBind(bind) {
        // Custom binds are those in hypr/custom/keybinds.lua
        // We identify them by description containing "(custom)" or being in the custom list
        // For now, show delete only for binds that have a description we track as custom
        return bind && bind._custom === true;
    }

    // ─── State ───────────────────────────────────────────────────────────

    property var keybinds: []
    property var disabledBinds: []
    property bool showAddForm: false
    property var editingBind: null  // null = add mode, object = edit mode

    // Add form fields
    property string formKey: ""
    property string formDispatcher: ""
    property string formArg: ""
    property string formDescription: ""
    property bool formModSuper: false
    property bool formModCtrl: false
    property bool formModAlt: false
    property bool formModShift: false

    // ─── JSON helpers ────────────────────────────────────────────────────────

    function getDisabledBinds(): array {
        try {
            let cfgPath = Directories.config.replace(/^file:\/\//, "") + "/illogical-impulse/config.json";
            let { exitCode, stdout } = Quickshell.execSync(["python3", "-c", "import json; d=json.load(open('" + cfgPath + "')); print(json.dumps(d.get('keybinds',{}).get('disabled',[])))"]);
            if (exitCode !== 0) return [];
            return JSON.parse(stdout.trim() || "[]");
        } catch (e) { return []; }
    }

    // ─── Refresh ──────────────────────────────────────────────────────────

    function refreshKeybinds() {
        disabledBinds = getDisabledBinds();
        // Keybinds are loaded via execSync in Component.onCompleted.
        // This function just refreshes the disabled state.
    }

    function isDisabled(desc): bool {
        return getDisabledBinds().includes(desc);
    }

    function getModifiers() {
        let mods = [];
        if (formModSuper) mods.push("SUPER");
        if (formModCtrl) mods.push("CTRL");
        if (formModAlt) mods.push("ALT");
        if (formModShift) mods.push("SHIFT");
        return mods;
    }

    function submitAddForm() {
        if (!formKey) return;
        let bindObj = {
            key: formKey,
            modifiers: getModifiers(),
            dispatcher: formDispatcher || "exec",
            arg: formArg || "",
            description: formDescription || (getModifiers().join("+") + "+" + formKey)
        };
        SettingsIpcHandler.addKeybind(bindObj);
        resetForm();
        // Refresh both keybinds list and disabled state
        refreshKeybinds();
    }

    function resetForm() {
        showAddForm = false;
        editingBind = null;
        formKey = "";
        formDispatcher = "";
        formArg = "";
        formDescription = "";
        formModSuper = false;
        formModCtrl = false;
        formModAlt = false;
        formModShift = false;
    }

    // ─── Header with + Add button ─────────────────────────────────────────

    RowLayout {
        id: header
        Layout.fillWidth: true
        Layout.bottomMargin: 8

        StyledText {
            text: Translation.tr("Keybinds")
            font.pixelSize: Appearance.font.pixelSize.title
            font.weight: Font.Medium
            Layout.fillWidth: true
        }

        RippleButton {
            implicitWidth: 36
            implicitHeight: 36
            buttonRadius: 8
            color: Appearance.m3colors.m3Primary
            onClicked: showAddForm = !showAddForm

            contentItem: RowLayout {
                anchors.centerIn: parent
                spacing: 4
                MaterialSymbol {
                    iconSize: 18
                    text: showAddForm ? "close" : "add"
                    color: Appearance.m3colors.colOnPrimary
                }
                StyledText {
                    text: Translation.tr("Add")
                    font.pixelSize: Appearance.font.pixelSize.label
                    color: Appearance.m3colors.colOnPrimary
                    visible: !showAddForm
                }
            }

            StyledToolTip {
                text: showAddForm ? Translation.tr("Cancel") : Translation.tr("Add keybind")
            }
        }
    }

    // ─── Add/Edit form ──────────────────────────────────────────────────

    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        visible: showAddForm
        radius: Appearance.rounding.m3containerMedium
        color: Appearance.m3colors.m3SurfaceContainerHigh
        border.color: Appearance.colors.colOutlineVariant
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Description
            RowLayout {
                spacing: 8
                StyledText {
                    text: Translation.tr("Description")
                    Layout.preferredWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.body
                }
                TextField {
                    id: descField
                    placeholderText: Translation.tr("e.g. Open terminal")
                    Layout.fillWidth: true
                    text: formDescription
                    onTextChanged: formDescription = text
                }
            }

            // Key
            RowLayout {
                spacing: 8
                StyledText {
                    text: Translation.tr("Key")
                    Layout.preferredWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.body
                }
                TextField {
                    id: keyField
                    placeholderText: Translation.tr("e.g. RETURN, E, F12")
                    Layout.fillWidth: true
                    text: formKey
                    onTextChanged: formKey = text
                }
            }

            // Modifiers
            RowLayout {
                spacing: 8
                StyledText {
                    text: Translation.tr("Modifiers")
                    Layout.preferredWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.body
                }
                CheckBox {
                    text: "SUPER"
                    checked: formModSuper
                    onCheckedChanged: formModSuper = checked
                }
                CheckBox {
                    text: "CTRL"
                    checked: formModCtrl
                    onCheckedChanged: formModCtrl = checked
                }
                CheckBox {
                    text: "ALT"
                    checked: formModAlt
                    onCheckedChanged: formModAlt = checked
                }
                CheckBox {
                    text: "SHIFT"
                    checked: formModShift
                    onCheckedChanged: formModShift = checked
                }
            }

            // Dispatcher
            RowLayout {
                spacing: 8
                StyledText {
                    text: Translation.tr("Action")
                    Layout.preferredWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.body
                }
                TextField {
                    id: dispatcherField
                    placeholderText: Translation.tr("e.g. exec, workspace")
                    Layout.fillWidth: true
                    text: formDispatcher
                    onTextChanged: formDispatcher = text
                }
            }

            // Argument
            RowLayout {
                spacing: 8
                StyledText {
                    text: Translation.tr("Argument")
                    Layout.preferredWidth: 90
                    font.pixelSize: Appearance.font.pixelSize.body
                }
                TextField {
                    id: argField
                    placeholderText: Translation.tr("e.g. kitty, 1")
                    Layout.fillWidth: true
                    text: formArg
                    onTextChanged: formArg = text
                }
            }

            // Submit button
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                RippleButton {
                    implicitWidth: 100
                    implicitHeight: 32
                    buttonRadius: 8
                    color: Appearance.m3colors.m3Primary
                    onClicked: submitAddForm()

                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            iconSize: 16
                            text: "check"
                            color: Appearance.m3colors.colOnPrimary
                        }
                        StyledText {
                            text: Translation.tr("Add bind")
                            font.pixelSize: Appearance.font.pixelSize.label
                            color: Appearance.m3colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }

    // ─── Keybinds list ───────────────────────────────────────────────────

    ListView {
        id: keybindsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        model: keybinds

        // Section header
        section.property: "description"
        section.criteria: ViewSection.FirstCharacter
        section.delegate: Rectangle {
            width: keybindsList.width
            height: 24
            color: Appearance.m3colors.m3SurfaceContainerHighest

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
                text: section.toUpperCase()
                font.pixelSize: Appearance.font.pixelSize.labelSmall
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        delegate: RowLayout {
            width: keybindsList.width
            height: 44

            // Enable/disable toggle
            Switch {
                id: bindSwitch
                checked: !isDisabled(modelData.description)
                onCheckedChanged: {
                    SettingsIpcHandler.setKeybindEnabled(modelData.description, checked);
                    // Update local state
                    if (checked) {
                        disabledBinds = disabledBinds.filter(d => d !== modelData.description);
                    } else {
                        if (!disabledBinds.includes(modelData.description)) {
                            disabledBinds.push(modelData.description);
                        }
                    }
                }
                Layout.preferredWidth: 44
                Layout.alignment: Qt.AlignVCenter
            }

            // Description
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: modelData.description || "(no description)"
                    font.pixelSize: Appearance.font.pixelSize.body
                    color: checked ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                }

                StyledText {
                    text: formatBindDesc(modelData) + " → " + (modelData.dispatcher || "") + (modelData.arg ? " " + modelData.arg : "")
                    font.pixelSize: Appearance.font.pixelSize.labelSmall
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            // Delete button (custom binds only — we show it for now on all non-upstream binds)
            RippleButton {
                visible: modelData.description && modelData.description.includes("(custom)")
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: 8
                color: "transparent"
                onClicked: {
                    SettingsIpcHandler.deleteKeybind(modelData.description);
                    refreshKeybinds();
                }

                contentItem: MaterialSymbol {
                    iconSize: 18
                    text: "delete"
                    color: Appearance.m3colors.m3Error
                }

                StyledToolTip {
                    text: Translation.tr("Delete this keybind")
                }
            }
        }

        // Empty state
        Component {
            id: emptyState
            Item {
                width: keybindsList.width
                height: 80

                StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("No keybinds found. Reload Hyprland to refresh.")
                    font.pixelSize: Appearance.font.pixelSize.body
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }

        Label {
            anchors.centerIn: parent
            visible: keybinds.length === 0
            text: Translation.tr("No keybinds — run hyprctl reload")
            font.pixelSize: Appearance.font.pixelSize.body
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
}
