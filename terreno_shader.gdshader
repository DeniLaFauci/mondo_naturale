shader_type spatial;

uniform vec3 colore_erba : source_color = vec3(0.10, 0.28, 0.08);
uniform vec3 colore_roccia : source_color = vec3(0.20, 0.18, 0.16);
uniform vec3 colore_neve : source_color = vec3(0.92, 0.95, 0.98);

uniform float soglia_pendenza : hint_range(0.0, 1.0) = 0.82;
uniform float quota_neve : hint_range(0.0, 40.0) = 16.0;

varying float quota_mondo;

void vertex() {
	quota_mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	vec3 normale_mondo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float pendenza = normale_mondo.y;

	float fattore_erba = smoothstep(soglia_pendenza - 0.08, soglia_pendenza + 0.08, pendenza);
	vec3 colore_base = mix(colore_roccia, colore_erba, fattore_erba);

	float fattore_neve = smoothstep(quota_neve, quota_neve + 4.0, quota_mondo);
	fattore_neve *= smoothstep(0.65, 0.85, pendenza);

	ALBEDO = mix(colore_base, colore_neve, fattore_neve);
	ROUGHNESS = mix(0.9, 0.5, fattore_neve);
}
