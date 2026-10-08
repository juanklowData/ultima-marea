class_name Comercio
extends Node

# Comercio del mar libre: mercancías (ver Objetos) que flotan en cajas a la deriva o caen de
# los barcos hundidos, la bodega donde se llevan, los asentamientos donde se venden y se
# compra munición, las balas limitadas de varios tipos y los barriles que se tiran por la popa.

const MUNICIONES := {
	"hierro": {"nombre": "Bala de hierro", "detalle": "Daño normal", "danio": 11.0, "color": Color("2a2d31"), "precio": 5, "lote": 15},
	"cadena": {"nombre": "Bala encadenada", "detalle": "Rompe las velas: el rival va a media vela", "danio": 6.0, "color": Color("9aa3ab"), "precio": 8, "lote": 6},
	"fuego": {"nombre": "Bala incendiaria", "detalle": "Prende fuego al casco unos segundos", "danio": 7.0, "color": Color("ff6a1e"), "precio": 10, "lote": 6},
	"explosiva": {"nombre": "Bala explosiva", "detalle": "Estalla y daña todo alrededor", "danio": 16.0, "color": Color("f2c230"), "precio": 14, "lote": 4},
}
const ORDEN_MUNICION: Array[String] = ["hierro", "cadena", "fuego", "explosiva"]
const MATERIALES := {
	"madera": {"nombre": "Madera", "precio": 8, "lote": 5},
	"metal": {"nombre": "Metal", "precio": 10, "lote": 3},
	"tela": {"nombre": "Tela", "precio": 8, "lote": 3},
}
const ORDEN_MATERIALES: Array[String] = ["madera", "metal", "tela"]
const NIVEL_MAXIMO := 3
# Coste de cada nivel: monedas, cantidad del material principal de la mejora y de los otros dos.
const COSTES: Array[Dictionary] = [
	{"monedas": 40, "principal": 10, "resto": 3},
	{"monedas": 100, "principal": 20, "resto": 8},
	{"monedas": 200, "principal": 35, "resto": 15},
]
const MEJORAS_BARCO := {
	"casco": {"nombre": "Casco reforzado", "detalle": "+15% de vida por nivel", "material": "madera"},
	"canones": {"nombre": "Cañones pesados", "detalle": "+15% de daño por nivel", "material": "metal"},
	"recarga": {"nombre": "Artilleros veteranos", "detalle": "Recargas un 15% más rápido por nivel", "material": "metal"},
	"velas": {"nombre": "Velas de lona fina", "detalle": "+7% de velocidad por nivel", "material": "tela"},
	"bodega": {"nombre": "Bodega ampliada", "detalle": "+8 huecos de bodega por nivel", "material": "madera"},
}
const MEJORAS_BASE := {
	"taberna": {"nombre": "Taberna", "detalle": "La renta de tu base se multiplica: x2, x3 y x4", "material": "madera"},
	"baterias": {"nombre": "Baterías del fuerte", "detalle": "Tu fuerte dispara más rápido y más lejos, también a los cazadores", "material": "metal"},
	"arsenal": {"nombre": "Arsenal", "detalle": "Al llegar a tu base te reparas más rápido y repones balas de hierro gratis", "material": "metal"},
}
const PRECIO_BASE := 1.5
# Al empezar cada partida del mar libre se zarpa con al menos estas balas de hierro.
const MUNICION_INICIAL := 200
# Al reaparecer tras hundirse nunca se zarpa con menos balas de hierro que estas.
const MUNICION_MINIMA := 20
const BARRILES_INICIALES := 2
const PRECIO_BARRIL := 6
# Monedas por cada punto de casco reparado.
const PRECIO_REPARACION := 0.25
const CAPACIDAD := {"balandro": 16, "bergantin": 24, "galeon": 32}
const CAJAS_MERCANCIA := 9
const CAJAS_MUNICION := 6
const VIDA_NAUFRAGIO := 120.0
const ALCANCE_RECOGER := 24.0
const RADIO_ASENTAMIENTO := 70.0
const ALCANCE_MERCADO := 210.0
# Cada asentamiento paga más por una categoría de mercancía.
const PREMIO_FAVORITA := 1.5
const DURACION_FRENADO := 4.0
const FRENO := 0.5
const DURACION_FUEGO := 5.0
const DANIO_FUEGO := 2.5
const RADIO_EXPLOSIVA := 75.0
const DANIO_EXPLOSIVA := 8.0
const ESPERA_BARRIL := 1.0
const ESPERA_AVISO := 3.0
# Botones del HUD, desde la esquina inferior derecha como los de disparo.
const BOTON_MUNICION := Vector2(-245.0, -212.0)
const BOTON_BARRIL := Vector2(-58.0, -212.0)
const BOTON_LUGAR := Vector2(-345.0, -212.0)
const RADIO_BOTON := 32.0
const COLOR_MERCADO := Color("ffcf6b")
const COLOR_MADERA := Color("9a6a3c")
const COLOR_PAJA := Color("d9b65c")
const COLOR_PARED := Color("c9a26b")
const COLORES_TOLDO: Array[Color] = [Color("c0392b"), Color("2e86c1"), Color("27ae60"), Color("8e44ad"), Color("d68910")]
const NOMBRES_ASENTAMIENTO: Array[String] = [
	"Puerto Coral", "Bahía Canela", "Cala del Ron", "Villa Perla", "Isla Mercante", "Rada del Sol",
	"Puerto Esmeralda", "Ensenada Brava", "Cayo Doblón", "Aldea Caracola", "Muelle del Loro",
	"Cala Tortuga", "Puerto Vainilla", "Bahía Ámbar", "Cayo Sirena", "Rada Ventosa",
]


class Caja:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var fase := 0.0
	var objetos: Array[String] = []
	var balas := {}
	var materiales := {}
	var edad := 0.0
	# Las de un naufragio se hunden al rato (vida > 0); las demás flotan hasta que alguien llega.
	var vida := -1.0
	var nodo: Node3D


class Asentamiento:
	var pos := Vector2.ZERO
	var nombre := ""
	var favorita := ""
	var isla: Circulo
	var nodo: Node3D
	var bandera: Node3D
	var fase := 0.0


# Lo último que se recogió, a la izquierda bajo el HUD con su dibujo.
class Reciente:
	var objeto := ""
	var municion := ""
	var material := ""
	var texto := ""
	var color := Color.WHITE
	var vida := 3.5


var mundo: Principal
var bodega: Array[String] = []
var coleccion := {}
var municion := {}
var tipo_bala := "hierro"
var barriles_carga := BARRILES_INICIALES
var materiales := {}
var mejoras := {}
var mejoras_base := {}
var cajas: Array[Caja] = []
var asentamientos: Array[Asentamiento] = []
var recientes: Array[Reciente] = []
var cerca: Asentamiento
var abierto: Asentamiento
# Junto a la base propia el panel abre el astillero y las mejoras de la base.
var cerca_base := false
var en_base := false
var espera_barril := 0.0
var espera_aviso := 0.0
var espera_reciclar := 0.0
var materiales_bala := {}
var caja_malla := BoxMesh.new()
var cilindro := CylinderMesh.new()
var cono := CylinderMesh.new()
var esfera := SphereMesh.new()
var textura_barril: ImageTexture

var boton_comerciar: Button
var textura_moneda: Texture2D
var boton_municion: Button
var boton_barril: Button
var panel: PanelContainer
var titulo: Label
var texto_favorita: Label
var texto_monedas: Label
var texto_info: Label
var textos_material := {}
var boton_todo: Button
var pestanas := {}
var pestana := "vender"
var contenido: VBoxContainer
var desplazable: ScrollContainer


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	cilindro.top_radius = 0.5
	cilindro.bottom_radius = 0.5
	cilindro.height = 1.0
	cilindro.radial_segments = 12
	cilindro.rings = 1
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 12
	cono.rings = 1
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 10
	esfera.rings = 5
	for tipo in MUNICIONES:
		var materia := StandardMaterial3D.new()
		materia.albedo_color = MUNICIONES[tipo]["color"]
		materia.metallic = 0.4
		materia.roughness = 0.5
		if tipo in ["fuego", "explosiva"]:
			materia.emission_enabled = true
			materia.emission = MUNICIONES[tipo]["color"]
			materia.emission_energy_multiplier = 1.6
		materiales_bala[tipo] = materia
	cargar()


# Guardado (en el mismo archivo que el mar libre)

func cargar() -> void:
	var archivo := ConfigFile.new()
	var hay := archivo.load(MarLibre.RUTA) == OK
	bodega.clear()
	for id in (archivo.get_value("comercio", "bodega", []) if hay else []):
		if Objetos.existe(str(id)):
			bodega.append(str(id))
	coleccion.clear()
	for id in (archivo.get_value("comercio", "coleccion", []) if hay else []):
		if Objetos.existe(str(id)):
			coleccion[str(id)] = true
	var guardada: Dictionary = archivo.get_value("comercio", "municion", {}) if hay else {}
	for tipo in ORDEN_MUNICION:
		municion[tipo] = int(guardada.get(tipo, MUNICION_INICIAL if tipo == "hierro" else 0))
	barriles_carga = int(archivo.get_value("comercio", "barriles", BARRILES_INICIALES)) if hay else BARRILES_INICIALES
	tipo_bala = str(archivo.get_value("comercio", "tipo", "hierro")) if hay else "hierro"
	if not MUNICIONES.has(tipo_bala):
		tipo_bala = "hierro"
	var guardados: Dictionary = archivo.get_value("comercio", "materiales", {}) if hay else {}
	for clave in ORDEN_MATERIALES:
		materiales[clave] = maxi(0, int(guardados.get(clave, 0)))
	var niveles: Dictionary = archivo.get_value("comercio", "mejoras", {}) if hay else {}
	for clave in MEJORAS_BARCO:
		mejoras[clave] = clampi(int(niveles.get(clave, 0)), 0, NIVEL_MAXIMO)
	var niveles_base: Dictionary = archivo.get_value("comercio", "mejoras_base", {}) if hay else {}
	for clave in MEJORAS_BASE:
		mejoras_base[clave] = clampi(int(niveles_base.get(clave, 0)), 0, NIVEL_MAXIMO)


