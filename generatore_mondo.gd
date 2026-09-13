extends Node3D

func _ready() -> void:
	crea_illuminazione()
	crea_mare()
	crea_terreno_collinare()
	crea_telecamera()
	print("Mondo con mare e atmosfera generato con successo!")

func crea_illuminazione() -> void:
	# 1. Crea la luce del Sole
	var sole = DirectionalLight3D.new()
	sole.name = "Sole"
	sole.shadow_bias = 0.05
	sole.shadow_enabled = true
	sole.light_color = Color(1.0, 0.92, 0.82)
	sole.light_energy = 1.2
	sole.rotation_degrees = Vector3(-22, 55, 0)
	add_child(sole)

	# 2. Crea il cielo e l'ambiente
	var cielo_mat = ProceduralSkyMaterial.new()
	cielo_mat.sky_top_color = Color(0.28, 0.52, 0.88)
	cielo_mat.sky_horizon_color = Color(0.72, 0.82, 0.90)
	cielo_mat.ground_bottom_color = Color(0.15, 0.35, 0.45)
	cielo_mat.ground_horizon_color = Color(0.72, 0.82, 0.90)
	cielo_mat.sun_angle_max = 15.0

	var cielo = Sky.new()
	cielo.sky_material = cielo_mat

	var env = Environment.new()
	env.sky = cielo
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

	env.fog_enabled = true
	env.fog_light_color = Color(0.70, 0.80, 0.88)
	env.fog_density = 0.003
	env.fog_aerial_perspective = 0.6

	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func crea_mare() -> void:
	var mesh_mare = MeshInstance3D.new()
	var piano_mare = PlaneMesh.new()
	piano_mare.size = Vector2(2000.0, 2000.0)
	mesh_mare.mesh = piano_mare
	mesh_mare.position.y = 0.5

	var mat_mare = StandardMaterial3D.new()
	mat_mare.albedo_color = Color(0.06, 0.18, 0.28)
	mat_mare.roughness = 0.15
	mat_mare.metallic = 0.1
	mesh_mare.material_override = mat_mare

	add_child(mesh_mare)

func crea_terreno_collinare() -> void:
	# 1. Configurazione rumore frattale (Fractional Brownian Motion)
	var rumore = FastNoiseLite.new()
	rumore.noise_type = FastNoiseLite.TYPE_PERLIN
	rumore.fractal_type = FastNoiseLite.FRACTAL_FBM
	rumore.fractal_octaves = 4
	rumore.frequency = 0.015

	# Usiamo PlaneMesh nativo che ha già la topologia e le normali perfette
	var piano = PlaneMesh.new()
	piano.size = Vector2(160, 160)
	piano.subdivide_width = 100
	piano.subdivide_depth = 100

	# Convertiamo in ArrayMesh per deformare la quota Y di ogni singolo vertice
	var array_mesh = ArrayMesh.new()
	var array = piano.get_mesh_arrays()
	var vertici = array[Mesh.ARRAY_VERTEX]

	var altezza_massima = 28.0
	for i in range(vertici.size()):
		var v = vertici[i]
		v.y = rumore.get_noise_2d(v.x, v.z) * altezza_massima
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

func crea_telecamera() -> void:
	var script_volo = load("res://telecamera_volo.gd")
	var cam = Camera3D.new()
	cam.set_script(script_volo)
	cam.current = true
	cam.position = Vector3(0, 22, 45)
	add_child(cam)
