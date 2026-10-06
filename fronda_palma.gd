extends RefCounted

static func costruisci(lungh: float = 4.2, arco_caduta: float = 1.6, rng: RandomNumberGenerator = null) -> ArrayMesh:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat = ShaderMaterial.new()
	mat.shader = load("res://foglia_palma.gdshader")

	# Asse centrale (Rachide legnosa)
	var passi = 60
	var spine: Array[Vector3] = []
	var spine_tangenti: Array[Vector3] = []

	# Calcolo dell'asse centrale (rachide a parabola naturale cadente
	for i in range(passi + 1):
		var t = float(i) / float(passi)
		var z = t * lungh
		# Sale dolcemente all'inizio (spinta elastica) e ricade per gravità
		var y = lungh * (0.18 * t) - arco_caduta * pow(t, 2.7)
		spine.append(Vector3(0.0, y, z))

	for i in range(passi):
		spine_tangenti.append((spine[i + 1] - spine[i]).normalized())
	spine_tangenti.append(spine_tangenti[passi - 1])

	# 2. Generazione rachide legnosa centrale
	for i in range(passi):
		var t = float(i) / float(passi)
		var p1 = spine[i]
		var p2 = spine[i + 1]
		var dir_lat = Vector3(1.0, 0.0, 0.0)

		var w1 = lerp(0.035, 0.006, t)
		var w2 = lerp(0.035, 0.006, float(i + 1) / float(passi))

		var g_dx1 = p1 + dir_lat * w1
		var g_sx1 = p1 - dir_lat * w1
		var g_dx2 = p2 + dir_lat * w2
		var g_sx2 = p2 - dir_lat * w2

		# COLOR.g = 0.0 indica la rachide
		st.set_color(Color(0.0, 0.0, 0.0));
		st.set_uv(Vector2(0.5, t))
		st.add_vertex(g_sx1); st.add_vertex(g_dx1); st.add_vertex(g_dx2) 
		st.add_vertex(g_sx1); st.add_vertex(g_dx2); st.add_vertex(g_sx2)
		
	# 3. Generazione pinne fogliari (distribuzione a pettine con diedro a V)
	var soglia_picciolo = 0.15

	for i in range(passi - 1):
		var t1 = float(i) / float(passi)
		var t2 = float(i + 1) / float(passi)
		if t1 < soglia_picciolo: continue

		# Normalizzazione coordinata pinne lungo la fronda (0 = prima pinna, 1 = cima)
		var u1 = (t1 - soglia_picciolo) / (1.0 - soglia_picciolo)
		var u2 = (t2 - soglia_picciolo) / (1.0 - soglia_picciolo)

		var p1 = spine[i]
		var p2 = spine[i + 1]

		var fwd1 = spine_tangenti[i]
		var fwd2 = spine_tangenti[i + 1]

		var lat = Vector3(1.0, 0.0, 0.0)
		var up1 = lat.cross(fwd1).normalized()
		var up2 = lat.cross(fwd2).normalized()

		var larghezza1 = sin(pow(u1, 0.62) * PI) * 0.38 + 0.04
		var larghezza2 = sin(pow(u2, 0.62) * PI) * 0.38 + 0.04

		var alzo_v = 0.28
		var caduta1 = pow(larghezza1, 1.3) * 0.45
		var caduta2 = pow(larghezza2, 1.3) * 0.45

		st.set_color(Color(0.0, 1.0, 0.0))

		# --- LATO DESTRO ---
		var dir_ala_dx1 = (lat + up1 * alzo_v + fwd1 * 0.45).normalized()
		var dir_ala_dx2 = (lat + up2 * alzo_v + fwd2 * 0.45).normalized()

		var punta_dx1 = p1 + dir_ala_dx1 * larghezza1 - Vector3(0.0, caduta1, 0.0)
		var punta_dx2 = p2 + dir_ala_dx2 * larghezza2 - Vector3(0.0, caduta2, 0.0)

		st.set_uv(Vector2(0.1, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(0.9, u1)); st.add_vertex(punta_dx1)
		st.set_uv(Vector2(0.9, u2)); st.add_vertex(punta_dx2)

		st.set_uv(Vector2(0.1, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(0.9, u2)); st.add_vertex(punta_dx2)
		st.set_uv(Vector2(0.1, u2)); st.add_vertex(p2)

		# --- LATO SINISTRO ---
		var dir_ala_sx1 = (-lat + up1 * alzo_v + fwd1 * 0.45).normalized()
		var dir_ala_sx2 = (-lat + up2 * alzo_v + fwd2 * 0.45).normalized()

		var punta_sx1 = p1 + dir_ala_sx1 * larghezza1 - Vector3(0.0, caduta1, 0.0)
		var punta_sx2 = p2 + dir_ala_sx2 * larghezza2 - Vector3(0.0, caduta2, 0.0)

		st.set_uv(Vector2(0.1, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(0.9, u2)); st.add_vertex(punta_sx1)
		st.set_uv(Vector2(0.9, u1)); st.add_vertex(punta_sx2)

		st.set_uv(Vector2(0.1, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(0.1, u2)); st.add_vertex(p2)
		st.set_uv(Vector2(0.9, u2)); st.add_vertex(punta_sx2)



	st.generate_normals()
	var mesh = st.commit()
	mesh.surface_set_material(0, mat)
	return mesh
