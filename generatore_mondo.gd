extends Node3D

var nodo_sole: DirectionalLight3D
var mat_cielo: ShaderMaterial
var mat_mare: ShaderMaterial
var env_risorse: Environment
var meteo_attuale: String = ""
var meteo_estratto: Dictionary = {}
var nodo_fulmine: MeshInstance3D
var mat_fulmine: StandardMaterial3D
var timer_prossimo_fulmine: float = 3.0
var lampo_attivo: bool = false
var durata_lampo: float = 0.0
var frame_flicker: int = 0

var tempo_giorno: float = 0.25	# Parte verso mattina/mezzogiorno
const DURATA_GIORNO_SECONDI: float = 240.0 # 4 minuti per fare un giorno intero

func _ready() -> void:
	randomize()
	crea_illuminazione()
	crea_mare()
	crea_montagne()
	crea_vegetazione()
	crea_nodo_fulmine()
	estrai_meteo_casuale()
	print("Catena montuosa stile monte Chiliad generata")

func crea_illuminazione() -> void:
	# 1. Crea la luce del Sole (assegnata alla variabile globale!)
	nodo_sole = DirectionalLight3D.new()
	nodo_sole.name = "Sole"
	nodo_sole.shadow_enabled = true
	nodo_sole.shadow_bias = 0.04
	nodo_sole.shadow_normal_bias = 2.0
	nodo_sole.light_color = Color(1.0, 0.90, 0.78)
	nodo_sole.light_energy = 1.8
	add_child(nodo_sole)

	# 2. Crea il cielo terso e nebbia bassa
	var env_risorse = Environment.new()
	mat_cielo = ShaderMaterial.new()
	mat_cielo.shader = load("res://cielo_shader.gdshader")	

	var cielo = Sky.new()
	cielo.sky_material = mat_cielo
	env_risorse.sky = cielo
	env_risorse.background_mode = Environment.BG_SKY
	env_risorse.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

	# Nebbia all'orizzonte per fondere i bordi
	env_risorse.fog_enabled = false
	env_risorse.fog_light_color = Color(0.75, 0.75, 0.78)
	env_risorse.fog_density = 0.0012

	var world_env = WorldEnvironment.new()
	world_env.environment = env_risorse
	add_child(world_env)

func crea_montagne() -> void:
	# 1. Configurazione rumore frattale (Fractional Brownian Motion)
	var rumore_dorsale = FastNoiseLite.new()
	rumore_dorsale.noise_type = FastNoiseLite.TYPE_PERLIN
	rumore_dorsale.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	rumore_dorsale.fractal_octaves = 5
	rumore_dorsale.fractal_lacunarity = 2.1
	rumore_dorsale.fractal_gain = 0.45
	rumore_dorsale.frequency = 0.007

	var rumore_erosione = FastNoiseLite.new()
	rumore_erosione.noise_type = FastNoiseLite.TYPE_PERLIN
	rumore_erosione.frequency = 0.03

	# Usiamo PlaneMesh nativo che ha già la topologia e le normali perfette
	var piano = PlaneMesh.new()
	piano.size = Vector2(260, 260)
	piano.subdivide_width = 160
	piano.subdivide_depth = 160

	var array = piano.get_mesh_arrays()
	var vertici = array[Mesh.ARRAY_VERTEX]
	var altezza_massima = 75.0
	var raggio_max = 130.0			# Metà della dimensione del piano (260/2)

	for i in range(vertici.size()):
		var v = vertici[i]

		# Calcolo del canale a cresta viva
		var raw_noise = rumore_dorsale.get_noise_2d(v.x, v.z)
		var cresta = 1.0 - abs(raw_noise)
		cresta = pow(cresta, 2.8)

		# Solchi di erosione
		var erosione = rumore_erosione.get_noise_2d(v.x, v.z) * 0.12 * cresta

		# Maschera di decadimento verso i bordi (effetto isola/costa)
		var dist_centro = Vector2(v.x, v.z).length()
		var fattore_bordo = clamp(dist_centro / raggio_max, 0.0, 1.0)
		var maschera_isola = smoothstep(1.0, 0.2, fattore_bordo)

		# Assicuriamo una base solida rialzata per le vallate interne
		var h_terra = 2.5 + (cresta + erosione) * altezza_massima
		v.y = lerp(-15.0, h_terra, maschera_isola)
		vertici[i] = v

	array[Mesh.ARRAY_VERTEX] = vertici

	# Usiamo SurfaceTool solo per rigenerare le normali lisce (Smooth Normals)
	var st = SurfaceTool.new()
	st.create_from_arrays(array)
	st.generate_normals()

	var mesh_istanza = MeshInstance3D.new()
	mesh_istanza.mesh = st.commit()

	var mat = ShaderMaterial.new()
	mat.shader = load("res://terreno_shader.gdshader")
	mesh_istanza.material_override = mat

	add_child(mesh_istanza);

