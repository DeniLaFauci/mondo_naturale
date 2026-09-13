extends Node3D

func _ready() -> void:
	crea_illuminazione()
	crea_terreno_collinare()
	crea_telecamera()
	print("Mondo collinare generato con successo!")

func crea_illuminazione() -> void:
	# 1. Crea la luce del Sole
	var sole = DirectionalLight3D.new()
	sole.name = "Sole"
	sole.shadow_enabled = true
	sole.rotation_degrees = Vector3(-35, 45, 0)
	add_child(sole)

	# 2. Crea il cielo e l'ambiente
	var env = Environment.new()
	var cielo_mat = ProceduralSkyMaterial.new()
	var cielo = Sky.new()
	cielo.sky_material = cielo_mat
	env.sky = cielo
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func crea_terreno_collinare() -> void:
	# 1. Configurazione rumore frattale (Fractional Brownian Motion)
	var rumore = FastNoiseLite.new()
	rumore.noise_type = FastNoiseLite.TYPE_PERLIN
	rumore.fractal_type = FastNoiseLite.FRACTAL_FBM
	rumore.fractal_octaves = 4
	rumore.frequency = 0.015

	# Usiamo PlaneMesh nativo che ha già la topologia e le normali perfette
	var piano = PlaneMesh.new()
	piano.size = Vector2(140, 140)
	piano.subdivide_width = 80
	piano.subdivide_depth = 80

	# Convertiamo in ArrayMesh per deformare la quota Y di ogni singolo vertice
	var array_mesh = ArrayMesh.new()
	var array = piano.get_mesh_arrays()
	var vertici = array[Mesh.ARRAY_VERTEX]

	var altezza_massima = 12.0
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

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.45, 0.18)
	mat.roughness = 0.85
	mesh_istanza.material_override = mat

	add_child(mesh_istanza)

func crea_telecamera() -> void:
	var cam = Camera3D.new()
	cam.position = Vector3(0, 15, 35)
	cam.rotation_degrees = Vector3(-20, 0, 0)
	add_child(cam)
