extends Node3D

var perno: Node3D

func _ready() -> void:
	# 1. Luce
	var luce = DirectionalLight3D.new()
	add_child(luce)
	luce.position = Vector3(3, 5, 4)
	luce.look_at(Vector3.ZERO, Vector3.UP)

	var cam = Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0.0, 1.0, 3.5)
	cam.look_at(Vector3(0.0, 0.0, 1.2), Vector3.UP)

	# 3. Perno e istanze della palma
	perno = Node3D.new()
	add_child(perno)

	var script_fronda = load("res://fronda_palma.gd")	
	var mesh_fronda = script_fronda.costruisci(2.8, 0.9)

	var inst = MeshInstance3D.new()
	inst.mesh = mesh_fronda
	perno.add_child(inst)

func _process(delta: float) -> void:
	if perno:
		perno.rotate_y(0.4 * delta)
