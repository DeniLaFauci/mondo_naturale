extends Node3D

const TroncoPalma = preload("res://tronco_palma.gd")
const FrondaPalma = preload("res://fronda_palma.gd")

var perno: Node3D

func _ready() -> void:
	# Luce solare
	var luce = DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-45, 35, 0)
	luce.shadow_enabled = true
	add_child(luce)

	# Luce ambiente
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.52, 0.75, 0.92)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.38, 0.44, 0.48)
	env.environment = environment
	add_child(env)

	# Telecamera posizionata per inquadrare tutta la palma
	var cam = Camera3D.new()
	cam.position = Vector3(0.0, 5.0, 12.0)
	add_child(cam)
	cam.look_at(Vector3(0.0, 4.0, 0.0), Vector3.UP)

	# 3. Perno rotante
	perno = Node3D.new()
	add_child(perno)

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var dati_tronco = TroncoPalma.costruisci(5.5, rng)
	var inst_tronco = MeshInstance3D.new()
	inst_tronco.mesh = dati_tronco.mesh
	perno.add_child(inst_tronco)

	# Innesco della chioma sull'apice inclinato del fusto
	var chioma = costruisci_chioma(rng)
	chioma.position = dati_tronco.apice

	var up_fusto = dati_tronco.tangente
	if abs(up_fusto.dot(Vector3.UP)) < 0.999:
		var asse_rot = Vector3.UP.cross(up_fusto).normalized()
		var angolo_rot = Vector3.UP.angle_to(up_fusto)
		chioma.transform.basis = Basis(asse_rot, angolo_rot)

	perno.add_child(chioma)

func costruisci_chioma(rng: RandomNumberGenerator) -> Node3D:
	var nodo = Node3D.new()
	var num_fronde = 72
	var angolo_aureo = 2.39996323

	for idx in range(num_fronde):
		var t = float(idx) / float(num_fronde - 1)
		var lungh = lerp(3.2, 5.0, pow(t, 0.45))
		var arco = lerp(0.8, 2.0, pow(t, 0.65))
		var fronda_mesh = FrondaPalma.costruisci(lungh, arco, rng)
		var inst = MeshInstance3D.new()
		inst.mesh = fronda_mesh

		var azimut = idx * angolo_aureo
		var elevaz = lerp(deg_to_rad(8.0), deg_to_rad(-82.0), pow(t, 0.65))
		var r_calotta = lerp(0.06, 0.38, pow(t, 0.7))

		var pos_innesto = Vector3(cos(azimut) * r_calotta, -pow(t, 1.2) * 0.28, sin(azimut) * r_calotta)
		inst.position = pos_innesto
		inst.rotation.y = -azimut + PI * 0.5
		inst.rotation.x = elevaz
		var rollio_z = sin(idx * 2.3) * deg_to_rad(lerp(2.0, 11.0, t))
		inst.rotation.z = rollio_z

		nodo.add_child(inst)

	return nodo
func _process(delta: float) -> void:
	if perno:
		perno.rotate_y(0.35 * delta)
