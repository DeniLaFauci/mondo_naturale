shader_type spatial;

uniform vec3 colore_spiaggia : source_color = vec3(0.76, 0.68, 0.48);
uniform vec3 colore_sabbia_umida : source_color = vec3(0.52, 0.44, 0.30);
uniform vec3 colore_prato : source_color = vec3(0.22, 0.38, 0.14);
uniform vec3 colore_erba_dettaglio : source_color = vec3(0.14, 0.26, 0.08);
uniform float distanza_inizio_erba = 12.0;
uniform float distanza_fine_erba = 3.5;
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

	// 2. Calcolo dettaglio erba ravvicinata (inversamente proporzionale alla distanza)
	float dist_camera = length(VERTEX);
	float fade_erba = smoothstep(distanza_inizio_erba, distanza_fine_erba, dist_camera);

	// Trama ad alta frequenza per fili e ciuffi (solo da vicino)
	vec2 uv_erba = pos_locale.xz * 14.0;
	float micro_trama = rumore_striature(uv_erba);
	vec3 prato_dettagliato = mix(colore_prato, colore_erba_dettaglio, micro_trama * 0.45);
	vec3 prato_finale = mix(colore_prato, prato_dettagliato, fade_erba);

	// Miscela roccia / prato
	float fattore_verde = smoothstep(soglia_pendenza - 0.08, soglia_pendenza + 0.08, pendenza);
	vec3 terra = mix(roccia, prato_finale, fattore_verde);

	// 3. Spiaggia ampliata con grana visibile da vicino
	vec2 uv_sabbia = pos_locale.xz * 20.0;
	float micro_sabbia = rumore_striature(uv_sabbia);
	vec3 sabbia_dettaglio = mix(colore_spiaggia, colore_sabbia_umida, micro_sabbia * 0.35);
	vec3 sabbia_finale = mix(colore_spiaggia, sabbia_dettaglio, fade_erba);

	// Allarghiamo la fascia della spiaggia fino a quota_mare + 5.5 metri
	float fattore_sabbia = smoothstep(quota_mare - 0.2, quota_mare + 5.5, quota_mondo);
	vec3 terra_e_spiaggia = mix(sabbia_finale, terra, fattore_sabbia);

	// 4. Schiuma della risacca che pulsa sulla battiglia (onda che sale e scende)
	float onda_battiglia = sin(TIME * 2.2 + pos_locale.x * 0.25 + pos_locale.z * 0.25) * 0.35;
	float fascia_schiuma = smoothstep(0.18, 0.0, abs(quota_mondo - (quota_mare + onda_battiglia)));
	terra_e_spiaggia = mix(terra_e_spiaggia, vec3(0.92, 0.95, 0.98), fascia_schiuma * 0.75);

	// 5. Fondale sommerso graduale
	float fattore_sommerso = smoothstep(-6.0, quota_mare - 0.3, quota_mondo);
	vec3 colore_finale = mix(colore_fondovalle, terra_e_spiaggia, fattore_sommerso);

	ALBEDO = colore_finale;
	ROUGHNESS = 0.88;
	SPECULAR = 0.10;
}
