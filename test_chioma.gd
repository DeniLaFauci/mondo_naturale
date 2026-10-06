extends Node3D

const FrondaPalma = preload("res://fronda_palma.gd")

func _ready() -> void:
	# Luce solare direzionale
	var dir_light = DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-50, 40, 0)
	dir_light.shadow_enabled = true
	add_child(dir_light)

	# Luce ambientale cielo
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.52, 0.75, 0.92)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.35, 0.42, 0.48)
	env.environment = environment
	add_child(env)

	# Telecamera posizionata per vedere la cupola intera
	var cam = Camera3D.new()
	cam.position = Vector3(0.0, 2.8, 6.2)
	add_child(cam)
	cam.look_at(Vector3(0.0, 1.2, 0.0), Vector3.UP)
	costruisci_chioma()

func costruisci_chioma() -> void:
	var pivot_chioma = Node3D.new()
	pivot_chioma.position = Vector3(0.0, 1.2, 0.0)
	add_child(pivot_chioma)

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Angolo d'oro per la fillotassi a spirale (distribuzione naturale uniforme)
	var angolo_aureo = deg_to_rad(137.5)
	var num_fronde = 68

	for idx in range(num_fronde):
		var t = float(idx) / float(num_fronde - 1) # 0 = cima/giovane, 1 = base/vecchia

		# Curvatura maggiore sulle foglie vecchie rispetto a quelle giovani erette
		var curvatura_arco = lerp(0.8, 2.1, pow(t, 0.7))
		var lungh_fronda = lerp(2.8, 4.3, pow(t, 0.5))
		var fronda_mesh = FrondaPalma.costruisci(lungh_fronda, curvatura_arco, rng)

		var nodo_fronda = MeshInstance3D.new()
		nodo_fronda.mesh = fronda_mesh

		# 1. Rotazione radiale a spirale aurea con micro-variazione
		var rot_y = idx * angolo_aureo + randf_range(-0.04, 0.04)

		# 2. Inclinazione verticale completa_
		var inclinazione_x = lerp(deg_to_rad(-76.0), deg_to_rad(12.0), pow(t, 0.55))

		# 3. Scala dimensionale progressiva
		var scala = lerp(0.65, 1.05, pow(t, 0.40))

		# 4. Leggera torsione naturale sul fianco
		var rollio_z = sin(idx * 2.4) * deg_to_rad(6.0)

		# 5. Sfalsamento verticale lungo la cupola vegetativa
		var offset_y = lerp(0.40, -0.15, pow(t, 0.75))

		var fronda_wrapper = Node3D.new()
		fronda_wrapper.position = Vector3(0.0, offset_y, 0.0) 
		fronda_wrapper.rotation.y = rot_y
		fronda_wrapper.rotate_object_local(Vector3.RIGHT, inclinazione_x) 
		fronda_wrapper.rotate_object_local(Vector3.FORWARD, rollio_z)
		fronda_wrapper.scale = Vector3.ONE * scala

		fronda_wrapper.add_child(nodo_fronda)
		pivot_chioma.add_child(fronda_wrapper)
