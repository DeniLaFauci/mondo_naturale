shader_type spatial;

uniform vec3 colore_spiaggia : source_color = vec3(0.76, 0.68, 0.48);
uniform vec3 colore_prato : source_color = vec3(0.22, 0.38, 0.14);
uniform vec3 colore_roccia_base : source_color = vec3(0.28, 0.25, 0.22);
uniform vec3 colore_roccia_chiara : source_color = vec3(0.48, 0.44, 0.38);
uniform vec3 colore_fondovalle : source_color = vec3(0.12, 0.18, 0.22);

uniform float quota_mare = 1.8;
uniform float soglia_pendenza : hint_range(0.0, 1.0) = 0.68;

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

	// 1. Striature pareti rocciose
	vec2 uv_fianco = vec2(pos_locale.x * 0.15 + pos_locale.z * 0.15, pos_locale.y * 0.5);
	vec3 roccia = mix(colore_roccia_base, colore_roccia_chiara, rumore_striature(uv_fianco));

	// 2. Miscela roccia / prato in base all'inclinazione
	float fattore_verde = smoothstep(soglia_pendenza - 0.08, soglia_pendenza + 0.08, pendenza);
	vec3 terra = mix(roccia, colore_prato, fattore_verde);

	// 3. Fascia della spiaggia (tra battiglia e inizio collina)
	float fattore_sabbia = smoothstep(quota_mare - 0.5, quota_mare + 0.5, quota_mondo);
	vec3 terra_e_spiaggia = mix(colore_spiaggia, terra, fattore_sabbia);

	// 4. Fondale sommerso scuro e graduale
	float fattore_sommerso = smoothstep(-6.0, quota_mare - 0.5, quota_mondo);
	vec3 colore_finale = mix(colore_fondovalle, terra_e_spiaggia, fattore_sommerso);

	ALBEDO = colore_finale;
	ROUGHNESS = 0.88;
	SPECULAR = 0.10;
}
