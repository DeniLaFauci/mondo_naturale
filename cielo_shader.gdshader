shader_type sky;

uniform vec3 colore_zenith : source_color = vec3(0.18, 0.42, 0.78);	// Azzurro cielo aperto
uniform vec3 colore_orizzonte : source_color = vec3(0.60, 0.72, 0.85);	// Schiarita costiera
uniform vec3 colore_nube_chiara : source_color = vec3(0.95, 0.95, 0.98); 	// Corpo nube
uniform vec3 colore_nube_scura : source_color = vec3(0.35, 0.38, 0.45);	// Fondo pesante e grigio

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
	// Gradiente di base del cielo dall'orizzonte allo zenith
	float h = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 colore_sfondo = mix(colore_orizzonte, colore_zenith, pow(h, 0.5));

	// Coordinate piane proiettata sulla calotta celeste
	vec2 uv = EYEDIR.xz / max(EYEDIR.y + 0.15, 0.08);
	vec2 vento = vec2(TIME * 0.03, TIME * 0.01);

	// Nubi pesanti e dense
	float nubi = fbm(uv * 0.4 + vento);
	// Dettaglio leggero e sfilacciato
	float velo = fbm(uv * 1.2 - vento * 1.5) * 0.35;

	float densita = smoothstep(0.38, 0.70, nubi + velo);

	// Tinta: base scura/carica d'ombra sotto e cresta bianca sopra
	vec3 colore_nube = mix(colore_nube_scura, colore_nube_chiara, smoothstep(0.40, 0.75, nubi));

	// Sfuma all'orizzonte
	float maschera_cielo = smoothstep(0.0, 0.12, EYEDIR.y);
	COLOR = mix(colore_sfondo, colore_nube_chiara, densita * maschera_cielo);
}