func escribir(archivo: ConfigFile) -> void:
	archivo.set_value("comercio", "bodega", Array(bodega))
	archivo.set_value("comercio", "coleccion", coleccion.keys())
	archivo.set_value("comercio", "municion", municion.duplicate())
	archivo.set_value("comercio", "barriles", barriles_carga)
	archivo.set_value("comercio", "tipo", tipo_bala)
	archivo.set_value("comercio", "materiales", materiales.duplicate())
	archivo.set_value("comercio", "mejoras", mejoras.duplicate())
	archivo.set_value("comercio", "mejoras_base", mejoras_base.duplicate())


func capacidad() -> int:
	var base: int = CAPACIDAD.get(mundo.jugador.tipo, 24) if mundo.jugador != null else 24
	return base + 8 * mejoras["bodega"]


# Las mejoras del astillero sobre el barco del jugador (después de vestirlo).
func aplicar_mejoras(barco: Barco) -> void:
	var proporcion := barco.vida / barco.vida_max
	var datos: Dictionary = Barco.TIPOS[barco.tipo]
	barco.vida_max = datos["vida"] * (1.0 + 0.15 * mejoras["casco"])
	barco.vida = barco.vida_max * proporcion
	barco.vel_max = datos["velocidad"] * (1.0 + 0.07 * mejoras["velas"])
	barco.factor_danio = 1.0 + 0.15 * mejoras["canones"]
	barco.factor_recarga = 1.0 / (1.0 + 0.15 * mejoras["recarga"])


func coste(clave: String, nivel: int, de_base: bool) -> Dictionary:
	var tabla: Dictionary = COSTES[nivel]
	var principal: String = (MEJORAS_BASE if de_base else MEJORAS_BARCO)[clave]["material"]
	var total := {"monedas": roundi(tabla["monedas"] * (PRECIO_BASE if de_base else 1.0))}
	for material in ORDEN_MATERIALES:
		total[material] = tabla["principal"] if material == principal else tabla["resto"]
	return total


func _alcanza(precio_total: Dictionary) -> bool:
	if mundo.personalizacion.monedas < precio_total["monedas"]:
		return false
	for material in ORDEN_MATERIALES:
		if materiales[material] < precio_total[material]:
			return false
	return true


func _mejorar(clave: String, de_base: bool) -> void:
	var niveles := mejoras_base if de_base else mejoras
	if niveles[clave] >= NIVEL_MAXIMO:
		return
	var precio_total := coste(clave, niveles[clave], de_base)
	if not _alcanza(precio_total):
		return
	mundo.personalizacion.monedas -= precio_total["monedas"]
	for material in ORDEN_MATERIALES:
		materiales[material] -= precio_total[material]
	niveles[clave] += 1
	if de_base:
		mundo.libre.adornar_base()
	else:
		aplicar_mejoras(mundo.jugador)
	mundo.personalizacion.guardar()
	mundo.voz_equipar.play()
	var nombre: String = (MEJORAS_BASE if de_base else MEJORAS_BARCO)[clave]["nombre"]
	mundo.libre._anunciar(tr("%s: nivel %d") % [tr(nombre), niveles[clave]], Principal.COLOR_ORO)
	mundo._pintar_botin()
	mundo.libre.guardar()
	var antes := desplazable.scroll_vertical
	_refrescar()
	desplazable.set_deferred("scroll_vertical", antes)


# Partida

func empezar() -> void:
	vaciar()
	municion["hierro"] = maxi(municion["hierro"], MUNICION_INICIAL)
	for _i in CAJAS_MERCANCIA:
		_soltar_caja(_lugar_caja(400.0), false)
	for _i in CAJAS_MUNICION:
		_soltar_caja(_lugar_caja(400.0), true)


func vaciar() -> void:
	for caja in cajas:
		caja.nodo.queue_free()
	cajas.clear()
	recientes.clear()
	cerrar()
	ocultar()


func ocultar() -> void:
	if boton_comerciar == null:
		return
	boton_comerciar.visible = false
	boton_municion.visible = false
	boton_barril.visible = false
	cerrar()


func actualizar(delta: float) -> void:
	var jugador := mundo.jugador
	espera_barril = maxf(0.0, espera_barril - delta)
	espera_aviso = maxf(0.0, espera_aviso - delta)
	for i in range(recientes.size() - 1, -1, -1):
		recientes[i].vida -= delta
		if recientes[i].vida <= 0.0:
			recientes.remove_at(i)
	_mover_cajas(delta)
	espera_reciclar -= delta
	if espera_reciclar <= 0.0:
		espera_reciclar = 1.0
		_reciclar()
	cerca = null
	var menor := ALCANCE_MERCADO
	for asentamiento in asentamientos:
		var d := jugador.pos.distance_to(asentamiento.pos)
		if d < menor:
			menor = d
			cerca = asentamiento
	var base: MarLibre.Base = mundo.libre._mi_base()
	var a_base := INF if base == null else jugador.pos.distance_to(base.pos)
	cerca_base = cerca == null and a_base < MarLibre.ALCANCE_BASE
	var en_juego := not mundo.panel_partida.visible and not panel.visible
	boton_comerciar.visible = (cerca != null or cerca_base) and jugador.viva and en_juego
	boton_comerciar.queue_redraw()
	boton_municion.visible = jugador.viva
	boton_barril.visible = jugador.viva
	if panel.visible:
		var lejos := a_base > MarLibre.ALCANCE_BASE * 1.3 if en_base else (abierto == null or jugador.pos.distance_to(abierto.pos) > ALCANCE_MERCADO * 1.3)
		if not jugador.viva or lejos:
			cerrar()
	boton_municion.queue_redraw()
	boton_barril.queue_redraw()


func al_reaparecer() -> void:
	municion["hierro"] = maxi(municion["hierro"], MUNICION_MINIMA)


# Al hundirse, la bodega queda flotando en una caja: la del jugador entera; los bots sueltan
# algo de mercancía (más los piratas) y a veces munición.
func al_hundirse(barco: Barco) -> void:
	var caja := Caja.new()
	caja.vida = VIDA_NAUFRAGIO
	if barco == mundo.jugador:
		caja.objetos.assign(bodega)
		bodega.clear()
	else:
		var cuantos := randi_range(1, 3)
		if barco.es_pirata:
			cuantos = randi_range(4, 6) if barco.recompensa >= MarLibre.RECOMPENSA_BUSCADO else randi_range(2, 4)
		for _i in cuantos:
			caja.objetos.append(Objetos.al_azar())
		if randf() < 0.4:
			var tipo: String = ORDEN_MUNICION.pick_random()
			caja.balas[tipo] = randi_range(3, 8)
		# Los restos del casco: madera siempre, metal y tela a veces; más cuanto mayor el barco.
		var grande: float = {"balandro": 1.0, "bergantin": 1.3, "galeon": 1.7}.get(barco.tipo, 1.0)
		caja.materiales["madera"] = roundi(randi_range(2, 5) * grande)
		if randf() < 0.6:
			caja.materiales["metal"] = roundi(randi_range(1, 3) * grande)
		if randf() < 0.6:
			caja.materiales["tela"] = roundi(randi_range(1, 3) * grande)
	if caja.objetos.is_empty() and caja.balas.is_empty():
		return
	_poner_caja(caja, barco.pos + Vector2.from_angle(randf() * TAU) * randf_range(15.0, 35.0), false)


# Botín suelto (fuertes rendidos, barcos legendarios): una caja de naufragio con lo que se dé.
func soltar_botin(punto: Vector2, objetos: Array[String], cuantos: Dictionary) -> void:
	var caja := Caja.new()
	caja.vida = VIDA_NAUFRAGIO
	caja.objetos.assign(objetos)
	caja.materiales = cuantos.duplicate()
	_poner_caja(caja, punto, false)


# Cajas a la deriva

func _lugar_caja(desde: float) -> Vector2:
	var centro := mundo.jugador.pos
	var punto := centro
	for _intento in 30:
		punto = centro + Vector2.from_angle(randf() * TAU) * randf_range(desde, MarLibre.ACTIVO)
		if punto.length() < MarLibre.RADIO * 0.95 and mundo.libre._libre(punto, 70.0) and not mundo.peligros.cerca(punto, 120.0):
			return punto
	return punto


func _soltar_caja(punto: Vector2, de_municion: bool) -> void:
	var caja := Caja.new()
	_llenar(caja, de_municion)
	_poner_caja(caja, punto, de_municion)


func _llenar(caja: Caja, de_municion: bool) -> void:
	caja.objetos.clear()
	caja.balas.clear()
	if de_municion:
		var tirada := randf()
		if tirada < 0.6:
			caja.balas["hierro"] = randi_range(8, 14)
		elif tirada < 0.75:
			caja.balas["cadena"] = randi_range(3, 6)
		elif tirada < 0.9:
			caja.balas["fuego"] = randi_range(3, 6)
		else:
			caja.balas["explosiva"] = randi_range(2, 4)
		return
	for _i in randi_range(1, 3):
		caja.objetos.append(Objetos.al_azar())
	caja.materiales.clear()
	if randf() < 0.35:
		caja.materiales[ORDEN_MATERIALES.pick_random()] = randi_range(2, 5)


