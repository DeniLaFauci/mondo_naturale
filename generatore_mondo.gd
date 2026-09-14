extends Node3D

func _ready() -> void:
	crea_illuminazione()
	crea_montagne()
	print("Catena montuosa stile monte Chiliad generata")

func crea_illuminazione() -> void:
	# 1. Crea la luce del Sole
	var sole = DirectionalLight3D.new()
	sole.name = "Sole"
	sole.shadow_enabled = true
	sole.shadow_bias = 0.04
	sole.shadow_normal_bias = 2.0
	sole.light_color = Color(1.0, 0.90, 0.78)
	sole.light_energy = 1.8
	sole.rotation_degrees = Vector3(-28, 40, 0)
	add_child(sole)

	# 2. Crea il cielo terso e nebbia bassa
	var env = Environment.new()
	var cielo_mat = ProceduralSkyMaterial.new()
	cielo_mat.sky_top_color = Color(0.20, 0.44, 0.82)
	cielo_mat.sky_horizon_color = Color(0.78, 0.75, 0.70)
	cielo_mat.ground_bottom_color = Color(0.16, 0.15, 0.14)
	cielo_mat.ground_horizon_color = Color(0.68, 0.65, 0.60)

	var cielo = Sky.new()
	cielo.sky_material = cielo_mat
	env.sky = cielo
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.35

	# Nebbia all'orizzonte per fondere i bordi
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.75, 0.78)
	env.fog_density = 0.0012

	var world_env = WorldEnvironment.new()
	world_env.environment = env
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

	for i in range(vertici.size()):
		var v = vertici[i]
		var raw_noise = rumore_dorsale.get_noise_2d(v.x, v.z)
		var cresta = 1.0 - abs(raw_noise)

		cresta = pow(cresta, 2.0)

		var erosione = rumore_erosione.get_noise_2d(v.x, v.z) * 0.12 * cresta

		v.y = (cresta + erosione) * altezza_massima
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

	add_child(mesh_istanza)
