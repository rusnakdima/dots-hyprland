import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.services
import QtQuick.Layouts

Item {
    id: root

    property bool enabled: Config.options.bar.clockShader.enabled
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    visible: enabled

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: "•"
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.longDate
        }
    }

    ShaderEffect {
        id: clockWave
        anchors.fill: parent
        visible: root.enabled

        property real time: 0
        property color color1: Appearance.colors.colPrimary
        property color color2: Appearance.colors.colSurface
        property real angle: 0.0

        property string vertexShader: "
            uniform float time;
            attribute vec2 qt_VertexPosition;
            varying vec2 qt_TexCoord0;
            void main() {
                qt_TexCoord0 = qt_VertexPosition * 0.5 + 0.5;
                gl_Position = vec4(qt_VertexPosition, 0.0, 1.0);
            }
        "

        property string fragmentShader: "
            uniform vec4 color1;
            uniform vec4 color2;
            uniform float angle;
            uniform float time;
            varying vec2 qt_TexCoord0;
            void main() {
                vec2 uv = qt_TexCoord0;
                vec2 center = vec2(0.5, 0.5);
                float dist = distance(uv, center);
                float wave = sin(dist * 20.0 - time * 3.0) * 0.5 + 0.5;
                float t = dist + wave * 0.05;
                gl_FragColor = mix(color1, color2, clamp(t, 0.0, 1.0));
            }
        "

        Timer {
            interval: 16
            repeat: true
            running: root.enabled
            onTriggered: clockWave.time = clockWave.time + 0.016
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        CalendarPopup {
            hoverTarget: mouseArea
        }
    }
}
