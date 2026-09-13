extends Camera3D

@export var velocita_base: float = 25.0
@export var velocita_rotazione: float = 2.0

var rot_x: float = 0.0
var rot_y: float = 0.0

func _ready() -> void:
	rot_x = rotation.x
	rot_y = rotation.y

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_LEFT):
		rot_y += velocita_rotazione * delta
	if Input.is_key_pressed(KEY_RIGHT):
		rot_y -= velocita_rotazione * delta
	if Input.is_key_pressed(KEY_UP):
		rot_x += velocita_rotazione * delta
	if Input.is_key_pressed(KEY_DOWN):
		rot_x -= velocita_rotazione * delta

	rot_x = clamp(rot_x, -deg_to_rad(89.0), deg_to_rad(89.0))
	rotation = Vector3(rot_x, rot_y, 0.0)

	var velocita = velocita_base
	if Input.is_key_pressed(KEY_SHIFT):
		velocita *= 2.5

	var direzione = Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		direzione -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direzione += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		direzione -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direzione += transform.basis.x
	if Input.is_key_pressed(KEY_SPACE):
		direzione += Vector3.UP
	if Input.is_key_pressed(KEY_C):
		direzione -= Vector3.UP

	if direzione != Vector3.ZERO:
		position += direzione.normalized() * velocita * delta
