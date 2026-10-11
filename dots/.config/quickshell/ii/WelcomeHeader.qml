import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    // Titlebar
    visible: Config.options?.windows.showTitlebar
    Layout.fillWidth: true
    implicitHeight: Math.max(welcomeText.implicitHeight, windowControlsRow.implicitHeight)

    property alias showNextTime: showNextTimeSwitch.checked

    StyledText {
        id: welcomeText
        anchors {
            left: Config.options.windows.centerTitle ? undefined : parent.left
            horizontalCenter: Config.options.windows.centerTitle ? parent.horizontalCenter : undefined
            verticalCenter: parent.verticalCenter
            leftMargin: 12
        }
        color: Appearance.colors.colOnLayer0
        text: Translation.tr("Hi there! First things first...")
        font {
            family: Appearance.font.family.title
            pixelSize: Appearance.font.pixelSize.title
            variableAxes: Appearance.font.variableAxes.title
        }
    }

    RowLayout { // Window controls row
        id: windowControlsRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.smaller
            text: Translation.tr("Show next time")
        }

        StyledSwitch {
            id: showNextTimeSwitch
            scale: 0.6
            Layout.alignment: Qt.AlignVCenter
            onCheckedChanged: {
                if (checked) {
                    Quickshell.execDetached(["rm", root.firstRunFilePath]);
                } else {
                    Quickshell.execDetached(["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(root.firstRunFileContent)}' > '${StringUtils.shellSingleQuoteEscape(root.firstRunFilePath)}'`]);
                }
            }
        }

        RippleButton {
            buttonRadius: Appearance.rounding.full
            implicitWidth: 35
            implicitHeight: 35
            onClicked: root.close()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                text: "close"
                iconSize: 20
            }

            StyledToolTip {
                text: Translation.tr("Tip: Close a window with Super+Q")
            }
        }
    }
}
