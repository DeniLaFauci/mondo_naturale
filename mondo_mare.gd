class_name MondoMare
extends RefCounted

static func crea_nodo() -> Dictionary:
	var mare_mesh = PlaneMesh.new()
	mare_mesh.size = Vector2(1200, 1200)
	var mat_mare = ShaderMaterial.new()
	mat_mare.shader = load("res://mare_shader.gdshader")

	var nodo = MeshInstance3D.new()
	nodo.mesh = mare_mesh
	nodo.material_override = mat_mare
	nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nodo.position.y = 1.2

	return {"nodo": nodo, "materiale": mat_mare}
