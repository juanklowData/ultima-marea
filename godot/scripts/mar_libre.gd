class_name MarLibre
extends Node

# Modo libre: un mar enorme con la tormenta quieta en el borde. Islas, bases y puertos salen
# de una semilla común (el mismo mar para todos los capitanes) repartidos por celdas, y solo
# existen las celdas cercanas al barco. Capitanes, piratas y peligros viven en un círculo
# activo alrededor del jugador: los que se quedan atrás reaparecen por delante.

const RADIO := 30000.0
const SEMILLA := 1847
const CELDA := 1600.0
# Celdas cargadas alrededor de la del barco y a partir de cuántas se descargan.
const CARGA := 2
const DESCARGA := 3
# Tiempo por fotograma para construir islas pendientes (microsegundos).
const PRESUPUESTO := 5000
const MARGEN_CELDA := 170.0
const SEPARACION := 110.0
const ACTIVO := 2600.0
const CAPITANES := 5
const PIRATAS := 3
# Segundos que tarda en volver a salir un bot hundido.
const ESPERA_BOT := 45.0
const BUSCADOS := 0.2
const RECOMPENSA_PIRATA := 6
const RECOMPENSA_BUSCADO := 20
const PROB_BASE := 0.45
const PROB_PUERTO := 0.22
const PROB_ASENTAMIENTO := 0.35
const OCUPADAS := 0.35
const RADIO_BASE := 44.0
const ALCANCE_BASE := 170.0
# Alrededor de tu base el mar está tranquilo (sin bots, tiburones, krakens ni remolinos)
# salvo en una incursión pirata de vez en cuando.
const ZONA_TRANQUILA := 1000.0
const ZONA_MERCADO := 450.0
const ESPERA_INCURSION := Vector2(240.0, 360.0)
const DURACION_INCURSION := 60.0
const COMISION_PUERTO := 0.2
const RENTA_SEGUNDOS := 90.0
const RENTA_MAX := 30
const CURA_BASE := 14.0
const ALCANCE_FUERTE := 270.0
# Fuertes de otros capitanes: vida, segundos sin daño antes de repararse y cuánto por segundo.
const VIDA_FUERTE := 320.0
const CALMA_FUERTE := 20.0
const REPARACION_FUERTE := 6.0
const BOTIN_FUERTE := 25
const RECARGA_FUERTE := 2.6
const RADAR := 2200.0
const ESPERA_REAPARICION := 3.5
const GUARDADO_AUTOMATICO := 20.0
const TABLAS := 20
const RUTA := "user://mar_libre.cfg"
const COLOR_MIA := Color("3dde7a")
const COLOR_LIBRE := Color("f3ecdf")
const COLOR_AJENA := Color("e2463d")
const COLOR_PIEDRA := Color("a19c90")
const COLOR_TEJADO := Color("7a3b2e")


class Celda:
	var clave := Vector2i.ZERO
	var islas: Array[Circulo] = []
	var nodos: Array[Node3D] = []
	var bases: Array[Base] = []
	var puertos: Array = []
	var orillas: Array[ShaderMaterial] = []
	var asentamientos: Array = []


class Base:
	var id := ""
	var pos := Vector2.ZERO
	var dueno := ""
	var isla: Circulo
	var nodo: Node3D
	var bandera: StandardMaterial3D
	var faro: StandardMaterial3D
	var trapo: Node3D
	var fase := 0.0
	var recarga := 0.0
	var vida := VIDA_FUERTE
	var golpeado := 0.0


var mundo: Principal
var celdas := {}
# Encargos de construcción: [celda, tipo, datos, semilla].
var pendientes: Array = []
var celda_actual := Vector2i(999999, 999999)
var espera_poblar := 0.0
var espera_reciclar := 0.0
var espera_guardar := GUARDADO_AUTOMATICO
var hundido_hace := -1.0
var boton_base: Button
var aviso := ""
var aviso_vida := 0.0
var aviso_color := Color.WHITE
var materiales := {}
var cilindro: CylinderMesh
var caja: BoxMesh
var cono: CylinderMesh

# Lo que se guarda entre sesiones: la base propia, su renta y dónde quedó el barco.
var base_id := ""
var base_pos := Vector2.INF
var esperas_bot := {}
var espera_incursion := ESPERA_INCURSION.x
var incursion := 0.0
var base_desde := 0.0
var pos_guardada := Vector2.INF
var botin_guardado := 0
var tesoros_guardados: Array[String] = []


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	cilindro = CylinderMesh.new()
	cilindro.top_radius = 0.5
	cilindro.bottom_radius = 0.5
	cilindro.height = 1.0
	cilindro.radial_segments = 14
	caja = BoxMesh.new()
	cono = CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 14
	_cargar()


func crear_interfaz(capa: CanvasLayer) -> void:
	boton_base = mundo.comercio.boton_lugar(_dibujar_boton_base, _reclamar)
	capa.add_child(boton_base)


func _dibujar_boton_base() -> void:
	mundo.comercio.dibujar_boton_lugar(boton_base, Objetos.icono_mejora("fuerte"), tr("Reclamar") if base_id == "" else tr("Mudarte"))


func activo() -> bool:
	return mundo.modo == "libre" and mundo.estado == Principal.Estado.JUGANDO


# Partida

func empezar() -> void:
	vaciar()
	mundo.misiones.vaciar()
	mundo.zona_centro = Vector2.ZERO
	mundo.zona_radio = RADIO
	mundo.zona_desde = RADIO
	_cargar()
	var inicio := pos_guardada
	if inicio == Vector2.INF:
		inicio = _junto_a_base() if base_id != "" else Vector2.from_angle(randf() * TAU) * randf_range(0.1, 0.6) * RADIO
	_mover_celdas(inicio, 1)
	inicio = _mar_abierto(inicio)
	var jugador := mundo._crear_barco(mundo.personalizacion, true, inicio)
	jugador.nombre = mundo.personalizacion.nombre_visible()
	jugador.botin = botin_guardado
	mundo.jugador = jugador
	mundo.comercio.aplicar_mejoras(jugador)
	for tipo in tesoros_guardados:
		mundo.tesoros.cargar(jugador, tipo)
	mundo.peligros.reiniciar()
	var nombres := mundo._nombres_bots(CAPITANES)
	for i in CAPITANES + PIRATAS:
		var bot := mundo._crear_barco(Personalizacion.al_azar(), false, Vector2.ZERO)
		bot.es_bot = true
		_reaparecer_bot(bot, i >= CAPITANES)
		if i < CAPITANES:
			bot.nombre = nombres[i]
	mundo.peligros.apartar_krakens()
	for _i in TABLAS:
		mundo._soltar_tabla()
	mundo.tiburones.reiniciar()
	mundo.barriles.reiniciar()
	mundo.misiones.poner_gemas()
	mundo.comercio.empezar()
	mundo.niebla.empezar()
	espera_incursion = randf_range(ESPERA_INCURSION.x, ESPERA_INCURSION.y)
	incursion = 0.0
	hundido_hace = -1.0
	espera_guardar = GUARDADO_AUTOMATICO


