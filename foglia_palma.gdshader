shader_type spatial;
render_mode cull_disabled;

uniform vec3 col_verde_base : source_color = vec3(0.16, 0.38, 0.07);
uniform vec3 col_verde_scuro : source_color = vec3(0.08, 0.22, 0.04);
uniform vec3 col_rachide : source_color = vec3(0.42, 0.32, 0.15);
uniform vec3 col_secco : source_color = vec3(0.55, 0.42, 0.16);
uniform vec3 col_trasluscenza : source_color = vec3(0.35, 0.55, 0.10);
uniform float densita_pinne : hint_range(40.0, 160.0) = 85.0;

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
