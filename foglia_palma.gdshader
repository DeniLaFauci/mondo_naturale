shader_type spatial;
render_mode cull_disabled;

// Parametri Vento
uniform float forza_vento : hint_range(0.0, 3.0) = 0.8;
uniform vec2 dir_vento = vec2(1.0, 0.4);
uniform vec3 col_foglia_base : source_color = vec3(0.18, 0.38, 0.12);

uniform vec3 col_verde_base : source_color = vec3(0.16, 0.38, 0.07);
uniform vec3 col_verde_scuro : source_color = vec3(0.08, 0.22, 0.04);
uniform vec3 col_rachide : source_color = vec3(0.42, 0.32, 0.15);
uniform vec3 col_secco : source_color = vec3(0.55, 0.42, 0.16);
uniform vec3 col_trasluscenza : source_color = vec3(0.35, 0.55, 0.10);
uniform float densita_pinne : hint_range(40.0, 160.0) = 85.0;

void vertex() {
	// Calcolo coordinate nel mondo per sincronizzare le onde del vento tra tutte le fronde
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 dir = normalize(dir_vento);

	// Fronte d'onda del vento nello spazio 3D
	float onda = dot(world_pos.xz, dir) * 0.4 - TIME * (1.8 + forza_vento * 1.2);

	// Flessione principale della fronda: nulla all'attacco (UV.y = 0), massima all'apice (UV.y = 1)
	float peso_lunghezza = pow(UV.y, 1.8);
	float oscillazione_principale = sin(onda) * 0.18 * forza_vento * peso_lunghezza;

	// Vibrazione/fruscio rapido delle punte e delle singole follaiole
	float fruscio = sin(onda * 3.5 + world_pos.y * 2.0) * 0.05 * forza_vento * pow(UV.y, 2.5);

	// Spostamento nel mondo (piega orizzontale lunga la direzione + piccolo cedimento verticale)
	vec3 spostamento_mondo = vec3(
		dir.x * (oscillazione_principale + fruscio),
		-abs(oscillazione_principale) * 0.4,
		dir.y * (oscillazione_principale + fruscio)
	);

	// Conversione dello scostamento nello spazio locale del vertice
	VERTEX += (inverse(MODEL_MATRIX) * vec4(spostamento_mondo, 0.0)).xyz;
}

void fragment() {
	if (COLOR.g < 0.5) {
		// Rachide centrale legnosa e opaca
		ALBEDO = col_rachide;
		ROUGHNESS = 0.85;
		SPECULAR = 0.05;
		ALPHA = 1.0;
		ALPHA_SCISSOR_THRESHOLD = 0.5;
	} else {
		// Calcolo pettine procedurale per incidere le pinne
		// Inclinazione in avanti verso la punta della fronda
		float pos_pettine = UV.y * densita_pinne;
		float id_pinna = floor(pos_pettine);
		float f = fract(pos_pettine);
		float centro_palma = abs(f - 0.5) * 2.0;

		// Micro-variazione casuale per ogni pinna
		float rnd = fract(sin(id_pinna * 78.233) * 43758.5453);

		// Spessore e rastremazione verso la punta
		float spessore = (1.0 - UV.x * 0.70) * 0.82;
		float len_max = 0.88 + rnd * 0.12;

		// Ritaglio: trasparenza tra le pinne e oltre la punta
		if (centro_palma > spessore || UV.x > len_max) {
			ALPHA = 0.0;
		} else {
			ALPHA = 1.0;
		}
		ALPHA_SCISSOR_THRESHOLD = 0.5;

		// Colore con nervatura dorsale marcata
		float nervatura = 1.0 - pow(centro_palma, 0.65);
		vec3 verde = mix(col_verde_scuro, col_verde_base, 0.50 + 0.50 * nervatura);
		verde = mix(verde, col_verde_base * 1.20, rnd * 0.18);

		float secco = smoothstep(0.72, 1.0, UV.x) * (0.35 + 0.65 * rnd);
		vec3 col_finale = mix(verde, col_secco, secco * 0.60);

		ALBEDO = col_finale;
		ROUGHNESS = mix(0.42, 0.24, secco);
		SPECULAR = mix(0.18, 0.45, nervatura);
		BACKLIGHT = col_trasluscenza * 0.70;
	}
}
