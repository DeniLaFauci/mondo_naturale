extends SceneTree

const Mattone = preload("res://mattone.gd")

func _init() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)

	# Luce solare e cielo neutro
	var luce = DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-35.0, 45.0, 0.0)
	luce.shadow_enabled = true
	root_node.add_child(luce)

	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.40, 0.55, 0.70)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.40, 0.45)
	env.environment = e
	root_node.add_child(env)

	# Telecamera ravvicinata
	var cam = Camera3D.new()
	root_node.add_child(cam)
	cam.look_at_from_position(Vector3(2.5, 2.0, 3.2), Vector3.ZERO, Vector3.UP)

	# Generazione del singolo mattone
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Proporzioni classiche da mattone da costruzione (es. 1.2 x 0.5 x 2.4 metri)
	var m = Mattone.new(Vector3(1.2, 0.5, 2.4), Vector3.ZERO, Vector3(0.0, deg_to_rad(25.0), 0.0))
	m.estrudi(st)

	var mesh = st.commit()

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.28, 0.18)
	mat.roughness = 0.85
	mesh.surface_set_material(0, mat)

	var inst = MeshInstance3D.new()
	inst.mesh = mesh
	root_node.add_child(inst)