func crea_mare() -> void:
	var mare_mesh = PlaneMesh.new()	
	mare_mesh.size = Vector2(1200, 1200)

	mat_mare = ShaderMaterial.new()
	mat_mare.shader = load("res://mare_shader.gdshader")

	var mare = MeshInstance3D.new()
	mare.name = "Oceano"
	mare.mesh = mare_mesh
	mare.material_override = mat_mare
	mare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mare.position.y = 1.2		# Quota del livello del mare
	add_child(mare)

func _process(delta: float) -> void:
	tempo_giorno += delta / DURATA_GIORNO_SECONDI
	if tempo_giorno > 1.0:
		tempo_giorno -= 1.0

	var angolo = tempo_giorno * TAU - (PI * 0.5)
	var dir_sole = Vector3(cos(angolo), sin(angolo), sin(angolo * 0.5) * 0.35).normalized()

	if nodo_sole:
		# Posizioniamo e orientiamo la luce verso l'origine con vettore inverso per proiettare le ombre
		nodo_sole.look_at_from_position(dir_sole * 100.0, Vector3.ZERO, Vector3.UP)

		var alt = dir_sole.y
		var fattore_buio_pioggia = 0.35 if (meteo_attuale == "Coperto Minaccioso") else 1.0
		if alt > 0.0:
			nodo_sole.light_energy = lerp(0.0, 1.6, clamp(alt * 4.0, 0.0, 1.0)) * fattore_buio_pioggia
			nodo_sole.light_color = Color(1.0, 0.5, 0.2).lerp(Color(1.0, 0.96, 0.88), clamp(alt * 3.0, 0.0, 1.0))
		else:
			nodo_sole.light_energy = 0.0

	if mat_cielo:
		mat_cielo.set_shader_parameter("direzione_sole", dir_sole)

	if mat_mare:
		mat_mare.set_shader_parameter("direzione_sole", dir_sole)
		var colore_sole_calc = Color(1.0, 0.5, 0.2).lerp(Color(1.0, 0.95, 0.88), clamp(dir_sole.y * 3.0, 0.0, 1.0))
		mat_mare.set_shader_parameter("colore_luce_sole", Vector3(colore_sole_calc.r, colore_sole_calc.g, colore_sole_calc.b))
	
	if env_risorse:
		var luce_amb = lerp(0.05, 0.65, clamp(dir_sole.y * 3.0 + 0.2, 0.0, 1.0))
		env_risorse.ambient_light_energy = luce_amb

	gestisci_temporale(delta)

