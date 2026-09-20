shader_type spatial;

uniform vec3 colore_spiaggia : source_color = vec3(0.76, 0.68, 0.48);
uniform vec3 colore_sabbia_umida : source_color = vec3(0.52, 0.44, 0.30);
uniform vec3 colore_prato : source_color = vec3(0.22, 0.38, 0.14);
uniform vec3 colore_erba_dettaglio : source_color = vec3(0.14, 0.26, 0.08);
uniform float distanza_inizio_erba = 12.0;
uniform float distanza_fine_erba = 3.5;
uniform vec3 colore_roccia_base : source_color = vec3(0.55, 0.54, 0.52);
uniform vec3 colore_roccia_chiara : source_color = vec3(0.74, 0.73, 0.70);
uniform vec3 colore_roccia_crepa : source_color = vec3(0.34, 0.33, 0.32);
uniform vec3 colore_fondovalle : source_color = vec3(0.28, 0.22, 0.17);

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

// Generatore frattale per pareti montuose erose
float fbm_falda(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i ++) {
		s += a * rumore_striature(p);
		p = p * 2.1 + vec2(1.7, 9.2);
		a * 0.5;
	}
	return s;
}

// Solchi verticali a canne d'organo e rotture vive (stile calanchi/gole)
float texture_roccia_3d(vec3 p) {
	// Canali di erosione verticali incisi (frequenza alta in orizzontale, allungata i Y)
	vec2 uv_canale = vec2(p.x * 0.95 + p.z * 0.95, p.y * 0.28);
	float v = fbm_falda(uv_canale);

	// Inverte e squadrata la cresta per simulare le gole scavate
	float gole = 1.0 - abs(v * 2.0 - 1.0);
	gole = pow(gole, 1.5);

	// Micro-porosità lapidea e granulosità da vicino
	vec2 uv_grana = vec2(p.x * 8.0 + p.z * 8.0, p.y * 6.0);
	float grana = rumore_striature(uv_grana);

	return mix(gole, grana, 0.30);
}

void fragment() {
	vec3 normale_mondo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float pendenza = normale_mondo.y;

	// 1. Solchi, pareti e balze con dominante chiara
	float pattern_roccia = texture_roccia_3d(pos_locale);

	// Gradienti a tre livelli: fessura scura, corpo base, cresta chiara
	vec3 roccia = mix(colore_roccia_crepa, colore_roccia_base, smoothstep(0.05, 0.20, pattern_roccia));
	roccia = mix(roccia, colore_roccia_chiara, smoothstep(0.25, 0.60, pattern_roccia));

	// 2. Calcolo dettaglio erba ravvicinata (inversamente proporzionale alla distanza)
	float dist_camera = length(VERTEX);
	float fade_erba = smoothstep(distanza_inizio_erba, distanza_fine_erba, dist_camera);

	// Più ci si avvicina alla parete, più la normale diventa tagliente e rugosa
	float fade_roccia_vicina = smoothstep(30.0, 3.0, dist_camera);
	float intensita_rilievo = mix(2.5, 6.5, fade_roccia_vicina);


	float eps = 0.035;
	float dx = texture_roccia_3d(pos_locale + vec3(eps, 0.0, 0.0)) - pattern_roccia;
	float dy = texture_roccia_3d(pos_locale + vec3(0.0, eps, 0.0)) - pattern_roccia;
	float dz = texture_roccia_3d(pos_locale + vec3(0.0, 0.0, eps)) - pattern_roccia;
	vec3 gradiente = vec3(dx, dy, dz);

	// Applichiamo forte rilievo sulla normale
	vec3 normale_roccia = normalize(NORMAL - gradiente * intensita_rilievo);

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

	// Applica la rugosità fisica solo alle pareti rocciose (non su spiaggia ed erba piana)
	NORMAL = mix(NORMAL, normale_roccia, (1.0 - fattore_verde) * step(quota_mare, quota_mondo));

	ALBEDO = colore_finale;
	ROUGHNESS = mix(0.98, 0.82, pattern_roccia);
	SPECULAR = 0.05;
}
