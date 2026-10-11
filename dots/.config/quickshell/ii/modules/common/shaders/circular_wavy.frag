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
