shader_type spatial;
render_mode cull_back;

uniform vec3 col_corteccia_base : source_color = vec3(0.22, 0.16, 0.12);
uniform vec3 col_corteccia_scura : source_color = vec3(0.12, 0.08, 0.06);
uniform vec3 col_corteccia_grigia : source_color = vec3(0.28, 0.25, 0.22);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float rumore_fessure(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	// allunghiamo la texture lungo Y per creare solchi verticali tipici delle conifere
	vec2 uv_tronco = vec2(UV.x * 4.0, UV.y * 1.5);
	float n_vert = rumore_fessure(vec2(uv_tronco.x * 8.0, uv_tronco.y * 1.2));
	float n_dettaglio = rumore_fessure(uv_tronco * 16.0);

	float solco = smoothstep(0.35, 0.65, n_vert);
	vec3 colore = mix(col_corteccia_scura, col_corteccia_base, solco);
	colore = mix(colore, col_corteccia_grigia, n_dettaglio * 0.35);

	ALBEDO = colore;
	ROUGHNESS = 0.88;
	SPECULAR = 0.12;
}
