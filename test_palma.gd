extends Node3D

const TroncoPalma = preload("res://tronco_palma.gd")
const FrondaPalma = preload("res://fronda_palma.gd")

var perno: Node3D
var nodo_chioma: Node3D
var inst_tronco: MeshInstance3D
var mat_foglia: ShaderMaterial

var pos_apice_base: Vector3
var rot_apice_base: Basis

var tempo_ciclo: float = 0.0
const PERIODO_RAFFICA: float = 8.0
const GAMMA: float = 1.3
const OMEGA: float = 4.2

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
	cam.position = Vector3(0.0, 5.0, 14.5)
	add_child(cam)
	cam.look_at(Vector3(0.0, 4.5, 0.0), Vector3.UP)

	# 3. Perno rotante
	perno = Node3D.new()
	add_child(perno)

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var dati_tronco = TroncoPalma.costruisci(5.0, rng)
	var inst_tronco = MeshInstance3D.new()
	inst_tronco.mesh = dati_tronco.mesh
	perno.add_child(inst_tronco)

	# Innesco e salvataggio riferimenti per animazione sincrona
	var nodo_chioma = costruisci_chioma(rng)
	pos_apice_base = dati_tronco.apice
	nodo_chioma.position = pos_apice_base

	var up_fusto = dati_tronco.tangente
	if abs(up_fusto.dot(Vector3.UP)) < 0.999:
		var asse_rot = Vector3.UP.cross(up_fusto).normalized()
		var angolo_rot = Vector3.UP.angle_to(up_fusto)
		rot_apice_base = Basis(asse_rot, angolo_rot)
	else:
		rot_apice_base = Basis.IDENTITY
	nodo_chioma.transform.basis = rot_apice_base
	perno.add_child(nodo_chioma)

func costruisci_chioma(rng: RandomNumberGenerator) -> Node3D:
	var nodo = Node3D.new()
	var num_fronde = 120
	var angolo_aureo = 2.39996323

	for idx in range(num_fronde):
		var t = float(idx) / float(num_fronde - 1)
		var lungh = lerp(4.5, 6.2, pow(t, 0.5))
		var arco = lerp(1.6, 4.2, pow(t, 0.55))
		var fronda_mesh = FrondaPalma.costruisci(lungh, arco, rng)
		if mat_foglia == null:
			mat_foglia = fronda_mesh.surface_get_material(0) as ShaderMaterial
		var inst = MeshInstance3D.new()
		inst.mesh = fronda_mesh

		var azimut = idx * angolo_aureo
		var elevaz = lerp(deg_to_rad(-25.0), deg_to_rad(65.0), pow(t, 0.65))
		var r_calotta = lerp(0.12, 0.65, pow(t, 0.60))

		var pos_innesto = Vector3(cos(azimut) * r_calotta, -pow(t, 1.2) * 0.45, sin(azimut) * r_calotta)
		inst.position = pos_innesto
		inst.rotation.y = -azimut + PI * 0.5
		inst.rotation.x = -elevaz
		var rollio_z = sin(idx * 2.3) * deg_to_rad(lerp(4.0, 18.0, t))
		inst.rotation.z = rollio_z

		nodo.add_child(inst)

	return nodo

func _process(delta: float) -> void:
	tempo_ciclo += delta
	var t_raffica = fmod(tempo_ciclo, PERIODO_RAFFICA)

	# Equazione transitorio sottosmorzato
	var ampiezza_iniziale = 0.42
	var flessione_rlc = 0.0
	if t_raffica < 5.0:
		flessione_rlc = ampiezza_iniziale * exp(-GAMMA * t_raffica) * sin(OMEGA * t_raffica)

	# Vettore di piega lungo l'asse del vento (direzione X/Z)
	var dir_x = 1.0
	var dir_z = 0.35
	var asse_piega = Vector3(-dir_z, 0.0, dir_x).normalized()

	# Flessione coerente dell'intera struttura
	if inst_tronco:
		inst_tronco.rotation = asse_piega * flessione_rlc

	if nodo_chioma:
		# L'apice ruota e si sposta rigidamente solidale con il tronco
		var rot_istantanea = Basis(asse_piega, flessione_rlc)
		nodo_chioma.position = rot_istantanea * pos_apice_base
		nodo_chioma.transform.basis = rot_istantanea * rot_apice_base

	# Regolazione vibrazione foglie proporzionale all'energia cinetica istantanea
	if mat_foglia:
		var energia_foglie = clamp(abs(flessione_rlc) * 4.0 + 0.25, 0.2,2.4)
		mat_foglia.set_shader_parameter("forza_vento", energia_foglie)
