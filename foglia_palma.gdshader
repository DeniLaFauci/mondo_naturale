shader_type spatial;
render_mode cull_disabled;

uniform vec3 col_verde_base : source_color = vec3(0.15, 0.32, 0.08);
uniform vec3 col_verde_scuro : source_color = vec3(0.08, 0.20, 0.05);
uniform vec3 col_bordo_secco : source_color = vec3(0.58, 0.45, 0.16);
uniform vec3 col_rachide : source_color = vec3(0.38, 0.28, 0.12);

void fragment() {
	// UV.y corre lungo la lunghezza della foglia (0 = base, 1 = punta)
	// UV.x corre lungo la larghezza (0 = margine esterno, 0.5 = piega / rachide)

	// 1. Striature longitudinali fini tipiche della foglia di palma
	float righe = sin(UV.x * 160.0) * 0.5 + 0.5;
	vec3 verde = mix(col_verde_scuro, col_verde_base, pow(righe, 1.4) * 0.5 + 0.5);

	// 2. Bordatura chiara / scura sui margini laterali (UV.x vicino a 0 o 1)
	float bordo = smoothstep(0.08, 0.0, UV.x) + smoothstep(0.92, 1.0, UV.x);
	vec3 col_finale = mix(verde, col_bordo_secco, clamp(bordo, 0.0, 1.0));

	// 3. Punta progressivamente più secca verso l'estremità
	float secco_punta = smoothstep(0.82, 1.0, UV.y + sin(UV.x * 20.0) * 0.05);
	col_finale = mix(col_finale, col_bordo_secco, secco_punta * 0.55);

	// Se il colore vertice indica il gambo legnoso centrale
	col_finale = mix(col_rachide, col_finale, COLOR.g);

	ALBEDO = col_finale;
	ROUGHNESS = mix(0.65, 0.95, bordo);
	SPECULAR = 0.05;

	// Simulazione della transluscenza alla luce solare
	BACKLIGHT = col_verde_base * 0.35;
}
