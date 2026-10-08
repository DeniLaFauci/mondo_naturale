shader_type spatial;
render_mode cull_disabled;

uniform vec3 col_corteccia_grigia : source_color = vec3(0.62, 0.56, 0.46);
uniform vec3 col_corteccia_bruna : source_color = vec3(0.44, 0.36, 0.28);
uniform vec3 col_solco_profondo : source_color = vec3(0.16, 0.11, 0.07);

// Rumore procedurale per le screpolature della corteccia
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rumore_corteccia(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv_fibra = vec2(UV.x * 45.0, UV.y * 12.0);
	float n = rumore_corteccia(uv_fibra);

	// Crepe verticali e fessurazioni del legno
	float crepe = sin(UV.x * 160.0 + n * 4.0) * 0.5 + 0.5;
	vec3 base = mix(col_corteccia_bruna, col_corteccia_grigia, n * 0.7 + crepe * 0.3);

	// Ombra nei solchi orizzontali (trasmessa dalla geometria tramite COLOR.r)
	float solco = COLOR.r;
	vec3 colore_finale = mix(col_solco_profondo, base, clamp(solco, 0.0, 1.0));

	ALBEDO = colore_finale;
	ROUGHNESS = 0.92;
	SPECULAR = 0.02;
}