func vaciar() -> void:
	for clave in celdas.keys():
		_descargar(celdas[clave])
	celdas.clear()
	pendientes.clear()
	celda_actual = Vector2i(999999, 999999)
	aviso_vida = 0.0
	if boton_base != null:
		boton_base.visible = false


func actualizar(delta: float) -> void:
	var jugador := mundo.jugador
	_mover_celdas(jugador.pos, CARGA)
	_construir_pendientes()
	espera_poblar -= delta
	if espera_poblar <= 0.0:
		espera_poblar = 0.5
		_poblar()
	espera_reciclar -= delta
	if espera_reciclar <= 0.0:
		espera_reciclar = 1.0
		_reciclar()
	for celda in celdas.values():
		for base in celda.bases:
			_defender(base, delta)
	aviso_vida = maxf(0.0, aviso_vida - delta)
	_vigilar_incursion(delta)
	mundo.comercio.actualizar(delta)
	mundo.persecucion.actualizar(delta)
	mundo.niebla.actualizar(delta)
	mundo.recompensas.actualizar(delta)
	if not jugador.viva:
		boton_base.visible = false
		hundido_hace += delta
		if hundido_hace >= ESPERA_REAPARICION:
			_reaparecer_jugador()
		return
	hundido_hace = 0.0
	_visitar(delta)
	espera_guardar -= delta
	if espera_guardar <= 0.0:
		espera_guardar = GUARDADO_AUTOMATICO
		guardar()


func salir() -> void:
	guardar()
	mundo.personalizacion.guardar()


# Celdas: carga y descarga según por dónde navega el barco

func _clave(punto: Vector2) -> Vector2i:
	return Vector2i(floori(punto.x / CELDA), floori(punto.y / CELDA))


# alcance: celdas alrededor que se cargan; con 1 se construyen al momento (al zarpar).
func _mover_celdas(punto: Vector2, alcance: int) -> void:
	var centro := _clave(punto)
	if centro == celda_actual and alcance == CARGA:
		return
	celda_actual = centro
	for clave in celdas.keys():
		if maxi(absi(clave.x - centro.x), absi(clave.y - centro.y)) > DESCARGA:
			_descargar(celdas[clave])
			celdas.erase(clave)
	for dx in range(-CARGA, CARGA + 1):
		for dy in range(-CARGA, CARGA + 1):
			var clave := centro + Vector2i(dx, dy)
			if not celdas.has(clave) and _celda_en_mar(clave):
				_planear(clave)
	if alcance < CARGA:
		pendientes.sort_custom(func(a: Array, b: Array) -> bool:
			return (a[0].clave - centro).length_squared() < (b[0].clave - centro).length_squared())
		while not pendientes.is_empty() and maxi(absi(pendientes[0][0].clave.x - centro.x), absi(pendientes[0][0].clave.y - centro.y)) <= alcance:
			_construir(pendientes.pop_front())
		randomize()


func _celda_en_mar(clave: Vector2i) -> bool:
	var centro := (Vector2(clave) + Vector2(0.5, 0.5)) * CELDA
	return centro.length() < RADIO + CELDA


# Reparte la celda con su propio generador: siempre sale igual para la misma clave.
func _planear(clave: Vector2i) -> void:
	var celda := Celda.new()
	celda.clave = clave
	celdas[clave] = celda
	var azar := RandomNumberGenerator.new()
	azar.seed = hash([SEMILLA, clave.x, clave.y])
	var ocupado: Array = []
	var origen := Vector2(clave) * CELDA
	var orden := 0
	if azar.randf() < PROB_BASE:
		var sitio := _sitio(azar, origen, ocupado, RADIO_BASE * 1.15 + 90.0)
		if sitio != Vector2.INF:
			var base := Base.new()
			base.id = "%d_%d" % [clave.x, clave.y]
			base.pos = sitio
			if base.id == base_id:
				base.dueno = mundo.personalizacion.nombre_visible()
			elif azar.randf() < OCUPADAS:
				base.dueno = "%s %s" % [Principal.TITULOS_PIRATAS[azar.randi() % Principal.TITULOS_PIRATAS.size()], Principal.NOMBRES_SUELTOS[azar.randi() % Principal.NOMBRES_SUELTOS.size()]]
			pendientes.append([celda, "base", base, hash([SEMILLA, clave.x, clave.y, orden])])
			orden += 1
	if azar.randf() < PROB_PUERTO:
		var sitio := _sitio(azar, origen, ocupado, Misiones.RADIO_PUERTO + 160.0)
		if sitio != Vector2.INF:
			pendientes.append([celda, "puerto", sitio, hash([SEMILLA, clave.x, clave.y, orden])])
			orden += 1
	var tandas := [[azar.randi_range(1, 2), 58.0, 92.0], [azar.randi_range(1, 2), 44.0, 56.0], [azar.randi_range(0, 2), 38.0, 46.0], [azar.randi_range(2, 4), 22.0, 34.0]]
	for tanda in tandas:
		for _i in tanda[0]:
			var radio := azar.randf_range(tanda[1], tanda[2])
			var sitio := _sitio(azar, origen, ocupado, radio + SEPARACION * 0.5)
			if sitio != Vector2.INF:
				pendientes.append([celda, "isla" if radio > Islas.RADIO_ROCAS else "roca", [sitio, radio], hash([SEMILLA, clave.x, clave.y, orden])])
				orden += 1
	# Va después de las islas para no cambiar el reparto que ya tenían las celdas.
	if azar.randf() < PROB_ASENTAMIENTO:
		var sitio := _sitio(azar, origen, ocupado, Comercio.RADIO_ASENTAMIENTO + 150.0)
		if sitio != Vector2.INF:
			var nombre: String = Comercio.NOMBRES_ASENTAMIENTO[azar.randi() % Comercio.NOMBRES_ASENTAMIENTO.size()]
			var favorita: String = Objetos.CATEGORIAS.keys()[azar.randi() % Objetos.CATEGORIAS.size()]
			pendientes.append([celda, "asentamiento", [sitio, nombre, favorita], hash([SEMILLA, clave.x, clave.y, orden])])


