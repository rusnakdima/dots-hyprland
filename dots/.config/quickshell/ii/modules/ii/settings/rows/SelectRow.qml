pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services
import "../../components/"

// One-of-many setting shown as a SegmentedControl
SettingRow {
    id: root

    required property var options
    property var value: path !== "" ? StateService.get(path, StateService.getDefault(path, options[0].value)) : options[0].value

    property real segmentWidth: Appearance.font.pixelSize.normal * 6

    signal selected(var value)

    SegmentedControl {
        anchors.verticalCenter: parent.verticalCenter
        Layout.preferredWidth: root.segmentWidth * root.options.length
        options: root.options.map(o => ({
            label: o.label,
            icon: o.icon ?? ""
        }))
        currentIndex: Math.max(0, root.options.findIndex(o => o.value === root.value))
        onSelected: index => {
            const value = root.options[index].value;
            if (root.path !== "")
                StateService.set(root.path, value);
            root.selected(value);
        }
    }
}
