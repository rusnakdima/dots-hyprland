import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    // Available keyboard layouts with display names
    property list var availableLayouts: [
        { displayName: "English (US)", value: "us" },
        { displayName: "English (US) Intl", value: "us,il" },
        { displayName: "Russian", value: "ru" },
        { displayName: "Ukrainian", value: "ua" },
        { displayName: "German", value: "de" },
        { displayName: "French", value: "fr" },
        { displayName: "Spanish", value: "es" },
        { displayName: "Polish", value: "pl" },
        { displayName: "Czech", value: "cz" },
        { displayName: "Swedish", value: "se" },
        { displayName: "Norwegian", value: "no" },
        { displayName: "Finnish", value: "fi" },
        { displayName: "Portuguese", value: "pt" },
        { displayName: "Japanese", value: "jp" },
        { displayName: "Korean", value: "kr" },
        { displayName: "Hebrew", value: "il" },
        { displayName: "Arabic", value: "ara" },
        { displayName: "Greek", value: "gr" },
        { displayName: "Turkish", value: "tr" },
        { displayName: "Dutch", value: "nl" },
        { displayName: "Hungarian", value: "hu" },
        { displayName: "Romanian", value: "ro" },
        { displayName: "Lithuanian", value: "lt" },
        { displayName: "Latvian", value: "lv" },
        { displayName: "Estonian", value: "ee" },
        { displayName: "Bulgarian", value: "bg" },
    ]

    // Read current layouts from config.json
    function getCurrentLayouts() {
        try {
            let raw = FileUtils.readFile(Directories.config.replace(/^file:\/\//, "") + "/illogical-impulse/config.json");
            let cfg = JSON.parse(raw);
            return cfg.keyboard && cfg.keyboard.layouts ? cfg.keyboard.layouts : ["us"];
        } catch (e) { return ["us"]; }
    }

    // Write layouts to config.json
    function setLayouts(layouts) {
        let cfgPath = Directories.config.replace(/^file:\/\//, "") + "/illogical-impulse/config.json";
        let escapedPath = cfgPath.replace(/"/g, '\\"');
        let layoutsJson = JSON.stringify(layouts);
        let script = "python3 -c \"import json; cfg=json.load(open(\\\"" + escapedPath + "\\\")); cfg['keyboard']['layouts']=" + layoutsJson + "; json.dump(cfg,open(\\\"" + escapedPath + "\\\"+'.tmp','w'),indent=2); import os; os.replace(\\\"" + escapedPath + "\\\"+'.tmp',\\\"" + escapedPath + "\\\")\"";
        Quickshell.execDetached(["bash", "-c", script]);
        Config.options.keyboard.layouts = layouts;
    }

    // Write active (first) layout to plain text file for hyprland general.lua
    function setActiveLayout(layout) {
        let script = "mkdir -p ~/.config/illogical-impulse && echo '" + layout + "' > ~/.config/illogical-impulse/kb_layout.txt";
        Quickshell.execDetached(["bash", "-c", script]);
    }

    ContentSection {
        title: Translation.tr("Keyboard Layout")

        // Active layout indicator
        ConfigRow {
            ConfigSpinBox {
                buttonText: Translation.tr("Active layout")
                // Show first layout from the layouts array
                value: 0
                from: 0
                to: Math.max(0, Config.options.keyboard.layouts.length - 1)
                stepSize: 1
                enabled: Config.options.keyboard.layouts.length > 1
                onValueChanged: {
                    let newActive = Config.options.keyboard.layouts[value];
                    if (newActive !== undefined) {
                        setActiveLayout(newActive);
                    }
                }
            }
        }

        // Layout list
        ContentSubsection {
            title: Translation.tr("Installed layouts")

            // Current layouts display
            Repeater {
                id: layoutRepeater
                model: Config.options.keyboard.layouts

                ConfigRow {
                    property int idx: index

                    RippleButton {
                        buttonText: {
                            let entry = availableLayouts.find(e => e.value === modelData);
                            return entry ? entry.displayName : modelData;
                        }
                        Layout.fillWidth: true
                    }

                    RippleButton {
                        buttonText: Translation.tr("Remove")
                        enabled: Config.options.keyboard.layouts.length > 1
                        onClicked: {
                            let current = Config.options.keyboard.layouts.slice();
                            current.splice(idx, 1);
                            setLayouts(current);
                        }
                    }
                }
            }

            // Add layout selector
            ConfigRow {
                Layout.column: 1
                Layout.fillWidth: true

                ConfigSelectionArray {
                    id: addLayoutSelector
                    currentValue: "us"
                    options: availableLayouts.map(e => ({ displayName: e.displayName, value: e.value }))
                    onSelected: newValue => {
                        let current = Config.options.keyboard.layouts.slice();
                        if (!current.includes(newValue)) {
                            current.push(newValue);
                            setLayouts(current);
                        }
                    }
                }

                RippleButton {
                    buttonText: Translation.tr("Add layout")
                    onClicked: {
                        let newLayout = addLayoutSelector.currentValue;
                        let current = Config.options.keyboard.layouts.slice();
                        if (!current.includes(newLayout)) {
                            current.push(newLayout);
                            setLayouts(current);
                        }
                    }
                }
            }
        }

        // Keybind section
        ContentSubsection {
            title: Translation.tr("Switch keybind")

            ConfigRow {
                RippleButton {
                    buttonText: Config.options.keyboard.switchKeybind
                    Layout.fillWidth: true
                    StyledToolTip {
                        buttonText: Translation.tr("Current keybind for layout switching. Change in keybinds.lua or restart Quickshell.")
                    }
                }

                RippleButton {
                    buttonText: Translation.tr("Test")
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", "hyprctl switchxkblayout next"]);
                    }
                }
            }
        }
    }

    // Initialize active layout file on load
    Component.onCompleted: {
        let layouts = getCurrentLayouts();
        if (layouts.length > 0) {
            setActiveLayout(layouts[0]);
        }
    }
}
