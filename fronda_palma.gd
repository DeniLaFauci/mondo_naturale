class_name FrondaPalma
extends RefCounted

static func costruisci(lungh: float = 4.2, arco: float = 0.65, rng: RandomNumberGenerator = null) -> ArrayMesh:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat = ShaderMaterial.new()
	mat.shader = load("res://foglia_palma.gdshader")

	# 1. Asse centrale (Rachide legnosa)
	var passi = 80
	var spine: Array[Vector3] = []
	for i in range(passi + 1):
		var t = float(i) / float(passi)
		var z = t * lungh
		# Parabola reale con culmine convesso: sale fino a 0.5m prima di flettere
		var y = sin(t * PI * 0.6) * 0.35 - pow(t, 4.0) * 0.45
		spine.append(Vector3(0.0, y, z))

	# Tinte realistiche: rachide ocra/legno, verde vivo, punta secca marroncina
	var col_rachide = Color(0.42, 0.31, 0.16)
	var col_verde_scuro = Color(0.08, 0.26, 0.05)
	var col_verde_vivo = Color(0.14, 0.34, 0.07)
	var col_secco = Color(0.48, 0.32, 0.12)

	# 2. Modellazione delle pinne con rachide solida e sfumatura sui vertici
	for i in range(passi):
		var t = float(i) / float(passi)
		var p1 = spine[i]
		var p2 = spine[i + 1]
		var dir_fwd = (p2 - p1).normalized()
		var dir_lat = Vector3(1.0, 0.0, 0.0)

		# Rachide legnosa centrale
		var w_gambo = lerp(0.024, 0.005, t)
		var g_dx1 = p1 + dir_lat * w_gambo
		var g_sx1 = p1 - dir_lat * w_gambo
		var g_dx2 = p2 + dir_lat * (w_gambo * 0.95)
		var g_sx2 = p2 - dir_lat * (w_gambo * 0.95)

		# COLOR.g = 0.0 indica il fusto centrale legnoso allo shader
		st.set_color(Color(0.0, 0.0, 0.0)); st.set_uv(Vector2(0.5, t))
		st.add_vertex(g_sx1); st.add_vertex(g_dx1); st.add_vertex(g_dx2) 
		st.add_vertex(g_sx1); st.add_vertex(g_dx2); st.add_vertex(g_sx2)
		
		if i == 0: continue

		# Pinna proporzionata, densa e senza zig-zag eccessivo
		var len_pinna = max(0.05, (1.0 - pow(t, 1.40)) * pow(t, 0.24) * 1.22)
		var inc_fwd = lerp(0.85, 3.4, pow(t, 0.80))
		var w_lamina = lerp(0.075, 0.028, t)
		var sfalso_v = 0.002 if (i % 2 == 0) else -0.002
		var discesa_v = len_pinna * lerp(0.10, 0.02, t) + sfalso_v
		var prof_canale = 0.035

		# COLOR.g = 1.0 indica foglia allo shader
		st.set_color(Color(0.0, 1.0, 0.0))

		# --- PINNA DESTRA (NASTRO A V) ---
		var dir_p_dx = (dir_lat + dir_fwd * inc_fwd).normalized()
		var p_dx_b1 = g_dx1
		var p_dx_b2 = g_dx1 + dir_fwd * (w_lamina * 0.5)
		var p_dx_b3 = g_dx1 + dir_fwd * w_lamina

		var tratto_lungo = len_pinna * 0.88
		var p_dx_m1 = p_dx_b1 + dir_p_dx * tratto_lungo - Vector3(0.0, discesa_v * 0.88, 0.0)
		var p_dx_m2 = p_dx_b2 + dir_p_dx * tratto_lungo - Vector3(0.0, discesa_v * 0.88 - prof_canale, 0.0)
		var p_dx_m3 = p_dx_b3 + dir_p_dx * tratto_lungo - Vector3(0.0, discesa_v * 0.88, 0.0)
		var punta_dx = p_dx_b2 + dir_p_dx * len_pinna - Vector3(0.0, discesa_v, 0.0)

		st.set_uv(Vector2(0.05, 0.0)); st.add_vertex(p_dx_b1)
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(p_dx_b2)
		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_dx_m2)

		st.set_uv(Vector2(0.05, 0.0)); st.add_vertex(p_dx_b1)
		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_dx_m2)
		st.set_uv(Vector2(0.05, 0.88)); st.add_vertex(p_dx_m1)

		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(p_dx_b2)
		st.set_uv(Vector2(0.95, 0.0)); st.add_vertex(p_dx_b3)
		st.set_uv(Vector2(0.95, 0.88)); st.add_vertex(p_dx_m3)

		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(p_dx_b2)
		st.set_uv(Vector2(0.95, 0.88)); st.add_vertex(p_dx_m3)
		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_dx_m2)

		st.set_uv(Vector2(0.05, 0.88)); st.add_vertex(p_dx_m1)
		st.set_uv(Vector2(0.95, 0.88)); st.add_vertex(p_dx_m2)
		st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(punta_dx)

		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_dx_m2)
		st.set_uv(Vector2(0.95, 0.88)); st.add_vertex(p_dx_m3)
		st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(punta_dx)


		# --- PINNA SINISTRA A CANNELLETTO (V) ---
		var dir_p_sx = (-dir_lat + dir_fwd * inc_fwd).normalized()
		var p_sx_b1 = g_sx1
		var p_sx_b2 = g_sx1 + dir_fwd * (w_lamina * 0.5)
		var p_sx_b3 = g_sx1 + dir_fwd * w_lamina

		var p_sx_m1 = p_sx_b1 + dir_p_sx * tratto_lungo - Vector3(0.0, discesa_v * 0.88, 0.0)
		var p_sx_m2 = p_sx_b2 + dir_p_sx * tratto_lungo - Vector3(0.0, discesa_v * 0.88 - prof_canale, 0.0)
		var p_sx_m3 = p_sx_b3 + dir_p_sx * tratto_lungo - Vector3(0.0, discesa_v * 0.88, 0.0)
		var punta_sx = p_sx_b2 + dir_p_sx * len_pinna - Vector3(0.0, discesa_v, 0.0)

		st.set_uv(Vector2(0.05, 0.0)); st.add_vertex(p_sx_b1)
		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_sx_b2)
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(p_sx_m2)

		st.set_uv(Vector2(0.05, 0.0)); st.add_vertex(p_sx_b1)
		st.set_uv(Vector2(0.05, 0.88)); st.add_vertex(p_sx_m1)
		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_sx_m2)

		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(p_sx_b2)
		st.set_uv(Vector2(0.95, 0.88)); st.add_vertex(p_sx_m3)
		st.set_uv(Vector2(0.95, 0.0)); st.add_vertex(p_sx_b3)

		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(p_sx_b2)
		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_sx_m2)
		st.set_uv(Vector2(0.95, 0.88)); st.add_vertex(p_sx_m3)

		st.set_uv(Vector2(0.05, 0.88)); st.add_vertex(p_sx_m1)
		st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(punta_sx)
		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_sx_m2)

		st.set_uv(Vector2(0.5, 0.88)); st.add_vertex(p_sx_m2)
		st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(punta_sx)
		st.set_uv(Vector2(0.95, 0.88)); st.add_vertex(p_sx_m3)
	
	# Foglia apicale terminale (chiusura a lancia della cima)
	var p_cima = spine[passi]
	var dir_cima = (spine[passi] - spine[passi - 1]).normalized()
	var punta_finale = p_cima + dir_cima * 0.45 - Vector3(0.0, 0.1, 0.0)
	st.set_color(col_rachide); st.add_vertex(spine[passi -1])
	st.set_color(col_secco); st.add_vertex(punta_finale)
	st.set_color(col_rachide); st.add_vertex(p_cima)



	st.generate_normals()
	var mesh = st.commit()
	mesh.surface_set_material(0, mat)
	return mesh
