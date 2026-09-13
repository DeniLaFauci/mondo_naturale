shader_type spatial;

uniform vec3 colore_erba : source_color = vec3(0.18, 0.45, 0.15);
uniform vec3 colore_roccia : source_color = vec3(0.38, 0.35, 0.32);
uniform float soglia_pendenza : hint_range(0.0, 1.0) = 0.92;
uniform float morbidezza : hint_range(0.01, 0.5) = 0.08;

void fragment() {
	vec3 normale_mondo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float pendenza = NORMAL.y;
	float fattore_erba = smoothstep(soglia_pendenza - morbidezza, soglia_pendenza + morbidezza, pendenza);

	ALBEDO = mix(colore_roccia, colore_erba, fattore_erba);
	ROUGHNESS = 0.9;
}
