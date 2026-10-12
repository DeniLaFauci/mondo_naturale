extends RefCounted

static func genera_mesh() -> ArrayMesh:
	var st_legno = SurfaceTool.new()
	st_legno.begin(Mesh.PRIMITIVE_TRIANGLES)

	var st_aghi = SurfaceTool.new()
	st_aghi.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat_legno = ShaderMaterial.new()
	mat_legno.shader = load("res://tronco_abete.gdshader")

	var mat_aghi = ShaderMaterial.new()
	mat_aghi.shader = load("res://aghi_abete.gdshader")

	# 1. TRONCO MONOPOIDALE CONTINUO (Continuo e leggero: 6 lati, 10 livelli)
	var h_tot = 6.2
	var r_base = 0.22
	var r_cima = 0.03
	var anelli_tronco = 10
	var lati_tronco = 6

	for s in range(anelli_tronco):
		var t1 = float(s) / float(anelli_tronco)
		var t2 = float(s + 1) / float(anelli_tronco)
		var y1 = t1 * h_tot
		var y2 = t2 * h_tot
		var r1 = lerp(r_base, r_cima, pow(t1, 0.75))
		var r2 = lerp(r_base, r_cima, pow(t2, 0.75))

		for i in range(lati_tronco):
			var a1 = float(i) / float(lati_tronco) * TAU
			var a2 = float(i + 1) / float(lati_tronco) * TAU
			var d1 = Vector3(cos(a1), 0.0, sin(a1))
			var d2 = Vector3(cos(a2), 0.0, sin(a2))

			var v1 = Vector3(d1.x * r1, y1, d1.z * r1)
			var v2 = Vector3(d2.x * r1, y1, d2.z * r1)
			var v3 = Vector3(d2.x * r2, y2, d2.z * r2)
			var v4 = Vector3(d1.x * r2, y2, d1.z * r2)

			st_legno.set_normal(d1); st_legno.set_uv(Vector2(float(i) / lati_tronco, t1 * 4.0)); st_legno.add_vertex(v1)
			st_legno.set_normal(d2); st_legno.set_uv(Vector2(float(i + 1) / lati_tronco, t1 * 4.0)); st_legno.add_vertex(v2)
			st_legno.set_normal(d2); st_legno.set_uv(Vector2(float(i + 1) / lati_tronco, t2 * 4.0)); st_legno.add_vertex(v3)

			st_legno.set_normal(d1); st_legno.set_uv(Vector2(float(i) / lati_tronco, t1 * 4.0)); st_legno.add_vertex(v1)
			st_legno.set_normal(d2); st_legno.set_uv(Vector2(float(i + 1) / lati_tronco, t2 * 4.0)); st_legno.add_vertex(v3)
			st_legno.set_normal(d1); st_legno.set_uv(Vector2(float(i) / lati_tronco, t2 * 4.0)); st_legno.add_vertex(v4)

	# 2. PALCHI DI RAMI CON CUSCINETTI D'AGHI (Compromesso densità/GPU: 14 palchi a spirale)
	var num_palchi = 14	
	var h_inizio = 0.8
	var h_fine = h_tot - 0.25

	for p in range(num_palchi):
		var t_p = float(p) / float(num_palchi - 1)
		var y_palco = lerp(h_inizio, h_fine, pow(t_p, 0.82))
		var lungh_ramo = lerp(2.2, 0.35, pow(t_p, 0.72))
		var num_rami = int(lerp(6, 4, t_p))
		var sfasamento = p * 2.39996

		for r in range(num_rami):
			var azimut = float(r) / float(num_rami) * TAU + sfasamento
			var dir_rad = Vector3(cos(azimut), 0.0, sin(azimut))
			var tang_rad = Vector3(-sin(azimut), 0.0, cos(azimut))

			# Curvatura del ramo: cade leggermente al centro e punta in fuori
			var p_base = Vector3(0.0, y_palco, 0.0)
			var caduta = lerp(0.28, 0.02, pow(t_p, 1.2))
			var inclinazione_apicale = lerp(0.0, 0.22, t_p)
			var p_mid = p_base + dir_rad * (lungh_ramo * 0.5) + Vector3(0.0, -caduta, 0.0)
			var p_punta = p_base + dir_rad * lungh_ramo + Vector3(0.0, -caduta * 0.4 + inclinazione_apicale, 0.0)

			# Asse legnoso interno del ramo (stecca triangolare sottile)
			_aggiungi_trave_legno(st_legno, p_base, p_punta, tang_rad * 0.025)

			# Cuscinetti fogliari ad aghi lungo il ramo
			var largh_cuscino = lerp(0.48, 0.24, t_p)

			# Cuscinetto primario continuo
			_aggiungi_quad(st_aghi, p_base, p_punta, tang_rad * (largh_cuscino * 0.5))
			_aggiungi_quad(st_aghi, p_base, p_punta, Vector3.UP * (largh_cuscino * 0.35))

			# 2 ventagli secondari laterali per chiudere i buchi
			if lungh_ramo > 0.8:
				var sub_largh = largh_cuscino * 0.7
				var sub_lungh = lungh_ramo * 0.38
				for lato in [-1.0, 1.0]:
					var dir_sub = (dir_rad * 0.7 + tang_rad * (lato * 0.7) + Vector3(0.0, -0.1, 0.0)).normalized()
					var fine_sub = p_mid + dir_sub * sub_lungh
					var tang_sub = dir_sub.cross(Vector3.UP).normalized() * (sub_largh * 0.5)
					_aggiungi_quad(st_aghi, p_mid, fine_sub, tang_sub)

	# Ciuffo apicale terminale
	var cima_fusto = Vector3(0.0, h_tot, 0.0)
	_aggiungi_quad(st_aghi, cima_fusto - Vector3(0.0, 0.4, 0.0), cima_fusto + Vector3(0.0, 0.2, 0.0), Vector3(0.18, 0.0, 0.0))
	_aggiungi_quad(st_aghi, cima_fusto - Vector3(0.0, 0.4, 0.0), cima_fusto + Vector3(0.0, 0.2, 0.0), Vector3(0.0, 0.0, 0.18))

	var mesh = st_legno.commit()
	mesh.surface_set_material(0, mat_legno)

	var mesh_totale = st_aghi.commit(mesh)
	mesh_totale.surface_set_material(1, mat_aghi)
	return mesh_totale

static func _aggiungi_trave_legno(st: SurfaceTool, da: Vector3, a: Vector3, off: Vector3) -> void:
	var v0 = da - off; var v1 = da + off; var v2 = a
	var n = (off.cross(a - da)).normalized()
	st.set_normal(n); st.add_vertex(v0); st.add_vertex(v1); st.add_vertex(v2)

static func _aggiungi_quad(st: SurfaceTool, da: Vector3, a: Vector3, off: Vector3) -> void:
	var v0 = da - off; var v1 = da + off; var v2 = a + off; var v3 = a - off
	var n = (off.cross(a - da)).normalized()

	st.set_normal(n); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(v0)
	st.set_normal(n); st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(v1)
	st.set_normal(n); st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(v2)

	st.set_normal(n); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(v0)
	st.set_normal(n); st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(v2)
	st.set_normal(n); st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(v3)