func _poner_caja(caja: Caja, punto: Vector2, de_municion: bool) -> void:
	caja.pos = punto
	caja.fase = randf() * TAU
	caja.vel = Vector2.from_angle(randf() * TAU) * 15.0
	caja.nodo = _modelo_caja(caja, de_municion)
	mundo.add_child(caja.nodo)
	cajas.append(caja)


func _mejor_rareza(caja: Caja) -> int:
	var mejor := 0
	for id in caja.objetos:
		mejor = maxi(mejor, Objetos.rareza(id))
	return mejor


# Caja de madera atada con cuerda (mercancía) o caja de hierro con balas encima (munición),
# con un aro del color de lo mejor que lleva.
func _modelo_caja(caja: Caja, de_municion: bool) -> Node3D:
	var nodo := Node3D.new()
	var madera := mundo.material(COLOR_MADERA if not de_municion else Color("56603f"), "madera")
	var oscura := mundo.material(Color("3b2a1c") if not de_municion else Color("2b2f2c"))
	_pieza(nodo, caja_malla, madera, Vector3(0, 0.2, 0), Vector3(0.7, 0.5, 0.55))
	for x in [-0.33, 0.33]:
		_pieza(nodo, caja_malla, oscura, Vector3(x, 0.2, 0), Vector3(0.06, 0.54, 0.6))
	_pieza(nodo, caja_malla, oscura, Vector3(0, 0.46, 0), Vector3(0.74, 0.04, 0.12))
	var color_aro := Color("bfe8ff")
	if de_municion:
		var tipo: String = caja.balas.keys()[0] if not caja.balas.is_empty() else "hierro"
		for k in 3:
			_pieza(nodo, esfera, materiales_bala[tipo], Vector3(-0.16 + k * 0.16, 0.54, 0.0), Vector3.ONE * 0.16)
		color_aro = Color("9fd8ff")
	else:
		_pieza(nodo, esfera, mundo.material(Color("d8c79c")), Vector3(0.12, 0.55, 0.05), Vector3(0.3, 0.2, 0.26))
		var barrilito := _pieza(nodo, cilindro, mundo.material(Color("8a5a32"), "madera"), Vector3(-0.5, 0.05, 0.2), Vector3(0.3, 0.42, 0.3))
		barrilito.rotation.x = PI / 2.0
		color_aro = Objetos.COLORES_RAREZA[_mejor_rareza(caja)]
	var aro := TorusMesh.new()
	aro.inner_radius = 0.75
	aro.outer_radius = 0.88
	aro.rings = 32
	aro.ring_segments = 4
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	brillo.albedo_color = Color(color_aro, 0.85)
	var anillo := MeshInstance3D.new()
	anillo.mesh = aro
	anillo.material_override = brillo
	anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anillo.name = "Aro"
	anillo.scale = Vector3(1.0, 0.2, 1.0)
	nodo.add_child(anillo)
	nodo.scale = Vector3.ONE * Principal.ESCALA_FLOTANTES * 2.2
	return nodo


func _pieza(padre: Node3D, malla: Mesh, materia: Material, pos: Vector3, escala: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = materia
	pieza.position = pos
	pieza.scale = escala
	padre.add_child(pieza)
	return pieza


func _mover_cajas(delta: float) -> void:
	var jugador := mundo.jugador
	for i in range(cajas.size() - 1, -1, -1):
		var caja := cajas[i]
		caja.edad += delta
		if caja.vida > 0.0 and caja.edad >= caja.vida:
			_quitar_caja(i)
			continue
		caja.pos += (mundo.peligros.arrastre(caja.pos) + mundo.peligros.viento(caja.pos) * 0.5 + caja.vel) * delta
		caja.vel *= maxf(0.0, 1.0 - delta * 1.5)
		if jugador.viva and jugador.pos.distance_to(caja.pos) < jugador.radio + ALCANCE_RECOGER:
			_recoger(i)


func _quitar_caja(i: int) -> void:
	cajas[i].nodo.queue_free()
	cajas.remove_at(i)


func _recoger(i: int) -> void:
	var caja := cajas[i]
	var jugador := mundo.jugador
	var tomado := false
	for tipo in caja.balas:
		municion[tipo] += caja.balas[tipo]
		_reciente("", tipo, tr("+%d %s") % [caja.balas[tipo], tr(MUNICIONES[tipo]["nombre"])], Principal.COLOR_TEXTO)
		tomado = true
	caja.balas.clear()
	for material in caja.materiales:
		materiales[material] += caja.materiales[material]
		var nuevo := Reciente.new()
		nuevo.material = material
		nuevo.texto = "+%d %s" % [caja.materiales[material], tr(MATERIALES[material]["nombre"])]
		nuevo.color = Color("e8d3a8")
		recientes.push_front(nuevo)
		tomado = true
	caja.materiales.clear()
	while recientes.size() > 4:
		recientes.pop_back()
	var sobran: Array[String] = []
	for id in caja.objetos:
		if bodega.size() >= capacidad():
			sobran.append(id)
			continue
		bodega.append(id)
		var nuevo := not coleccion.has(id)
		coleccion[id] = true
		var texto := tr(Objetos.nombre(id))
		if nuevo:
			texto = tr("¡Nuevo! %s") % texto
		_reciente(id, "", texto, Objetos.COLORES_RAREZA[Objetos.rareza(id)])
		tomado = true
	caja.objetos = sobran
	if tomado:
		mundo._brillo_reparacion(caja.nodo.position + Vector3(0, 0.5, 0))
		mundo.voz_moneda.pitch_scale = 1.2
		mundo.voz_moneda.play()
		mundo._pintar_botin()
	if not sobran.is_empty():
		if espera_aviso <= 0.0:
			espera_aviso = ESPERA_AVISO
			mundo.libre._anunciar(tr("¡Bodega llena! Vende en un asentamiento"), Principal.COLOR_PELIGRO)
		return
	_quitar_caja(i)


func _reciente(objeto: String, tipo: String, texto: String, color: Color) -> void:
	var nuevo := Reciente.new()
	nuevo.objeto = objeto
	nuevo.municion = tipo
	nuevo.texto = texto
	nuevo.color = color
	recientes.push_front(nuevo)
	if recientes.size() > 4:
		recientes.pop_back()


# Las cajas que se quedan atrás reaparecen alrededor del barco con otra carga; las de los
# naufragios lejanos se pierden. Si faltan (porque se recogieron) salen otras fuera de la vista.
func _reciclar() -> void:
	var centro := mundo.jugador.pos
	var mercancia := 0
	var de_municion := 0
	for i in range(cajas.size() - 1, -1, -1):
		var caja := cajas[i]
		var lejos := caja.pos.distance_to(centro) > MarLibre.ACTIVO * 1.2
		if caja.vida > 0.0:
			if lejos:
				_quitar_caja(i)
			continue
		var es_municion := caja.objetos.is_empty() and not caja.balas.is_empty()
		if lejos:
			_quitar_caja(i)
			continue
		if es_municion:
			de_municion += 1
		else:
			mercancia += 1
	for _i in CAJAS_MERCANCIA - mercancia:
		_soltar_caja(_lugar_caja(1300.0), false)
	for _i in CAJAS_MUNICION - de_municion:
		_soltar_caja(_lugar_caja(1300.0), true)


# Munición

func balas_de(tipo: String) -> int:
	return municion.get(tipo, 0)


func danio(tipo: String) -> float:
	return MUNICIONES[tipo]["danio"] if MUNICIONES.has(tipo) else Principal.DANIO_BALA


func material_bala(tipo: String) -> Material:
	return materiales_bala.get(tipo, materiales_bala["hierro"])


# Gasta hasta "cuantas" balas del tipo elegido y devuelve las que hay; si se acabó ese tipo
# pasa al siguiente que quede.
func gastar_balas(cuantas: int) -> int:
	if balas_de(tipo_bala) <= 0:
		var otro := _siguiente_con_balas()
		if otro == "":
			_avisar(tr("¡Sin balas! Recoge cajas o cómpralas en un asentamiento"))
			return 0
		tipo_bala = otro
		mundo.libre._anunciar(tr("Cargas %s") % tr(MUNICIONES[tipo_bala]["nombre"]), MUNICIONES[tipo_bala]["color"].lightened(0.3))
	var dadas := mini(cuantas, balas_de(tipo_bala))
	municion[tipo_bala] -= dadas
	return dadas


func _siguiente_con_balas() -> String:
	var i := ORDEN_MUNICION.find(tipo_bala)
	for k in range(1, ORDEN_MUNICION.size() + 1):
		var tipo := ORDEN_MUNICION[(i + k) % ORDEN_MUNICION.size()]
		if balas_de(tipo) > 0:
			return tipo
	return ""


func cambiar_municion() -> void:
	var otro := _siguiente_con_balas()
	if otro == "" or otro == tipo_bala:
		if balas_de(tipo_bala) <= 0:
			_avisar(tr("¡Sin balas! Recoge cajas o cómpralas en un asentamiento"))
		return
	tipo_bala = otro
	mundo.voz_equipar.play()
	mundo.libre._anunciar(tr("Cargas %s") % tr(MUNICIONES[tipo_bala]["nombre"]), MUNICIONES[tipo_bala]["color"].lightened(0.3))


func elegir_municion(tipo: String) -> void:
	if tipo == tipo_bala:
		return
	if balas_de(tipo) <= 0:
		_avisar(tr("No te quedan: %s. Cómprala en un mercado o en tu base") % tr(MUNICIONES[tipo]["nombre"]))
		return
	tipo_bala = tipo
	mundo.voz_equipar.play()
	mundo.libre._anunciar(tr("Cargas %s") % tr(MUNICIONES[tipo]["nombre"]), MUNICIONES[tipo]["color"].lightened(0.3))


func _avisar(texto: String) -> void:
	if espera_aviso > 0.0:
		return
	espera_aviso = ESPERA_AVISO
	mundo.libre._anunciar(texto, Principal.COLOR_PELIGRO)


# Efecto de cada bala especial al acabar su vuelo (golpeado es el barco alcanzado o null).
func impacto(tipo: String, punto: Vector2, golpeado: Barco, dueno: Barco) -> void:
	match tipo:
		"cadena":
			if golpeado != null and golpeado.viva:
				golpeado.frenado = DURACION_FRENADO
				_avisar_en(golpeado, tr("¡Velas rotas!"), Color("cfd6dc"))
		"fuego":
			if golpeado != null and golpeado.viva:
				golpeado.quemadura = DURACION_FUEGO
				golpeado.quemador = dueno
				_avisar_en(golpeado, tr("¡En llamas!"), Color("ff8a3d"))
		"explosiva":
			for barco in mundo.barcos:
				if not barco.viva or barco == golpeado or barco == dueno:
					continue
				var d := barco.pos.distance_to(punto) - barco.radio * 0.5
				if d < RADIO_EXPLOSIVA:
					barco.recibir_danio(DANIO_EXPLOSIVA * (1.0 - maxf(0.0, d) / RADIO_EXPLOSIVA), true, dueno)
			mundo.peligros.explosion(punto, RADIO_EXPLOSIVA, DANIO_EXPLOSIVA, dueno)
			mundo.tiburones.explosion(punto, RADIO_EXPLOSIVA, DANIO_EXPLOSIVA, dueno)
			var centro := mundo.a_3d(punto, 0.8)
			mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.9, 0.6, 0.95), centro, Vector3.ZERO, 0.2, 1.0, 4.0)
			mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.5, 0.12, 0.9), centro, Vector3(0, 0.6, 0), 0.4, 0.9, 3.0)
			for _i in 4:
				var vel := Vector3(randf_range(-0.6, 0.6), randf_range(0.8, 1.6), randf_range(-0.6, 0.6))
				mundo.crear_efecto(mundo.malla_humo, Color(0.2, 0.18, 0.17, 0.7), centro, vel, randf_range(1.2, 1.8), 0.7, 2.0, 0.0, true)
			mundo.salpicar(punto, 12)
			mundo.sonar_explosion(centro)


