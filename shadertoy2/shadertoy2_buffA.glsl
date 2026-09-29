vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

vec2 point(vec2 cell, float size) {
    return 0.5 + 0.4 * sin(iTime + 6.2831 * hash(mod(cell, size)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float size = 8.0;
    vec2 p = uv * size;
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 best = vec2(8.0);
    vec2 id = vec2(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 g = vec2(float(x), float(y));
            vec2 v = g + point(i + g, size) - f;
            if (dot(v, v) < dot(best, best)) {
                best = v;
                id = hash(mod(i + g, size));
            }
        }
    }
    float edge = 8.0;
    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            vec2 g = vec2(float(x), float(y));
            vec2 v = g + point(i + g, size) - f;
            if (dot(v - best, v - best) > 0.0001) {
                edge = min(edge, dot(0.5 * (best + v), normalize(v - best)));
            }
        }
    }
    float h = smoothstep(0.0, 0.2, edge);
    vec3 col = mix(vec3(0.05, 0.30, 0.08), vec3(0.45, 0.90, 0.25), id.x);
    col *= 0.75 + 0.25 * sin(2.0 * iTime + 6.2831 * id.y);
    col *= mix(0.15, 1.0, h);
    fragColor = vec4(col, h);
}
