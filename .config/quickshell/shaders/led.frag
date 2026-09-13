#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;
    float cell;
    float dotRadius;
    vec4 led;
    float bloom;
};

layout(binding = 1) uniform sampler2D source;

float lumAt(vec2 c) {
    vec2 uv = (c + 0.5) * cell / res;
    vec4 t = texture(source, clamp(uv, vec2(0.0), vec2(1.0)));
    return max(t.r, max(t.g, t.b));
}

void main() {
    vec2 g = qt_TexCoord0 * res / cell;
    vec2 ci = floor(g);
    vec2 sub = fract(g) - 0.5;

    float s0 = lumAt(ci + vec2(-0.22, -0.22));
    float s1 = lumAt(ci + vec2( 0.22, -0.22));
    float s2 = lumAt(ci + vec2(-0.22,  0.22));
    float s3 = lumAt(ci + vec2( 0.22,  0.22));
    float s4 = lumAt(ci);
    float avg = (s0 + s1 + s2 + s3 + s4) * 0.2;
    float peak = max(max(max(s0, s1), max(s2, s3)), s4);
    float lit = clamp(avg * 1.3 + peak * 1.1, 0.0, 1.0);

    float halo = 0.0;
    halo += lumAt(ci + vec2(-1.0,  0.0));
    halo += lumAt(ci + vec2( 1.0,  0.0));
    halo += lumAt(ci + vec2( 0.0, -1.0));
    halo += lumAt(ci + vec2( 0.0,  1.0));
    halo += 0.6 * lumAt(ci + vec2(-1.0, -1.0));
    halo += 0.6 * lumAt(ci + vec2( 1.0, -1.0));
    halo += 0.6 * lumAt(ci + vec2(-1.0,  1.0));
    halo += 0.6 * lumAt(ci + vec2( 1.0,  1.0));
    halo = clamp(halo * 0.125 * bloom, 0.0, 1.0);

    float aa = 0.3 / cell;
    float d = length(sub);
    float dotMask = 1.0 - smoothstep(dotRadius - aa, dotRadius, d);

    float a = dotMask * clamp(0.02 + lit + halo * 0.7, 0.0, 1.0) + halo * 0.18;
    vec3 tint = mix(led.rgb, vec3(1.0), lit);

    fragColor = vec4(tint * a, a) * qt_Opacity;
}