func _sitio(azar: RandomNumberGenerator, origen: Vector2, ocupado: Array, radio: float) -> Vector2:
	for _intento in 25:
		var punto := origen + Vector2(azar.randf_range(MARGEN_CELDA, CELDA - MARGEN_CELDA), azar.randf_range(MARGEN_CELDA, CELDA - MARGEN_CELDA))
		if punto.length() > RADIO * 0.97 - radio:
			continue
		var libre := true
		for otro in ocupado:
			if punto.distance_to(otro[0]) < otro[1] + radio + SEPARACION * 0.5:
				libre = false
				break
		if libre:
			ocupado.append([punto, radio])
			return punto
	return Vector2.INF


func _construir_pendientes() -> void:
	if pendientes.is_empty():
		return
	var inicio := Time.get_ticks_usec()
	var centro := celda_actual
	while not pendientes.is_empty() and Time.get_ticks_usec() - inicio < PRESUPUESTO:
		var mejor := 0
		var menor := 999999
		for i in pendientes.size():
			var d: int = (pendientes[i][0].clave - centro).length_squared()
			if d < menor:
				menor = d
				mejor = i
		_construir(pendientes.pop_at(mejor))
	randomize()


# Cada pieza se construye con su propia semilla: las mismas palmeras, rocas y forma de costa
# para todos.
func _construir(encargo: Array) -> void:
	var celda: Celda = encargo[0]
	if not celdas.has(celda.clave) or celdas[celda.clave] != celda:
		return
	seed(encargo[3])
	var islas := mundo.islas
	var antes := islas.materiales_orilla.size()
	match encargo[1]:
		"isla", "roca":
			var datos: Array = encargo[2]
			var isla := Circulo.new(datos[0], datos[1])
			var nodo: Node3D
			if encargo[1] == "roca":
				nodo = islas._crear_rocas(isla)
			else:
				isla.radio *= 1.15
				isla.dar_forma()
				nodo = islas._crear_isla(isla)
			islas.add_child(nodo)
			islas.islotes.append(isla)
			celda.islas.append(isla)
			celda.nodos.append(nodo)
		"base":
			var base: Base = encargo[2]
			base.isla = Circulo.new(base.pos, RADIO_BASE * 1.15)
			base.nodo = _crear_base(base)
			islas.add_child(base.nodo)
			islas.islotes.append(base.isla)
			_adornar(base)
			celda.islas.append(base.isla)
			celda.nodos.append(base.nodo)
			celda.bases.append(base)
		"puerto":
			celda.puertos.append(mundo.misiones.crear_puerto(encargo[2]))
		"asentamiento":
			var asentamiento := mundo.comercio.crear_asentamiento(encargo[2])
			islas.add_child(asentamiento.nodo)
			islas.islotes.append(asentamiento.isla)
			celda.islas.append(asentamiento.isla)
			celda.nodos.append(asentamiento.nodo)
			celda.asentamientos.append(asentamiento)
	for i in range(antes, islas.materiales_orilla.size()):
		celda.orillas.append(islas.materiales_orilla[i])


func _descargar(celda: Celda) -> void:
	var islas := mundo.islas
	for isla in celda.islas:
		islas.islotes.erase(isla)
	for nodo in celda.nodos:
		mundo.fauna.olvidar(nodo)
		if is_instance_valid(nodo):
			nodo.queue_free()
	for materia in celda.orillas:
		islas.materiales_orilla.erase(materia)
	for puerto in celda.puertos:
		mundo.misiones.quitar_puerto(puerto)
	for asentamiento in celda.asentamientos:
		mundo.comercio.quitar_asentamiento(asentamiento)
	pendientes = pendientes.filter(func(encargo: Array) -> bool: return encargo[0] != celda)


# Bases: islotes con un fuerte que un capitán puede reclamar si está libre

# Islote redondo con un fuerte de piedra: muralla almenada, cuatro torres, torreón con la
# bandera del dueño, dos cañones y un embarcadero.
func _crear_base(base: Base) -> Node3D:
	var islas := mundo.islas
	var nodo := Node3D.new()
	nodo.position = mundo.a_3d(base.pos)
	var r := base.isla.radio * Principal.ESCALA
	base.fase = randf() * TAU
	islas._malla(nodo, islas._arena(r, base.isla), Islas.COLOR_ARENA, Vector3.ZERO)
	nodo.add_child(islas._orilla(r * 1.15))
	islas._fondo(nodo, r, base.isla, int(10 + r * 2.5))
	nodo.set_meta("radio", r)

	var fuerte := Node3D.new()
	fuerte.rotation.y = randf() * TAU
	nodo.add_child(fuerte)
	var piedra := mundo.material(COLOR_PIEDRA, "roca")
	var oscura := mundo.material(COLOR_PIEDRA.darkened(0.25), "roca")
	var madera := mundo.material(Color("7a5434"), "madera")
	var tejado := mundo.material(COLOR_TEJADO)
	var radio_muro := r * 0.62
	_pieza(fuerte, cilindro, oscura, Vector3(0, 0.55, 0), Vector3(radio_muro * 2.1, 0.22, radio_muro * 2.1))
	var lados := 8
	for k in lados:
		var a := TAU * (k + 0.5) / lados
		var tramo := 2.0 * radio_muro * sin(PI / lados)
		var centro := Vector3(cos(a), 0.0, sin(a)) * radio_muro * cos(PI / lados)
		var muro := _pieza(fuerte, caja, piedra, centro + Vector3(0, 0.9, 0), Vector3(tramo, 0.55, 0.2))
		muro.rotation.y = -a + PI / 2.0
		for m in 3:
			_pieza(muro, caja, piedra, Vector3((m - 1) * 0.33, 0.7, 0), Vector3(0.16 / tramo, 0.4, 1.0))
	for k in 4:
		var a := TAU * k / 4.0
		var sitio := Vector3(cos(a), 0.0, sin(a)) * radio_muro
		_pieza(fuerte, cilindro, piedra, sitio + Vector3(0, 1.05, 0), Vector3(0.5, 1.0, 0.5))
		_pieza(fuerte, cono, tejado, sitio + Vector3(0, 1.85, 0), Vector3(0.62, 0.6, 0.62))
	_pieza(fuerte, caja, piedra, Vector3(0, 1.15, 0), Vector3(0.9, 1.1, 0.9))
	_pieza(fuerte, caja, oscura, Vector3(0, 1.75, 0), Vector3(1.0, 0.12, 1.0))
	for k in 4:
		var a := TAU * k / 4.0
		_pieza(fuerte, caja, piedra, Vector3(cos(a), 0.0, sin(a)) * 0.4 + Vector3(0, 1.9, 0), Vector3(0.18, 0.2, 0.18))
	base.faro = StandardMaterial3D.new()
	base.faro.emission_enabled = true
	_pieza(fuerte, cilindro, base.faro, Vector3(0, 2.0, 0), Vector3(0.22, 0.2, 0.22))
	_pieza(fuerte, cilindro, madera, Vector3(0, 2.9, 0), Vector3(0.06, 2.0, 0.06))
	base.trapo = Node3D.new()
	base.trapo.position = Vector3(0, 3.55, 0)
	fuerte.add_child(base.trapo)
	base.bandera = StandardMaterial3D.new()
	base.bandera.cull_mode = BaseMaterial3D.CULL_DISABLED
	_pieza(base.trapo, caja, base.bandera, Vector3(0.38, 0, 0), Vector3(0.7, 0.42, 0.03))
	var hierro := mundo.material(Color("26292c"))
	for k: int in [1, 3, 5, 7]:
		var a: float = TAU * (k + 0.5) / lados
		var afuera := Vector3(cos(a), 0.0, sin(a))
		var costado := afuera.cross(Vector3.UP).normalized()
		var canon := _pieza(fuerte, cilindro, hierro, afuera * (radio_muro + 0.12) + Vector3(0, 1.3, 0), Vector3.ONE)
		canon.basis = Basis(costado * 0.14, afuera * 0.7, costado.cross(afuera) * 0.14)
	var muelle := Node3D.new()
	muelle.rotation.y = randf() * TAU
	nodo.add_child(muelle)
	for k in 5:
		_pieza(muelle, caja, madera, Vector3(r * 0.85 + k * 0.32, 0.42, 0), Vector3(0.3, 0.08, 0.9))
	for lado in [-1.0, 1.0]:
		_pieza(muelle, cilindro, madera, Vector3(r * 0.85 + 1.4, 0.2, lado * 0.4), Vector3(0.1, 0.8, 0.1))
	_pintar_base(base)
	return nodo