func estrai_meteo_casuale() -> void:
	if not mat_cielo:
		return

	var tipi_meteo = [
		{
			"nome": "Sereno Limpido",
			"copertura": 0.0,
			"scala": 1.0,
			"dettaglio": 0.0,
			"pioggia": 0.0,
			"vento": Vector2(0.01, 0.003)
		},
		{
			"nome": "Velature e Cirri Alti",
			"copertura": 0.28,
			"scala": 0.45,
			"dettaglio": 0.15,
			"pioggia": 0.0,
			"vento": Vector2(0.035, 0.012)
		},
		{
			"nome": "Altocumuli (Cielo a pecorelle)",
			"copertura": 0.52,
			"scala": 2.4,
			"dettaglio": 0.60,
			"pioggia": 0.0,
			"vento": Vector2(0.018, 0.008)
		},
		{
			"nome": "Cumuli Sparsi Costieri",
			"copertura": 0.55,
			"scala": 0.95,
			"dettaglio": 0.35,
			"pioggia": 0.0,
			"vento": Vector2(0.022, 0.005)
		},
		{
			"nome": "Coperto Minaccioso",
			"copertura": 1.0,
			"scala": 0.9,
			"dettaglio": 0.65,
			"pioggia": 1.0,
			"vento": Vector2(0.06, 0.025)
		}
	]

	var meteo_estratto = tipi_meteo[randi() % tipi_meteo.size()]
	#var meteo_estratto = tipi_meteo[4]
	meteo_attuale = meteo_estratto["nome"]
	print(">>> METEO ESTRATTO ALL'AVVIO: ", meteo_attuale)

	mat_cielo.set_shader_parameter("copertura_nubi", meteo_estratto["copertura"])
	mat_cielo.set_shader_parameter("scala_nubi", meteo_estratto["scala"])
	mat_cielo.set_shader_parameter("densita_dettaglio", meteo_estratto["dettaglio"])
	mat_cielo.set_shader_parameter("oscuramento_pioggia", meteo_estratto["pioggia"])
	mat_cielo.set_shader_parameter("velocita_vento", meteo_estratto["vento"])

	if mat_mare:
		mat_mare.set_shader_parameter("oscuramento_pioggia", meteo_estratto["pioggia"])

func crea_nodo_fulmine() -> void:
	nodo_fulmine = MeshInstance3D.new()
	mat_fulmine = StandardMaterial3D.new()
	mat_fulmine.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_fulmine.albedo_color = Color(1.8, 2.0, 2.5)
	mat_fulmine.cull_mode = BaseMaterial3D.CULL_DISABLED
	nodo_fulmine.material_override = mat_fulmine
	nodo_fulmine.visible = false
	add_child(nodo_fulmine)

func gestisci_temporale(delta: float) -> void:
	if meteo_attuale != "Coperto Minaccioso":
		if nodo_fulmine:
			nodo_fulmine.visible = false
		if mat_cielo:
			mat_cielo.set_shader_parameter("intensita_lampo", 0.0)
		return

	if not lampo_attivo:
		timer_prossimo_fulmine -= delta
		if timer_prossimo_fulmine <= 0.0:
			scocca_fulmine()
	else:
		durata_lampo -= delta
		frame_flicker += 1

		# Effetto strobo / flicker rapido tipico del fulmine
		var flash = 1.0 if (frame_flicker % 2 == 0) else 0.3
		if durata_lampo <= 0.0:
			lampo_attivo = false
			nodo_fulmine.visible = false
			timer_prossimo_fulmine = randf_range(2.5, 6.0)
			if mat_cielo: mat_cielo.set_shader_parameter("intensita_lampo", 0.0)
		else:
			if mat_cielo: mat_cielo.set_shader_parameter("intensita_lampo", flash * 2.0)
			if env_risorse: env_risorse.ambient_light_energy = 0.8 * flash

func scocca_fulmine() -> void:
	lampo_attivo = true
	durata_lampo = randf_range(0.12, 0.22)
	frame_flicker = 0

	# Punto di origine in quota e bersaglio (terra o mare)
	var x_start = randf_range(-100.0, 100.0)
	var z_start = randf_range(-100.0, 100.0)
	var p_inizio = Vector3(x_start, 68.0, z_start)
	var p_fine = Vector3(x_start + randf_range(-20.0, 20.0), 2.0, z_start + randf_range(-20.0, 20.0))

	# Genera la linea spezzata a nastro
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var punti: Array[Vector3] = []
	var num_segmenti = 14
	punti.append(p_inizio)

	for i in range(1, num_segmenti):
		var t = float(i) / float(num_segmenti)
		var p_base = p_inizio.lerp(p_fine, t)
		var deviazione = Vector3(randf_range(-3.5, 3.5), randf_range(-1.0, 1.0), randf_range(-3.5, 3.5))
		punti.append(p_base + deviazione)
	punti.append(p_fine)

	# Crea un nastro con larghezza visibile
	var larghezza = 0.4
	for p in punti:
		st.add_vertex(p + Vector3(-larghezza, 0.0, larghezza))
		st.add_vertex(p + Vector3(larghezza, 0.0, -larghezza))

	nodo_fulmine.mesh = st.commit()
	nodo_fulmine.visible = true

