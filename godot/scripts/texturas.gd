class_name Texturas
extends RefCounted
# Texturas que dan a los materiales lisos un aspecto pintado a mano: se proyectan en
# triplanar, así sirven para cualquier malla sin UVs. Las procedurales de abajo quedan
# como reserva por si faltaran los archivos pintados.

const LADO := 128
# tipo: [repeticiones por metro, fuerza del relieve, proyección en el mundo (true) o en la pieza]
const AJUSTES := {
	"hierba": [0.45, 0.9, true],
	"roca": [0.6, 1.0, true],
	"arena": [0.5, 0.5, true],
	"madera": [1.4, 0.6, false],
	"casco": [1.1, 0.6, false],
	"pintura": [1.2, 0.4, false],
	"metal": [2.0, 0.4, false],
	"oro": [2.2, 0.4, false],
	"corteza": [1.6, 0.6, false],
	"tela": [1.5, 0.3, false],
	"general": [1.4, 0.35, false],
}

# tipo -> [color, relieve, brillo medio lineal]
static var _hechas := {}


# Texturas pintadas a mano propias del juego (res://texturas, generadas con
# herramientas/pintar_texturas.py). Solo color, sin mapa de relieve: tres lecturas por píxel
# con la proyección triplanar, que el móvil aguanta bien.
const ACTIVAS := true
const CARPETA := "res://texturas/%s.png"


# Prepara el material para el tipo y aclara su color para que la textura no lo oscurezca.
static func aplicar(material: StandardMaterial3D, tipo: String, contorno := true) -> void:
	if not ACTIVAS:
		return
	if contorno:
		_con_contorno.append(material)
		if contornos:
			material.next_pass = _contorno()
	var hecha := _pintada(tipo)
	if hecha.is_empty():
		return
	var ajuste: Array = AJUSTES[tipo]
	material.albedo_texture = hecha[0]
	material.uv1_triplanar = true
	material.uv1_world_triplanar = ajuste[2]
	material.uv1_triplanar_sharpness = 4.0
	material.uv1_scale = Vector3.ONE * float(ajuste[0])
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Se aclara solo en parte: el conjunto queda algo más oscuro y rico, como pintado.
	var lineal := material.albedo_color.srgb_to_linear()
	var media := pow(float(hecha[1]), 0.6)
	material.albedo_color = Color(minf(1.0, lineal.r / media), minf(1.0, lineal.g / media), minf(1.0, lineal.b / media), lineal.a).linear_to_srgb()


# Qué textura pintada le va a una pieza según su color: hierro oscuro, oro, madera,
# madera pintada o la general.
static func tipo_de_color(color: Color) -> String:
	if color.v < 0.3 and color.s < 0.45:
		return "metal"
	if color.h > 0.09 and color.h < 0.17 and color.s > 0.45 and color.v > 0.55:
		return "oro"
	if color.h < 0.13 and color.s > 0.2 and color.v < 0.75:
		return "madera"
	if color.s > 0.3:
		return "pintura"
	return "general"


# Contorno de tinta alrededor de las piezas (estilo de cuento ilustrado). Es una segunda pasada
# del material con la cara de atrás algo hinchada; se enciende o apaga con los gráficos.
static var contornos := false
static var _con_contorno: Array[StandardMaterial3D] = []
static var _tinta: StandardMaterial3D


static func _contorno() -> StandardMaterial3D:
	if _tinta == null:
		_tinta = StandardMaterial3D.new()
		_tinta.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_tinta.cull_mode = BaseMaterial3D.CULL_FRONT
		_tinta.grow = true
		_tinta.grow_amount = 0.035
		_tinta.albedo_color = Color("2a1b14")
		_tinta.disable_receive_shadows = true
	return _tinta


static func poner_contornos(encendidos: bool) -> void:
	contornos = encendidos
	for material in _con_contorno:
		if is_instance_valid(material):
			material.next_pass = _contorno() if encendidos else null


# Brillo medio lineal de cada textura pintada (lo calcula pintar_texturas.py), para que el
# color del material quede igual con textura que sin ella.
const MEDIAS := {"madera": 0.562, "casco": 0.524, "pintura": 0.608, "metal": 0.504, "oro": 0.508, "tela": 0.647,
	"arena": 0.495, "hierba": 0.4, "roca": 0.485, "corteza": 0.423, "general": 0.552}


# [textura, brillo medio lineal] de la textura pintada, o vacío si falta el archivo.
static func _pintada(tipo: String) -> Array:
	var clave := "pintada_" + tipo
	if _hechas.has(clave):
		return _hechas[clave]
	var ruta := CARPETA % tipo
	if not ResourceLoader.exists(ruta):
		_hechas[clave] = []
		return []
	_hechas[clave] = [load(ruta) as Texture2D, float(MEDIAS.get(tipo, 0.8))]
	return _hechas[clave]


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
