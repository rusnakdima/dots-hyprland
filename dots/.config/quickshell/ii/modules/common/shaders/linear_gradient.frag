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
