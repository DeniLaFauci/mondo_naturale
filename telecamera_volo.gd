extends Camera3D

@export var velocita_base: float = 35.0
@export var velocita_rotazione: float = 2.5

var rot_x: float = -0.3
var rot_y: float = 0.0

func _ready() -> void:
	current = true
	rot_x = rotation.x
	rot_y = rotation.y
	print("Telecamera inizializzata e attiva!")

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
