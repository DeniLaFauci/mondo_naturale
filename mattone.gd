class_name Mattone
extends RefCounted

var dimensioni: Vector3
var trasformazione: Transform3D

func _init(dim: Vector3 = Vector3(1.0, 0.5, 2.0), pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> void:
	dimensioni = dim
	trasformazione = Transform3D()
	if rot != Vector3.ZERO:
		trasformazione = trasformazione.rotated(Vector3.UP, rot.y)
		trasformazione = trasformazione.rotated(Vector3.RIGHT, rot.x)
		trasformazione = trasformazione.rotated(Vector3.FORWARD, rot.z)
	trasformazione.origin = pos

func estrudi(st: SurfaceTool, uv_scala: float = 1.0) -> void:
	var hx = dimensioni.x * 0.5
	var hy = dimensioni.y * 0.5
	var hz = dimensioni.z * 0.5

	# Gli 8 vertici del parallelepipedo nello spazio locale
	var p000 = Vector3(-hx, -hy, -hz)
	var p001 = Vector3(-hx, -hy, hz)
	var p010 = Vector3(-hx, hy, -hz)
	var p011 = Vector3(-hx, hy, hz)
	var p100 = Vector3(hx, -hy, -hz)
	var p101 = Vector3(hx, -hy, hz)
	var p110 = Vector3(hx, hy, -hz)
	var p111 = Vector3(hx, hy, hz)

	# Definizione delle 6 facce (normale locale, 4 vertici in senso orario, dimensioni uv)
	var facce = [
		{"n": Vector3.UP,		"v": [p011, p111, p110, p010], "sx": dimensioni.x, "sy": dimensioni.z},
		{"n": Vector3.DOWN,		"v": [p000, p100, p101, p001], "sx": dimensioni.x, "sy": dimensioni.z},
		{"n": Vector3.FORWARD,		"v": [p100, p000, p010, p110], "sx": dimensioni.x, "sy": dimensioni.y},
		{"n": Vector3.BACK,		"v": [p001, p101, p111, p011], "sx": dimensioni.x, "sy": dimensioni.y},
		{"n": Vector3.LEFT,		"v": [p000, p001, p011, p010], "sx": dimensioni.z, "sy": dimensioni.y},
		{"n": Vector3.RIGHT,		"v": [p101, p100, p110, p111], "sx": dimensioni.z, "sy": dimensioni.y}
	]

	for f in facce:
		var norm = (trasformazione.basis * f["n"]).normalized()
		var v0 = trasformazione * f["v"][0]
		var v1 = trasformazione * f["v"][1]
		var v2 = trasformazione * f["v"][2]
		var v3 = trasformazione * f["v"][3]

		var max_u = f["sx"] * uv_scala
		var max_v = f["sy"] * uv_scala

		st.set_normal(norm); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(v0)
		st.set_normal(norm); st.set_uv(Vector2(max_u, 0.0)); st.add_vertex(v1)
		st.set_normal(norm); st.set_uv(Vector2(max_u, max_v)); st.add_vertex(v2)

		st.set_normal(norm); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(v0)
		st.set_normal(norm); st.set_uv(Vector2(max_u, max_v)); st.add_vertex(v2)
		st.set_normal(norm); st.set_uv(Vector2(0.0, max_v)); st.add_vertex(v3)
