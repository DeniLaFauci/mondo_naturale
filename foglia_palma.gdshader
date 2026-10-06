shader_type spatial;
render_mode cull_disabled;

uniform vec3 col_verde_base : source_color = vec3(0.18, 0.38, 0.08);
uniform vec3 col_verde_scuro : source_color = vec3(0.09, 0.22, 0.05);
uniform vec3 col_bordo_secco : source_color = vec3(0.62, 0.46, 0.18);
uniform vec3 col_rachide : source_color = vec3(0.40, 0.30, 0.14);
uniform vec3 col_trasluscenza : source_color = vec3(0.35, 0.55, 0.12);

void fragment() {
	// COLOTR.g discrimina rachide (0.0) da foglia (1.0)
	float maschera_foglia = COLOR.g;

	// 1. Venature longitudinali a frequenza visiva naturale
	float venatura = sin(UV.x * 32.0) * 0.5 + 0.5;
	vec3 verde = mix(col_verde_scuro, col_verde_base, 0.65 + 0.35 * venatura);

	// 2. Bordatura e ingiallimento periferico
	float bordo = smoothstep(0.12, 0.0, UV.x) + smoothstep(0.88, 1.0, UV.x);
	vec3 col_lamina = mix(verde, col_bordo_secco, clamp(bordo * 0.7, 0.0, 1.0));

	// 3. Punta secca progressiva verso l'apice della fogliolina
	float secco_punta = smoothstep(0.85, 1.0, UV.y);
	col_lamina = mix(col_lamina, col_bordo_secco, secco_punta * 0.75);

	// Miscela tra legno centrale e fogliame verde
	vec3 col_finale = mix(col_rachide, col_lamina, maschera_foglia);

	ALBEDO = col_finale;
	ROUGHNESS = mix(0.85, 0.38, maschera_foglia);
	SPECULAR = mix(0.1, 0.35, maschera_foglia);

	// Trasluscenza / subsurface scattering quando in controluce rispetto al sole
	BACKLIGHT = col_trasluscenza * maschera_foglia * 0.55;
}