func _avisar_en(barco: Barco, texto: String, color: Color) -> void:
	if barco.visible:
		mundo.avisar_premio(barco.position + Vector3(0, barco.altura * 0.5, 0), texto, color)


# Estela de chispas de las balas de fuego y explosivas.
func estela(tipo: String, sitio: Vector3) -> void:
	if tipo in ["fuego", "explosiva"] and randf() < 0.6:
		mundo.crear_efecto(mundo.malla_humo, Color(MUNICIONES[tipo]["color"], 0.8), sitio, Vector3(0, 0.3, 0), 0.3, 0.25, 0.5)


# Barriles

func tirar_barril() -> void:
	var jugador := mundo.jugador
	if jugador == null or not jugador.viva or espera_barril > 0.0:
		return
	if barriles_carga <= 0:
		_avisar(tr("Sin barriles: cómpralos en un asentamiento"))
		return
	barriles_carga -= 1
	espera_barril = ESPERA_BARRIL
	var punto := jugador.pos - jugador.proa() * jugador.radio * 1.3
	mundo.barriles.lanzar(punto, jugador)
	mundo.salpicar(punto, 8)
	mundo.voz_equipar.play()


# Teclado: Tab o F cambia la munición, 1-4 la elige, R tira un barril y C abre el mercado.
func tecla(evento: InputEvent) -> bool:
	var tecla_pulsada := evento as InputEventKey
	if tecla_pulsada == null or not tecla_pulsada.pressed or tecla_pulsada.echo:
		return false
	match tecla_pulsada.keycode:
		KEY_TAB, KEY_F:
			cambiar_municion()
		KEY_R:
			tirar_barril()
		KEY_C:
			if boton_comerciar.visible:
				abrir()
		KEY_1, KEY_2, KEY_3, KEY_4:
			elegir_municion(ORDEN_MUNICION[tecla_pulsada.keycode - KEY_1])
		_:
			return false
	return true


# Asentamientos: islas con chozas, un mercado y un muelle donde se vende la mercancía

func crear_asentamiento(datos: Array) -> Asentamiento:
	var asentamiento := Asentamiento.new()
	asentamiento.pos = datos[0]
	asentamiento.nombre = datos[1]
	asentamiento.favorita = datos[2]
	asentamiento.fase = randf() * TAU
	asentamiento.isla = Circulo.new(asentamiento.pos, RADIO_ASENTAMIENTO)
	asentamiento.nodo = _crear_asentamiento(asentamiento)
	asentamientos.append(asentamiento)
	return asentamiento


func quitar_asentamiento(asentamiento: Asentamiento) -> void:
	asentamientos.erase(asentamiento)
	if abierto == asentamiento:
		cerrar()


# Isla de arena con chozas de paja, un puesto de mercado con toldo de rayas y mercancía,
# palmeras, un muelle con faroles y una bandera del color de la categoría que más paga.
func _crear_asentamiento(asentamiento: Asentamiento) -> Node3D:
	var islas := mundo.islas
	var nodo := Node3D.new()
	nodo.position = mundo.a_3d(asentamiento.pos)
	var r := asentamiento.isla.radio * Principal.ESCALA
	islas._malla(nodo, islas._arena(r, asentamiento.isla), Islas.COLOR_ARENA, Vector3.ZERO)
	nodo.add_child(islas._orilla(r * 1.15))
	islas._fondo(nodo, r, asentamiento.isla, int(10 + r * 2.5))
	nodo.set_meta("radio", r)
	var pueblo := Node3D.new()
	pueblo.rotation.y = randf() * TAU
	nodo.add_child(pueblo)
	var suelo := 0.45
	var madera := mundo.material(COLOR_MADERA, "madera")
	var oscura := mundo.material(Color("4a3222"), "madera")
	var pared := mundo.material(COLOR_PARED, "madera")
	var paja := mundo.material(COLOR_PAJA)
	var toldo_color: Color = COLORES_TOLDO[randi() % COLORES_TOLDO.size()]
	var toldo := mundo.material(toldo_color)
	var claro := mundo.material(Color("f1e6cc"))

	# Chozas en corro alrededor de la plaza.
	var chozas := randi_range(3, 5)
	for k in chozas:
		var a := PI * 0.35 + TAU * 0.75 * k / maxf(1.0, chozas - 1)
		var sitio := Vector3(cos(a), 0.0, sin(a)) * r * randf_range(0.48, 0.6)
		var choza := Node3D.new()
		choza.position = sitio + Vector3(0, suelo, 0)
		choza.rotation.y = -a - PI / 2.0
		pueblo.add_child(choza)
		var ancho := randf_range(0.5, 0.65)
		_pieza(choza, cilindro, pared, Vector3(0, 0.35, 0), Vector3(ancho * 2.0, 0.7, ancho * 2.0))
		_pieza(choza, cono, paja, Vector3(0, 0.98, 0), Vector3(ancho * 2.7, 0.65, ancho * 2.7))
		_pieza(choza, cilindro, oscura, Vector3(0, 1.35, 0), Vector3(0.06, 0.18, 0.06))
		_pieza(choza, caja_malla, oscura, Vector3(0, 0.28, ancho * 0.98), Vector3(0.3, 0.5, 0.05))

	# Puesto del mercado: cuatro postes, toldo de rayas, mostrador y género a la vista.
	var puesto := Node3D.new()
	puesto.position = Vector3(r * 0.05, suelo, r * 0.05)
	pueblo.add_child(puesto)
	for x in [-0.7, 0.7]:
		for z in [-0.45, 0.45]:
			_pieza(puesto, cilindro, oscura, Vector3(x, 0.55, z), Vector3(0.07, 1.1, 0.07))
	for k in 5:
		var raya := _pieza(puesto, caja_malla, toldo if k % 2 == 0 else claro, Vector3(-0.6 + k * 0.3, 1.15, 0), Vector3(0.3, 0.05, 1.15))
		raya.rotation.x = 0.12
	_pieza(puesto, caja_malla, madera, Vector3(0, 0.42, 0.3), Vector3(1.5, 0.08, 0.4))
	_pieza(puesto, caja_malla, oscura, Vector3(0, 0.2, 0.3), Vector3(1.4, 0.4, 0.36))
	var generos := [Color("e2b15a"), Color("c0392b"), Color("8e44ad"), Color("27ae60"), Color("ecf0f1")]
	for k in 5:
		_pieza(puesto, esfera, mundo.material(generos[k]), Vector3(-0.56 + k * 0.28, 0.52, 0.3), Vector3(0.16, 0.12, 0.16))
	for k in 3:
		_pieza(puesto, caja_malla, madera, Vector3(-1.05 + (k % 2) * 0.05, 0.18 + k * 0.32, -0.2), Vector3(0.34, 0.32, 0.34))
	for z in [-0.5, 0.0]:
		_pieza(puesto, cilindro, mundo.material(Color("8a5a32"), "madera"), Vector3(1.05, 0.25, z), Vector3(0.32, 0.5, 0.32))
	for saco in [Vector3(0.4, 0.15, -0.55), Vector3(0.0, 0.15, -0.6)]:
		_pieza(puesto, esfera, mundo.material(Color("d8c79c")), saco, Vector3(0.36, 0.3, 0.3))

	# Palmeras repartidas por la orilla.
	for k in randi_range(3, 5):
		var a := randf() * TAU
		islas._palmera(pueblo, Vector3(cos(a), 0.0, sin(a)) * r * randf_range(0.7, 0.82) + Vector3(0, suelo, 0), randf_range(1.6, 2.4))

	# Muelle hacia el mar con faroles en la punta.
	var muelle := Node3D.new()
	muelle.rotation.y = -PI * 0.1
	pueblo.add_child(muelle)
	for k in 7:
		_pieza(muelle, caja_malla, madera, Vector3(r * 0.78 + k * 0.32, 0.42, 0), Vector3(0.3, 0.08, 0.95))
	for lado in [-1.0, 1.0]:
		for k in 3:
			_pieza(muelle, cilindro, oscura, Vector3(r * 0.85 + k * 0.9, 0.2, lado * 0.45), Vector3(0.1, 0.8, 0.1))
		var farol := _pieza(muelle, esfera, null, Vector3(r * 0.78 + 2.0, 0.8, lado * 0.45), Vector3(0.2, 0.24, 0.2))
		farol.material_override = _brillo(Color("ffd27a"))

	# Mástil con la bandera del mercado.
	_pieza(pueblo, cilindro, oscura, Vector3(-r * 0.15, suelo + 1.6, -r * 0.25), Vector3(0.07, 3.2, 0.07))
	asentamiento.bandera = Node3D.new()
	asentamiento.bandera.position = Vector3(-r * 0.15, suelo + 2.9, -r * 0.25)
	pueblo.add_child(asentamiento.bandera)
	var tela := _pieza(asentamiento.bandera, caja_malla, _brillo(COLOR_MERCADO.darkened(0.1)), Vector3(0.42, 0, 0), Vector3(0.8, 0.5, 0.03))
	tela.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pieza(asentamiento.bandera, esfera, mundo.material(toldo_color), Vector3(0.42, 0, 0.02), Vector3(0.24, 0.24, 0.03))
	return nodo


