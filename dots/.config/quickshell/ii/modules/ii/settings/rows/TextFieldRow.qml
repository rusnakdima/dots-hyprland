pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services
import "../../../components/"

// Text input setting row
SettingRow {
    id: root

    property string text: path !== "" ? StateService.get(path, StateService.getDefault(path, "")) : ""
    property string placeholder
    property real fieldWidth: Appearance.font.pixelSize.normal * 16

    signal submitted(string value)

    function _submit() {
        const value = input.text.trim();
        if (value === root.text)
            return;
        if (root.path !== "")
            StateService.set(root.path, value);
        root.submitted(value);
    }

    onTextChanged: {
        if (!input.activeFocus)
            input.text = text;
    }

    Rectangle {
        Layout.preferredWidth: root.fieldWidth
        implicitHeight: Appearance.font.pixelSize.iconSmall + Appearance.sizes.spacing * 3
        radius: Appearance.rounding.roundedMd
        color: root.controlColor
        border.width: input.activeFocus ? 1 : 0
        border.color: Qt.alpha(Appearance.colors.colAccent, 0.6)
        anchors.verticalCenter: parent.verticalCenter

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: Appearance.sizes.spacing * 2
            anchors.rightMargin: Appearance.sizes.spacing * 2
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            text: root.text
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnSurface
            selectionColor: Qt.alpha(Appearance.colors.colAccent, 0.4)
            selectByMouse: true

            onEditingFinished: root._submit()
            Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape
            Keys.onEscapePressed: event => {
                text = root.text;
                focus = false;
                event.accepted = true;
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === "" && !input.activeFocus
                text: root.placeholder
                font: input.font
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            enabled: !input.activeFocus
            onClicked: input.forceActiveFocus()
        }
    }
}
