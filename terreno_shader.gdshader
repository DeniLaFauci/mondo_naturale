shader_type spatial;

uniform vec3 colore_erba_secca : source_color = vec3(0.36, 0.32, 0.18);
uniform vec3 colore_roccia_base : source_color = vec3(0.28, 0.26, 0.23);
uniform vec3 colore_roccia_chiara : source_color = vec3(0.48, 0.45, 0.40);

uniform float soglia_pendenza : hint_range(0.0, 1.0) = 0.70;

varying float quota_mondo;
varying vec3 pos_locale;

void vertex() {
	quota_mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	pos_locale = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float rumore_striature(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec3 normale_mondo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float pendenza = normale_mondo.y;

	vec2 uv_fianco = vec2(pos_locale.x * 0.15 + pos_locale.z * 0.15, pos_locale.y * 0.6);
	float striatura = rumore_striature(uv_fianco);
	vec3 roccia = mix(colore_roccia_base, colore_roccia_chiara, striatura);

	float fattore_cresta = smoothstep(soglia_pendenza - 0.07, soglia_pendenza + 0.07, pendenza);
	vec3 colore_finale = mix(roccia, colore_erba_secca, fattore_cresta);

	ALBEDO = colore_finale;
	ROUGHNESS = 0.92;
	SPECULAR = 0.08;
}
