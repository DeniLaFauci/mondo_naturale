class_name MondoMeteo
extends RefCounted

static var nodo_fulmine: MeshInstance3D
static var timer_prossimo_fulmine: float = 3.0
static var lampo_attivo: bool = false
static var durata_lampo: float = 0.0
static var frame_flicker: int = 0

static func crea_nodo_fulmine(parent: Node3D) -> MeshInstance3D:
	nodo_fulmine = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.8, 2.0, 2.5)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	nodo_fulmine.material_override = mat
	nodo_fulmine.visible = false
	parent.add_child(nodo_fulmine)
	return nodo_fulmine

static func estrai_meteo(mat_cielo: ShaderMaterial, mat_mare: ShaderMaterial) -> String:
	var tipi = [
		{"nome": "Sereno Limpido", "c": 0.0, "s": 1.0, "d": 0.0, "p": 0.0, "v": Vector2(0.01, 0.003)},
		{"nome": "Velature e Cirri Alti", "c": 0.28, "s": 0.45, "d": 0.15, "p": 0.0, "v": Vector2(0.035, 0.012)},
		{"nome": "Altocumuli (Cielo a pecorelle)", "c": 0.52, "s": 2.4, "d": 0.60, "p": 0.0, "v": Vector2(0.018, 0.008)},
		{"nome": "Cumuli Sparsi Costieri", "c": 0.55, "s": 0.95, "d": 0.35, "p": 0.0, "v": Vector2(0.022, 0.005)},
		{"nome": "Coperto Minaccioso", "c": 1.0, "s": 0.9, "d": 0.65, "p": 1.0, "v": Vector2(0.06, 0.025)}
	]

	var m = tipi[randi() % tipi.size()]

	if mat_cielo:
		mat_cielo.set_shader_parameter("copertura_nubi", m["c"])
		mat_cielo.set_shader_parameter("scala_nubi", m["s"])
		mat_cielo.set_shader_parameter("densita_dettaglio", m["d"])
		mat_cielo.set_shader_parameter("oscuramento_pioggia", m["p"])
		mat_cielo.set_shader_parameter("velocita_vento", m["v"])

	if mat_mare:
		mat_mare.set_shader_parameter("oscuramento_pioggia", m["p"])

	return m["nome"]

static func gestisci_temporale(delta: float, meteo: String, mat_cielo: ShaderMaterial, env: Environment) -> void:
	if meteo != "Coperto Minaccioso":
		if nodo_fulmine: nodo_fulmine.visible = false
		if mat_cielo: mat_cielo.set_shader_parameter("intensita_lampo", 0.0)
		return

	if not lampo_attivo:
		timer_prossimo_fulmine -= delta
		if timer_prossimo_fulmine <= 0.0: _scocca_fulmine()
	else:
		durata_lampo -= delta
		frame_flicker += 1
		var flash = 1.0 if (frame_flicker % 2 == 0) else 0.3
		if durata_lampo <= 0.0:
			lampo_attivo = false
			nodo_fulmine.visible = false
			timer_prossimo_fulmine = randf_range(2.5, 6.0)
			if mat_cielo: mat_cielo.set_shader_parameter("intensita_lampo", 0.0)
		else:
			if mat_cielo: mat_cielo.set_shader_parameter("intensita_lampo", flash * 2.0)
			if env: env.ambient_light_energy = 0.8 * flash

static func _scocca_fulmine() -> void:
	lampo_attivo = true
	durata_lampo = randf_range(0.12, 0.22)
	frame_flicker = 0

	var x_s = randf_range(-100.0, 100.0); var z_s = randf_range(-100.0, 100.0)
	var p_in = Vector3(x_s, 68.0, z_s)
	var p_fi = Vector3(x_s + randf_range(-20.0, 20.0), 2.0, z_s + randf_range(-20.0, 20.0))

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var seg = 14

	for i in range(seg + 1):
		var t = float(i) / float(seg)
		var p = p_in.lerp(p_fi, t)
		if i > 0 and i < seg:
			p += Vector3(randf_range(-3.5, 3.5), randf_range(-1.0, 1.0), randf_range(-3.5, 3.5))
		st.add_vertex(p + Vector3(-0.4, 0.0, 0.4))
		st.add_vertex(p + Vector3(0.4, 0.0, -0.4))

	nodo_fulmine.mesh = st.commit()
	nodo_fulmine.visible = true