func _pieza(padre: Node3D, malla: Mesh, materia: Material, pos: Vector3, escala: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = materia
	pieza.position = pos
	pieza.scale = escala
	padre.add_child(pieza)
	return pieza


# Lo que se ve de las mejoras de tu base: chozas de la taberna, cañones de las baterías y
# pilas de balas del arsenal, uno más por nivel. Las demás bases quedan sin adornos.
func adornar_base() -> void:
	var base := _mi_base()
	if base != null:
		_adornar(base)


func _adornar(base: Base) -> void:
	if base.nodo == null:
		return
	var viejo := base.nodo.get_node_or_null("Mejoras")
	if viejo != null:
		base.nodo.remove_child(viejo)
		viejo.queue_free()
	if base.id != base_id:
		return
	var adornos := Node3D.new()
	adornos.name = "Mejoras"
	base.nodo.add_child(adornos)
	var r: float = base.nodo.get_meta("radio")
	var niveles: Dictionary = mundo.comercio.mejoras_base
	var madera := mundo.material(Color("8a5d36"), "madera")
	var paja := mundo.material(Color("c9a45a"))
	var hierro := mundo.material(Color("26292c"))
	for k: int in int(niveles["taberna"]):
		var a := 0.6 + k * 0.55
		var sitio := Vector3(cos(a), 0.0, sin(a)) * r * 0.88
		_pieza(adornos, caja, madera, sitio + Vector3(0, 0.35, 0), Vector3(0.55, 0.5, 0.45))
		_pieza(adornos, cono, paja, sitio + Vector3(0, 0.8, 0), Vector3(0.7, 0.45, 0.6))
	for k: int in int(niveles["baterias"]):
		var a := 2.6 + k * 0.5
		var afuera := Vector3(cos(a), 0.0, sin(a))
		var sitio := afuera * r * 0.9
		_pieza(adornos, caja, madera, sitio + Vector3(0, 0.25, 0), Vector3(0.45, 0.2, 0.45))
		var costado := afuera.cross(Vector3.UP).normalized()
		var canon := _pieza(adornos, cilindro, hierro, sitio + afuera * 0.2 + Vector3(0, 0.45, 0), Vector3.ONE)
		canon.basis = Basis(costado * 0.16, afuera * 0.75, costado.cross(afuera) * 0.16)
	for k: int in int(niveles["arsenal"]):
		var a := 4.4 + k * 0.5
		var sitio := Vector3(cos(a), 0.0, sin(a)) * r * 0.86
		for b in 4:
			var lado := Vector3(0.0, 0.46, 0.0) if b == 3 else Vector3(cos(b * TAU / 3.0), 0.0, sin(b * TAU / 3.0)) * 0.14 + Vector3(0, 0.3, 0)
			_pieza(adornos, mundo.malla_humo, hierro, sitio + lado, Vector3.ONE * 0.5)


func _pintar_base(base: Base) -> void:
	var color := _color_base(base)
	base.bandera.albedo_color = color
	base.faro.albedo_color = color
	base.faro.emission = color
	base.faro.emission_energy_multiplier = 1.4 if base.id == base_id else 0.5


func _color_base(base: Base) -> Color:
	if base.id == base_id:
		return COLOR_MIA
	return COLOR_LIBRE if base.dueno == "" else COLOR_AJENA


func _base_cercana(punto: Vector2, alcance: float) -> Base:
	var mejor: Base = null
	var menor := alcance
	for celda in celdas.values():
		for base in celda.bases:
			var d: float = punto.distance_to(base.pos)
			if d < menor:
				menor = d
				mejor = base
	return mejor


func _mi_base() -> Base:
	for celda in celdas.values():
		for base in celda.bases:
			if base.id == base_id:
				return base
	return null


func _reclamar() -> void:
	var jugador := mundo.jugador
	var base := _base_cercana(jugador.pos, ALCANCE_BASE)
	if base == null or base.dueno != "" or not jugador.viva:
		return
	var vieja := _mi_base()
	if vieja != null:
		vieja.dueno = ""
		_pintar_base(vieja)
		_adornar(vieja)
	base_id = base.id
	base_pos = base.pos
	base_desde = Time.get_unix_time_from_system()
	base.dueno = mundo.personalizacion.nombre_visible()
	base.vida = VIDA_FUERTE
	_pintar_base(base)
	_adornar(base)
	guardar()
	mundo.voz_equipar.play()
	_anunciar(tr("¡Base reclamada! Aquí reapareces y guardas tu botín"), COLOR_MIA)


# Al pasar por la base propia se guarda el botín, se repara el barco y se cobra la renta;
# en un puerto flotante también se guarda, pero el puerto se queda una comisión.
func _visitar(delta: float) -> void:
	var jugador := mundo.jugador
	var cerca := _base_cercana(jugador.pos, ALCANCE_BASE)
	boton_base.visible = cerca != null and cerca.dueno == "" and not mundo.panel_partida.visible \
			and not mundo.comercio.boton_comerciar.visible and not mundo.comercio.panel.visible
	if boton_base.visible:
		boton_base.queue_redraw()
	if cerca != null and cerca.id == base_id:
		var arsenal: int = mundo.comercio.mejoras_base["arsenal"]
		if jugador.vida < jugador.vida_max:
			jugador.vida = minf(jugador.vida_max, jugador.vida + CURA_BASE * (1.0 + 0.5 * arsenal) * delta)
		var reserva := Comercio.MUNICION_MINIMA + 15 * arsenal
		if arsenal > 0 and mundo.comercio.municion["hierro"] < reserva:
			if reserva - mundo.comercio.municion["hierro"] >= 10:
				_anunciar(tr("Arsenal: balas de hierro repuestas"), COLOR_MIA)
			mundo.comercio.municion["hierro"] = reserva
		var renta := _renta()
		if renta > 0:
			base_desde += renta * RENTA_SEGUNDOS
			renta *= 1 + mundo.comercio.mejoras_base["taberna"]
			mundo.personalizacion.monedas += renta
			mundo.avisar_premio(cerca.nodo.position + Vector3(0, 4.0, 0), tr("+%d de renta") % renta, COLOR_MIA)
			_guardar_todo()
		mundo.tesoros.vender_jugador()
		if jugador.botin > 0:
			var botin := jugador.botin
			jugador.botin = 0
			mundo.personalizacion.monedas += botin
			mundo._pintar_botin()
			mundo.voz_monedas.play()
			_anunciar(tr("Botín guardado en tu base: +%d monedas") % botin, Principal.COLOR_ORO)
			_guardar_todo()
		return
	if jugador.botin <= 0:
		return
	for puerto in mundo.misiones.puertos:
		if jugador.pos.distance_to(puerto.pos) < Misiones.ALCANCE_PUERTO:
			var botin := jugador.botin
			var comision := ceili(botin * COMISION_PUERTO)
			jugador.botin = 0
			mundo.personalizacion.monedas += botin - comision
			mundo._pintar_botin()
			mundo.voz_monedas.play()
			_anunciar(tr("Botín guardado en el puerto: +%d (comisión %d)") % [botin - comision, comision], Principal.COLOR_ORO)
			_guardar_todo()
			return


func _renta() -> int:
	if base_id == "":
		return 0
	var pasado := Time.get_unix_time_from_system() - base_desde
	if pasado >= RENTA_SEGUNDOS * RENTA_MAX:
		base_desde = Time.get_unix_time_from_system() - RENTA_SEGUNDOS * RENTA_MAX
	return clampi(floori(pasado / RENTA_SEGUNDOS), 0, RENTA_MAX)


# Tu fuerte dispara a los piratas, a los cazadores y a quien te haya atacado hace poco (más
# rápido y más lejos con las baterías mejoradas). Los fuertes de otros capitanes disparan
# a tu barco: se pueden asediar hasta que se rinden y quedan libres para tomarlos.
func _defender(base: Base, delta: float) -> void:
	if base.dueno == "" or base.nodo == null:
		return
	var mia := base.id == base_id
	if not mia and base.vida < VIDA_FUERTE:
		base.golpeado += delta
		if base.golpeado > CALMA_FUERTE:
			base.vida = minf(VIDA_FUERTE, base.vida + REPARACION_FUERTE * delta)
	base.recarga = maxf(0.0, base.recarga - delta)
	if base.recarga > 0.0:
		return
	var jugador := mundo.jugador
	var baterias: int = mundo.comercio.mejoras_base["baterias"] if mia else 0
	var alcance := ALCANCE_FUERTE * (1.0 + 0.15 * baterias)
	var atacante: Barco = null
	if mia and jugador.ultimo_atacante != null and Time.get_ticks_msec() - jugador.hora_ataque < 10000:
		atacante = jugador.ultimo_atacante
	var blanco: Barco = null
	var menor := alcance + 60.0
	for barco in mundo.barcos:
		if not barco.viva:
			continue
		if mia and not barco.es_pirata and barco != atacante and not (baterias > 0 and barco.cazador):
			continue
		if not mia and barco != jugador:
			continue
		var d := barco.pos.distance_to(base.pos)
		if d < menor:
			menor = d
			blanco = barco
	if blanco == null:
		return
	base.recarga = RECARGA_FUERTE / (1.0 + 0.35 * baterias) if mia else RECARGA_FUERTE * 0.9
	var salida := base.pos + (blanco.pos - base.pos).normalized() * base.isla.radio * 0.7
	var previsto := blanco.pos + blanco.proa() * blanco.velocidad * salida.distance_to(blanco.pos) / Principal.VEL_BALA * 0.85
	mundo.disparar_desde(salida, (previsto - salida).normalized(), jugador if mia else null, base.isla)


# Bala que da contra una isla: si es un fuerte ajeno y la disparó el jugador, lo daña.
func golpear_isla(isla: Circulo, dueno: Barco, danio: float) -> void:
	if dueno != mundo.jugador:
		return
	for celda in celdas.values():
		for base in celda.bases:
			if base.isla != isla or base.dueno == "" or base.id == base_id:
				continue
			base.vida -= danio
			base.golpeado = 0.0
			mundo.persecucion.golpe_fuerte()
			mundo.avisar_combate()
			if base.vida <= 0.0:
				_rendir(base)
			return


# El fuerte se rinde: queda libre (se puede tomar como base) y suelta su botín en la orilla.
func _rendir(base: Base) -> void:
	base.vida = 0.0
	base.dueno = ""
	_pintar_base(base)
	var jugador := mundo.jugador
	var orilla := base.pos + (jugador.pos - base.pos).normalized() * (base.isla.radio + 40.0)
	var botin: Array[String] = [Objetos.de_rareza(1), Objetos.de_rareza(1), Objetos.de_rareza(2)]
	mundo.comercio.soltar_botin(orilla, botin, {"madera": 12, "metal": 8, "tela": 5})
	mundo.soltar_cofre(orilla + Vector2(30, 0), BOTIN_FUERTE)
	mundo.persecucion.fuerte_rendido()
	var centro := base.nodo.position + Vector3(0, 1.5, 0)
	for _i in 10:
		var vel := Vector3(randf_range(-0.8, 0.8), randf_range(1.0, 2.0), randf_range(-0.8, 0.8))
		mundo.crear_efecto(mundo.malla_humo, Color(0.25, 0.23, 0.22, 0.75), centro + vel * 0.4, vel, randf_range(2.0, 3.0), 1.0, 2.5, 0.0, true)
	mundo.sonar_explosion(centro)
	_anunciar(tr("¡Fuerte rendido! Recoge su botín y tómalo como tu base"), COLOR_MIA)


# Población: capitanes y piratas alrededor del jugador

func _poblar() -> void:
	var jugador := mundo.jugador
	for barco in mundo.barcos:
		if barco == jugador or barco.cazador or barco.legendario or barco.fantasma:
			continue
		var lejos := barco.pos.distance_to(jugador.pos) > ACTIVO * 1.25
		var hundido := not barco.viva and (barco.hundimiento >= 1.0 or not barco.visible)
		if hundido and not lejos:
			var id := barco.get_instance_id()
			esperas_bot[id] = esperas_bot.get(id, ESPERA_BOT) - 0.5
			if esperas_bot[id] > 0.0:
				continue
			esperas_bot.erase(id)
		if lejos or hundido:
			_reaparecer_bot(barco, barco.es_pirata)


func _reaparecer_bot(barco: Barco, pirata: bool) -> void:
	barco.objetivo = ""
	var aspecto := Personalizacion.al_azar()
	if pirata:
		aspecto.elegidos["velas"] = "pirata"
		aspecto.elegidos["bandera"] = "jolly_roger"
		aspecto.elegidos["casco"] = ["corsario", "fantasma", "ebano"].pick_random()
	barco.vestir(aspecto)
	mundo.tesoros.quitar(barco)
	barco.viva = true
	barco.hundimiento = 0.0
	barco.velocidad = 0.0
	barco.ultimo_atacante = null
	barco.destino_libre = Vector2.INF
	barco.es_pirata = pirata
	barco.agresivo = pirata or randf() < 0.3
	barco.pos = _punto_aparicion()
	barco.rumbo = randf_range(-PI, PI)
	if pirata:
		var buscado := randf() < BUSCADOS
		barco.recompensa = RECOMPENSA_BUSCADO if buscado else RECOMPENSA_PIRATA
		var suelto: String = Principal.NOMBRES_SUELTOS.pick_random()
		barco.nombre = tr("Buscado: %s") % suelto if buscado else tr("Pirata %s") % suelto
		barco.botin = randi_range(2, 6)
		if buscado or randf() < 0.5:
			mundo.tesoros.cargar(barco, "calavera")
		if buscado and randf() < 0.5:
			mundo.tesoros.cargar(barco, "cofre")
	else:
		barco.recompensa = 0
		barco.botin = randi_range(0, Principal.BOTIN_INICIAL_BOTS)
		if randf() < Principal.BOTS_CON_COFRE:
			mundo.tesoros.cargar(barco, "cofre")
	barco.colocar(0.0)


func _punto_aparicion() -> Vector2:
	var jugador := mundo.jugador
	var centro := jugador.pos if jugador != null else Vector2.ZERO
	var punto := centro
	for _intento in 40:
		punto = centro + Vector2.from_angle(randf() * TAU) * randf_range(1300.0, ACTIVO)
		if _libre(punto, 90.0) and punto.length() < RADIO * 0.95 and not tranquila(punto):
			var lejos := true
			for barco in mundo.barcos:
				if barco.viva and barco.pos.distance_to(punto) < 300.0:
					lejos = false
					break
			if lejos:
				return punto
	return punto


func _libre(punto: Vector2, margen: float) -> bool:
	for isla in mundo.islotes:
		if isla.dentro(punto, margen):
			return false
	return true


# El punto más cercano sin tierra ni peligros alrededor.
func _mar_abierto(punto: Vector2) -> Vector2:
	if _libre(punto, 90.0) and not mundo.peligros.cerca(punto, 150.0):
		return punto
	for vuelta in range(1, 30):
		for k in 8:
			var probado := punto + Vector2.from_angle(TAU * k / 8.0) * vuelta * 60.0
			if _libre(probado, 90.0) and not mundo.peligros.cerca(probado, 150.0):
				return probado
	return punto


# Con margen, también cuenta lo que esté a esa distancia del borde (para los que patrullan).
func tranquila(punto: Vector2, margen := 0.0) -> bool:
	if mundo.modo != "libre":
		return false
	if base_id != "" and base_pos != Vector2.INF and incursion <= 0.0 and punto.distance_to(base_pos) < ZONA_TRANQUILA + margen:
		return true
	return _mercado_cerca(punto, margen) != Vector2.INF


# Alrededor de los mercados también hay calma, para comprar y vender sin sustos.
func _mercado_cerca(punto: Vector2, margen := 0.0) -> Vector2:
	for asentamiento in mundo.comercio.asentamientos:
		if punto.distance_to(asentamiento.pos) < ZONA_MERCADO + margen:
			return asentamiento.pos
	return Vector2.INF


# Centro de la zona tranquila en la que cae el punto (un mercado o tu base).
func centro_calma(punto: Vector2, margen := 0.0) -> Vector2:
	var mercado := _mercado_cerca(punto, margen)
	return base_pos if mercado == Vector2.INF else mercado


# De vez en cuando unos piratas vienen a por tu base: durante un rato la zona deja de estar
# tranquila y, si estás en ella, el pirata más cercano pone rumbo hacia ti.
func _vigilar_incursion(delta: float) -> void:
	var peligros := mundo.peligros
	for remolino in peligros.remolinos:
		if remolino.fundido <= 0.0 and tranquila(remolino.pos):
			remolino.fundido = 4.0
	for tornado in peligros.tornados:
		if tranquila(tornado.pos):
			tornado.vida = 0.0
	for ventisca in peligros.ventiscas:
		if tranquila(ventisca.pos):
			var fuera: Vector2 = (ventisca.pos - centro_calma(ventisca.pos)).normalized()
			ventisca.pos += (fuera if fuera != Vector2.ZERO else Vector2.RIGHT) * 60.0 * delta
	if incursion > 0.0:
		incursion -= delta
		return
	espera_incursion -= delta
	if espera_incursion > 0.0 or base_id == "" or base_pos == Vector2.INF:
		return
	espera_incursion = randf_range(ESPERA_INCURSION.x, ESPERA_INCURSION.y)
	var jugador := mundo.jugador
	if not jugador.viva or jugador.pos.distance_to(base_pos) > ZONA_TRANQUILA:
		return
	incursion = DURACION_INCURSION
	var pirata: Barco = null
	var menor := INF
	for barco in mundo.barcos:
		if barco.viva and barco.es_bot and barco.es_pirata and not barco.legendario and barco.pos.distance_to(jugador.pos) < menor:
			menor = barco.pos.distance_to(jugador.pos)
			pirata = barco
	if pirata != null:
		pirata.destino_libre = jugador.pos
		_anunciar(tr("¡Unos piratas se acercan a tu base!"), Principal.COLOR_PELIGRO)


func _junto_a_base() -> Vector2:
	if base_pos == Vector2.INF:
		return Vector2.ZERO
	return base_pos + Vector2.from_angle(randf() * TAU) * (RADIO_BASE * 1.15 + 110.0)


# Los bots navegan de un punto a otro sin rumbo fijo en vez de ir al centro.
func destino_bot(barco: Barco) -> Vector2:
	if barco.fantasma:
		return mundo.niebla.destino(barco)
	if mundo.persecucion.persigue(barco):
		return mundo.jugador.pos
	if barco.destino_libre == Vector2.INF or barco.pos.distance_to(barco.destino_libre) < 150.0 or tranquila(barco.destino_libre):
		barco.destino_libre = Vector2.INF
		for _intento in 10:
			var punto := barco.pos + Vector2.from_angle(randf() * TAU) * randf_range(500.0, 1200.0)
			if punto.length() < RADIO * 0.9 and _libre(punto, 80.0) and not tranquila(punto):
				barco.destino_libre = punto
				break
	return barco.destino_libre if barco.destino_libre != Vector2.INF else barco.pos


# Los piratas atacan a cualquiera que no sea pirata; los capitanes responden a quien les
# dispara, persiguen piratas cercanos y algunos (los agresivos) atacan a quien pase.
func rival_de(barco: Barco) -> Barco:
	if mundo.persecucion.persigue(barco):
		return mundo.jugador
	var atacante := barco.ultimo_atacante
	if atacante != null and atacante.viva and Time.get_ticks_msec() - barco.hora_ataque < 15000 \
			and atacante.pos.distance_to(barco.pos) < 900.0:
		return atacante
	var mejor: Barco = null
	var menor := INF
	for otro in mundo.barcos:
		if otro == barco or not otro.viva or (otro == mundo.jugador and tranquila(otro.pos)):
			continue
		var alcance := 0.0
		if barco.es_pirata:
			alcance = 0.0 if otro.es_pirata else 700.0
		elif otro.es_pirata:
			alcance = 520.0
		elif barco.agresivo:
			alcance = 420.0
		var d := barco.pos.distance_to(otro.pos)
		if d < alcance and d < menor:
			menor = d
			mejor = otro
	return mejor


func al_hundirse(barco: Barco, verdugo: Barco) -> void:
	mundo.persecucion.al_hundir(barco, verdugo)
	mundo.niebla.al_hundir(barco)
	if verdugo != null and verdugo.es_jugador:
		mundo.recompensas.al_hundir(barco)
	if verdugo != null and verdugo.viva and barco.recompensa > 0:
		mundo.ganar_botin(verdugo, barco.recompensa, barco.position + Vector3(0, 3.0, 0))
		if verdugo == mundo.jugador and not barco.legendario:
			_anunciar(tr("¡Recompensa cobrada! +%d monedas") % barco.recompensa, Principal.COLOR_ORO)
	if barco == mundo.jugador:
		mundo.persecucion.al_morir()
		mundo.misiones.cancelar()
		hundido_hace = 0.0


func _reaparecer_jugador() -> void:
	var jugador := mundo.jugador
	var destino := Vector2.INF
	if base_id != "":
		destino = _junto_a_base()
		_mover_celdas(destino, 1)
	else:
		var menor := INF
		for puerto in mundo.misiones.puertos:
			var d: float = puerto.pos.distance_to(jugador.pos)
			if d < menor:
				menor = d
				destino = puerto.pos + Vector2.from_angle(randf() * TAU) * (Misiones.RADIO_PUERTO + 120.0)
		if destino == Vector2.INF:
			destino = jugador.pos + Vector2.from_angle(randf() * TAU) * 700.0
	jugador.vestir(mundo.personalizacion)
	mundo.comercio.aplicar_mejoras(jugador)
	jugador.viva = true
	jugador.hundimiento = 0.0
	jugador.velocidad = 0.0
	jugador.botin = 0
	jugador.ultimo_atacante = null
	jugador.pos = _mar_abierto(destino)
	jugador.colocar(0.0)
	jugador.visible = true
	mundo.foco = jugador.position
	mundo.camara.position = jugador.position + Vector3(0.0, 5.0, 11.0)
	mundo.comercio.al_reaparecer()
	mundo._pintar_botin()
	hundido_hace = -1.0
	_anunciar(tr("Reapareces en tu base") if base_id != "" else tr("Reapareces junto a un puerto"), Principal.COLOR_TEXTO)
	guardar()


# Lo que se queda atrás (peligros, tablas, gemas) reaparece alrededor del barco.
func _reciclar() -> void:
	var centro := mundo.jugador.pos
	var lejos := ACTIVO * 1.2
	var peligros := mundo.peligros
	for remolino in peligros.remolinos:
		if remolino.fundido <= 0.0 and remolino.pos.distance_to(centro) > lejos:
			remolino.pos = peligros._lugar_libre(remolino.radio + 40.0, ACTIVO, 900.0)
	for ventisca in peligros.ventiscas:
		if ventisca.pos.distance_to(centro) > lejos:
			ventisca.pos = peligros._lugar_libre(ventisca.radio, ACTIVO, 600.0)
	for tornado in peligros.tornados:
		if tornado.pos.distance_to(centro) > lejos:
			tornado.vida = 0.0
	for kraken in peligros.krakens:
		if kraken.sumergido > 0.0 or kraken.pos.distance_to(centro) <= lejos:
			continue
		peligros.revivir_kraken(kraken, peligros.lugar_kraken(kraken, ACTIVO))
	var tiburones := mundo.tiburones
	for tiburon in tiburones.tiburones:
		if tiburon.muerte < 0.0 and tiburon.pos.distance_to(centro) > lejos:
			tiburones._revivir(tiburon)
	for barril in mundo.barriles.barriles:
		if not barril.lanzado and barril.espera < 0.0 and barril.mecha < 0.0 and barril.pos.distance_to(centro) > lejos:
			barril.pos = mundo.barriles._lugar_libre()
	for tabla in mundo.tablas:
		if not tabla.de_restos and tabla.pos.distance_to(centro) > lejos:
			tabla.pos = _punto_aparicion()
	var misiones := mundo.misiones
	for cofre in misiones.cofres:
		if cofre.pos.distance_to(centro) > lejos:
			cofre.pos = misiones._lugar_libre(centro, 900.0, ACTIVO, 800.0)


# Guardado

func _cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA) != OK:
		return
	base_id = archivo.get_value("base", "id", "")
	base_pos = archivo.get_value("base", "pos", Vector2.INF)
	base_desde = archivo.get_value("base", "desde", Time.get_unix_time_from_system())
	pos_guardada = archivo.get_value("barco", "pos", Vector2.INF)
	botin_guardado = archivo.get_value("barco", "botin", 0)
	tesoros_guardados.clear()
	for tipo in archivo.get_value("barco", "tesoros", []):
		if Tesoros.TIPOS.has(str(tipo)):
			tesoros_guardados.append(str(tipo))


