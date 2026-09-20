shader_type sky;

uniform vec3 direzione_sole = vec3(0.0, 1.0, 0.0);
uniform float velocita_vento = 0.02;

// Colori Giorno
uniform vec3 cielo_zenith_giorno : source_color = vec3(0.18, 0.42, 0.78);
uniform vec3 cielo_orizzonte_giorno : source_color = vec3(0.69, 0.72, 0.85);

// Colori Tramonto / Alba
uniform vec3 cielo_zenith_tramonto : source_color = vec3(0.12, 0.15, 0.35);
uniform vec3 cielo_orizzonte_tramonto : source_color = vec3(0.85, 0.38, 0.15);

// Colori Notte
uniform vec3 cielo_zenith_notte : source_color = vec3(0.02, 0.02, 0.05);
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
	float quota_sole = clamp(direzione_sole.y, -1.0, 1.0);
	float fattore_giorno = smoothstep(-0.1, 0.3, quota_sole);	
	float fattore_tramonto = smoothstep(-0.15, 0.05, quota_sole) * (1.0 - smoothstep(0.05, 0.35, quota_sole));

	// 1. Miscela del cielo in base all'ora
	float h = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 zenith = mix(cielo_zenith_notte, cielo_zenith_giorno, fattore_giorno);
	zenith = mix(zenith, cielo_zenith_tramonto, fattore_tramonto);

	vec3 orizzonte = mix(cielo_orizzonte_notte, cielo_orizzonte_giorno, fattore_giorno);
	orizzonte = mix(orizzonte, cielo_orizzonte_tramonto, fattore_tramonto);

	vec3 sfondo = mix(orizzonte, zenith, pow(h, 0.5));

	// 2. Stelle (visibili solo di notte)
	float stelle = 0.0;
	if (fattore_giorno < 0.25 && EYEDIR.y > 0.05) {
		vec2 uv_stelle = EYEDIR.xz / (EYEDIR.y + 0.4) * 120.0;
		float rnd = hash_cielo(floor(uv_stelle));
		if (rnd > 0.985) {
			stelle = pow(hash_cielo(floor(uv_stelle) * 1.5), 8.0) * (1.0 - fattore_giorno * 4.0);
		}
	}
	sfondo += vec3(stelle);

	// 3. Disco del Sole
	float cos_angolo_sole = dot(EYEDIR, normalize(direzione_sole));
	if (cos_angolo_sole > 0.0 && quota_sole > -0.15) {
		float disco_sole = smoothstep(0.9985, 0.9995, cos_angolo_sole);
		float alone_sole = pow(max(0.0, cos_angolo_sole), 64.0) * 0.6;
		vec3 colore_sole_cielo = mix(vec3(1.0, 0.4, 0.1), vec3(1.0, 0.95, 0.85), smoothstep(0.0, 0.3, quota_sole));
		sfondo += (disco_sole * 3.0 + alone_sole) * colore_sole_cielo;
	}

	// 4, Nuvole (Illuminate dal sole e scure di notte)
	vec2 uv = EYEDIR.xz / max(EYEDIR.y + 0.15, 0.08);
	vec2 vento = vec2(TIME * velocita_vento, TIME * velocita_vento * 0.3);

	float nubi = fbm(uv * 0.4 + vento);
	float velo = fbm(uv * 1.2 - vento * 1.5) * 0.35;
	float densita = smoothstep(0.38, 0.70, nubi + velo);
	
	vec3 nube_base = mix(vec3(0.05, 0.06, 0.08), vec3(0.95, 0.95, 0.98), fattore_giorno);
	vec3 nube_ombra = mix(vec3(0.02, 0.03, 0.04), vec3(0.35, 0.38, 0.45), fattore_giorno);
	nube_base = mix(nube_base, vec3(0.9, 0.45, 0.2), fattore_tramonto * 0.8);

	vec3 colore_nube = mix(nube_ombra, nube_base, smoothstep(0.40, 0.75, nubi));
	float maschera_cielo = smoothstep(0.0, 0.12, EYEDIR.y);

	COLOR = mix(sfondo, colore_nube, densita * maschera_cielo);
}
