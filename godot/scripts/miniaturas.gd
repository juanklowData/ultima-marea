class_name Miniaturas
extends Node

# Fotos 3D de las piezas de la tienda. Se sacan de a poco, fuera de pantalla,
# y se guardan en memoria para no repetirlas.

const CATEGORIAS: Array[String] = ["tipo", "casco", "adorno", "proa", "popa", "canones"]
const TAM := Vector2i(192, 144)
const ESTUDIOS := 3
const COLOR_MADERA := Color("6b4a30")


class Estudio:
	var vista: SubViewport
	var camara: Camera3D
	var escena: Node3D
	var pedido := {}
	var espera := 0


var cache := {}
var cola: Array = []
var estudios: Array = []


func _ready() -> void:
	for _i in ESTUDIOS:
		estudios.append(_crear_estudio())


func _crear_estudio() -> Estudio:
	var estudio := Estudio.new()
	estudio.vista = SubViewport.new()
	estudio.vista.size = TAM
	estudio.vista.own_world_3d = true
	estudio.vista.transparent_bg = true
	estudio.vista.msaa_3d = Viewport.MSAA_4X
	estudio.vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(estudio.vista)

	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_CLEAR_COLOR
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Paleta.AMBIENTE
	ambiente.ambient_light_energy = 0.55
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.adjustment_enabled = true
	ambiente.adjustment_saturation = Paleta.SATURACION
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	estudio.vista.add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
	sol.light_energy = 1.15
	sol.light_color = Paleta.SOL
	estudio.vista.add_child(sol)
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-20.0, -140.0, 0.0)
	relleno.light_energy = 0.4
	relleno.light_color = Color("bcd8ff")
	estudio.vista.add_child(relleno)

	estudio.camara = Camera3D.new()
	estudio.camara.projection = Camera3D.PROJECTION_ORTHOGONAL
	estudio.camara.current = true
	estudio.vista.add_child(estudio.camara)
	estudio.escena = Node3D.new()
	estudio.vista.add_child(estudio.escena)
	return estudio


func calidad(nivel: int) -> void:
	for estudio: Estudio in estudios:
		estudio.vista.msaa_3d = Viewport.MSAA_4X if nivel == 3 else Viewport.MSAA_2X if nivel == 2 else Viewport.MSAA_DISABLED


func pedir(categoria: String, pieza: Dictionary, base: Personalizacion, destino: Button) -> void:
	var clave := _clave(categoria, pieza, base)
	if cache.has(clave):
		destino.icon = cache[clave]
		return
	var aspecto := base.copia()
	aspecto.elegidos[categoria] = pieza["id"]
	cola.append({"clave": clave, "categoria": categoria, "pieza": pieza, "aspecto": aspecto, "destino": destino})


func cancelar() -> void:
	cola.clear()


func _clave(categoria: String, pieza: Dictionary, base: Personalizacion) -> String:
	if categoria in ["tipo", "canones"]:
		return "%s/%s" % [categoria, pieza["id"]]
	return "%s/%s/%s" % [categoria, pieza["id"], base.elegidos["tipo"]]


func _process(_delta: float) -> void:
	var montados := 0
	for estudio: Estudio in estudios:
		if estudio.espera > 0:
			estudio.espera -= 1
			if estudio.espera == 0:
				_revelar(estudio)
			continue
		# Armar un barco cuesta algo: como mucho dos por cuadro.
		while montados < 2 and not cola.is_empty():
			var pedido: Dictionary = cola.pop_front()
			if not is_instance_valid(pedido["destino"]):
				continue
			if cache.has(pedido["clave"]):
				pedido["destino"].icon = cache[pedido["clave"]]
				continue
			_montar(estudio, pedido)
			montados += 1
			break


func _revelar(estudio: Estudio) -> void:
	var textura := ImageTexture.create_from_image(estudio.vista.get_texture().get_image())
	cache[estudio.pedido["clave"]] = textura
	var destino = estudio.pedido["destino"]
	if is_instance_valid(destino):
		destino.icon = textura
	estudio.vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
	estudio.pedido = {}


func _montar(estudio: Estudio, pedido: Dictionary) -> void:
	for hijo in estudio.escena.get_children():
		hijo.free()
	estudio.pedido = pedido
	var categoria: String = pedido["categoria"]
	var aspecto: Personalizacion = pedido["aspecto"]
	if categoria == "canones":
		_montar_canon(estudio, pedido["pieza"])
	else:
		estudio.escena.add_child(ModeloBarco.crear(aspecto))
		var medidas: Dictionary = ModeloBarco.MEDIDAS[aspecto.tipo]
		var forma: Dictionary = aspecto.pieza("tipo").get("forma", {})
		var largo: float = medidas["largo"] * forma.get("largo", 1.0)
		var alto: float = medidas["alto"] * forma.get("alto", 1.0)
		match categoria:
			"proa":
				_encuadrar(estudio, Vector3(0, alto + 0.1, -largo * 0.5 - 0.3), Vector3(1.0, 0.35, -0.5), 2.3)
			"popa":
				_encuadrar(estudio, Vector3(0, alto + 0.45, largo * 0.45), Vector3(0.9, 0.45, 1.0), 2.4)
			"adorno":
				var tam: float = {"balandro": 4.0, "bergantin": 4.6, "galeon": 5.4}[aspecto.tipo]
				_encuadrar(estudio, Vector3(0, alto + 0.7, -largo * 0.05), Vector3(1.0, 0.4, -0.45), tam)
			_:
				var tamano: float = {"balandro": 4.4, "bergantin": 5.1, "galeon": 6.0}[aspecto.tipo]
				_encuadrar(estudio, Vector3(0, tamano * 0.4, 0), Vector3(1.0, 0.45, -0.65), tamano)
	estudio.vista.render_target_update_mode = SubViewport.UPDATE_ONCE
	estudio.espera = 2


func _montar_canon(estudio: Estudio, pieza: Dictionary) -> void:
	var color: Color = pieza.get("color", Color("26292c"))
	ModeloBarco._canon(estudio.escena, pieza.get("estilo", "clasico"), color, Vector3(-0.15, 0.05, 0), Vector3(1, 0, 0), 4.0)
	var soporte := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.95, 0.22, 0.5)
	soporte.mesh = caja
	soporte.material_override = ModeloBarco._material(COLOR_MADERA)
	soporte.position = Vector3(-0.3, -0.33, 0)
	estudio.escena.add_child(soporte)
	for x: float in [-0.65, 0.05]:
		for z: float in [-0.3, 0.3]:
			var rueda := MeshInstance3D.new()
			var cilindro := CylinderMesh.new()
			cilindro.top_radius = 0.17
			cilindro.bottom_radius = 0.17
			cilindro.height = 0.08
			cilindro.radial_segments = 16
			rueda.mesh = cilindro
			rueda.material_override = ModeloBarco._material(COLOR_MADERA.darkened(0.25))
			rueda.rotation.x = PI / 2.0
			rueda.position = Vector3(x, -0.45, z)
			estudio.escena.add_child(rueda)
	_encuadrar(estudio, Vector3(0.3, -0.05, 0), Vector3(0.3, 0.5, 1.0), 1.95)


func _encuadrar(estudio: Estudio, centro: Vector3, desde: Vector3, tamano: float) -> void:
	estudio.camara.size = tamano
	estudio.camara.position = centro + desde.normalized() * 20.0
	estudio.camara.look_at_from_position(estudio.camara.position, centro, Vector3.UP)