func _brillo(color: Color) -> StandardMaterial3D:
	var materia := StandardMaterial3D.new()
	materia.albedo_color = color
	materia.emission_enabled = true
	materia.emission = color
	materia.emission_energy_multiplier = 0.8
	return materia


func precio(id: String, asentamiento: Asentamiento) -> int:
	var extra := PREMIO_FAVORITA if asentamiento != null and Objetos.categoria(id) == asentamiento.favorita else 1.0
	return roundi(Objetos.valor(id) * extra)


# Animación (también fuera de la partida, para que no se congele al terminar)

func animar(delta: float) -> void:
	var t := mundo.tiempo
	for caja in cajas:
		var sitio := mundo.a_3d(caja.pos)
		var hundido := clampf((caja.edad - caja.vida + 3.0) / 3.0, 0.0, 1.0) if caja.vida > 0.0 else 0.0
		caja.nodo.visible = sitio.distance_to(Vector3(mundo.foco.x, 0.0, mundo.foco.z)) < Principal.DISTANCIA_VISIBLE
		if not caja.nodo.visible:
			continue
		caja.nodo.position = Vector3(sitio.x, mundo.altura_mar(sitio.x, sitio.z) - 0.12 - hundido * 0.9, sitio.z)
		caja.nodo.rotation = Vector3(sin(t * 1.5 + caja.fase) * 0.12, caja.fase + t * 0.2, cos(t * 1.2 + caja.fase) * 0.1)
		var aro: Node3D = caja.nodo.get_node("Aro")
		aro.scale = Vector3(1.0, 0.2, 1.0) * (1.0 + 0.12 * sin(t * 4.0 + caja.fase))
	for asentamiento in asentamientos:
		if asentamiento.bandera != null and asentamiento.nodo.visible:
			asentamiento.bandera.rotation.y = sin(t * 2.0 + asentamiento.fase) * 0.3
	animar_llamas(delta)


# Llamas y humo sobre los barcos que arden (balas incendiarias o la bola de fuego del MOBA).
func animar_llamas(delta: float) -> void:
	for barco in mundo.barcos:
		if barco.quemadura > 0.0 and barco.viva and barco.visible and randf() < delta * 16.0:
			var lado := Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5)) * barco.radio * Principal.ESCALA
			var base := barco.position + lado + Vector3(0, 0.7, 0)
			mundo.crear_efecto(mundo.malla_humo, Color(1.0, randf_range(0.35, 0.65), 0.1, 0.9), base, Vector3(0, 1.4, 0), 0.5, 0.35, 1.2)
			if randf() < 0.4:
				mundo.crear_efecto(mundo.malla_humo, Color(0.2, 0.19, 0.18, 0.6), base + Vector3(0, 0.6, 0), Vector3(0, 1.2, 0), 1.4, 0.4, 2.0, 0.0, true)


# Interfaz: botón de comerciar, botones de munición y barril y el panel del mercado

func crear_interfaz(capa: CanvasLayer) -> void:
	textura_moneda = Ui.textura_moneda()
	boton_comerciar = boton_lugar(_dibujar_boton_comerciar, abrir)
	capa.add_child(boton_comerciar)
	boton_municion = _boton_redondo(BOTON_MUNICION, _dibujar_boton_municion, cambiar_municion)
	capa.add_child(boton_municion)
	for k in ORDEN_MUNICION.size():
		var selector := Button.new()
		selector.focus_mode = Control.FOCUS_NONE
		selector.flat = true
		for estado in ["normal", "hover", "pressed", "focus"]:
			selector.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
		var lado := 38.0
		var sitio := BOTON_MUNICION + Vector2.from_angle(_angulo_selector(k)) * (RADIO_BOTON + 20.0)
		Ui.anclar(selector, Vector2(1, 1), sitio - Vector2.ONE * lado / 2.0, Vector2.ONE * lado)
		selector.pressed.connect(elegir_municion.bind(ORDEN_MUNICION[k]))
		boton_municion.visibility_changed.connect(func() -> void: selector.visible = boton_municion.visible)
		selector.visible = false
		capa.add_child(selector)
	boton_barril = _boton_redondo(BOTON_BARRIL, _dibujar_boton_barril, tirar_barril)
	capa.add_child(boton_barril)
	textura_barril = _crear_textura_barril()

	panel = PanelContainer.new()
	var estilo := Ui.estilo_panel()
	estilo.set_content_margin_all(22)
	estilo.bg_color.a = 0.97
	panel.add_theme_stylebox_override("panel", estilo)
	Ui.anclar(panel, Vector2(0.5, 0.5), Vector2(-460, -320), Vector2(920, 640))
	panel.visible = false
	capa.add_child(panel)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 10)
	panel.add_child(cuerpo)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	cuerpo.add_child(cabecera)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 0)
	cabecera.add_child(columna)
	titulo = Ui.etiqueta_panel("", 30, COLOR_MERCADO)
	columna.add_child(titulo)
	texto_favorita = Ui.etiqueta_panel("", 17, Color("c9d1d3"))
	columna.add_child(texto_favorita)
	for material in ORDEN_MATERIALES:
		var dibujo := TextureRect.new()
		dibujo.texture = Objetos.icono_mejora(material)
		dibujo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dibujo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dibujo.custom_minimum_size = Vector2(34, 34)
		dibujo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dibujo.tooltip_text = MATERIALES[material]["nombre"]
		cabecera.add_child(dibujo)
		var cifra := Ui.etiqueta_panel("0", 22, Color("e8d3a8"))
		cifra.autowrap_mode = TextServer.AUTOWRAP_OFF
		cifra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cabecera.add_child(cifra)
		textos_material[material] = cifra
	cabecera.add_child(Ui.icono_moneda(30))
	texto_monedas = Ui.etiqueta_panel("", 28, Principal.COLOR_ORO)
	texto_monedas.autowrap_mode = TextServer.AUTOWRAP_OFF
	texto_monedas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cabecera.add_child(texto_monedas)
	var cerrar_boton := Ui.boton("Cerrar", false)
	Ui.estilo_volver(cerrar_boton)
	cerrar_boton.custom_minimum_size = Vector2(140, 60)
	cerrar_boton.add_theme_font_size_override("font_size", 24)
	cerrar_boton.pressed.connect(cerrar)
	cabecera.add_child(cerrar_boton)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	cuerpo.add_child(fila)
	for nombre in ["vender", "comprar", "astillero", "base", "recompensas", "coleccion"]:
		var texto: String = {"vender": "Vender", "comprar": "Comprar", "astillero": "Astillero", "base": "Tu base", "recompensas": "Recompensas", "coleccion": "Colección"}[nombre]
		var boton := Ui.boton(texto, false)
		boton.custom_minimum_size = Vector2(0, 54)
		boton.add_theme_font_size_override("font_size", 22)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.pressed.connect(_abrir_pestana.bind(nombre))
		fila.add_child(boton)
		pestanas[nombre] = boton

	desplazable = ScrollContainer.new()
	desplazable.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cuerpo.add_child(desplazable)
	contenido = VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 10)
	desplazable.add_child(contenido)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 12)
	cuerpo.add_child(pie)
	texto_info = Ui.etiqueta_panel("", 18, Color("c9d1d3"))
	texto_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pie.add_child(texto_info)
	boton_todo = Ui.boton("Vender todo", true)
	boton_todo.custom_minimum_size = Vector2(300, 62)
	boton_todo.add_theme_font_size_override("font_size", 24)
	boton_todo.pressed.connect(_vender_todo)
	pie.add_child(boton_todo)


