class_name MondoCielo
extends RefCounted

const DURATA_GIORNO_SECONDI: float = 240.0

static func crea_setup(parent: Node3D) -> Dictionary:
	var sole = DirectionalLight3D.new()
	sole.shadow_enabled = true
	sole.shadow_bias = 0.04
	sole.shadow_normal_bias = 2.0
	sole.light_energy = 1.8
	parent.add_child(sole)

	var env = Environment.new()
	var mat_cielo = ShaderMaterial.new()
	mat_cielo.shader = load("res://cielo_shader.gdshader")

	var sky = Sky.new()
	sky.sky_material = mat_cielo
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

	var world_env = WorldEnvironment.new()
	world_env.environment = env
	parent.add_child(world_env)

	return {"sole": sole, "mat_cielo": mat_cielo, "env": env}

static func aggiorna_ciclo(delta: float, tempo_attuale: float, sole: DirectionalLight3D, mat_cielo: ShaderMaterial, mat_mare: ShaderMaterial, env: Environment, meteo: String) -> float:
	var t_giorno = fposmod(tempo_attuale + delta / DURATA_GIORNO_SECONDI, 1.0)
	var ang = t_giorno * TAU - (PI * 0.5)
	var dir_sole = Vector3(cos(ang), sin(ang), sin(ang * 0.5) * 0.35).normalized()

	if sole:
		sole.look_at_from_position(dir_sole * 100.0, Vector3.ZERO, Vector3.UP)
		var fattore_pioggia = 0.35 if (meteo == "Coperto Minaccioso") else 1.0
		sole.light_energy = (lerp(0.0, 1.6, clamp(dir_sole.y * 4.0, 0.0, 1.0)) * fattore_pioggia) if dir_sole.y > 0.0 else 0.0
		sole.light_color = Color(1.0, 0.5, 0.2).lerp(Color(1.0, 0.96, 0.88), clamp(dir_sole.y * 3.0, 0.0, 1.0))

	if mat_cielo: mat_cielo.set_shader_parameter("direzione_sole", dir_sole)
	if mat_mare:
		mat_mare.set_shader_parameter("direzione_sole", dir_sole)
		var c_sole = Color(1.0, 0.5, 0.2).lerp(Color(1.0, 0.95, 0.88), clamp(dir_sole.y * 3.0, 0.0, 1.0))
		mat_mare.set_shader_parameter("colore_luce_sole", Vector3(c_sole.r, c_sole.g, c_sole.b))
	if env:
		env.ambient_light_energy = lerp(0.05, 0.65, clamp(dir_sole.y * 3.0 + 0.2, 0.0, 1.0))

	return t_giorno