func guardar() -> void:
	var jugador := mundo.jugador
	if jugador != null and mundo.modo == "libre":
		pos_guardada = jugador.pos if jugador.viva else Vector2.INF
		botin_guardado = jugador.botin if jugador.viva else 0
		tesoros_guardados.assign(jugador.tesoros if jugador.viva else [])
	var archivo := ConfigFile.new()
	archivo.set_value("base", "id", base_id)
	archivo.set_value("base", "pos", base_pos)
	archivo.set_value("base", "desde", base_desde)
	archivo.set_value("barco", "pos", pos_guardada)
	archivo.set_value("barco", "botin", botin_guardado)
	archivo.set_value("barco", "tesoros", Array(tesoros_guardados))
	mundo.comercio.escribir(archivo)
	mundo.persecucion.escribir(archivo)
	mundo.recompensas.escribir(archivo)
	archivo.save(RUTA)


func _guardar_todo() -> void:
	guardar()
	mundo.personalizacion.guardar()


# Dibujo

func _anunciar(texto: String, color: Color) -> void:
	aviso = texto
	aviso_color = color
	aviso_vida = 3.5


func texto_estado() -> String:
	var jugador := mundo.jugador
	if not jugador.viva:
		return tr("Hundido: pierdes el botín a bordo")
	if jugador.pos.length() > RADIO:
		return tr("Estás en la tormenta")
	if jugador.pos.length() > RADIO - 1500.0:
		return tr("Cerca del límite: la tormenta")
	if base_id == "":
		return tr("Sin base: busca un fuerte libre")
	return tr("Tu base: %d m") % roundi(jugador.pos.distance_to(base_pos) / 10.0)