func _boton_redondo(desde: Vector2, dibujo: Callable, accion: Callable) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	var vacio := StyleBoxEmpty.new()
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		boton.add_theme_stylebox_override(estado, vacio)
	var lado := RADIO_BOTON * 2.0 + 8.0
	Ui.anclar(boton, Vector2(1, 1), desde - Vector2.ONE * lado / 2.0, Vector2.ONE * lado)
	boton.draw.connect(dibujo)
	boton.pressed.connect(accion)
	boton.visible = false
	return boton


func _fondo_boton(boton: Button, listo: bool) -> Vector2:
	var c := boton.size / 2.0
	if boton.button_pressed:
		c.y += 2.0
	boton.draw_circle(c + Vector2(0, 4), RADIO_BOTON + 3.0, Color(0, 0, 0, 0.3))
	boton.draw_circle(c, RADIO_BOTON + 3.0, Principal.COLOR_ORO if listo else Color("7d7368"))
	boton.draw_circle(c, RADIO_BOTON, Color("16384a") if listo else Color("1c2a33"))
	boton.draw_circle(c + Vector2(0, -RADIO_BOTON * 0.28), RADIO_BOTON * 0.68, Color(1, 1, 1, 0.07))
	return c


# Bala del tipo cargado con su cantidad y, alrededor, un punto por tipo (el cargado, grande)
# con las balas que quedan de ese tipo.
func _dibujar_boton_municion() -> void:
	var cantidad := balas_de(tipo_bala)
	var c := _fondo_boton(boton_municion, cantidad > 0)
	var color: Color = MUNICIONES[tipo_bala]["color"]
	boton_municion.draw_circle(c + Vector2(0, -8), 12.0, Color("0b0d0f"))
	boton_municion.draw_circle(c + Vector2(0, -8), 10.5, color)
	boton_municion.draw_circle(c + Vector2(-3.5, -11.5), 3.5, Color(1, 1, 1, 0.45))
	var fuente := ThemeDB.fallback_font
	var cifra := str(cantidad)
	var ancho := fuente.get_string_size(cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	boton_municion.draw_string_outline(fuente, c + Vector2(-ancho / 2.0, 19), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.8))
	boton_municion.draw_string(fuente, c + Vector2(-ancho / 2.0, 19), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff3dc") if cantidad > 0 else Principal.COLOR_PELIGRO)
	for k in ORDEN_MUNICION.size():
		var tipo := ORDEN_MUNICION[k]
		var a := _angulo_selector(k)
		var punto := c + Vector2.from_angle(a) * (RADIO_BOTON + 10.0)
		var hay := balas_de(tipo) > 0
		boton_municion.draw_circle(punto, 6.0 if tipo == tipo_bala else 4.5, Color("0b0d0f"))
		boton_municion.draw_circle(punto, 4.8 if tipo == tipo_bala else 3.4, MUNICIONES[tipo]["color"] if hay else Color(0.3, 0.3, 0.3))
		var numero := str(balas_de(tipo))
		var tam := 17 if tipo == tipo_bala else 15
		var lugar := c + Vector2.from_angle(a) * (RADIO_BOTON + 28.0)
		var medida := fuente.get_string_size(numero, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
		lugar += Vector2(-medida.x / 2.0, medida.y * 0.3)
		var tinta: Color = MUNICIONES[tipo]["color"].lightened(0.55) if hay else Color(0.55, 0.55, 0.55)
		boton_municion.draw_string_outline(fuente, lugar, numero, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 4, Color(0, 0, 0, 0.85))
		boton_municion.draw_string(fuente, lugar, numero, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, tinta)


func _angulo_selector(k: int) -> float:
	return lerpf(-PI * 0.8, -PI * 0.2, k / 3.0)


func _dibujar_boton_barril() -> void:
	var listo := barriles_carga > 0 and espera_barril <= 0.0
	var c := _fondo_boton(boton_barril, listo)
	boton_barril.draw_texture_rect(textura_barril, Rect2(c + Vector2(-15, -24), Vector2(30, 30)), false, Color.WHITE if barriles_carga > 0 else Color(1, 1, 1, 0.4))
	var fuente := ThemeDB.fallback_font
	var cifra := "x%d" % barriles_carga
	var ancho := fuente.get_string_size(cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	boton_barril.draw_string_outline(fuente, c + Vector2(-ancho / 2.0, 22), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.8))
	boton_barril.draw_string(fuente, c + Vector2(-ancho / 2.0, 22), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff3dc") if barriles_carga > 0 else Principal.COLOR_PELIGRO)


# Botón redondo del lugar (mercado, astillero de la base o reclamar base): aparece en un
# hueco fijo junto a los de disparo, con un halo dorado que late para llamar la atención.
func boton_lugar(dibujo: Callable, accion: Callable) -> Button:
	var boton := _boton_redondo(BOTON_LUGAR, dibujo, accion)
	var lado := (RADIO_BOTON + 10.0) * 2.0
	Ui.anclar(boton, Vector2(1, 1), BOTON_LUGAR - Vector2.ONE * lado / 2.0, Vector2.ONE * lado)
	return boton


func dibujar_boton_lugar(boton: Button, icono: Texture2D, texto: String) -> void:
	var c := boton.size / 2.0
	var latido := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 260.0)
	boton.draw_circle(c, RADIO_BOTON + 5.0 + 4.0 * latido, Color(Principal.COLOR_ORO, 0.18 + 0.2 * latido))
	c = _fondo_boton(boton, true)
	boton.draw_texture_rect(icono, Rect2(c + Vector2(-16, -26), Vector2(32, 32)), false)
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	boton.draw_string_outline(fuente, c + Vector2(-ancho / 2.0, 21), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.8))
	boton.draw_string(fuente, c + Vector2(-ancho / 2.0, 21), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff3dc"))


func _dibujar_boton_comerciar() -> void:
	if cerca != null:
		dibujar_boton_lugar(boton_comerciar, textura_moneda, tr("Mercado"))
	else:
		dibujar_boton_lugar(boton_comerciar, Objetos.icono_mejora("casco"), tr("Astillero"))


# Barril rojo con aros de hierro y franja amarilla, para el botón y la tienda.
func _crear_textura_barril() -> ImageTexture:
	var lado := 64
	var imagen := Image.create_empty(lado, lado, false, Image.FORMAT_RGBA8)
	for y in lado:
		for x in lado:
			var v := (y + 0.5) / lado * 2.0 - 1.0
			var mitad := 20.0 + 6.0 * (1.0 - v * v)
			var px := absf(x + 0.5 - lado / 2.0)
			if absf(v) > 0.9 or px > mitad:
				continue
			var color := Barriles.COLOR_MADERA.lerp(Color("b2452e"), clampf(1.0 - px / mitad, 0.0, 1.0) * 0.6)
			if absf(v) > 0.78 or absf(absf(v) - 0.45) < 0.06:
				color = Barriles.COLOR_HIERRO
			elif absf(v) < 0.1:
				color = Barriles.COLOR_FRANJA
			color.a = clampf(mitad - px, 0.0, 1.0)
			imagen.set_pixel(x, y, color)
	return ImageTexture.create_from_image(imagen)


# En un asentamiento: mercado y astillero. En la base propia: astillero y mejoras de la base.
func abrir() -> void:
	if (cerca == null and not cerca_base) or not mundo.jugador.viva:
		return
	abierto = cerca
	en_base = cerca == null
	mundo.misiones.cerrar_mapa()
	panel.visible = true
	boton_comerciar.visible = false
	if en_base:
		titulo.text = tr("Tu base")
		texto_favorita.text = tr("Compra munición y mejora tu barco y tu fuerte")
	else:
		titulo.text = tr("Mercado de %s") % abierto.nombre
		texto_favorita.text = tr("Aquí pagan más por: %s") % tr(Objetos.CATEGORIAS[abierto.favorita]["nombre"])
	for clave in pestanas:
		pestanas[clave].visible = clave in (["comprar", "astillero", "base", "recompensas", "coleccion"] if en_base else ["vender", "comprar", "astillero", "recompensas", "coleccion"])
	refrescar_pestanas()
	mundo.voz_equipar.play()
	_abrir_pestana("astillero" if en_base else "vender")


func cerrar() -> void:
	if panel == null or not panel.visible:
		return
	panel.visible = false
	abierto = null
	en_base = false
	if mundo.modo == "libre":
		mundo.libre.guardar()


# La pestaña de recompensas lleva cuántas hay listas para cobrar.
func refrescar_pestanas() -> void:
	var listas := mundo.recompensas.listos()
	pestanas["recompensas"].text = tr("Recompensas") + (" (%d)" % listas if listas > 0 else "")


func _abrir_pestana(nombre: String) -> void:
	pestana = nombre
	for clave in pestanas:
		Ui.estilo_boton(pestanas[clave], clave == nombre)
	_refrescar()
	desplazable.scroll_vertical = 0


func _refrescar() -> void:
	for hijo in contenido.get_children():
		hijo.queue_free()
	texto_monedas.text = str(mundo.personalizacion.monedas)
	for material in ORDEN_MATERIALES:
		textos_material[material].text = str(materiales[material])
	boton_todo.visible = pestana == "vender"
	match pestana:
		"vender":
			_llenar_vender()
		"comprar":
			_llenar_comprar()
		"astillero":
			_llenar_mejoras(false)
		"base":
			_llenar_mejoras(true)
		"recompensas":
			mundo.recompensas.llenar(contenido)
		_:
			_llenar_coleccion()


# Una fila por mejora: dibujo, nombre, qué hace, nivel y lo que cuesta el siguiente.
func _llenar_mejoras(de_base: bool) -> void:
	var lista := MEJORAS_BASE if de_base else MEJORAS_BARCO
	var niveles := mejoras_base if de_base else mejoras
	for clave in lista:
		var datos: Dictionary = lista[clave]
		var nivel: int = niveles[clave]
		var estado := tr("Nivel %d de %d") % [nivel, NIVEL_MAXIMO]
		var texto_boton := tr("Máximo")
		var activo := false
		var color_estado := Principal.COLOR_ORO
		if nivel < NIVEL_MAXIMO:
			var precio_total := coste(clave, nivel, de_base)
			var partes: Array[String] = [tr("%d monedas") % precio_total["monedas"]]
			for material in ORDEN_MATERIALES:
				partes.append("%d %s" % [precio_total[material], tr(MATERIALES[material]["nombre"]).to_lower()])
			estado += "  ·  " + tr("Siguiente: %s") % ", ".join(partes)
			activo = _alcanza(precio_total)
			if not activo:
				color_estado = Principal.COLOR_PELIGRO
			texto_boton = tr("Mejorar")
		_fila(Objetos.icono_mejora(clave), tr(datos["nombre"]), tr(datos["detalle"]), estado, color_estado, texto_boton, activo, _mejorar.bind(clave, de_base))
	if de_base:
		texto_info.text = tr("Las mejoras de la base se quedan contigo aunque te mudes de fuerte")
	else:
		texto_info.text = tr("Consigue madera, metal y tela en los naufragios, los fuertes y los mercados")


func _llenar_vender() -> void:
	var jugador := mundo.jugador
	var cuentas := {}
	for id in bodega:
		cuentas[id] = cuentas.get(id, 0) + 1
	var ids: Array = cuentas.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return precio(a, abierto) > precio(b, abierto))
	var total := 0
	for id in bodega:
		total += precio(id, abierto)
	var tesoros := mundo.tesoros.valor(jugador)
	if not jugador.tesoros.is_empty():
		var aviso := Ui.etiqueta_panel(tr("Tesoros en cubierta: %d (+%d monedas)") % [jugador.tesoros.size(), tesoros], 20, Principal.COLOR_ORO)
		contenido.add_child(aviso)
	if ids.is_empty():
		contenido.add_child(Ui.etiqueta_panel(tr("Tu bodega está vacía. Recoge las cajas que flotan a la deriva y los restos de los naufragios."), 20, Principal.COLOR_TEXTO))
	else:
		var rejilla := GridContainer.new()
		rejilla.columns = 6
		rejilla.add_theme_constant_override("h_separation", 10)
		rejilla.add_theme_constant_override("v_separation", 10)
		contenido.add_child(rejilla)
		for id in ids:
			var celda := _celda(id, true, cuentas[id], precio(id, abierto))
			celda.pressed.connect(_vender.bind(id))
			rejilla.add_child(celda)
	texto_info.text = tr("Bodega: %d/%d · Toca un objeto para venderlo") % [bodega.size(), capacidad()]
	boton_todo.text = tr("Vender todo: +%d") % (total + tesoros)
	boton_todo.disabled = total + tesoros <= 0


# Ficha de un objeto: su dibujo, el nombre del color de su rareza y, si se vende, el precio.
func _celda(id: String, conocido: bool, cantidad: int, valor: int) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.custom_minimum_size = Vector2(134, 178 if valor >= 0 else 150)
	var color: Color = Objetos.COLORES_RAREZA[Objetos.rareza(id)] if conocido else Color(1, 1, 1, 0.2)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.06)
	normal.border_color = Color(color, 0.8)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	var pulsado := normal.duplicate() as StyleBoxFlat
	pulsado.bg_color = Color(1, 1, 1, 0.16)
	for estado in ["normal", "hover", "disabled", "focus"]:
		boton.add_theme_stylebox_override(estado, normal)
	boton.add_theme_stylebox_override("pressed", pulsado)
	var columna := VBoxContainer.new()
	columna.set_anchors_preset(Control.PRESET_FULL_RECT)
	columna.offset_left = 6
	columna.offset_right = -6
	columna.offset_top = 6
	columna.offset_bottom = -4
	columna.add_theme_constant_override("separation", 2)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(columna)
	var icono := TextureRect.new()
	icono.texture = Objetos.icono(id)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.custom_minimum_size = Vector2(0, 92)
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not conocido:
		icono.modulate = Color(0.16, 0.2, 0.24)
	columna.add_child(icono)
	var nombre := Ui.etiqueta_panel(tr(Objetos.nombre(id)) if conocido else "???", 14, color if conocido else Color(1, 1, 1, 0.4))
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(nombre)
	if valor >= 0:
		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(Ui.icono_moneda(18))
		var cifra := Ui.etiqueta_panel(str(valor), 18, Principal.COLOR_ORO)
		cifra.autowrap_mode = TextServer.AUTOWRAP_OFF
		fila.add_child(cifra)
		if cantidad > 0 and abierto != null and Objetos.categoria(id) == abierto.favorita:
			fila.add_child(Ui.etiqueta_panel("+50%", 15, Color("7dff9a")))
		columna.add_child(fila)
	if cantidad > 1:
		var marca := Ui.etiqueta("x%d" % cantidad, 18)
		marca.position = Vector2(8, 4)
		boton.add_child(marca)
	return boton


