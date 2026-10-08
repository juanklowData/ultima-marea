class_name Texturas
extends RefCounted
# Texturas procedurales (sin archivos) que dan grano y relieve a los materiales
# lisos: se proyectan en triplanar, así sirven para cualquier malla sin UVs.

const LADO := 128
# tipo: [repeticiones por metro, fuerza del relieve, proyección en el mundo (true) o en la pieza]
const AJUSTES := {
	"hierba": [0.55, 0.9, true],
	"roca": [0.7, 1.0, true],
	"arena": [0.6, 0.5, true],
	"madera": [2.2, 0.6, false],
	"general": [1.6, 0.35, false],
}

# tipo -> [color, relieve, brillo medio lineal]
static var _hechas := {}


# Prepara el material para el tipo y aclara su color para que el grano no lo oscurezca.
static func aplicar(material: StandardMaterial3D, tipo: String) -> void:
	var hecha := _textura(tipo)
	var ajuste: Array = AJUSTES[tipo]
	material.albedo_texture = hecha[0]
	material.normal_enabled = true
	material.normal_texture = hecha[1]
	material.normal_scale = ajuste[1]
	material.uv1_triplanar = true
	material.uv1_world_triplanar = ajuste[2]
	material.uv1_triplanar_sharpness = 4.0
	material.uv1_scale = Vector3.ONE * float(ajuste[0])
	var lineal := material.albedo_color.srgb_to_linear()
	var media: float = hecha[2]
	material.albedo_color = Color(lineal.r / media, lineal.g / media, lineal.b / media, lineal.a).linear_to_srgb()


static func _textura(tipo: String) -> Array:
	if _hechas.has(tipo):
		return _hechas[tipo]
	var alto := _altura(tipo)
	var color := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	var minimo: float = {"hierba": 0.7, "roca": 0.62, "arena": 0.82, "madera": 0.68, "general": 0.84}[tipo]
	var suma := 0.0
	for y in LADO:
		for x in LADO:
			var v := lerpf(minimo, 1.0, alto[y * LADO + x])
			suma += pow(v, 2.2)
			color.set_pixel(x, y, Color(v, v, v))
	color.generate_mipmaps()
	var relieve := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	for y in LADO:
		for x in LADO:
			var v := alto[y * LADO + x]
			relieve.set_pixel(x, y, Color(v, v, v))
	relieve.bump_map_to_normal_map(4.0)
	relieve.generate_mipmaps()
	_hechas[tipo] = [ImageTexture.create_from_image(color), ImageTexture.create_from_image(relieve), suma / (LADO * LADO)]
	return _hechas[tipo]


# Altura de 0 a 1 en cada píxel; todo se repite sin costuras.
static func _altura(tipo: String) -> PackedFloat32Array:
	var grande := _ruido(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.03, 4)
	var fino := _ruido(FastNoiseLite.TYPE_VALUE, 0.35, 1)
	var alto := PackedFloat32Array()
	alto.resize(LADO * LADO)
	var celdas := PackedFloat32Array()
	if tipo == "roca":
		celdas = _ruido(FastNoiseLite.TYPE_CELLULAR, 0.05, 1)
	for y in LADO:
		for x in LADO:
			var i := y * LADO + x
			var u := float(x) / LADO
			var v := 0.0
			match tipo:
				"hierba":
					# Manchas de pasto más y menos tupido con briznas sueltas.
					var brizna := pow(fino[i], 3.0)
					v = grande[i] * 0.55 + brizna * 0.45
				"roca":
					# Grietas entre placas y algo de grano.
					v = celdas[i] * 0.6 + grande[i] * 0.25 + fino[i] * 0.15
				"arena":
					# Ondulitas del viento y granos.
					var onda := 0.5 + 0.5 * sin((u * 6.0 + grande[i] * 1.5) * TAU)
					v = onda * 0.45 + fino[i] * 0.55
				"madera":
					# Vetas largas y algo onduladas.
					var veta := 0.5 + 0.5 * sin((u * 9.0 + grande[i] * 0.8) * TAU)
					v = pow(veta, 2.0) * 0.7 + fino[i] * 0.3
				_:
					v = grande[i] * 0.6 + fino[i] * 0.4
			alto[i] = clampf(v, 0.0, 1.0)
	return alto


static func _ruido(tipo: FastNoiseLite.NoiseType, frecuencia: float, octavas: int) -> PackedFloat32Array:
	var ruido := FastNoiseLite.new()
	ruido.noise_type = tipo
	ruido.seed = randi()
	ruido.frequency = frecuencia
	ruido.fractal_octaves = octavas
	ruido.fractal_type = FastNoiseLite.FRACTAL_FBM if octavas > 1 else FastNoiseLite.FRACTAL_NONE
	if tipo == FastNoiseLite.TYPE_CELLULAR:
		ruido.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_DIV
	var imagen := ruido.get_seamless_image(LADO, LADO)
	var valores := PackedFloat32Array()
	valores.resize(LADO * LADO)
	for y in LADO:
		for x in LADO:
			valores[y * LADO + x] = imagen.get_pixel(x, y).r
	return valores
