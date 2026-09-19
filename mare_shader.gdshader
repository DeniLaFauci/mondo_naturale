shader_type spatial;
render_mode cull_back;

float hash_mare(vec2 p) {
return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rumore_onda(vec2 p) {
vec2 i = floor(p);
vec2 f = fract(p);
vec2 u = f * f * (3.0 - 2.0 * f);
return mix(mix(hash_mare(i), hash_mare(i + vec2(1.0, 0.0)), u.x), mix(hash_mare(i + vec2(0.0, 1.0)), hash_mare(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
float dist = length(VERTEX);
float fade_increspature = smoothstep(140.0, 15.0, dist);

vec2 uv1 = (VERTEX.xz + vec2(TIME * 1.5, TIME * 0.8)) * 0.12;
vec2 uv2 = (VERTEX.xz + vec2(-TIME * 1.1, TIME * 1.3)) * 0.18;
float onda = (rumore_onda(uv1) + rumore_onda(uv2)) * 0.5;

vec3 colore_profondo = vec3(0.05, 0.20, 0.38);
vec3 colore_cresta = vec3(0.12, 0.35, 0.52);

ALBEDO = mix(colore_profondo, colore_cresta, onda * fade_increspature);
ROUGHNESS = mix(0.28, 0.15, onda * fade_increspature);
SPECULAR = 0.4;
}