func calcola_quota_e_normale_terreno(x: float, z: float) -> Dictionary:
	var r_dorsale = FastNoiseLite.new()
	r_dorsale.noise_type = FastNoiseLite.TYPE_PERLIN
	r_dorsale.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	r_dorsale.fractal_octaves = 5
	r_dorsale.fractal_lacunarity = 2.1
	r_dorsale.fractal_gain = 0.45
	r_dorsale.frequency = 0.007

	var r_erosione = FastNoiseLite.new()
	r_erosione.noise_type = FastNoiseLite.TYPE_PERLIN
	r_erosione.frequency = 0.03

	var raggio_max = 130.0
	var altezza_max = 75.0

	var calcola_h = func(px: float, pz: float) -> float:
		var raw = r_dorsale.get_noise_2d(px, pz)
		var cresta = pow(1.0 - abs(raw), 2.8)
		var eros = r_erosione.get_noise_2d(px, pz) * 0.12 * cresta
		var dist = Vector2(px, pz).length()
		var maschera = smoothstep(1.0, 0.2, clamp(dist / raggio_max, 0.0, 1.0))
		var h = 2.5 + (cresta + eros) * altezza_max
		return lerp(-15.0, h, maschera)

	var h_centro = calcola_h.call(x, z)
	var delta = 0.5
	var hx = calcola_h.call(x + delta, z) - calcola_h.call(x - delta, z)
	var hz = calcola_h.call(x, z + delta) - calcola_h.call(x, z - delta)
	var normale = Vector3(-hx, 2.0 * delta, -hz).normalized()

	return {"quota": h_centro, "normale": normale}

func crea_mesh_palma() -> Mesh:
	# Materiale tronco palma
	var mat_tronco = StandardMaterial3D.new()
	mat_tronco.albedo_color = Color(0.38, 0.28, 0.18)
	mat_tronco.roughness = 0.95

	var mat_foglie = StandardMaterial3D.new()
	mat_foglie.albedo_color = Color(0.16, 0.42, 0.08)
	mat_foglie.roughness = 0.65
	mat_foglie.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Fusto curvo e segmentato (stile spiaggia tropicale)
	var st_tronco = SurfaceTool.new()
	st_tronco.begin(Mesh.PRIMITIVE_TRIANGLES)

	var num_nodi = 7
	var anelli: Array[Array] = []
	var raggio_tronco = 0.14
	var inclinazione_totale = 1.1

	for n in range(num_nodi + 1):
		var t = float(n) / float(num_nodi)
		var h = t * 4.6
		var curva = pow(t, 1.6) * inclinazione_totale
		var centro = Vector3(curva, h, 0.0)
		var r_anello = raggio_tronco * (1.0 - t * 0.4)

		var punti_anello: Array[Vector3] = []
		for i in range(6):
			var a = float(i) / 6.0 * TAU		
			punti_anello.append(centro + Vector3(cos(a) * r_anello, 0.0, sin(a) * r_anello))
		anelli.append(punti_anello)

	for n in range(num_nodi):
		var a_inf = anelli[n]
		var a_sup = anelli[n + 1]
		for i in range(6):
			var i_next = (i + 1) % 6
			st_tronco.add_vertex(a_inf[i]); st_tronco.add_vertex(a_inf[i_next]); st_tronco.add_vertex(a_sup[i_next])
			st_tronco.add_vertex(a_inf[i]); st_tronco.add_vertex(a_sup[i_next]); st_tronco.add_vertex(a_sup[i])

	st_tronco.generate_normals()
	var mesh = st_tronco.commit()

	# Chioma a foglie arcuate e spioventi
	var st_foglie = SurfaceTool.new()
	st_foglie.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertice_cima = Vector3(inclinazione_totale, 4.6, 0.0)
	var num_fronde = 12

	for f in range(num_fronde): 
		var rot_ang = float(f) / float(num_fronde) * TAU
		var dir_radiale = Vector3(cos(rot_ang), 0.0, sin(rot_ang))

		var p_origine = vertice_cima
		var p_arco = vertice_cima + dir_radiale * 1.5 + Vector3(0.0, 0.35, 0.0)
		var p_punta = vertice_cima + dir_radiale * 3.1 - Vector3(0.0, 1.25, 0.0)

		var orto = Vector3(-dir_radiale.z, 0.0, dir_radiale.x) * 0.45
		var p_lato1 = p_arco + orto
		var p_lato2 = p_arco - orto

		st_foglie.add_vertex(p_origine); st_foglie.add_vertex(p_lato1); st_foglie.add_vertex(p_punta)
		st_foglie.add_vertex(p_origine); st_foglie.add_vertex(p_punta); st_foglie.add_vertex(p_lato2)

	st_foglie.generate_normals()
	mesh = st_foglie.commit(mesh)
	mesh.surface_set_material(0, mat_tronco)
	mesh.surface_set_material(1, mat_foglie)
	return mesh

