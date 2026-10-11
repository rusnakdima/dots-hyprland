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
