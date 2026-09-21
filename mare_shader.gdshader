shader_type spatial;
render_mode cull_back;

uniform vec3 direzione_sole = vec3(0.0, 1.0, 0.0);
uniform vec3 colore_luce_sole = vec3(1.0, 0.95, 0.85);

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
	vec3 colore_acqua = mix(base_profonda, base_cresta, onda * fade_increspature);

	// Riflesso solare: scia allungata sull'acqua specialmente al tramonto (luce radente)
	vec3 dir_s = normalize(direzione_sole);
	vec3 dir_v = normalize(VIEW);
	vec3 dir_h = normalize(dir_s + dir_v);

	// Più il sole è basso, più la scia speculare si stende orizzontalmente sull'orizzonte
	float esponente_spec = mix(32.0, 140.0, clamp(dir_s.y * 2.0, 0.0, 1.0));
	float spec_intensita = pow(max(dot(NORMAL, dir_h), 0.0), esponente_spec);

	// Il riflesso resta visibile finché il sole tocca l'orizzonte (-0.05)
	float visibilita_riflesso = smoothstep(-0.06, 0.08, dir_s.y);
	vec3 riflesso_solare = colore_luce_sole * spec_intensita * visibilita_riflesso * 3.5;

	ALBEDO = colore_acqua;
	ROUGHNESS = mix(0.18, 0.08, onda * fade_increspature);
	SPECULAR = 0.6;
	EMISSION = riflesso_solare;
}
