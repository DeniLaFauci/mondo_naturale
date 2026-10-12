shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 col_aghi_base : source_color = vec3(0.08, 0.22, 0.08);
uniform vec3 col_aghi_punta : source_color = vec3(0.18, 0.38, 0.14);
uniform vec3 col_rametto_legno : source_color = vec3(0.25, 0.16, 0.10);

float hash_aghi(vec2 p) {
	return fract(sin(dot(p, vec2(27.64, 53.19))) * 43758.5453);
}

void fragment() {
	float dist_x = abs(UV.x - 0.5) * 2.0;

	// Silhouette organica ad aghi compatti: sagoma a lancia con estremità sfrangiata
	float spessore = (1.0 - pow(dist_x, 2.2) * (1.0 - UV.y * 0.35));
	float bordo_ruvido = hash_aghi(floor(vec2(UV.x * 36.0, UV.y * 24.0))) * 0.2;
	float densita = spessore + bordo_ruvido;

	if (dist_x > 0.30) {
		discard;
	}

	// Verde profondo Picea abies con sfumatura legnosa al rachide centrale
	vec3 col_rachide = vec3(0.24, 0.16, 0.10);
	vec3 col_ombra = vec3(0.04, 0.13, 0.06);
	vec3 col_luce = vec3(0.11, 0.26, 0.13);

	float lum = clamp(UV.y * 0.7 + (1.0 - dist_x) * 0.4, 0.0, 1.0);
	vec3 colore = mix(col_ombra, col_luce, lum);

	if (dist_x < 0.09) {
		colore = col_rachide;
	}

	ALBEDO = colore;
	ROUGHNESS = 0.80;
	SPECULAR = 0.12;
	SSS_STRENGTH = 0.25;
}
