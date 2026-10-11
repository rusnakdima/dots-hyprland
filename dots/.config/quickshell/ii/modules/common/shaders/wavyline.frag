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