func animar(_delta: float) -> void:
	var t := mundo.tiempo
	for celda in celdas.values():
		for base in celda.bases:
			if base.trapo != null and base.nodo.visible:
				base.trapo.rotation.y = sin(t * 2.2 + base.fase) * 0.25


# Nombre de cada base a la vista y el anuncio grande del centro.
func dibujar(lienzo: Control, camara: Camera3D) -> void:
	var fuente := ThemeDB.fallback_font
	for celda in celdas.values():
		for base in celda.bases:
			if not base.nodo.visible or base.nodo.position.distance_to(mundo.foco) > Principal.DISTANCIA_VISIBLE:
				continue
			var arriba: Vector3 = base.nodo.position + Vector3(0, 4.4, 0)
			if camara.is_position_behind(arriba):
				continue
			var punto := camara.unproject_position(arriba)
			var nombre := tr("Tu base") if base.id == base_id else (tr("Base libre") if base.dueno == "" else tr("Base de %s") % base.dueno)
			lienzo.draw_string_outline(fuente, punto + Vector2(-140, 0), nombre, HORIZONTAL_ALIGNMENT_CENTER, 280, 20, 5, Color(0, 0, 0, 0.75))
			lienzo.draw_string(fuente, punto + Vector2(-140, 0), nombre, HORIZONTAL_ALIGNMENT_CENTER, 280, 20, _color_base(base))
			if base.dueno != "" and base.id != base_id and base.vida < VIDA_FUERTE:
				var barra := Rect2(punto + Vector2(-60, 10), Vector2(120, 10))
				lienzo.draw_rect(barra.grow(2), Color(0, 0, 0, 0.7))
				lienzo.draw_rect(Rect2(barra.position, Vector2(barra.size.x * base.vida / VIDA_FUERTE, barra.size.y)), COLOR_AJENA)
	if aviso_vida > 0.0:
		var alfa := clampf(aviso_vida / 0.5, 0.0, 1.0)
		var lugar := Vector2(0, lienzo.size.y * 0.38)
		lienzo.draw_string_outline(fuente, lugar, aviso, HORIZONTAL_ALIGNMENT_CENTER, lienzo.size.x, 30, 8, Color(0, 0, 0, 0.8 * alfa))
		lienzo.draw_string(fuente, lugar, aviso, HORIZONTAL_ALIGNMENT_CENTER, lienzo.size.x, 30, Color(aviso_color, alfa))


