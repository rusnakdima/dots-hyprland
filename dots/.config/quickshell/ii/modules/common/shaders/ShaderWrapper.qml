import QtQuick

Item {
    id: root

    property string shaderName: "linear_gradient"
    property color color1: Appearance.colors.colPrimary
    property color color2: Appearance.colors.colSurface
    property real angle: 45.0
    property real time: 0.0
    property bool shaderValid: true
    property bool useShader: true

    Rectangle {
        id: fallbackRect
        anchors.fill: parent
        color: root.color1
        visible: !root.useShader || !root.shaderValid
    }

    ShaderEffect {
        id: shaderEffect
        anchors.fill: parent
        visible: root.useShader && root.shaderValid

        property real time: root.time
        property real angle: root.angle
        property color color1: root.color1
        property color color2: root.color2

        // Common vertex shader (fullscreen quad)
        property string vertexShader: "
            uniform float time;
            attribute vec2 qt_VertexPosition;
            varying vec2 qt_TexCoord0;
            void main() {
                qt_TexCoord0 = qt_VertexPosition * 0.5 + 0.5;
                gl_Position = vec4(qt_VertexPosition, 0.0, 1.0);
            }
        "

        // Fragment shader selected by shaderName
        property string fragmentShader: {
            if (shaderName === "circular_wavy") return circularWavyFrag;
            if (shaderName === "halftone") return halftoneFrag;
            if (shaderName === "linear_gradient") return linearGradientFrag;
            if (shaderName === "radial_gradient") return radialGradientFrag;
            if (shaderName === "unified_pass1") return unifiedPass1Frag;
            if (shaderName === "unified_pass2") return unifiedPass2Frag;
            if (shaderName === "wavyline") return wavylineFrag;
            return linearGradientFrag;
        }

        // linear_gradient
        property string linearGradientFrag: "
            uniform vec4 color1;
            uniform vec4 color2;
            uniform float angle;
            uniform float time;
            varying vec2 qt_TexCoord0;
            void main() {
                vec2 uv = qt_TexCoord0;
                float rad = angle * 0.01745329251;
                float t = dot(uv - 0.5, vec2(cos(rad), sin(rad))) + 0.5;
                t = clamp(t, 0.0, 1.0);
                gl_FragColor = mix(color1, color2, t);
            }
        "

        // circular_wavy
        property string circularWavyFrag: "
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

        // halftone
        property string halftoneFrag: "
            uniform vec4 color1;
            uniform vec4 color2;
            uniform float angle;
            uniform float time;
            varying vec2 qt_TexCoord0;
            void main() {
                vec2 uv = qt_TexCoord0;
                float rad = angle * 0.01745329251;
                vec2 dir = vec2(cos(rad), sin(rad));
                float projected = dot(uv - 0.5, dir) + 0.5;
                float dots = sin(projected * 40.0 + time) * 0.5 + 0.5;
                dots = step(0.5, dots);
                gl_FragColor = mix(color1, color2, dots);
            }
        "

        // radial_gradient
        property string radialGradientFrag: "
            uniform vec4 color1;
            uniform vec4 color2;
            uniform float angle;
            uniform float time;
            varying vec2 qt_TexCoord0;
            void main() {
                vec2 uv = qt_TexCoord0;
                vec2 center = vec2(0.5, 0.5);
                float dist = distance(uv, center) * 2.0;
                dist = clamp(dist, 0.0, 1.0);
                gl_FragColor = mix(color1, color2, dist);
            }
        "

        // unified_pass1
        property string unifiedPass1Frag: "
            uniform vec4 color1;
            uniform vec4 color2;
            uniform float angle;
            uniform float time;
            varying vec2 qt_TexCoord0;
            void main() {
                vec2 uv = qt_TexCoord0;
                float rad = angle * 0.01745329251;
                vec2 dir = vec2(cos(rad), sin(rad));
                float projected = dot(uv - 0.5, dir) + 0.5;
                float blur = smoothstep(0.0, 1.0, projected);
                gl_FragColor = mix(color1, color2, blur);
            }
        "

        // unified_pass2
        property string unifiedPass2Frag: "
            uniform vec4 color1;
            uniform vec4 color2;
            uniform float angle;
            uniform float time;
            varying vec2 qt_TexCoord0;
            void main() {
                vec2 uv = qt_TexCoord0;
                vec2 center = vec2(0.5, 0.5);
                float dist = distance(uv, center) * 2.0;
                float glow = 1.0 - smoothstep(0.0, 0.8, dist);
                gl_FragColor = mix(color1, color2, glow * 0.5);
            }
        "

        // wavyline
        property string wavylineFrag: "
            uniform vec4 color1;
            uniform vec4 color2;
            uniform float angle;
            uniform float time;
            varying vec2 qt_TexCoord0;
            void main() {
                vec2 uv = qt_TexCoord0;
                float rad = angle * 0.01745329251;
                float projected = dot(uv - 0.5, vec2(-sin(rad), cos(rad))) + 0.5;
                float wave = sin(projected * 30.0 + time * 2.0) * 0.5 + 0.5;
                float line = smoothstep(0.45, 0.5, wave) - smoothstep(0.5, 0.55, wave);
                gl_FragColor = mix(color1, color2, line);
            }
        "

        Timer {
            id: animationTimer
            interval: 16
            repeat: true
            running: root.useShader && (root.shaderName === "circular_wavy" || root.shaderName === "wavyline")
            onTriggered: {
                shaderEffect.time = shaderEffect.time + 0.016;
            }
        }
    }
}
