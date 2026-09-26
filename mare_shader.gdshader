shader_type spatial;
render_mode cull_back;

uniform vec3 direzione_sole = vec3(0.0, 1.0, 0.0);
uniform vec3 colore_luce_sole = vec3(1.0, 0.95, 0.85);

varying vec3 pos_mondo;

void vertex() {
	pos_mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

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

	// L'acqua si adatta alla luce del cielo: blu intenso di giorno, dorata/scura al tramonto e di notte
	float quota_s = clamp(direzione_sole.y, -0.2, 1.0);
	float fattore_giorno_mare = smoothstep(-0.05, 0.25, quota_s);
	vec3 base_profonda = mix(vec3(0.01, 0.03, 0.06), colore_profondo, fattore_giorno_mare);
	vec3 base_cresta = mix(vec3(0.02, 0.05, 0.10), colore_cresta, fattore_giorno_mare);	

	// L'acqua si scurisce naturalmente quando cala la notte;
	float fattore_luce = smoothstep(-0.05, 0.20, quota_s);

	vec3 mare_notturno = vec3(0.005, 0.010, 0.020);
	vec3 mare_diurno = mix(colore_profondo, colore_cresta, onda * fade_increspature);
	vec3 colore_acqua = mix(mare_notturno, mare_diurno, fattore_luce);

	// Vettore vista in coordinate mondo verso il frammento
	vec3 dir_s = normalize(direzione_sole);

	// Vettore vista traformato in coordinate mondo (funziona in modo speculare a 360°)
	vec3 dir_v_mondo = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 norm_mondo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Half-vector tra vista e luce del sole
	vec3 dir_h = normalize(dir_s + dir_v_mondo);
	float NdotH = max(dot(norm_mondo, dir_h), 0.0);

	// Allineamento azimutale sul piano orizzontale (asse XZ)
	// Garantisce simmetria perfetta sia che il sola sia a Est (alba) sia che sia a Ovest (tramonto)
	float allineamento_orizzontale = max(dot(normalize(dir_v_mondo.xz), normalize(dir_s.xz)), 0.0);

	// Più il sole è basso, più la scia si stende e si allarga sull'acqua
	float alt_sole = clamp(dir_s.y, 0.0, 1.0);

	// Più il sole cala, più l'esponente si abbassa per consentire all'onda di catturare luce radente
	float esponente_radente = mix(8.0, 9.0, alt_sole);
	float spec_base = pow(NdotH, esponente_radente);

	// Rinforzo di Fesnel radente: a bassi angoli l'acqua diventa quasi uno specchio perfetto
	float fresnel_sole = pow(clamp(1.0 - dir_v_mondo.y, 0.0, 1.0), 3.0);
	float scia_allungata = mix(spec_base, pow(allineamento_orizzontale, 16.0) * NdotH, 0.55 + fresnel_sole * 0.35);

	// Tinta crepuscolare: arancio fuoco al tramonto/alba
	vec3 tinta_sole = mix(vec3(1.0, 0.38, 0.03), colore_luce_sole, smoothstep(0.02, 0.28, alt_sole));

	// La scia rimane visibile finché l'intero disco solare non sprofonda sotto l'orizzonte (-0.08)
	float visibilita_sole = smoothstep(-0.08, 0.02, dir_s.y);
	vec3 scia_solare = tinta_sole * scia_allungata * visibilita_sole * 3.6;

	ALBEDO = colore_acqua;
	ROUGHNESS = mix(0.18, 0.08, onda * fade_increspature);
	SPECULAR = 0.5;
	EMISSION = scia_solare;
}
