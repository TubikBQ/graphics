#define STEPS 100
#define FAR   30.0
#define EPS   0.001

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float box(vec3 p, vec3 size) {
    vec3 q = abs(p) - size;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float blend(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

mat2 rotate(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 scene(vec3 p) {
    float ground = p.y;
    vec3 q = p - vec3(0.0, 1.0, 0.0);
    q.xz *= rotate(iTime * 0.5);
    float d1 = box(q, vec3(0.45)) - 0.08;
    float d2 = sphere(p - vec3(1.3 * sin(iTime), 1.0, 0.0), 0.45);
    float d = blend(d1, d2, 0.4);
    return ground < d ? vec2(ground, 0.0) : vec2(d, 1.0);
}

vec2 march(vec3 start, vec3 dir) {
    float t = 0.0;
    for (int i = 0; i < STEPS; i++) {
        vec2 h = scene(start + dir * t);
        if (h.x < EPS) return vec2(t, h.y);
        t += h.x;
        if (t > FAR) break;
    }
    return vec2(-1.0);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPS, 0.0);
    return normalize(vec3(
        scene(p + e.xyy).x - scene(p - e.xyy).x,
        scene(p + e.yxy).x - scene(p - e.yxy).x,
        scene(p + e.yyx).x - scene(p - e.yyx).x));
}

float getShadow(vec3 start, vec3 dir) {
    float res = 1.0;
    float t = 0.02;
    for (int i = 0; i < 50; i++) {
        float h = scene(start + dir * t).x;
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.2);
        if (res < 0.001 || t > 10.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float angle = 0.3 * iTime;
    vec3 cam = vec3(4.0 * sin(angle), 2.0, 4.0 * cos(angle));
    vec3 target = vec3(0.0, 0.8, 0.0);
    vec3 forward = normalize(target - cam);
    vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, forward);
    vec3 dir = normalize(uv.x * right + uv.y * up + 1.8 * forward);
    vec3 sky = vec3(0.75, 0.85, 1.0);
    vec3 col = mix(sky, vec3(0.25, 0.45, 0.8), uv.y * 0.5 + 0.5);
    vec2 hit = march(cam, dir);
    if (hit.x > 0.0) {
        vec3 p = cam + dir * hit.x;
        vec3 n = getNormal(p);
        vec3 base = vec3(1.0, 0.45, 0.2);
        if (hit.y < 0.5) {
            float checker = mod(floor(p.x) + floor(p.z), 2.0);
            base = mix(vec3(0.35), vec3(0.8), checker);
        }
        vec3 light = normalize(vec3(0.6, 0.8, 0.4));
        vec3 refl = reflect(-light, n);
        float ambient = 0.15;
        float diffuse = max(dot(n, light), 0.0);
        float specular = pow(max(dot(refl, -dir), 0.0), 32.0);
        float shadow = getShadow(p + n * 0.01, light);
        col = base * (ambient + diffuse * shadow) + vec3(0.5) * specular * shadow;
        col = mix(col, sky, 1.0 - exp(-0.004 * hit.x * hit.x));
    }
    col = pow(col, vec3(1.0 / 2.2));
    fragColor = vec4(col, 1.0);
}
