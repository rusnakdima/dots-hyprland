uniform float time;
attribute vec2 qt_VertexPosition;
varying vec2 qt_TexCoord0;

void main() {
    qt_TexCoord0 = qt_VertexPosition * 0.5 + 0.5;
    gl_Position = vec4(qt_VertexPosition, 0.0, 1.0);
}
