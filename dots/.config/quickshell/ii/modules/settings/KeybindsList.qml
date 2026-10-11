/*
 * KeybindsList.qml — Categorized keybind list with search, filter, and conflict detection
 *
 * Lives in: dots-extra/quickshell/ii/modules/settings/
 *
 * Provides:
 *   - Categorized list (Window, Workspace, Media, etc.)
 *   - Search/filter by description, key, or dispatcher
 *   - Enable/disable toggle per keybind
 *   - Conflict indicator on overlapping bindings
 *   - Category navigation sidebar
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.services

Item {
    id: root
    implicitWidth: 700
    implicitHeight: 500

    // ─── Properties ────────────────────────────────────────────────────────

    property var keybinds: HyprlandKeybinds.keybinds
    property var categories: HyprlandKeybinds.keybindCategories
    property string searchQuery: ""
    property string selectedCategory: "All"
    property bool showDisabled: false

    // ─── Conflict Detection ──────────────────────────────────────────────

    function hasConflict(bind) {
        if (!bind || !bind.key) return false;
        const bindKey = bind.key.toUpperCase();
        const bindMods = bind.modmask ?? 0;

        for (let i = 0; i < keybinds.length; i++) {
            const other = keybinds[i];
            if (other === bind || !other.key) continue;

            // Same key
            if (other.key.toUpperCase() !== bindKey) continue;

            // Check if mods overlap (both have at least one common mod)
            const otherMods = other.modmask ?? 0;
            if (otherMods !== 0 && bindMods !== 0) {
                // Check for exact modmask match or overlapping mods
                const conflicting = (otherMods & bindMods) !== 0;
                if (conflicting) {
                    // Skip if they have same description (same bind)
                    if ((other.description ?? "") !== (bind.description ?? "")) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function getConflicts(bind) {
        if (!bind || !bind.key) return [];
        const bindKey = bind.key.toUpperCase();
        const bindMods = bind.modmask ?? 0;
        const result = [];

        for (let i = 0; i < keybinds.length; i++) {
            const other = keybinds[i];
            if (other === bind || !other.key) continue;

            if (other.key.toUpperCase() !== bindKey) continue;

            const otherMods = other.modmask ?? 0;
            if (otherMods !== 0 && bindMods !== 0) {
                const conflicting = (otherMods & bindMods) !== 0;
                if (conflicting && (other.description ?? "") !== (bind.description ?? "")) {
                    result.push(other);
                }
            }
        }
        return result;
    }

    // ─── Filtered/Sorted Model ─────────────────────────────────────────────

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

    function formatBind(bind) {
        if (!bind) return "";
        const mods = modmaskToString(bind.modmask ?? 0);
        const key = bind.key || "";
        return mods.length > 0 ? mods.join("+") + "+" + key : key;
    }

    function categoryFromDescription(desc) {
        if (!desc) return "Other";
        const idx = desc.indexOf(":");
        return idx > 0 ? desc.substring(0, idx) : "Other";
    }

    function matchesSearch(bind) {
        if (!searchQuery || searchQuery.trim() === "") return true;
        const query = searchQuery.toLowerCase();

        // Search in description, key, dispatcher, arg
        const desc = (bind.description || "").toLowerCase();
        const key = (bind.key || "").toLowerCase();
        const dispatcher = (bind.dispatcher || "").toLowerCase();
        const arg = (bind.arg || "").toLowerCase();

        return desc.includes(query) ||
               key.includes(query) ||
               dispatcher.includes(query) ||
               arg.includes(query) ||
               formatBind(bind).toLowerCase().includes(query);
    }

    function matchesCategory(bind) {
        if (selectedCategory === "All") return true;
        return categoryFromDescription(bind.description) === selectedCategory;
    }

    property var filteredKeybinds: {
        const filtered = [];
        for (let i = 0; i < keybinds.length; i++) {
            const bind = keybinds[i];
            if (matchesSearch(bind) && matchesCategory(bind)) {
                filtered.push(bind);
            }
        }
        return filtered;
    }

    // ─── Layout ────────────────────────────────────────────────────────────

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Category sidebar
        Rectangle {
            Layout.preferredWidth: 160
            Layout.fillHeight: true
            color: Appearance.m3colors.m3SurfaceContainerLow

            ListView {
                id: categoryList
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                model: ["All", ...categories]

                delegate: RippleButton {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: 36
                    buttonRadius: 8
                    color: modelData === selectedCategory ?
                        Appearance.m3colors.m3SecondaryContainer :
                        "transparent"
                    onClicked: selectedCategory = modelData

                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        spacing: 8

                        MaterialSymbol {
                            iconSize: 16
                            text: modelData === "All" ? "apps" : "folder"
                            color: modelData === selectedCategory ?
                                Appearance.colors.colOnSecondaryContainer :
                                Appearance.colors.colOnSurfaceVariant
                        }

                        StyledText {
                            text: modelData
                            font.pixelSize: Appearance.font.pixelSize.body
                            color: modelData === selectedCategory ?
                                Appearance.colors.colOnSecondaryContainer :
                                Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }

        // Main content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: Appearance.m3colors.m3SurfaceContainerHighest

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8

                    MaterialSymbol {
                        iconSize: 18
                        text: "search"
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Search keybinds...")
                        background: Rectangle { color: "transparent" }
                        font.pixelSize: Appearance.font.pixelSize.body
                        color: Appearance.colors.colOnSurface
                        onTextChanged: searchQuery = text
                    }

                    RippleButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: 16
                        color: searchQuery ? Appearance.m3colors.m3PrimaryContainer : "transparent"
                        visible: searchQuery.length > 0
                        onClicked: {
                            searchField.text = "";
                            searchQuery = "";
                        }

                        contentItem: MaterialSymbol {
                            iconSize: 16
                            text: "close"
                            color: searchQuery ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }

            // Toggle show disabled
            RowLayout {
                spacing: 8

                Switch {
                    id: showDisabledSwitch
                    checked: showDisabled
                    onCheckedChanged: showDisabled = checked
                }

                StyledText {
                    text: Translation.tr("Show disabled")
                    font.pixelSize: Appearance.font.pixelSize.body
                    color: Appearance.colors.colOnSurfaceVariant
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: filteredKeybinds.length + " " + Translation.tr("keybinds")
                    font.pixelSize: Appearance.font.pixelSize.label
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Keybinds list
            ListView {
                id: keybindsView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                model: filteredKeybinds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                // Section header
                section.property: "description"
                section.criteria: ViewSection.FirstCharacter
                section.delegate: Rectangle {
                    width: keybindsView.width
                    height: 28
                    color: Appearance.m3colors.m3SurfaceContainerHighest

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        text: section.toUpperCase()
                        font.pixelSize: Appearance.font.pixelSize.labelSmall
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                delegate: RowLayout {
                    width: keybindsView.width
                    height: 52
                    spacing: 12

                    // Enable/disable toggle
                    Switch {
                        id: bindSwitch
                        checked: !isKeybindDisabled(modelData.description)
                        onCheckedChanged: {
                            SettingsIpcHandler.setKeybindEnabled(modelData.description, checked);
                        }
                        Layout.preferredWidth: 44
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Key display
                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        function buildKeyLabel(bind) {
                            const parts = modmaskToString(bind.modmask ?? 0);
                            if (bind.key) parts.push(bind.key.toUpperCase());
                            return parts.join("+");
                        }

                        Repeater {
                            model: buildKeyLabel(modelData).split("+")

                            KeyboardKey {
                                key: modelData
                                pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                    }

                    // Description and action
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        StyledText {
                            text: modelData.description || "(no description)"
                            font.pixelSize: Appearance.font.pixelSize.body
                            color: bindSwitch.checked ?
                                Appearance.colors.colOnSurface :
                                Appearance.colors.colOnSurfaceVariant
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: (modelData.dispatcher || "") + (modelData.arg ? " " + modelData.arg : "")
                            font.pixelSize: Appearance.font.pixelSize.labelSmall
                            color: Appearance.colors.colOnSurfaceVariant
                            elide: Text.ElideRight
                        }
                    }

                    // Conflict indicator
                    Loader {
                        active: hasConflict(modelData)
                        Layout.preferredWidth: 24
                        Layout.alignment: Qt.AlignVCenter

                        sourceComponent: ToolTip {
                            text: Translation.tr("Conflict with:") + "\n" +
                                  getConflicts(modelData).map(b => b.description || formatBind(b)).join("\n")
                            property string tooltipText: text
                            MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: 18
                                text: "warning"
                                color: Appearance.m3colors.m3Error
                            }
                        }
                    }

                    // User bind indicator
                    Loader {
                        active: modelData._isUserBind === true
                        Layout.preferredWidth: 24
                        Layout.alignment: Qt.AlignVCenter

                        sourceComponent: MaterialSymbol {
                            iconSize: 16
                            text: "person"
                            color: Appearance.m3colors.m3Primary
                        }
                    }
                }

                // Empty state
                Component {
                    id: emptyState
                    Item {
                        width: keybindsView.width
                        height: 120

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            MaterialSymbol {
                                iconSize: 48
                                text: "search_off"
                                color: Appearance.colors.colOnSurfaceVariant
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: searchQuery ?
                                    Translation.tr("No keybinds match your search") :
                                    Translation.tr("No keybinds in this category")
                                font.pixelSize: Appearance.font.pixelSize.body
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: filteredKeybinds.length === 0
                    text: ""
                }
            }
        }
    }

    // ─── Disabled Binds State ─────────────────────────────────────────────

    function isKeybindDisabled(desc) {
        try {
            const disabled = getDisabledBindsList();
            return disabled.includes(desc);
        } catch (e) {
            return false;
        }
    }

    function getDisabledBindsList() {
        try {
            const cfgPath = CF.FileUtils.trimFileProtocol(Directories.home) + "/.config/illogical-impulse/config.json";
            const { exitCode, stdout } = Quickshell.execSync(["python3", "-c",
                "import json; d=json.load(open('" + cfgPath + "')); print(json.dumps(d.get('keybinds',{}).get('disabled',[])))"
            ]);
            if (exitCode !== 0) return [];
            return JSON.parse(stdout.trim() || "[]");
        } catch (e) {
            return [];
        }
    }
}
