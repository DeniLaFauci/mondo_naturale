extends Node3D

const MondoTerreno = preload("res://mondo_terreno.gd")
const MondoMare = preload("res://mondo_mare.gd")
const MondoCielo = preload("res://mondo_cielo.gd")
const MondoMeteo = preload("res://mondo_meteo.gd")
const MondoVegetazione = preload("res://mondo_vegetazione.gd")

var sole: DirectionalLight3D
var mat_cielo: ShaderMaterial
var mat_mare: ShaderMaterial
var env: Environment
var meteo_attuale: String = ""
var tempo_giorno: float = 0.25

func _ready() -> void:
	randomize()

	# 1. Cielo e illuminazione
	var setup_cielo = MondoCielo.crea_setup(self)
	sole = setup_cielo.sole
	mat_cielo = setup_cielo.mat_cielo
	env = setup_cielo.env

	# 2. Mare
	var setup_mare = MondoMare.crea_nodo()
	mat_mare = setup_mare.materiale
	add_child(setup_mare.nodo)

	# 3. Montagne e vegetazione
	add_child(MondoTerreno.genera_nodo_montagne())
	MondoVegetazione.popola(self)

	# 4. Meteo e fulmini
	MondoMeteo.crea_nodo_fulmine(self)
	meteo_attuale = MondoMeteo.estrai_meteo(mat_cielo, mat_mare)

func _process(delta: float) -> void:
	tempo_giorno = MondoCielo.aggiorna_ciclo(delta, tempo_giorno, sole, mat_cielo, mat_mare, env, meteo_attuale)
	MondoMeteo.gestisci_temporale(delta, meteo_attuale, mat_cielo, env)