func _vender(id: String) -> void:
	if abierto == null or not bodega.has(id):
		return
	var valor := precio(id, abierto)
	bodega.erase(id)
	mundo.personalizacion.monedas += valor
	mundo.personalizacion.guardar()
	mundo.voz_moneda.pitch_scale = 1.0
	mundo.voz_moneda.play()
	mundo._pintar_botin()
	_refrescar()


func _vender_todo() -> void:
	if abierto == null:
		return
	var total := 0
	var cuantos := bodega.size()
	for id in bodega:
		total += precio(id, abierto)
	bodega.clear()
	mundo.personalizacion.monedas += total
	mundo.tesoros.vender_jugador()
	mundo.personalizacion.guardar()
	if cuantos > 0:
		mundo.voz_monedas.play()
		mundo.libre._anunciar(tr("Vendiste %d objetos: +%d monedas") % [cuantos, total], Principal.COLOR_ORO)
	mundo._pintar_botin()
	mundo.libre.guardar()
	_refrescar()


func _llenar_comprar() -> void:
	var persecucion := mundo.persecucion
	if persecucion.notoriedad > 0.0:
		var soborno := persecucion.precio_soborno()
		_fila(Objetos.icono_mejora("soborno"), tr("Sobornar a las autoridades"), tr("Borra tu nivel de Se busca y los cazadores dejan de perseguirte"),
			tr("Se busca: nivel %d") % persecucion.estrellas(), Persecucion.COLOR_CAZADOR, tr("Pagar %d") % soborno,
			mundo.personalizacion.monedas >= soborno, _sobornar)
	var jugador := mundo.jugador
	var falta := jugador.vida_max - jugador.vida
	if falta >= 1.0:
		var precio := precio_reparacion()
		var alcanza := mini(precio, mundo.personalizacion.monedas)
		_fila(Objetos.icono_mejora("casco"), tr("Reparar el barco"), tr("Los carpinteros del puerto tapan las vías de agua del casco"),
			tr("Casco: %d / %d") % [int(jugador.vida), int(jugador.vida_max)], Principal.COLOR_PELIGRO,
			tr("Reparar: %d") % precio if alcanza >= precio else tr("Reparar a medias: %d") % alcanza, alcanza > 0, _reparar)
	else:
		_fila(Objetos.icono_mejora("casco"), tr("Reparar el barco"), tr("Los carpinteros del puerto tapan las vías de agua del casco"),
			tr("Tu barco está como nuevo"), Color("7dffb2"), tr("Reparar"), false, _reparar)
	for tipo in ORDEN_MUNICION:
		var datos: Dictionary = MUNICIONES[tipo]
		_fila_compra(Ui.textura_circulo(64, datos["color"]), tr(datos["nombre"]), tr(datos["detalle"]) + " · " + tr("Daño %d") % int(datos["danio"]),
			balas_de(tipo), datos["lote"], datos["precio"], _comprar.bind(tipo))
	_fila_compra(textura_barril, tr("Barril explosivo"), tr("Se tira por la popa y revienta al tocarlo un barco"),
		barriles_carga, 1, PRECIO_BARRIL, _comprar.bind("barril"))
	for material in ORDEN_MATERIALES:
		var datos: Dictionary = MATERIALES[material]
		_fila_compra(Objetos.icono_mejora(material), tr(datos["nombre"]), tr("Para las mejoras del astillero y de tu base"),
			materiales[material], datos["lote"], datos["precio"], _comprar.bind(material))
	texto_info.text = tr("Elige la munición con el botón junto al de disparo (o Tab) y tira barriles con el de la derecha (o R)")


func _sobornar() -> void:
	var soborno := mundo.persecucion.precio_soborno()
	if mundo.personalizacion.monedas < soborno:
		return
	mundo.personalizacion.monedas -= soborno
	mundo.persecucion.sobornar()
	mundo.personalizacion.guardar()
	mundo.voz_monedas.play()
	_refrescar()


func precio_reparacion() -> int:
	var jugador := mundo.jugador
	return ceili((jugador.vida_max - jugador.vida) * PRECIO_REPARACION)