func crea_mesh_pino() -> ArrayMesh:
	var mat_legno = StandardMaterial3D.new()
	mat_legno.albedo_color = Color(0.24, 0.16, 0.10)
	mat_legno.roughness = 0.95

	var mat_aghi = StandardMaterial3D.new()
	mat_aghi.albedo_color = Color(0.09, 0.22, 0.11)
	mat_aghi.roughness = 0.85
	mat_aghi.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 1. Fusto sottile ed eretto
	var st_fusto = SurfaceTool.new()
	st_fusto.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r_base = 0.12
	var r_cima = 0.04
	var h_tot = 3.6

	for i in range(5):
		var ang1 = float(i) / 5.0 * TAU
		var ang2 = float(i + 1) / 5.0 * TAU
		var v1 = Vector3(cos(ang1) * r_base, 0.0, sin(ang1) * r_base)
		var v2 = Vector3(cos(ang2) * r_base, 0.0, sin(ang2) * r_base)
		var v3 = Vector3(cos(ang2) * r_cima, h_tot, sin(ang2) * r_cima)
		var v4 = Vector3(cos(ang1) * r_cima, h_tot, sin(ang1) * r_cima)

		st_fusto.add_vertex(v1); st_fusto.add_vertex(v2); st_fusto.add_vertex(v3)
		st_fusto.add_vertex(v1); st_fusto.add_vertex(v3); st_fusto.add_vertex(v4)

	st_fusto.generate_normals()
	var mesh_tot = st_fusto.commit()

	# 2. Palchi d'aghi a stella frastagliati (5 strati con pendenza verso il basso)
	var st_chioma = SurfaceTool.new()
	st_chioma.begin(Mesh.PRIMITIVE_TRIANGLES)

	var piani = [
		{y = 0.7, r_ext = 1.35, r_int = 0.55, h_punta = 1.4},
		{y = 1.3, r_ext = 1.15, r_int = 0.45, h_punta = 1.3},
		{y = 1.9, r_ext = 0.90, r_int = 0.35, h_punta = 1.2},
		{y = 2.5, r_ext = 0.65, r_int = 0.25, h_punta = 1.0},
		{y = 3.1, r_ext = 0.40, r_int = 0.15, h_punta = 0.8}
	]

	for p in piani:
		var apice = Vector3(0.0, p.y + p.h_punta, 0.0)
		var n_spicchi = 8
		for i in range(n_spicchi):
			var a1 = float(i) / float(n_spicchi) * TAU
			var a_mid = (float(i) + 0.5) / float(n_spicchi) * TAU
			var a2 = float(i + 1) / float(n_spicchi) * TAU

			var punta_ramo = Vector3(cos(a_mid) * p.r_ext, p.y, sin(a_mid) * p.r_ext)
			var rientro1 = Vector3(cos(a1) * p.r_int, p.y + 0.15, sin(a1) * p.r_int)
			var rientro2 = Vector3(cos(a2) * p.r_int, p.y + 0.15, sin(a2) * p.r_int)

			st_chioma.add_vertex(apice); st_chioma.add_vertex(rientro1); st_chioma.add_vertex(punta_ramo)
			st_chioma.add_vertex(apice); st_chioma.add_vertex(punta_ramo); st_chioma.add_vertex(rientro2)

	st_chioma.generate_normals()
	var mesh = st_chioma.commit(mesh_tot)
	mesh.surface_set_material(0, mat_legno)
	mesh.surface_set_material(1, mat_aghi)
	return mesh

