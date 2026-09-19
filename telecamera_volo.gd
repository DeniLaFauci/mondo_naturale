extends Camera3D

@export var velocita_base: float = 35.0
@export var velocita_rotazione: float = 2.5

var rot_x: float = -0.21
var rot_y: float = 0.0

var rumore_dorsale: FastNoiseLite
var rumore_erosione: FastNoiseLite
const ALTEZZA_MAX: float = 75.0
const RAGGIO_MAX: float = 133.0
const MARGINE_SICUREZZA: float = 2.2

func _ready() -> void:
	current = true
	rot_x = rotation.x
	rot_y = rotation.y
	print("Telecamera inizializzata e attiva!")

	rumore_dorsale = FastNoiseLite.new()
	rumore_dorsale.noise_type = FastNoiseLite.TYPE_PERLIN
	rumore_dorsale.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	rumore_dorsale.fractal_octaves = 5
	rumore_dorsale.fractal_lacunarity = 2.1
	rumore_dorsale.fractal_gain = 0.45
	rumore_dorsale.frequency = 0.007

	rumore_erosione = FastNoiseLite.new()
	rumore_erosione.noise_type = FastNoiseLite.TYPE_PERLIN
	rumore_erosione.frequency = 0.03

func calcola_quota_suolo(x: float, z: float) -> float:
	var raw = rumore_dorsale.get_noise_2d(x, z)
	var cresta = pow(1.0 - abs(raw), 2.8)
	var erosione = rumore_erosione.get_noise_2d(x, z) * 0.12 * cresta
	var dist = Vector2(x, z).length()
	var maschera = smoothstep(1.0, 0.2, clamp(dist / RAGGIO_MAX, 0.0, 1.0))
	var h_terra = 2.5 + (cresta + erosione) * ALTEZZA_MAX
	return lerp(-15.0, h_terra, maschera)


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_LEFT):
		rot_y += velocita_rotazione * delta
	if Input.is_key_pressed(KEY_RIGHT):
		rot_y -= velocita_rotazione * delta
	if Input.is_key_pressed(KEY_UP):
		rot_x += velocita_rotazione * delta
	if Input.is_key_pressed(KEY_DOWN):
		rot_x -= velocita_rotazione * delta

	rot_x = clamp(rot_x, -deg_to_rad(88.0), deg_to_rad(88.0))
	rotation = Vector3(rot_x, rot_y, 0.0)

	var vel = velocita_base
	if Input.is_key_pressed(KEY_SHIFT):
		vel *= 2.5

	var dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		dir += transform.basis.x
	if Input.is_key_pressed(KEY_SPACE):
		dir += Vector3.UP
	if Input.is_key_pressed(KEY_C):
		dir -= Vector3.UP

	if dir != Vector3.ZERO:
		position += dir.normalized() * vel * delta
		print("Nuova posizione: ", position)

	# Reazione vincolare del terreno e del mare
	var quota_suolo = calcola_quota_suolo(position.x, position.z)
	var quota_minima = max(1.2, quota_suolo) + MARGINE_SICUREZZA
	if position.y < quota_minima:	position.y = quota_minima
