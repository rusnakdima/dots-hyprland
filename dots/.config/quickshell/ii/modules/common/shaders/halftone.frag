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
