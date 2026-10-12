class_name MondoVegetazione
extends RefCounted

const AlberoAbete = preload("res://albero_abete.gd")
const AlberoPalma = preload("res://albero_palma.gd")
const MondoTerreno = preload("res://mondo_terreno.gd")

static func popola(parent: Node3D) -> void:
	var mesh_palma = AlberoPalma.genera(1234)
	var mesh_abete = AlberoAbete.genera_mesh()
	var t_palme: Array[Transform3D] = []
	var t_abeti: Array[Transform3D] = []
	var r_lim = 118.0
	var passo = 3.2

	for x in range(int(-r_lim), int(r_lim), int(passo)):
		for z in range(int(-r_lim), int(r_lim), int(passo)):
			var px = float(x) + randf_range(-1.2, 1.2)
			var pz = float(z) + randf_range(-1.2, 1.2)
			if Vector2(px, pz).length() > r_lim: continue

			var info = MondoTerreno.calcola_quota_e_normale(px, pz)
			var h = info["quota"]
			var norm = info["normale"]

			# Spiaggia: palme
			if h > 1.4 and h < 6.4 and norm.y > 0.72:
				if randf() < 0.22:
					var sc = randf_range(0.55, 0.85)
					var ang = atan2(pz, px)
					var t = Transform3D().scaled(Vector3.ONE * sc).rotated(Vector3.UP, -ang + randf_range(-0.4, 0.4))
					t.origin = Vector3(px, h - 0.1, pz)
					t_palme.append(t)

				# Rilievi e creste: abeti
			elif h >= 6.4 and h < 48.0 and norm.y > 0.68 and norm.y < 0.94:
				if randf() < 0.30:
					var sc = randf_range(0.45, 0.80)
					var t = Transform3D().scaled(Vector3.ONE * sc).rotated(Vector3.UP, randf_range(0.0, TAU))
					t.origin = Vector3(px, h - 0.15, pz)
					t_abeti.append(t)

	_crea_mm(parent, mesh_palma, t_palme)
	_crea_mm(parent, mesh_abete, t_abeti)

static func _crea_mm(parent: Node3D, mesh: Mesh, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty(): return
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in range(transforms.size()): mm.set_instance_transform(i, transforms[i])
	var inst = MultiMeshInstance3D.new()
	inst.multimesh = mm
	parent.add_child(inst)

