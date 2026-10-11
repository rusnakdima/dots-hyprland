pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.services
import "../../../components/"

// On/off setting row bound to StateService path
SettingRow {
    id: root

    property bool inverted: false
    property bool checked: path !== "" ? StateService.get(path, StateService.getDefault(path, false)) !== inverted : false

    signal toggled(bool value)

    StyledSwitch {
        id: toggle
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        onToggled: {
            if (root.path !== "")
                StateService.set(root.path, checked !== root.inverted);
            root.toggled(checked);
            checked = Qt.binding(() => root.checked);
        }
    }
}