# Con pocas monedas se repara solo lo que alcance.
func _reparar() -> void:
	var jugador := mundo.jugador
	var pago := mini(precio_reparacion(), mundo.personalizacion.monedas)
	if pago <= 0 or not jugador.viva:
		return
	mundo.personalizacion.monedas -= pago
	jugador.vida = minf(jugador.vida_max, jugador.vida + pago / PRECIO_REPARACION)
	mundo.personalizacion.guardar()
	mundo.voz_equipar.play()
	mundo.libre._anunciar(tr("Barco reparado: -%d monedas") % pago, Color("7dffb2"))
	_refrescar()


func _fila_compra(textura: Texture2D, nombre: String, detalle: String, tienes: int, lote: int, precio_lote: int, accion: Callable) -> void:
	_fila(textura, nombre, detalle, tr("Tienes: %d") % tienes, Principal.COLOR_ORO, tr("+%d por %d") % [lote, precio_lote],
		mundo.personalizacion.monedas >= precio_lote, accion)


func _fila(textura: Texture2D, nombre: String, detalle: String, estado: String, color_estado: Color, texto_boton: String, activo: bool, accion: Callable) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	contenido.add_child(fila)
	var icono := TextureRect.new()
	icono.texture = textura
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.custom_minimum_size = Vector2(58, 58)
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(icono)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 0)
	fila.add_child(columna)
	columna.add_child(Ui.etiqueta_panel(nombre, 22, Principal.COLOR_TEXTO))
	columna.add_child(Ui.etiqueta_panel(detalle, 15, Color("c9d1d3")))
	columna.add_child(Ui.etiqueta_panel(estado, 16, color_estado))
	var boton := Ui.boton(texto_boton, true)
	boton.custom_minimum_size = Vector2(210, 60)
	boton.add_theme_font_size_override("font_size", 22)
	boton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boton.disabled = not activo
	if boton.disabled:
		Ui.estilo_boton(boton, false)
	boton.pressed.connect(accion)
	fila.add_child(boton)


func _comprar(tipo: String) -> void:
	var precio_lote: int = PRECIO_BARRIL if tipo == "barril" else (MATERIALES[tipo] if MATERIALES.has(tipo) else MUNICIONES[tipo])["precio"]
	if mundo.personalizacion.monedas < precio_lote:
		return
	mundo.personalizacion.monedas -= precio_lote
	if tipo == "barril":
		barriles_carga += 1
	elif MATERIALES.has(tipo):
		materiales[tipo] += MATERIALES[tipo]["lote"]
	else:
		municion[tipo] += MUNICIONES[tipo]["lote"]
	mundo.personalizacion.guardar()
	mundo.voz_equipar.play()
	var antes := desplazable.scroll_vertical
	_refrescar()
	desplazable.set_deferred("scroll_vertical", antes)


func _llenar_coleccion() -> void:
	for categoria in Objetos.CATEGORIAS:
		var lista: Array = Objetos.CATEGORIAS[categoria]["objetos"]
		var vistos := 0
		for i in lista.size():
			if coleccion.has("%s:%d" % [categoria, i]):
				vistos += 1
		contenido.add_child(Ui.etiqueta_panel("%s  (%d/%d)" % [tr(Objetos.CATEGORIAS[categoria]["nombre"]), vistos, lista.size()], 22, COLOR_MERCADO))
		var rejilla := GridContainer.new()
		rejilla.columns = 6
		rejilla.add_theme_constant_override("h_separation", 10)
		rejilla.add_theme_constant_override("v_separation", 10)
		contenido.add_child(rejilla)
		for i in lista.size():
			var id := "%s:%d" % [categoria, i]
			var conocido := coleccion.has(id)
			var celda := _celda(id, conocido, 0, Objetos.valor(id) if conocido else -1)
			celda.custom_minimum_size = Vector2(134, 178)
			rejilla.add_child(celda)
	texto_info.text = tr("Descubiertos: %d de %d · Los colores marcan la rareza") % [coleccion.size(), Objetos.total()]


# Dibujo en pantalla: qué lleva cada caja, nombres de los asentamientos y lo recogido

func dibujar(lienzo: Control, camara: Camera3D) -> void:
	var fuente := ThemeDB.fallback_font
	for asentamiento in asentamientos:
		if not asentamiento.nodo.visible or asentamiento.nodo.position.distance_to(mundo.foco) > Principal.DISTANCIA_VISIBLE:
			continue
		var arriba: Vector3 = asentamiento.nodo.position + Vector3(0, 4.6, 0)
		if camara.is_position_behind(arriba):
			continue
		var punto := camara.unproject_position(arriba)
		var nombre := tr("Mercado: %s") % asentamiento.nombre
		lienzo.draw_string_outline(fuente, punto + Vector2(-160, 0), nombre, HORIZONTAL_ALIGNMENT_CENTER, 320, 20, 5, Color(0, 0, 0, 0.75))
		lienzo.draw_string(fuente, punto + Vector2(-160, 0), nombre, HORIZONTAL_ALIGNMENT_CENTER, 320, 20, COLOR_MERCADO)
	for caja in cajas:
		if not caja.nodo.visible:
			continue
		var arriba: Vector3 = caja.nodo.position + Vector3(0, 2.0, 0)
		if camara.is_position_behind(arriba):
			continue
		var punto := camara.unproject_position(arriba)
		var dibujos: Array = []
		for id in caja.objetos:
			dibujos.append([Objetos.icono(id), Objetos.COLORES_RAREZA[Objetos.rareza(id)]])
		for material in caja.materiales:
			dibujos.append([Objetos.icono_mejora(material), Color("e8d3a8")])
		if not dibujos.is_empty():
			var mostrar := mini(dibujos.size(), 4)
			var lado := 40.0
			var inicio := punto - Vector2((lado + 4.0) * mostrar / 2.0, lado)
			for k in mostrar:
				var marco := Rect2(inicio + Vector2(k * (lado + 4.0), 0), Vector2(lado, lado))
				lienzo.draw_rect(marco.grow(2.0), dibujos[k][1])
				lienzo.draw_texture_rect(dibujos[k][0], marco, false)
		for tipo in caja.balas:
			var cifra := "+%d" % caja.balas[tipo]
			lienzo.draw_circle(punto + Vector2(-16, -10), 11.0, Color("0b0d0f"))
			lienzo.draw_circle(punto + Vector2(-16, -10), 9.0, MUNICIONES[tipo]["color"])
			lienzo.draw_string_outline(fuente, punto + Vector2(-2, -3), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 5, Color(0, 0, 0, 0.75))
			lienzo.draw_string(fuente, punto + Vector2(-2, -3), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Principal.COLOR_TEXTO)
	var y := 170.0
	for reciente in recientes:
		var alfa := clampf(reciente.vida / 0.5, 0.0, 1.0)
		var marco := Rect2(Vector2(20, y), Vector2(52, 52))
		lienzo.draw_rect(Rect2(Vector2(14, y - 6), Vector2(360, 64)), Color(0.05, 0.16, 0.2, 0.75 * alfa))
		if reciente.objeto != "" or reciente.material != "":
			var dibujo := Objetos.icono(reciente.objeto) if reciente.objeto != "" else Objetos.icono_mejora(reciente.material)
			lienzo.draw_rect(marco.grow(2.0), Color(reciente.color, alfa))
			lienzo.draw_texture_rect(dibujo, marco, false, Color(1, 1, 1, alfa))
		else:
			lienzo.draw_circle(marco.get_center(), 20.0, Color(0, 0, 0, alfa))
			lienzo.draw_circle(marco.get_center(), 17.0, Color(MUNICIONES[reciente.municion]["color"], alfa))
		lienzo.draw_string_outline(fuente, Vector2(84, y + 33), reciente.texto, HORIZONTAL_ALIGNMENT_LEFT, 284, 18, 4, Color(0, 0, 0, 0.7 * alfa))
		lienzo.draw_string(fuente, Vector2(84, y + 33), reciente.texto, HORIZONTAL_ALIGNMENT_LEFT, 284, 18, Color(reciente.color, alfa))
		y += 70.0


func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	for asentamiento in asentamientos:
		if not mundo.en_mapa(asentamiento.pos):
			continue
		var punto: Vector2 = centro + asentamiento.pos * escala
		var casa := PackedVector2Array([punto + Vector2(0, -6), punto + Vector2(5, -1), punto + Vector2(5, 5), punto + Vector2(-5, 5), punto + Vector2(-5, -1)])
		lienzo.draw_colored_polygon(casa, COLOR_MERCADO)
		casa.append(casa[0])
		lienzo.draw_polyline(casa, Color("08161c"), 1.0, true)


# Flecha dorada en el bisel hacia el mercado más cercano si queda fuera del radar.
func dibujar_brujula(lienzo: Control, centro: Vector2, exterior: float, interior: float) -> void:
	var jugador := mundo.jugador
	if jugador == null or not jugador.viva:
		return
	var mejor: Asentamiento = null
	var menor := INF
	for asentamiento in asentamientos:
		var d := jugador.pos.distance_to(asentamiento.pos)
		if d < menor:
			menor = d
			mejor = asentamiento
	if mejor == null or mundo.en_mapa(mejor.pos):
		return
	var direccion := (mejor.pos - jugador.pos).normalized()
	var lado := direccion.orthogonal()
	var base := centro + direccion * (interior + 2.0)
	var punta := centro + direccion * (exterior + 4.0)
	var flecha := PackedVector2Array([punta, base + lado * 5.0, base - direccion * 2.0, base - lado * 5.0])
	lienzo.draw_colored_polygon(flecha, COLOR_MERCADO)
	flecha.append(flecha[0])
	lienzo.draw_polyline(flecha, Color("08161c"), 1.5, true)
