class_name MondoTerreno
extends RefCounted

const RAGGIO_ISOLA: float = 130.0
const ALTEZZA_MAX: float = 75.0

static var r_dorsale: FastNoiseLite
static var r_erosione: FastNoiseLite

static func inizializza_noise() -> void:
	if r_dorsale != null:
		return
	r_dorsale = FastNoiseLite.new()
	r_dorsale.noise_type = FastNoiseLite.TYPE_PERLIN
	r_dorsale.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	r_dorsale.fractal_octaves = 5
	r_dorsale.fractal_lacunarity = 2.1
	r_dorsale.fractal_gain = 0.45
	r_dorsale.frequency = 0.007

	r_erosione = FastNoiseLite.new()
	r_erosione.noise_type = FastNoiseLite.TYPE_PERLIN
	r_erosione.frequency = 0.03

static func calcola_h(px: float, pz: float) -> float:
	inizializza_noise()
	var raw = r_dorsale.get_noise_2d(px, pz)
	var cresta = pow(1.0 - abs(raw), 2.8)
	var eros = r_erosione.get_noise_2d(px, pz) * 0.12 * cresta
	var dist = Vector2(px, pz).length()
	var maschera = smoothstep(1.0, 0.2, clamp(dist / RAGGIO_ISOLA, 0.0, 1.0))
	return lerp(-15.0, 2.5 + (cresta + eros) * ALTEZZA_MAX, maschera)

static func calcola_quota_e_normale(x: float, z: float) -> Dictionary:
	var h_centro = calcola_h(x, z)
	var d = 0.5
	var hx = calcola_h(x - d, z) - calcola_h(x - d, z)
	var hz = calcola_h(x, z + d) - calcola_h(x, z - d)
	return {"quota": h_centro, "normale": Vector3(-hx, 2.0 * d, -hz).normalized()}

static func genera_nodo_montagne() -> MeshInstance3D:
	inizializza_noise()
	var piano = PlaneMesh.new()
	piano.size = Vector2(260, 260)
	piano.subdivide_width = 160
	piano.subdivide_depth = 160

	var array = piano.get_mesh_arrays()
	var vertici = array[Mesh.ARRAY_VERTEX]
	for i in range(vertici.size()):
		vertici[i].y = calcola_h(vertici[i].x, vertici[i].z)
	array[Mesh.ARRAY_VERTEX] = vertici

	var st = SurfaceTool.new()
	st.create_from_arrays(array)
	st.generate_normals()

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = st.commit()
	var mat = ShaderMaterial.new()
	mat.shader = load("res://terreno_shader.gdshader")
	mesh_inst.material_override = mat
	return mesh_inst
