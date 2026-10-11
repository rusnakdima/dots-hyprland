pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.services
import "../../../components/"

// Numeric setting with full-width slider below the label
SettingRow {
    id: root

    property real from: 0
    property real to: 1
    property real stepSize: 1
    property real value: path !== "" ? StateService.get(path, StateService.getDefault(path, from)) : from
    property var format: v => String(v)

    signal moved(real value)

    function _snap(v: real): real {
        const snapped = Math.round((v - from) / stepSize) * stepSize + from;
        return Number(Math.min(to, Math.max(from, snapped)).toFixed(4));
    }

    Text {
        anchors.verticalCenter: sliderRowContent.verticalCenter
        text: root.format(root.value)
        font.family: Appearance.font.family
        font.pixelSize: Appearance.font.pixelSize.small
        font.bold: true
        color: Appearance.colors.colOnSurfaceVariant
    }

    below: RowLayout {
        id: sliderRowContent
        width: parent.width

        StyledSlider {
            Layout.fillWidth: true
            from: root.from
            to: root.to
            value: root.value
            stepSize: root.stepSize
            onMoved: v => {
                const snapped = root._snap(v);
                if (root.path !== "")
                    StateService.set(root.path, snapped);
                root.moved(snapped);
            }
        }
    }
}
