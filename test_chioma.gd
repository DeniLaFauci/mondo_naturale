extends Node3D

const FrondaPalma = preload("res://fronda_palma.gd")

func _ready() -> void:
	# Luce solare direzionale
	var dir_light = DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-45, 35, 0)
	dir_light.shadow_enabled = true
	add_child(dir_light)

	# Luce ambientale cielo
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.72, 0.88)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4, 0.45, 0.5)
	env.environment = environment
	add_child(env)

	# Telecamera posizionata per vedere la cupola intera
	var cam = Camera3D.new()
	cam.position = Vector3(0.0, 3.2, 5.8)
	add_child(cam)
	cam.look_at(Vector3(0.0, 1.2, 0.0), Vector3.UP)
	costruisci_chioma()

func costruisci_chioma() -> void:
	var pivot_chioma = Node3D.new()
	pivot_chioma.position = Vector3(0.0, 1.5, 0.0)
	add_child(pivot_chioma)

	# Angolo d'oro per la fillotassi a spirale (distribuzione naturale uniforme)
	var angolo_aureo = deg_to_rad(137.5)
	var num_fronde = 54

	for idx in range(num_fronde):
		var t = float(idx) / float(num_fronde - 1) # 0 = cima/giovane, 1 = base/vecchia

		var fronda_mesh = FrondaPalma.costruisci()
		var nodo_fronda = MeshInstance3D.new()
		nodo_fronda.mesh = fronda_mesh

		# 1. Distribuzione a spirale attorno all'asse Y
		var rot_y = idx * angolo_aureo + randf_range(-0.05, 0.05)

		# 2. Distribuzione emisferica: apicali tese (-26°), mediane ad arco (15°-35°), basali a 52°
		var inclinazione_x = lerp(deg_to_rad(-6.0), deg_to_rad(32.0), pow(t, 0.75))

		# 3. Scala proporzionata: cuore compatti e fronde espanse
		var scala = lerp(0.55, 1.10, pow(t, 0.50))

		# 4. Torsione laterale fluida
		var torsione_z = sin(idx * 1.618) * deg_to_rad(8.0)

		# 5. Sfalsamento verticale compatto
		var offset_y = lerp(0.35, -0.10, pow(t, 0.8))

		var fronda_wrapper = Node3D.new()
		fronda_wrapper.position = Vector3(0.0, offset_y, 0.0) 
		fronda_wrapper.rotation.y = rot_y
		fronda_wrapper.rotate_object_local(Vector3.RIGHT, inclinazione_x) 
		fronda_wrapper.rotate_object_local(Vector3.FORWARD, torsione_z)
		fronda_wrapper.scale = Vector3.ONE * scala

		fronda_wrapper.add_child(nodo_fronda)
		pivot_chioma.add_child(fronda_wrapper)
