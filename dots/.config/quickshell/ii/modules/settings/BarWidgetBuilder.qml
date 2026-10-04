import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    property var widgetList: Config.options.bar.customWidgets || []
    property int draggedIndex: -1

    function addWidget(type) {
        let newWidget = {
            type: type,
            enabled: true,
            position: widgetList.length,
            config: {}
        };
        widgetList.push(newWidget);
        Config.options.bar.customWidgets = widgetList;
    }

    function removeWidget(index) {
        widgetList.splice(index, 1);
        for (let i = 0; i < widgetList.length; i++) {
            widgetList[i].position = i;
        }
        Config.options.bar.customWidgets = widgetList;
    }

    function moveWidget(from, to) {
        if (from < 0 || from >= widgetList.length || to < 0 || to >= widgetList.length) return;
        let item = widgetList.splice(from, 1)[0];
        widgetList.splice(to, 0, item);
        for (let i = 0; i < widgetList.length; i++) {
            widgetList[i].position = i;
        }
        Config.options.bar.customWidgets = widgetList;
    }

    function toggleWidget(index) {
        widgetList[index].enabled = !widgetList[index].enabled;
        Config.options.bar.customWidgets = widgetList;
    }

    function exportConfig() {
        let exportData = JSON.stringify(widgetList, null, 2);
        console.log("Exporting widget config:", exportData);
    }

    function importConfig(jsonString) {
        try {
            let imported = JSON.parse(jsonString);
            if (Array.isArray(imported)) {
                Config.options.bar.customWidgets = imported;
            }
        } catch (e) {
            console.error("Failed to import config:", e);
        }
    }

    function getWidgetIcon(type) {
        switch (type) {
            case "weather": return "cloud";
            case "networkSpeed": return "wifi";
            case "cpuRam": return "memory";
            case "mediaPlayer": return "music_note";
            default: return "widgets";
        }
    }

    function getWidgetName(type) {
        switch (type) {
            case "weather": return Translation.tr("Weather");
            case "networkSpeed": return Translation.tr("Network Speed");
            case "cpuRam": return Translation.tr("CPU/RAM");
            case "mediaPlayer": return Translation.tr("Media Player");
            default: return type;
        }
    }

    ContentSection {
        icon: "add_circle"
        title: Translation.tr("Available Widgets")

        Flow {
            spacing: 8
            layout.fillWidth: true

            ConfigSwitch {
                buttonIcon: "cloud"
                text: Translation.tr("Weather")
                checked: widgetList.some(w => w.type === "weather")
                onCheckedChanged: {
                    if (checked) addWidget("weather");
                    else {
                        let idx = widgetList.findIndex(w => w.type === "weather");
                        if (idx >= 0) removeWidget(idx);
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "wifi"
                text: Translation.tr("Network Speed")
                checked: widgetList.some(w => w.type === "networkSpeed")
                onCheckedChanged: {
                    if (checked) addWidget("networkSpeed");
                    else {
                        let idx = widgetList.findIndex(w => w.type === "networkSpeed");
                        if (idx >= 0) removeWidget(idx);
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr("CPU/RAM")
                checked: widgetList.some(w => w.type === "cpuRam")
                onCheckedChanged: {
                    if (checked) addWidget("cpuRam");
                    else {
                        let idx = widgetList.findIndex(w => w.type === "cpuRam");
                        if (idx >= 0) removeWidget(idx);
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "music_note"
                text: Translation.tr("Media Player")
                checked: widgetList.some(w => w.type === "mediaPlayer")
                onCheckedChanged: {
                    if (checked) addWidget("mediaPlayer");
                    else {
                        let idx = widgetList.findIndex(w => w.type === "mediaPlayer");
                        if (idx >= 0) removeWidget(idx);
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "widget"
        title: Translation.tr("Active Widgets")

        Column {
            spacing: 8
            layout.fillWidth: true

            Repeater {
                model: widgetList.length

                Rectangle {
                    width: parent.width
                    height: 56
                    radius: Appearance.rounding.medium
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colOutlineVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 12

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignVCenter
                            text: getWidgetIcon(widgetList[index]?.type)
                            iconSize: Appearance.font.pixelSize.large
                            color: widgetList[index]?.enabled ?
                                Appearance.colors.colOnLayer1 :
                                Appearance.colors.colOutline
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            StyledText {
                                text: getWidgetName(widgetList[index]?.type)
                                color: widgetList[index]?.enabled ?
                                    Appearance.colors.colOnLayer1 :
                                    Appearance.colors.colOutline
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }

                            StyledText {
                                text: widgetList[index]?.enabled ?
                                    Translation.tr("Active") :
                                    Translation.tr("Disabled")
                                color: widgetList[index]?.enabled ?
                                    Appearance.colors.colOnLayer1 :
                                    Appearance.colors.colOutline
                                font.pixelSize: Appearance.font.pixelSize.small
                                opacity: 0.7
                            }
                        }

                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            ConfigSwitch {
                                implicitWidth: 40
                                buttonIcon: widgetList[index]?.enabled ? "visibility" : "visibility_off"
                                checked: widgetList[index]?.enabled ?? false
                                onCheckedChanged: toggleWidget(index)
                            }

                            MaterialSymbolButton {
                                icon: "delete"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colError
                                onClicked: removeWidget(index)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.OpenHandCursor
                        drag.target: widgetList[index]?.enabled ? this : null
                        drag.axis: Drag.YAxis
                    }
                }
            }

            StyledText {
                visible: widgetList.length === 0
                text: Translation.tr("No custom widgets added yet")
                color: Appearance.colors.colOutline
                font.pixelSize: Appearance.font.pixelSize.normal
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    ContentSection {
        icon: "settings"
        title: Translation.tr("Widget Settings")

        Column {
            spacing: 8
            layout.fillWidth: true

            Repeater {
                model: widgetList.length

                ContentSubsection {
                    title: getWidgetName(widgetList[index]?.type)

                    ConfigSwitch {
                        buttonIcon: "check"
                        text: Translation.tr("Enabled")
                        checked: widgetList[index]?.enabled ?? false
                        onCheckedChanged: toggleWidget(index)
                    }

                    ConfigSwitch {
                        buttonIcon: "compact"
                        text: Translation.tr("Compact mode")
                        checked: widgetList[index]?.config?.compact ?? false
                        onCheckedChanged: {
                            widgetList[index].config = widgetList[index].config || {};
                            widgetList[index].config.compact = checked;
                            Config.options.bar.customWidgets = widgetList;
                        }
                    }
                }
            }

            StyledText {
                visible: widgetList.length === 0
                text: Translation.tr("Add widgets above to configure them")
                color: Appearance.colors.colOutline
                font.pixelSize: Appearance.font.pixelSize.normal
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    ContentSection {
        icon: "file_upload"
        title: Translation.tr("Import / Export")

        ConfigRow {
            uniform: true

            ConfigButton {
                buttonIcon: "file_upload"
                text: Translation.tr("Export")
                onClicked: exportConfig()
            }

            ConfigButton {
                buttonIcon: "file_download"
                text: Translation.tr("Import")
                onClicked: {
                    console.log("Import functionality - paste JSON in console")
                }
            }
        }
    }
}
