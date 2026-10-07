extends RefCounted

static func costruisci(lungh: float = 4.4, arco_caduta: float = 1.7, rng: RandomNumberGenerator = null) -> ArrayMesh:
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

	# Asse centrale: sale ad arco, culmina a rachide
	for i in range(passi + 1):
		var t = float(i) / float(passi)
		var z = t * lungh
		# Sale dolcemente all'inizio (spinta elastica) e ricade per gravità
		var y = lungh * (0.28 * sin(t * PI * 0.65)) - (arco_caduta / lungh) * pow(t, 2.2)
		spine.append(Vector3(0.0, y, z))

	for i in range(passi):
		spine_tangenti.append((spine[i + 1] - spine[i]).normalized())
	spine_tangenti.append(spine_tangenti[passi - 1])

	# 2. Rachide legnosa solida
	for i in range(passi):
		var t1 = float(i) / float(passi)
		var t2 = float(i + 1) / float(passi)
		var p1 = spine[i]
		var p2 = spine[i + 1]
		var dir_lat = Vector3(1.0, 0.0, 0.0)

		var w1 = lerp(0.040, 0.007, t1)
		var w2 = lerp(0.040, 0.007, t2)

		var g_sx1 = p1 - dir_lat * w1
		var g_dx1 = p1 + dir_lat * w1
		var g_sx2 = p2 - dir_lat * w2
		var g_dx2 = p2 + dir_lat * w2

		st.set_color(Color(0.0, 0.0, 0.0));
		st.set_uv(Vector2(0.0, t1))
		st.add_vertex(g_sx1); st.add_vertex(g_dx1); st.add_vertex(g_dx2) 
		st.add_vertex(g_sx1); st.add_vertex(g_dx2); st.add_vertex(g_sx2)
		
	# 3. Lamina a "V" (base geometrica per il pettine dello shader)
	var soglia_picciolo = 0.03

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

#---------------------------------------------------------------------
		# Ampiezza a fuso
		var larghezza1 = sin(pow(u1, 0.65) * PI) * 0.44 + 0.04
		var larghezza2 = sin(pow(u2, 0.65) * PI) * 0.44 + 0.04

		# Spinta in avanti ad angolo acuto (si chiude verso l'apice
		var fwd_spinta1 = lerp(0.70, 2.4, pow(u1, 0.6))
		var fwd_spinta2 = lerp(0.70, 2.4, pow(u2, 0.6))
		var lat_spinta1 = lerp(0.85, 0.35, u1)
		var lat_spinta2 = lerp(0.85, 0.35, u2)

		st.set_color(Color(0.0, 1.0, 0.0))

		# --- STRATO A: PINNE SUPERIORI (più erette a V, fwd spinto) ---
		var alzo_A = 0.45
		var caduta_A1 = pow(larghezza1, 1.3) * 0.28
		var caduta_A2 = pow(larghezza2, 1.3) * 0.28
		var dir_dx_A1 = (lat * lat_spinta1 + up1 * alzo_A + fwd1 * fwd_spinta1).normalized()
		var dir_dx_A2 = (lat * lat_spinta2 + up2 * alzo_A + fwd2 * fwd_spinta2).normalized()
		var p_dx_A1 = p1 + dir_dx_A1 * (larghezza1 * 0.90) - Vector3(0.0, caduta_A1, 0.0)
		var p_dx_A2 = p2 + dir_dx_A2 * (larghezza2 * 0.90) - Vector3(0.0, caduta_A2, 0.0)

		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(1.0, u1)); st.add_vertex(p_dx_A1)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_dx_A2)
		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_dx_A2)
		st.set_uv(Vector2(0.0, u2)); st.add_vertex(p2)

		var dir_sx_A1 = (-lat * lat_spinta1 + up1 * alzo_A + fwd1 * fwd_spinta1).normalized()
		var dir_sx_A2 = (-lat * lat_spinta2 + up2 * alzo_A + fwd2 * fwd_spinta2).normalized()
		var p_sx_A1 = p1 + dir_dx_A1 * (larghezza1 * 0.90) - Vector3(0.0, caduta_A1, 0.0)
		var p_sx_A2 = p2 + dir_dx_A2 * (larghezza2 * 0.90) - Vector3(0.0, caduta_A2, 0.0)

		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_sx_A1)
		st.set_uv(Vector2(1.0, u1)); st.add_vertex(p_sx_A2)
		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(0.0, u2)); st.add_vertex(p2)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_sx_A2)

# --- STRATO B: PINNE INFERIORII (più aperte e lunghe, volume 3D) ---
		var alzo_B = 0.12
		var caduta_B1 = pow(larghezza1, 1.4) * 0.42
		var caduta_B2 = pow(larghezza2, 1.4) * 0.42
		var dir_dx_B1 = (lat * (lat_spinta1 * 1.1) + up1 * alzo_B + fwd1 * (fwd_spinta1 * 0.85)).normalized()
		var dir_dx_B2 = (lat * (lat_spinta2 * 1.1) + up2 * alzo_B + fwd2 * (fwd_spinta2 * 0.85)).normalized()
		var p_dx_B1 = p1 + dir_dx_B1 * larghezza1 - Vector3(0.0, caduta_B1, 0.0)
		var p_dx_B2 = p2 + dir_dx_B2 * larghezza2 - Vector3(0.0, caduta_B2, 0.0)

		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(1.0, u1)); st.add_vertex(p_dx_B1)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_dx_B2)
		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_dx_B2)
		st.set_uv(Vector2(0.0, u2)); st.add_vertex(p2)

		var dir_sx_B1 = (-lat * (lat_spinta1 * 1.1) + up1 * alzo_B + fwd1 * (fwd_spinta1 * 0.85)).normalized()
		var dir_sx_B2 = (-lat * (lat_spinta2 * 1.1) + up2 * alzo_B + fwd2 * (fwd_spinta2 * 0.85)).normalized()
		var p_sx_B1 = p1 + dir_dx_B1 * larghezza1 - Vector3(0.0, caduta_B1, 0.0)
		var p_sx_B2 = p2 + dir_dx_B2 * larghezza2 - Vector3(0.0, caduta_B2, 0.0)

		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_sx_B1)
		st.set_uv(Vector2(1.0, u1)); st.add_vertex(p_sx_B2)
		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(0.0, u2)); st.add_vertex(p2)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_sx_B2)

		
#---------------------------------------------------------------------------------------------
		st.set_uv(Vector2(0.0, u1)); st.add_vertex(p1)
		st.set_uv(Vector2(0.0, u2)); st.add_vertex(p2)
		st.set_uv(Vector2(1.0, u2)); st.add_vertex(p_sx_B2)

	st.generate_normals()
	var mesh = st.commit()
	mesh.surface_set_material(0, mat)
	return mesh
