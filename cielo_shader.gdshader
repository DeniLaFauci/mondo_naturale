shader_type sky;

uniform vec3 direzione_sole = vec3(0.0, 1.0, 0.0);
uniform float velocita_vento = 0.02;

// Colori Giorno
uniform vec3 cielo_zenith_giorno : source_color = vec3(0.18, 0.42, 0.78);
uniform vec3 cielo_orizzonte_giorno : source_color = vec3(0.69, 0.72, 0.85);

// Colori Tramonto / Alba (lato sole)
uniform vec3 cielo_zenith_tramonto : source_color = vec3(0.14, 0.16, 0.35);
uniform vec3 cielo_orizzonte_tramonto : source_color = vec3(0.92, 0.38, 0.10);

// Colore lato opposto al sole durante l'imbrunire (antielio / notte anticipata)
uniform vec3 cielo_orizzonte_opposto : source_color = vec3(0.25, 0.18, 0.32);

// Colori Notte
uniform vec3 cielo_zenith_notte : source_color = vec3(0.01, 0.015, 0.03);
uniform vec3 cielo_orizzonte_notte : source_color = vec3(0.03, 0.05, 0.10);

float hash_cielo(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rumore_cielo(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash_cielo(i), hash_cielo(i + vec2(1.0, 0.0)), u.x), mix(hash_cielo(i + vec2(0.0, 1.0)), hash_cielo(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * rumore_cielo(p);
		p = p * 2.1 + vec2(1.7, 3.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir_s = normalize(direzione_sole);
	float quota_sole = dir_s.y;

	// Calcola l'azimuth: +1 se guardi verso il sole, 0 laterale, -1 se guardi dalla parte opposta
	vec2 occhio_piano = normalize(EYEDIR.xz + vec2(0.0001));
	vec2 sole_piano = normalize(dir_s.xz + vec2(0.0001));
	float verso_sole = clamp(dot(occhio_piano, sole_piano) * 0.5 + 0.5, 0.0, 1.0);

	float giorno_puro = smoothstep(0.02, 0.30, quota_sole);
	float notte_pura = 1.0 - smoothstep(-0.18, 0.02, quota_sole);
	float crepuscolo = (1.0 - giorno_puro) * (1.0 - notte_pura);

	float h = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 col_giorno = mix(cielo_orizzonte_giorno, cielo_zenith_giorno, pow(h, 0.55));
	vec3 col_notte = mix(cielo_orizzonte_notte, cielo_zenith_notte, pow(h, 0.55));

	// Verso il sole arancio vivo; alle spalle del sole viola scuro/notte
	vec3 col_orizzonte_crep = mix(cielo_orizzonte_opposto, cielo_orizzonte_tramonto, pow(verso_sole, 1.6));
	vec3 col_zenith_crep = mix(cielo_zenith_notte, cielo_zenith_tramonto, verso_sole);
	vec3 col_crepuscolo = mix(col_orizzonte_crep, col_zenith_crep, pow(h, 0.55));

	vec3 sfondo = mix(mix(col_notte, col_crepuscolo, crepuscolo), col_giorno, giorno_puro);

	// 2. Stelle: compaiono solo dove il cielo è buio (a notte o alle spalle del sole al tramonto)
	float oscurita_locale = (1.0 - giorno_puro) * mix(1.0, 0.0, crepuscolo * verso_sole);
	float visibilita_stelle = smoothstep(0.55, 0.95, oscurita_locale);
	if (visibilita_stelle > 0.001 && EYEDIR.y > 0.04) {
		vec2 uv_stelle = EYEDIR.xz / (EYEDIR.y + 0.35) * 160.0;
		float rnd = hash_cielo(floor(uv_stelle));
		if (rnd > 0.988) {
			float lum = pow(hash_cielo(floor(uv_stelle) * 2.1), 5.0);
			sfondo += vec3(lum * visibilita_stelle * 1.5);
		}
	}

	// 3. Disco del Sole
	float cos_angolo_sole = dot(EYEDIR, dir_s);
	if (cos_angolo_sole > 0.0 && quota_sole > -0.08) {
		float disco = smoothstep(0.9992, 0.9997, cos_angolo_sole);
		float alone = pow(max(0.0, cos_angolo_sole), 280.0) * 0.4;
		vec3 tinta_sole = mix(vec3(1.0, 0.32, 0.04), vec3(1.0, 0.97, 0.90), smoothstep(-0.02, 0.22, quota_sole));
		sfondo += (disco * 2.5 + alone) * tinta_sole;
	}

	// 4, Nuvole (Illuminate dal sole e scure di notte)
	vec2 uv = EYEDIR.xz / max(EYEDIR.y + 0.15, 0.08);
	vec2 vento = vec2(TIME * velocita_vento, TIME * velocita_vento * 0.3);

	float nubi = fbm(uv * 0.4 + vento);
	float velo = fbm(uv * 1.2 - vento * 1.5) * 0.35;
	float densita = smoothstep(0.38, 0.70, nubi + velo);
	
	vec3 nube_base = mix(vec3(0.04, 0.05, 0.07), vec3(0.95, 0.95, 0.98), giorno_puro);
	vec3 nube_ombra = mix(vec3(0.015, 0.02, 0.03), vec3(0.35, 0.38, 0.45), giorno_puro);
	nube_base = mix(nube_base, vec3(0.95, 0.40, 0.15), crepuscolo * verso_sole * 0.9);

	vec3 colore_nube = mix(nube_ombra, nube_base, smoothstep(0.40, 0.75, nubi));
	float maschera_cielo = smoothstep(0.0, 0.12, EYEDIR.y);

	COLOR = mix(sfondo, colore_nube, densita * maschera_cielo);
}
