import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property bool expanded: false
    property int maxItems: 10

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            MaterialSymbol {
                text: "content_paste"
                iconSize: 18
            }
            StyledText {
                text: Translation.tr("Clipboard")
                font.pixelSize: Appearance.font?.pixelSize?.body ?? 14
            }
            Item { Layout.fillWidth: true }
            RippleButton {
                id: toggleBtn
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                contentItem: MaterialSymbol {
                    text: expanded ? "chevron_up" : "chevron_down"
                    iconSize: 18
                }
                onClicked: expanded = !expanded
            }
        }

        // Clipboard items
        ListView {
            id: clipboardList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: expanded ? 150 : 0
            visible: expanded
            clip: true
            model: Cliphist.entries.slice(0, maxItems)

            delegate: RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 4

                MaterialSymbol {
                    text: Cliphist.entryIsImage(modelData) ? "image" : "content_copy"
                    iconSize: 14
                    opacity: 0.7
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Cliphist.entryIsImage(modelData) 
                        ? Translation.tr("[Image]")
                        : String(modelData).substring(0, 40)
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    opacity: 0.8
                }
                RippleButton {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    contentItem: MaterialSymbol {
                        text: "content_paste"
                        iconSize: 14
                    }
                    onClicked: {
                        Cliphist.copy(modelData)
                    }
                }
            }

            placeholder: PagePlaceholder {
                shown: clipboardList.count === 0
                icon: "content_paste_off"
                description: Translation.tr("Empty")
            }
        }
    }
}
