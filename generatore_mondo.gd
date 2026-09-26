extends Node3D

var nodo_sole: DirectionalLight3D
var mat_cielo: ShaderMaterial
var mat_mare: ShaderMaterial
var env_risorse: Environment
var tempo_giorno: float = 0.25	# Parte verso mattina/mezzogiorno
const DURATA_GIORNO_SECONDI: float = 240.0 # 4 minuti per fare un giorno intero

func _ready() -> void:
	randomize()
	crea_illuminazione()
	crea_mare()
	crea_montagne()
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
		if alt > 0.0:
			nodo_sole.light_energy = lerp(0.0, 1.6, clamp(alt * 4.0, 0.0, 1.0))
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
			"copertura": 0.88,
			"scala": 1.1,
			"dettaglio": 0.50,
			"pioggia": 0.85,
			"vento": Vector2(0.045, 0.02)
		}
	]

	var meteo_estratto = tipi_meteo[randi() % tipi_meteo.size()]
	print(">>> METEO ESTRATTO ALL'AVVIO: ", meteo_estratto["nome"])

	mat_cielo.set_shader_parameter("copertura_nubi", meteo_estratto["copertura"])
	mat_cielo.set_shader_parameter("scala_nubi", meteo_estratto["scala"])
	mat_cielo.set_shader_parameter("densita_dettaglio", meteo_estratto["dettaglio"])
	mat_cielo.set_shader_parameter("oscuramento_pioggia", meteo_estratto["pioggia"])
	mat_cielo.set_shader_parameter("velocita_vento", meteo_estratto["vento"])