func crea_vegetazione() -> void:
	var mesh_palma = crea_mesh_palma()
	var mesh_pino = crea_mesh_pino()

	var transforms_palme: Array[Transform3D] = []
	var transforms_pini: Array[Transform3D] = []

	var raggio_isola = 118.0
	var quota_mare_rif = 1.2
	var passo = 3.2

	# Campionamento a griglia con perturbazione casuale
	for x in range (int(-raggio_isola), int(raggio_isola), int(passo)):
		for z in range(int(-raggio_isola), int(raggio_isola), int(passo)):
			var px = float(x) + randf_range(-1.2, 1.2)
			var pz = float(z) + randf_range(-1.2, 1.2)
			if Vector2(px, pz).length() > raggio_isola: continue

			var info = calcola_quota_e_normale_terreno(px, pz)
			var h = info["quota"]
			var norm = info["normale"]
			var pendenza = norm.y

			# 1. PALME: solo nella fascia costiera / spiaggia (sopra il mare e sotto quota 7.0)
			if h > quota_mare_rif + 0.2 and h < quota_mare_rif + 5.2 and pendenza > 0.72:
				if randf() < 0.24: # Densità palme
					var t = Transform3D()
					var sc = randf_range(0.55, 0.85)
					t = t.scaled(Vector3(sc, sc, sc))
					# Inclinazione naturale verso il mare aperto
					var angolo_costa = atan2(pz, px)
					t = t.rotated(Vector3.UP, -angolo_costa + randf_range(-0.4, 0.4))
					# Leggera inclinazione verso l'esterno dell'isola
					t.origin = Vector3(px, h - 0.1, pz)
					transforms_palme.append(t)

			# 2. PINI: sulle zone collinari / erbose e sui pendii intermedi (quota 7.0 - 45.0, pendenza moderata)
			elif h >= quota_mare_rif + 5.2 and h < 48.0 and pendenza > 0.58 and pendenza < 0.94:
				if randf() < 0.32: # Densità pini
					var t = Transform3D()
					var sc = randf_range(0.45, 0.80)
					t = t.scaled(Vector3(sc, sc, sc))
					t = t.rotated(Vector3.UP, randf_range(0.0, TAU))
					# Il pino cresce verticale rispetto al mondo, ancorandosi sul pendio
					t.origin = Vector3(px, h - 0.15, pz)
					transforms_pini.append(t)

	# Assegna al MultiMesh delle Palme
	if transforms_palme.size() > 0:
		var mm_palme = MultiMesh.new()
		mm_palme.transform_format = MultiMesh.TRANSFORM_3D
		mm_palme.mesh = mesh_palma
		mm_palme.instance_count = transforms_palme.size()
		for i in range(transforms_palme.size()): mm_palme.set_instance_transform(i, transforms_palme[i])

		var inst_palme = MultiMeshInstance3D.new()
		inst_palme.multimesh = mm_palme
		add_child(inst_palme)

	# Assegna al MultiMesh dei Pini
	if transforms_pini.size() > 0:
		var mm_pini = MultiMesh.new()
		mm_pini.transform_format = MultiMesh.TRANSFORM_3D
		mm_pini.mesh = mesh_pino
		mm_pini.instance_count = transforms_pini.size()
		for i in range(transforms_pini.size()): mm_pini.set_instance_transform(i, transforms_pini[i])

		var inst_pini = MultiMeshInstance3D.new()
		inst_pini.multimesh = mm_pini
		add_child(inst_pini)

	print("vegetazione generata: ", transforms_palme.size(), " palme, ", transforms_pini.size(), " pini.")