func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	for celda in celdas.values():
		for base in celda.bases:
			if not mundo.en_mapa(base.pos):
				continue
			var punto: Vector2 = centro + base.pos * escala
			var color := _color_base(base)
			var lado := 7.0 if base.id == base_id else 5.0
			lienzo.draw_rect(Rect2(punto - Vector2.ONE * lado / 2.0, Vector2.ONE * lado), color)
			lienzo.draw_rect(Rect2(punto - Vector2.ONE * lado / 2.0, Vector2.ONE * lado), Color("08161c"), false, 1.0)


# Flecha verde en el bisel de la brújula hacia la base propia cuando queda fuera del radar.
func dibujar_brujula(lienzo: Control, centro: Vector2, exterior: float, interior: float) -> void:
	var jugador := mundo.jugador
	if base_id == "" or jugador == null or not jugador.viva or mundo.en_mapa(base_pos):
		return
	var direccion := (base_pos - jugador.pos).normalized()
	var lado := direccion.orthogonal()
	var base := centro + direccion * (interior + 2.0)
	var punta := centro + direccion * (exterior + 4.0)
	var flecha := PackedVector2Array([punta, base + lado * 6.0, base - direccion * 2.0, base - lado * 6.0])
	lienzo.draw_colored_polygon(flecha, COLOR_MIA)
	flecha.append(flecha[0])
	lienzo.draw_polyline(flecha, Color("08161c"), 1.5, true)
