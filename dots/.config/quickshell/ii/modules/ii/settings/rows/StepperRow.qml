pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.services
import "../../../components/"

// Numeric setting with −/+ buttons
SettingRow {
    id: root

    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: path !== "" ? StateService.get(path, StateService.getDefault(path, from)) : from
    property var values: []
    property var format: v => String(v)

    signal moved(real value)

    readonly property int buttonSize: Math.round(Appearance.font.pixelSize.iconSmall) + Appearance.sizes.spacing * 2

    readonly property int _index: {
        let best = 0;
        values.forEach((v, i) => {
            if (Math.abs(v - value) < Math.abs(values[best] - value))
                best = i;
        });
        return best;
    }
    readonly property bool _canDecrease: values.length > 0 ? _index > 0 : value > from
    readonly property bool _canIncrease: values.length > 0 ? _index < values.length - 1 : value < to

    function _step(direction: int) {
        const next = values.length > 0
            ? values[Math.min(values.length - 1, Math.max(0, _index + direction))]
            : Number(Math.min(to, Math.max(from, value + direction * stepSize)).toFixed(4));
        if (next === value)
            return;
        if (path !== "")
            StateService.set(path, next);
        moved(next);
    }

    // Decrease button
    RippleButton {
        size: root.buttonSize
        anchors.verticalCenter: parent.verticalCenter
        buttonIcon: "remove"
        iconSize: Appearance.font.pixelSize.normal
        baseColor: root.controlColor
        hoverColor: Appearance.colors.colLayer1Hover
        opacity: root._canDecrease ? 1 : 0.4
        onClicked: root._step(-1)
    }

    // Value display
    Text {
        Layout.preferredWidth: valueMetrics.width
        horizontalAlignment: Text.AlignHCenter
        text: root.format(root.value)
        font.family: Appearance.font.family
        font.pixelSize: Appearance.font.pixelSize.normal
        font.bold: true
        color: Appearance.colors.colOnSurface

        TextMetrics {
            id: valueMetrics
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.pixelSize.normal
            font.bold: true
            text: (root.values.length > 0
                ? root.values.map(v => root.format(v)).reduce((a, b) => b.length > a.length ? b : a, "")
                : root.format(root.to)) + "0"
        }
    }

    // Increase button
    RippleButton {
        size: root.buttonSize
        anchors.verticalCenter: parent.verticalCenter
        buttonIcon: "add"
        iconSize: Appearance.font.pixelSize.normal
        baseColor: root.controlColor
        hoverColor: Appearance.colors.colLayer1Hover
        opacity: root._canIncrease ? 1 : 0.4
        onClicked: root._step(1)
    }
}
