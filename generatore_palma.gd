class_name GeneratorePalma
extends RefCounted

# Costruisce proceduralmente una palma fotorealisticamente dettagliata.
# Il parametro 'seme' garantisce che ogni istanza sia unica e non un clone
static func genera(seme: int = 0) -> ArrayMesh:
	var rng = RandomNumberGenerator.new()
	if seme != 0: rng.seed = seme
	else: rng.randomize()

	# 1. MATERIALI DEDICATI
	var mat_tronco = StandardMaterial3D.new()
	mat_tronco.albedo_color = Color(0.24, 0.17, 0.12)
	mat_tronco.roughness = 1.0
	mat_tronco.metallic = 0.0

	var mat_foglie = StandardMaterial3D.new()
	mat_foglie.albedo_color = Color(0.12, 0.36, 0.08)
	mat_foglie.roughness = 0.4
	mat_foglie.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_foglie.backlight_enabled = true
	mat_foglie.backlight = Color(0.18, 0.42, 0.08)


	# 2. GENERAZIONE TRONCO CON SCAGLIE E CURVATURA ORGANICA
	var st_tronco = SurfaceTool.new()
	st_tronco.begin(Mesh.PRIMITIVE_TRIANGLES)

	var altezza_fusto = rng.randf_range(4.5, 6.2)
	var num_sezioni = 42
	var raggio_base = 0.22
	var curvatura_max = rng.randf_range(0.6, 1.2)
	var dir_curvatura = rng.randf_range(0.0, TAU)
	var asse_curva = Vector3(cos(dir_curvatura), 0.0, sin(dir_curvatura))

	var nodi_tronco: Array[Vector3] = []
	for s in range(num_sezioni + 1):
		var t = float(s) / float(num_sezioni)
		var quota = t * altezza_fusto
		var offset_curva = asse_curva * pow(t, 1.8) * curvatura_max
		nodi_tronco.append(Vector3(offset_curva.x, quota, offset_curva.z))

	# Cilindro base fusto
	for s in range(num_sezioni):
		var p_basso = nodi_tronco[s]
		var p_alto = nodi_tronco[s + 1]
		var t = float(s) / float(num_sezioni)
		var r1 = (raggio_base * (1.0 - t * 0.45)) * (1.18 if s % 2 == 0 else 0.88)
		var r2 = (raggio_base * (1.0 - (t + 1.0 / float(num_sezioni)) * 0.45)) * 0.88

		var spicchi = 8
		for i in range(spicchi):
			var a1 = float(i) / float(spicchi) * TAU
			var a2 = float(i + 1) / float(spicchi) * TAU

			var v1 = p_basso + Vector3(cos(a1) * r1, 0.0, sin(a1) * r1)
			var v2 = p_basso + Vector3(cos(a2) * r1, 0.0, sin(a2) * r1)
			var v3 = p_alto + Vector3(cos(a2) * r2, 0.0, sin(a2) * r2)
			var v4 = p_alto + Vector3(cos(a1) * r2, 0.0, sin(a1) * r2)

			st_tronco.add_vertex(v1); st_tronco.add_vertex(v2); st_tronco.add_vertex(v3)
			st_tronco.add_vertex(v1); st_tronco.add_vertex(v3); st_tronco.add_vertex(v4)

			# Scaglie a cuneo (resti dei piccoli caduti) disposte lungo il fusto)
			if s > 2 and s < num_sezioni - 1:
				var a_mid = (a1 + a2) * 0.5;
				var dir_scaglia = Vector3(cos(a_mid), 0.0, sin(a_mid))
				var p_cuneo = (v1 + v2) * 0.5 + dir_scaglia * (r1 * 1.1) + Vector3(0.0, 0.12, 0.0)
				st_tronco.add_vertex(v1); st_tronco.add_vertex(v2); st_tronco.add_vertex(p_cuneo)

	st_tronco.generate_normals()
	var mesh_tot = st_tronco.commit()

	# GENERAZIONE CORONA DI FRONDE PIUMATE DETTAGLIATE
	var st_foglie = SurfaceTool.new()
	st_foglie.begin(Mesh.PRIMITIVE_TRIANGLES)

	var apice = nodi_tronco[num_sezioni]
	var num_fronde = rng.randi_range(48, 62)

	for f in range(num_fronde):
		var frac = float(f) / float(num_fronde)
		var rot_corona = frac * TAU + rng.randf_range(-0.08, 0.08)
		# Fronde interne più erette, fronde esterne basse e spioventi
		var inclinazione = lerp(-0.35, 1.40, pow(frac, 1.2)) + rng.randf_range(-0.05, 0.05)
		var lungh_fronda = rng.randf_range(2.6, 3.4)

		var dir_h = Vector3(cos(rot_corona), 0.0, sin(rot_corona))
		var dir_orto = Vector3(-dir_h.z, 0.0, dir_h.x)

		# Costruzione rachide (asse centrale arcuato a parabola)
		var passi_rachide = 32
		var punti_rachide: Array[Vector3] = []
		for p in range(passi_rachide + 1):
			var tr = float(p) / float(passi_rachide)
			var estensione = tr * lungh_fronda
			var caduta = pow(tr, 2.3) * inclinazione * 2.2 - sin(tr * PI) * 0.45
			var pt = apice + dir_h * estensione - Vector3(0.0, caduta, 0.0)
			punti_rachide.append(pt)

		# Nastro piumato continuo a spiovente naturale (senza rombi staccati)
		for p in range(1, passi_rachide):
			var tr1 = float(p) / float(passi_rachide)
			var tr2 = float(p + 1) / float(passi_rachide)
			var pt_a = punti_rachide[p]
			var pt_b = punti_rachide[p + 1]
		
			var w1 = sin(pow(tr1, 0.65) * PI) * 0.92
			var w2 = sin(pow(tr2, 0.65) * PI) * 0.92
			var spiovente1 = w1 * 0.45
			var spiovente2 = w2 * 0.45

			var dx_a = pt_a + dir_orto * w1 - Vector3(0.0, spiovente1, 0.0)
			var dx_b = pt_b + dir_orto * w2 - Vector3(0.0, spiovente2, 0.0)
			st_foglie.add_vertex(pt_a); st_foglie.add_vertex(dx_a); st_foglie.add_vertex(dx_b)
			st_foglie.add_vertex(pt_a); st_foglie.add_vertex(dx_b); st_foglie.add_vertex(pt_b)

			var sx_a = pt_a - dir_orto * w1 - Vector3(0.0, spiovente1, 0.0)
			var sx_b = pt_b - dir_orto * w2 - Vector3(0.0, spiovente2, 0.0)
			st_foglie.add_vertex(pt_a); st_foglie.add_vertex(sx_b); st_foglie.add_vertex(sx_a)
			st_foglie.add_vertex(pt_a); st_foglie.add_vertex(pt_b); st_foglie.add_vertex(sx_b)


	st_foglie.generate_normals()
	mesh_tot = st_foglie.commit(mesh_tot)
	mesh_tot.surface_set_material(0, mat_tronco)
	mesh_tot.surface_set_material(1, mat_foglie)

	return  mesh_tot







