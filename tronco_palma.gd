extends RefCounted

static func costruisci(altezza: float = 6.8, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat = ShaderMaterial.new()
	mat.shader = load("res://tronco_palma.gdshader")

	var num_anelli = 44
	var spicchi = 14
	var raggio_tronco = 0.18

	# Curvatura organica dolcissima del fusto
	var dir_curva = rng.randf_range(0.0, TAU)
	var asse_curva = Vector3(cos(dir_curva), 0.0, sin(dir_curva)) * rng.randf_range(0.25, 0.55)

	# 1. Calcolo asse centrale e profilo di spessore
	var nodi_asse: Array[Vector3] = []
	var raggi_medi: Array[float] = []

	for s in range(num_anelli + 1):
		var t = float(s) / float(num_anelli)
		var y = t * altezza
		var deviazione = asse_curva * pow(t, 1.8)
		nodi_asse.append(Vector3(deviazione.x, y, deviazione.z))

		# Profilo: colonna salda che si allarga a campana dolce negli ultimi 15%
		var r = raggio_tronco * (1.0 - t * 0.14)
		if t > 0.75:
			var u_colletto = (t - 0.75) / 0.25
			r += pow(u_colletto, 1.5) * 0.08 # Raccordo solido senza palla a fungo
		raggi_medi.append(r)

	# 2. Generazione tessellatura a losanghe/diamanti sfalsati
	for s in range(num_anelli):
		var t1 = float(s) / float(num_anelli)
		var t2 = float(s + 1) / float(num_anelli)
		var c1 = nodi_asse[s]
		var c2 = nodi_asse[s + 1]

		# Sfalsamento ad elica tra anelli per creare la trama a scacchiera
		var shift1 = (PI / float(spicchi)) if (s % 2 == 1) else 0.0
		var shift2 = (PI / float(spicchi)) if ((s + 1) % 2 == 1) else 0.0

		for i in range(spicchi):
			var a1_basso = float(i) / float(spicchi) * TAU + shift1
			var a2_basso = float(i + 1) / float(spicchi) * TAU + shift1
			var a1_alto = float(i) / float(spicchi) * TAU + shift2
			var a2_alto = float(i + 1) / float(spicchi) * TAU + shift2

			# Direzioni radiali
			var d1_basso = Vector3(cos(a1_basso), 0.0, sin(a1_basso))
			var d2_basso = Vector3(cos(a2_basso), 0.0, sin(a2_basso))
			var d1_alto = Vector3(cos(a1_alto), 0.0, sin(a1_alto))
			var d2_alto = Vector3(cos(a2_alto), 0.0, sin(a2_alto))

			var r_base1 = raggi_medi[s]
			var r_base2 = raggi_medi[s + 1]

			var v1 = c1 + d1_basso * r_base1
			var v2 = c1 + d2_basso * r_base1
			var v3 = c2 + d2_alto * r_base2
			var v4 = c2 + d1_alto * r_base2

			# Mensola orizzontale a sbalzo: cresta larga che sporge a ripiano
			var sporgenza = 0.065
			var dir_m1 = (d1_basso + d1_alto).normalized()
			var dir_m2 = (d2_basso + d2_alto).normalized()
			var c_medio = (c1 + c2) * 0.5 + Vector3(0.0, (c2.y - c1.y) * 0.15, 0.0)

			var r_mensola = (r_base1 + r_base2) * 0.5 + sporgenza
			var m1 = c_medio + dir_m1 * r_mensola
			var m2 = c_medio + dir_m2 * r_mensola

			var u_coord1 = float(i) / float(spicchi)
			var u_coord2 = float(i + 1) / float(spicchi)
			var t_med = (t1 + t2) * 0.5

			# Faccia inferiore: sale dal solco buio fino alla cresta della mensola
			st.set_color(Color(0.18, 0.0, 0.0)); st.set_uv(Vector2(u_coord1, t1)); st.add_vertex(v1)
			st.set_color(Color(0.18, 0.0, 0.0)); st.set_uv(Vector2(u_coord2, t1)); st.add_vertex(v2)
			st.set_color(Color(0.95, 0.0, 0.0)); st.set_uv(Vector2(u_coord2, t_med)); st.add_vertex(m2)

			st.set_color(Color(0.18, 0.0, 0.0)); st.set_uv(Vector2(u_coord1, t1)); st.add_vertex(v1)
			st.set_color(Color(0.18, 0.0, 0.0)); st.set_uv(Vector2(u_coord2, t_med)); st.add_vertex(m2)
			st.set_color(Color(0.95, 0.0, 0.0)); st.set_uv(Vector2(u_coord1, t_med)); st.add_vertex(m1)

			# Faccia superiore: ripiano a gradino che rientra nel solco dell'anello successivo
			st.set_color(Color(0.95, 0.0, 0.0)); st.set_uv(Vector2(u_coord1, t_med)); st.add_vertex(m1)
			st.set_color(Color(0.95, 0.0, 0.0)); st.set_uv(Vector2(u_coord2, t_med)); st.add_vertex(m2)
			st.set_color(Color(0.25, 0.0, 0.0)); st.set_uv(Vector2(u_coord2, t2)); st.add_vertex(v3)

			st.set_color(Color(0.95, 0.0, 0.0)); st.set_uv(Vector2(u_coord1, t_med)); st.add_vertex(m1)
			st.set_color(Color(0.95, 0.0, 0.0)); st.set_uv(Vector2(u_coord2, t2)); st.add_vertex(v3)
			st.set_color(Color(0.25, 0.0, 0.0)); st.set_uv(Vector2(u_coord1, t2)); st.add_vertex(v4)

#--------------------------------------------------
	st.generate_normals()
	var mesh = st.commit()
	mesh.surface_set_material(0, mat)
	var apice = nodi_asse[-1]
	var tangente = (nodi_asse[-1] - nodi_asse[-2]).normalized()
	return {
		"mesh": mesh,
		"apice": apice,
		"tangente": tangente
	}
