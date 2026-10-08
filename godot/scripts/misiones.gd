class_name Misiones
extends Node3D

# Puertos flotantes donde se recogen misiones, una detrás de otra: llevar mercancía a una
# isla, seguir un mapa del tesoro, vencer a un kraken y vencer a un tiburón. En los puertos
# también se venden los tesoros que se llevan en cubierta. También reparte los cofres de gemas,
# escasos y quietos en el mar; las gemas se guardan al recogerlas.

const ORDEN: Array[String] = ["entrega", "tesoro", "kraken", "tiburon"]
# El mapa no paga al momento: el premio es el cofre, que hay que llevar a vender.
const RECOMPENSAS := {"entrega": 10, "tesoro": 0, "kraken": 18, "tiburon": 12}
const TITULOS := {
	"entrega": "Lleva la mercancía a la isla marcada",
	"tesoro": "Sigue el mapa del tesoro",
	"kraken": "Vence a un kraken",
	"tiburon": "Vence a un tiburón",
}
const PUERTOS := 4
const ESCALA_PUERTO := 0.45
const RADIO_PUERTO := 68.0 * ESCALA_PUERTO
const ALCANCE_PUERTO := 90.0
const ALTURA_PUERTO := 0.25
const ALCANCE_ENTREGA := 35.0
const COFRES_GEMAS := 6
const DURACION_ANUNCIO := 3.5
const COLOR_GEMA := Color("c77dff")
const COLOR_TABLA := Color("9c7048")
const COLOR_TECHO := Color("b5302a")
const COLOR_PARED := Color("e3cc98")
# Mapa del tesoro: el radar solo marca una zona aproximada; la isla se reconoce por su forma
# dibujada en el mapa y la X se ve en la arena al llegar. Se cava arrimado a la orilla.
const ZONA_MAPA := 420.0
const DESVIO_MAPA := 250.0
const VISTA_MAPA := 380.0
const TIEMPO_CAVAR := 3.0
const ALCANCE_CAVAR := 55.0
const MUESTRA_MAPA := 5.0
const COLOR_PAPEL := Color("ead6a6")
const COLOR_TINTA := Color("5a3b1e")
const COLOR_X := Color("c0392b")


class Fondeadero:
	var pos := Vector2.ZERO
	var fase := 0.0
	var nodo: Node3D
	var aro: MeshInstance3D


class CofreGema:
	var pos := Vector2.ZERO
	var fase := 0.0
	var nodo: Node3D


var mundo: Principal
var puertos: Array[Fondeadero] = []
var cofres: Array[CofreGema] = []
# Misión en curso ("" si no hay) y cuántas se han completado en esta partida.
var actual := ""
var completadas := 0
var isla_destino: Circulo
var base_krakens := 0
var base_tiburones := 0
# Gemas recogidas en esta partida (ya están guardadas en la personalización).
var gemas := 0
var anuncio := ""
var anuncio_color := Color.WHITE
var anuncio_vida := 0.0
var carga: Node3D
var material_aro: StandardMaterial3D
var material_gema: StandardMaterial3D
var material_haz: StandardMaterial3D
var mapa_isla: Circulo
var mapa_punto := Vector2.INF
var mapa_zona := Vector2.INF
var cavado := 0.0
var marca: Node3D
var boton_mapa: Button
var panel_mapa: Control
var cierre_mapa := 0.0
var espera_aceptar := 0.0


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	material_aro = StandardMaterial3D.new()
	material_aro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_aro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_aro.albedo_color = Color(1.0, 0.8, 0.3, 0.8)
	material_gema = StandardMaterial3D.new()
	material_gema.albedo_color = COLOR_GEMA
	material_gema.emission_enabled = true
	material_gema.emission = COLOR_GEMA
	material_gema.emission_energy_multiplier = 1.6
	material_gema.metallic = 0.3
	material_gema.roughness = 0.15
	material_haz = StandardMaterial3D.new()
	material_haz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_haz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_haz.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material_haz.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_haz.albedo_color = Color(COLOR_GEMA, 0.5)


func vaciar() -> void:
	for puerto in puertos:
		puerto.nodo.queue_free()
	puertos.clear()
	for cofre in cofres:
		cofre.nodo.queue_free()
	cofres.clear()
	actual = ""
	completadas = 0
	isla_destino = null
	gemas = 0
	anuncio = ""
	anuncio_vida = 0.0
	espera_aceptar = 0.0
	_quitar_carga()
	_olvidar_mapa()


func reiniciar() -> void:
	vaciar()
	# El primer puerto queda cerca del jugador para empezar enseguida.
	var cerca := _lugar_libre(mundo.jugador.pos, 250.0, 450.0, 500.0)
	_crear_puerto(cerca)
	for _i in mundo.cantidad_mapa(PUERTOS - 1):
		_crear_puerto(_lugar_libre(mundo.zona_centro, 300.0, mundo.zona_radio * 0.75, 500.0))
	for _i in mundo.cantidad_mapa(COFRES_GEMAS):
		_crear_cofre(_lugar_libre(mundo.zona_centro, 200.0, mundo.zona_radio * 0.9, 400.0))


# En el mar libre los puertos salen con las celdas del mapa; al zarpar solo se reparten gemas.
func poner_gemas() -> void:
	for _i in mundo.cantidad_mapa(COFRES_GEMAS):
		_crear_cofre(_lugar_libre(mundo.centro_juego(), 600.0, mundo.alcance_juego(), 800.0))


func crear_puerto(pos: Vector2) -> Fondeadero:
	return _crear_puerto(pos)


func quitar_puerto(puerto: Fondeadero) -> void:
	puertos.erase(puerto)
	if is_instance_valid(puerto.nodo):
		puerto.nodo.queue_free()


# Al hundirse en el mar libre la misión en curso se pierde con la carga.
func cancelar() -> void:
	if actual == "":
		return
	actual = ""
	isla_destino = null
	completadas += 1
	_quitar_carga()
	_olvidar_mapa()


func _lugar_libre(centro: Vector2, desde: float, hasta: float, separacion: float) -> Vector2:
	var punto := centro
	for intento in 60:
		var lejos := separacion if intento < 40 else separacion * 0.5
		punto = centro + Vector2.from_angle(randf() * TAU) * sqrt(randf_range(desde * desde, hasta * hasta))
		var libre := punto.length() < mundo.radio_mundo() - 200.0
		for isla in mundo.islotes:
			if punto.distance_to(isla.pos) < isla.radio + 160.0:
				libre = false
		for puerto in puertos:
			if punto.distance_to(puerto.pos) < lejos:
				libre = false
		for cofre in cofres:
			if punto.distance_to(cofre.pos) < lejos:
				libre = false
		if libre and mundo.peligros.cerca(punto, 250.0):
			libre = false
		if libre:
			return punto
	return punto


# Plataforma de tablones sobre barriles con una caseta, el farol y la bandera de encargos.
# Puesto de comercio sobre balsas: casa de entramado con chimenea, torre vigía con farol,
# grúa de carga, muelle pequeño y mercancía por la cubierta.
func _crear_puerto(pos: Vector2) -> Fondeadero:
	var puerto := Fondeadero.new()
	puerto.pos = pos
	puerto.fase = randf() * TAU
	var nodo := Node3D.new()
	add_child(nodo)
	puerto.nodo = nodo
	var caja := BoxMesh.new()
	var cilindro := CylinderMesh.new()
	cilindro.radial_segments = 10
	cilindro.rings = 1
	var cono := CylinderMesh.new()
	cono.top_radius = 0.0
	cono.radial_segments = 10
	cono.rings = 1
	var esfera := SphereMesh.new()
	esfera.radial_segments = 8
	esfera.rings = 4
	var oscura := Color("4a3222")
	var piedra := Color("8d8a82")

	# Balsa: troncos que flotan, tablones con marco oscuro y muelle hacia delante.
	for z in [-1.6, 0.0, 1.6]:
		var tronco := _pieza(nodo, cilindro, Color("6b4126"), Vector3(0, 0.02, z), Vector3(0.75, 2.45, 0.75), "madera")
		tronco.rotation.z = PI / 2.0
	for i in 12:
		var tablon := _pieza(nodo, caja, COLOR_TABLA.darkened(randf() * 0.2), Vector3(-2.31 + i * 0.42, 0.3, 0), Vector3(0.4, 0.1, 4.3), "madera")
		tablon.rotation.y = randf_range(-0.01, 0.01)
	for lado in [-1.0, 1.0]:
		_pieza(nodo, caja, oscura, Vector3(0, 0.32, lado * 2.2), Vector3(5.1, 0.16, 0.18), "madera")
		_pieza(nodo, caja, oscura, Vector3(lado * 2.5, 0.32, 0), Vector3(0.18, 0.16, 4.5), "madera")
	for k in 5:
		_pieza(nodo, caja, COLOR_TABLA.darkened(randf() * 0.25), Vector3(-0.4, 0.3, 2.45 + k * 0.26), Vector3(1.0, 0.08, 0.24), "madera")
	for x in [-0.95, 0.15]:
		_pieza(nodo, cilindro, oscura, Vector3(x, 0.15, 3.55), Vector3(0.14, 0.45, 0.14), "madera")
		_pieza(nodo, cilindro, Color("2f2a26"), Vector3(x, 0.64, 3.55), Vector3(0.2, 0.08, 0.2))

	# Postes con barandilla de cuerda en tres lados; el de delante queda abierto.
	var postes := [Vector3(-2.45, 0, 2.15), Vector3(-2.45, 0, 0), Vector3(-2.45, 0, -2.15), Vector3(0, 0, -2.15),
		Vector3(2.45, 0, -2.15), Vector3(2.45, 0, 0), Vector3(2.45, 0, 2.15)]
	for poste in postes:
		_pieza(nodo, cilindro, oscura, poste + Vector3(0, 0.6, 0), Vector3(0.13, 0.4, 0.13), "madera")
	for k in postes.size() - 1:
		_viga(nodo, caja, Color("c9b48a"), postes[k] + Vector3(0, 0.88, 0), postes[k + 1] + Vector3(0, 0.88, 0), 0.04, "general")
	for x in [-2.45, 2.45]:
		var farol := _pieza(nodo, esfera, Color("ffd27a"), Vector3(x, 1.05, 2.15), Vector3(0.22, 0.26, 0.22))
		farol.material_override = _brillo(Color("ffd27a"))

	# Casa de entramado sobre zócalo de piedra.
	var casa := Node3D.new()
	casa.position = Vector3(-0.85, 0.35, -0.75)
	nodo.add_child(casa)
	_pieza(casa, caja, piedra, Vector3(0, 0.1, 0), Vector3(2.2, 0.2, 1.8), "roca")
	_pieza(casa, caja, COLOR_PARED, Vector3(0, 0.8, 0), Vector3(2.0, 1.2, 1.6), "madera")
	for x in [-1.0, 1.0]:
		for z in [-0.8, 0.8]:
			_pieza(casa, caja, oscura, Vector3(x, 0.8, z), Vector3(0.12, 1.24, 0.12), "madera")
	for z in [-0.81, 0.81]:
		_pieza(casa, caja, oscura, Vector3(0, 0.82, z), Vector3(2.0, 0.08, 0.04), "madera")
		_pieza(casa, caja, oscura, Vector3(0, 1.38, z), Vector3(2.0, 0.08, 0.04), "madera")
	for lado in [-1.0, 1.0]:
		_viga(casa, caja, oscura, Vector3(lado * 0.95, 0.85, 0.82), Vector3(lado * 0.35, 1.36, 0.82), 0.06)
	var techo := PrismMesh.new()
	_pieza(casa, techo, COLOR_TECHO, Vector3(0, 1.82, 0), Vector3(2.5, 0.85, 2.0))
	_pieza(casa, caja, COLOR_TECHO.darkened(0.35), Vector3(0, 2.25, 0), Vector3(0.1, 0.08, 2.05))
	_pieza(casa, caja, piedra, Vector3(0.6, 2.05, -0.35), Vector3(0.32, 0.9, 0.32), "roca")
	_pieza(casa, caja, piedra.darkened(0.3), Vector3(0.6, 2.52, -0.35), Vector3(0.4, 0.08, 0.4), "roca")
	# Puerta con marco y letrero dorado encima.
	_pieza(casa, caja, Color("5b3a22"), Vector3(0, 0.6, 0.82), Vector3(0.5, 0.82, 0.04), "madera")
	_pieza(casa, caja, oscura, Vector3(0, 1.04, 0.83), Vector3(0.62, 0.07, 0.05), "madera")
	_pieza(casa, esfera, Principal.COLOR_ORO, Vector3(0.15, 0.6, 0.86), Vector3(0.06, 0.06, 0.06))
	_pieza(casa, caja, Color("6b4126"), Vector3(0, 1.18, 0.86), Vector3(0.8, 0.22, 0.04), "madera")
	var emblema := _pieza(casa, cilindro, Principal.COLOR_ORO, Vector3(0, 1.18, 0.89), Vector3(0.16, 0.02, 0.16))
	emblema.rotation.x = PI / 2.0
	emblema.material_override = _brillo(Principal.COLOR_ORO.darkened(0.15))
	# Ventanas encendidas con contraventanas verdes.
	for x in [-0.6, 0.6]:
		var ventana := _pieza(casa, caja, Color("ffd27a"), Vector3(x, 0.95, 0.82), Vector3(0.34, 0.3, 0.03))
		ventana.material_override = _brillo(Color("ffd27a"))
		_pieza(casa, caja, oscura, Vector3(x, 0.95, 0.84), Vector3(0.04, 0.3, 0.02), "madera")
		for lado in [-1.0, 1.0]:
			_pieza(casa, caja, Color("3f6b4a"), Vector3(x + lado * 0.24, 0.95, 0.84), Vector3(0.13, 0.32, 0.03), "madera")
	var lateral := _pieza(casa, caja, Color("ffd27a"), Vector3(1.01, 0.95, 0), Vector3(0.03, 0.3, 0.34))
	lateral.material_override = _brillo(Color("ffd27a"))
	# Toldo a rayas sobre la puerta.
	for k in 4:
		var raya := _pieza(casa, caja, COLOR_TECHO if k % 2 == 0 else Color("f1e6cc"), Vector3(-0.36 + k * 0.24, 1.42, 1.08), Vector3(0.24, 0.04, 0.55))
		raya.rotation.x = 0.35
	for x in [-0.45, 0.45]:
		_pieza(casa, cilindro, oscura, Vector3(x, 0.7, 1.3), Vector3(0.06, 0.7, 0.06), "madera")

	# Torre vigía con farol en la esquina de atrás.
	var torre := Node3D.new()
	torre.position = Vector3(1.75, 0.35, -1.45)
	nodo.add_child(torre)
	for x in [-0.4, 0.4]:
		for z in [-0.4, 0.4]:
			_viga(torre, caja, oscura, Vector3(x * 1.2, 0.0, z * 1.2), Vector3(x, 2.3, z), 0.11)
	_viga(torre, caja, oscura, Vector3(-0.46, 0.6, 0.46), Vector3(0.43, 1.6, 0.43), 0.06)
	_viga(torre, caja, oscura, Vector3(0.46, 0.6, 0.46), Vector3(-0.43, 1.6, 0.43), 0.06)
	_viga(torre, caja, oscura, Vector3(0.46, 0.6, -0.46), Vector3(0.43, 1.6, 0.43), 0.06)
	_pieza(torre, caja, COLOR_TABLA, Vector3(0, 2.35, 0), Vector3(1.1, 0.1, 1.1), "madera")
	for k in 4:
		var baranda := _pieza(torre, caja, oscura, Vector3(0, 2.62, 0.52), Vector3(1.1, 0.06, 0.06), "madera")
		baranda.position = Vector3(0, 2.62, 0).rotated(Vector3.UP, k * PI / 2.0) + Vector3(0, 0, 0.52).rotated(Vector3.UP, k * PI / 2.0)
		baranda.rotation.y = k * PI / 2.0
	var luz := _pieza(torre, cilindro, Color("fff1b8"), Vector3(0, 2.65, 0), Vector3(0.42, 0.25, 0.42))
	luz.material_override = _brillo(Color("fff1b8"))
	for k in 4:
		_pieza(torre, caja, oscura, Vector3(0.21, 2.65, 0).rotated(Vector3.UP, k * PI / 2.0), Vector3(0.05, 0.52, 0.05), "madera")
	_pieza(torre, cono, COLOR_TECHO, Vector3(0, 3.15, 0), Vector3(1.4, 0.3, 1.4))

	# Grúa de carga con una caja colgando sobre el agua.
	var grua := Node3D.new()
	grua.position = Vector3(2.0, 0.35, 1.5)
	nodo.add_child(grua)
	_pieza(grua, cilindro, oscura, Vector3(0, 0.97, 0), Vector3(0.16, 0.97, 0.16), "madera")
	_viga(grua, caja, oscura, Vector3(0, 1.7, 0), Vector3(1.2, 1.9, 0.5), 0.1)
	_viga(grua, caja, oscura, Vector3(0, 1.1, 0), Vector3(0.7, 1.82, 0.3), 0.06)
	_viga(grua, caja, Color("c9b48a"), Vector3(1.2, 1.9, 0.5), Vector3(1.2, 1.05, 0.5), 0.03, "general")
	_pieza(grua, caja, Color("b08552"), Vector3(1.2, 0.85, 0.5), Vector3(0.4, 0.4, 0.4), "madera")

	# Mercancía: cajas, barriles de pie, sacos y un rollo de cuerda.
	for k in 3:
		_pieza(nodo, caja, Color("b08552").darkened(k * 0.08), Vector3(-1.95 + (k % 2) * 0.05, 0.6 + k * 0.4, 1.3), Vector3(0.45, 0.4, 0.45), "madera")
	_pieza(nodo, caja, Color("a27a4a"), Vector3(-1.45, 0.58, 1.55), Vector3(0.4, 0.36, 0.4), "madera")
	for barril in [Vector3(0.75, 0, 0.9), Vector3(1.1, 0, 0.6), Vector3(0.85, 0, 0.3)]:
		_pieza(nodo, cilindro, Color("8a5a32"), barril + Vector3(0, 0.62, 0), Vector3(0.38, 0.275, 0.38), "madera")
		_pieza(nodo, cilindro, Color("3a3430"), barril + Vector3(0, 0.75, 0), Vector3(0.4, 0.04, 0.4))
	for saco in [Vector3(-1.3, 0, 0.6), Vector3(-1.0, 0, 0.75)]:
		_pieza(nodo, esfera, Color("d8c79c"), saco + Vector3(0, 0.5, 0), Vector3(0.38, 0.3, 0.32))
	var cuerda := TorusMesh.new()
	cuerda.inner_radius = 0.1
	cuerda.outer_radius = 0.24
	cuerda.rings = 12
	cuerda.ring_segments = 6
	_pieza(nodo, cuerda, Color("c9b48a"), Vector3(0.6, 0.4, 1.7), Vector3(1.0, 1.6, 1.0))

	var asta := _pieza(nodo, cilindro, oscura, Vector3(-2.1, 1.9, -1.85), Vector3(0.07, 3.2, 0.07), "madera")
	asta.name = "Asta"
	var bandera := _pieza(nodo, caja, Principal.COLOR_ORO, Vector3(-1.65, 3.15, -1.85), Vector3(0.9, 0.55, 0.03))
	bandera.material_override = _brillo(Principal.COLOR_ORO.darkened(0.1))
	bandera.name = "Bandera"
	var toro := TorusMesh.new()
	toro.inner_radius = 3.5
	toro.outer_radius = 3.7
	toro.rings = 48
	toro.ring_segments = 4
	puerto.aro = MeshInstance3D.new()
	puerto.aro.mesh = toro
	puerto.aro.material_override = material_aro
	puerto.aro.scale = Vector3(1.0, 0.2, 1.0)
	puerto.aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nodo.add_child(puerto.aro)
	nodo.scale = Vector3.ONE * ESCALA_PUERTO
	puertos.append(puerto)
	return puerto


# Listón de grosor dado que va de un punto a otro: vigas inclinadas y cuerdas.
func _viga(padre: Node3D, malla: Mesh, color: Color, desde: Vector3, hasta: Vector3, grosor: float, textura := "madera") -> MeshInstance3D:
	var tramo := hasta - desde
	var pieza := _pieza(padre, malla, color, (desde + hasta) * 0.5, Vector3.ONE, textura)
	var arriba := Vector3.FORWARD if absf(tramo.normalized().y) > 0.95 else Vector3.UP
	pieza.basis = Basis.looking_at(tramo, arriba)
	pieza.scale = Vector3(grosor, grosor, tramo.length())
	return pieza

# Cofre oscuro de herrajes plateados, lleno de gemas que brillan, con un haz de luz
# violeta que se ve de lejos.
func _crear_cofre(pos: Vector2) -> void:
	var cofre := CofreGema.new()
	cofre.pos = pos
	cofre.fase = randf() * TAU
	var nodo := Node3D.new()
	add_child(nodo)
	cofre.nodo = nodo
	var caja := BoxMesh.new()
	_pieza(nodo, caja, Color("2b2238"), Vector3(0, 0.22, 0), Vector3(0.8, 0.44, 0.55), "madera")
	_pieza(nodo, caja, Color("3a2f4c"), Vector3(0, 0.5, 0.18), Vector3(0.82, 0.08, 0.3), "madera")
	for lado in [-0.3, 0.3]:
		_pieza(nodo, caja, Color("c9ced6"), Vector3(lado, 0.24, 0), Vector3(0.06, 0.48, 0.58))
	var gema := SphereMesh.new()
	gema.radius = 0.5
	gema.height = 1.0
	gema.radial_segments = 6
	gema.rings = 2
	for k in 5:
		var pieza := MeshInstance3D.new()
		pieza.mesh = gema
		pieza.material_override = material_gema
		pieza.position = Vector3(randf_range(-0.25, 0.25), 0.5, randf_range(-0.15, 0.05))
		pieza.scale = Vector3(0.14, 0.2, 0.14)
		pieza.rotation = Vector3(randf_range(-0.5, 0.5), randf() * TAU, randf_range(-0.5, 0.5))
		nodo.add_child(pieza)
	var haz := CylinderMesh.new()
	haz.top_radius = 0.0
	haz.bottom_radius = 0.3
	haz.height = 3.2
	haz.radial_segments = 12
	haz.cap_top = false
	haz.cap_bottom = false
	var columna := MeshInstance3D.new()
	columna.mesh = haz
	columna.material_override = material_haz
	columna.position = Vector3(0, 1.8, 0)
	columna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nodo.add_child(columna)
	var toro := TorusMesh.new()
	toro.inner_radius = 0.9
	toro.outer_radius = 1.05
	toro.rings = 32
	toro.ring_segments = 4
	var aro := MeshInstance3D.new()
	aro.mesh = toro
	aro.material_override = material_haz
	aro.scale = Vector3(1.0, 0.2, 1.0)
	aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nodo.add_child(aro)
	nodo.scale = Vector3.ONE * 0.9
	cofres.append(cofre)


func _pieza(padre: Node3D, malla: Mesh, color: Color, pos: Vector3, escala: Vector3, textura := "general") -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = mundo.material(color, textura)
	pieza.position = pos
	pieza.scale = escala
	padre.add_child(pieza)
	return pieza


func _brillo(color: Color) -> StandardMaterial3D:
	var materia := StandardMaterial3D.new()
	materia.albedo_color = color
	materia.emission_enabled = true
	materia.emission = color
	materia.emission_energy_multiplier = 1.2
	return materia


func actualizar(delta: float) -> void:
	anuncio_vida = maxf(0.0, anuncio_vida - delta)
	for barco in mundo.barcos:
		if not barco.viva:
			continue
		for puerto in puertos:
			var sep: Vector2 = barco.pos - puerto.pos
			var minimo := RADIO_PUERTO + barco.radio * 0.6
			if sep.length() < minimo and sep != Vector2.ZERO:
				barco.pos = puerto.pos + sep.normalized() * minimo
				barco.velocidad *= 0.95
	var jugador := mundo.jugador
	if jugador == null or not jugador.viva:
		return
	for i in range(cofres.size() - 1, -1, -1):
		var cofre := cofres[i]
		if jugador.pos.distance_to(cofre.pos) < jugador.radio + 26.0:
			_recoger_gema(cofre)
			cofre.nodo.queue_free()
			cofres.remove_at(i)
	espera_aceptar = maxf(0.0, espera_aceptar - delta)
	if not jugador.tesoros.is_empty():
		for puerto in puertos:
			if jugador.pos.distance_to(puerto.pos) < ALCANCE_PUERTO:
				mundo.tesoros.vender_jugador()
				# Deja leer la venta antes de anunciar el siguiente encargo.
				espera_aceptar = 2.0
				break
	if actual == "":
		# Fuera del mar libre los puertos son solo puertos: no dan encargos.
		if espera_aceptar > 0.0 or mundo.modo != "libre":
			return
		for puerto in puertos:
			if jugador.pos.distance_to(puerto.pos) < ALCANCE_PUERTO:
				_aceptar(puerto)
				break
		return
	match actual:
		"entrega":
			# Hay que arrimarse a la orilla: el casco choca a radio * 0.7 del borde.
			if isla_destino != null and jugador.pos.distance_to(isla_destino.pos) < isla_destino.borde(jugador.pos) + jugador.radio * 0.7 + ALCANCE_ENTREGA:
				_completar()
		"kraken":
			if mundo.peligros.ahuyentados > base_krakens:
				_completar()
			elif not mundo.peligros.quedan_krakens():
				# Sin krakens no se puede cumplir: se anula y el siguiente puerto da otro encargo.
				_anunciar(tr("Ya no quedan krakens: misión anulada"), Principal.COLOR_TEXTO)
				actual = ""
				completadas += 1
		"tiburon":
			if mundo.tiburones.vencidos > base_tiburones:
				_completar()
		"tesoro":
			_cavar(delta)


# Arrimado a la orilla junto a la X el cofre va saliendo; si se aleja, la arena lo vuelve a tapar.
func _cavar(delta: float) -> void:
	var jugador := mundo.jugador
	var cerca := jugador.pos.distance_to(mapa_punto) < _alcance_cavar()
	cavado = clampf(cavado + delta / TIEMPO_CAVAR * (1.0 if cerca else -0.5), 0.0, 1.0)
	if cerca and randf() < delta * 10.0:
		var vel := Vector3(randf_range(-1.0, 1.0), randf_range(1.5, 3.0), randf_range(-1.0, 1.0))
		mundo.crear_efecto(mundo.malla_gota, Color(Islas.COLOR_ARENA, 0.95), mundo.a_3d(mapa_punto, 0.55), vel, 0.7, 1.2, 0.0, 6.0, true)
	if cavado >= 1.0:
		_desenterrar()


func _alcance_cavar() -> float:
	return mundo.jugador.radio * 0.7 + mapa_isla.radio * 0.14 + ALCANCE_CAVAR


# El cofre sale de la arena, salta y vuela a la cubierta.
func _desenterrar() -> void:
	var cofre := mundo.tesoros.modelo("cofre")
	cofre.scale = Vector3.ONE * 1.6
	cofre.position = mundo.a_3d(mapa_punto, 0.1)
	add_child(cofre)
	for k in 16:
		var vel := Vector3(randf_range(-2.0, 2.0), randf_range(2.0, 4.5), randf_range(-2.0, 2.0))
		mundo.crear_efecto(mundo.malla_gota, Color(Islas.COLOR_ARENA, 0.95), cofre.position + Vector3(0, 0.4, 0), vel, 0.9, 1.6, 0.0, 7.0, true)
	var vuelo := create_tween()
	vuelo.tween_property(cofre, "position:y", 2.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	vuelo.parallel().tween_property(cofre, "rotation:y", TAU, 0.9)
	vuelo.tween_method(func(k: float) -> void: _volar_a_cubierta(cofre, k), 0.0, 1.0, 0.55)
	vuelo.tween_callback(func() -> void: _llegar_a_cubierta(cofre))
	_anunciar(tr("¡Tesoro desenterrado! Véndelo en un puerto"), Principal.COLOR_ORO)
	mundo.voz_monedas.play()
	actual = ""
	completadas += 1
	_olvidar_mapa()


func _volar_a_cubierta(cofre: Node3D, k: float) -> void:
	var jugador := mundo.jugador
	if jugador == null or not is_instance_valid(cofre):
		return
	var desde := Vector3(cofre.position.x, 2.0, cofre.position.z)
	var hasta := jugador.position + Vector3(0, 1.0, 0)
	cofre.position = desde.lerp(hasta, k) + Vector3(0, sin(k * PI) * 1.5, 0)
	cofre.scale = Vector3.ONE * lerpf(1.6, 0.8, k)


func _llegar_a_cubierta(cofre: Node3D) -> void:
	var jugador := mundo.jugador
	if is_instance_valid(cofre):
		cofre.queue_free()
	if jugador == null:
		return
	if jugador.viva:
		mundo.tesoros.cargar(jugador, "cofre")
		mundo.avisar_premio(jugador.position + Vector3(0, 2.0, 0), tr("Cofre del tesoro"), Principal.COLOR_ORO)
	else:
		mundo.soltar_tesoro(jugador.pos, "cofre")


func _preparar_mapa(isla: Circulo) -> void:
	_olvidar_mapa()
	mapa_isla = isla
	var angulo := randf() * TAU
	mapa_punto = isla.pos + Vector2.from_angle(angulo) * isla.radio * isla.factor(angulo) * 0.86
	mapa_zona = mapa_punto + Vector2.from_angle(randf() * TAU) * randf_range(0.3, 1.0) * DESVIO_MAPA
	cavado = 0.0
	# X pintada en la arena, que se ve al llegar a la isla.
	marca = Node3D.new()
	marca.position = mundo.a_3d(mapa_punto, 0.47)
	marca.rotation.y = randf() * TAU
	add_child(marca)
	var caja := BoxMesh.new()
	var tinta := _brillo(COLOR_X)
	tinta.emission_energy_multiplier = 0.4
	for giro in [PI / 4.0, -PI / 4.0]:
		var trazo := MeshInstance3D.new()
		trazo.mesh = caja
		trazo.material_override = tinta
		trazo.scale = Vector3(1.5, 0.04, 0.28)
		trazo.rotation.y = giro
		trazo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marca.add_child(trazo)


func _olvidar_mapa() -> void:
	mapa_isla = null
	mapa_punto = Vector2.INF
	mapa_zona = Vector2.INF
	cavado = 0.0
	if marca != null and is_instance_valid(marca):
		marca.queue_free()
	marca = null
	cerrar_mapa()


func anunciar(texto: String, color: Color) -> void:
	_anunciar(texto, color)


# Botón redondo con un pergamino junto al engranaje y el mapa a pantalla, que se cierra al tocarlo.
func crear_interfaz(capa: CanvasLayer) -> void:
	boton_mapa = Button.new()
	boton_mapa.focus_mode = Control.FOCUS_NONE
	boton_mapa.tooltip_text = "Mapa"
	var redondo := StyleBoxFlat.new()
	redondo.bg_color = Color(0.05, 0.16, 0.2, 0.9)
	redondo.border_color = Principal.COLOR_ORO
	redondo.set_border_width_all(2)
	redondo.set_corner_radius_all(40)
	for estado in ["normal", "hover", "pressed"]:
		boton_mapa.add_theme_stylebox_override(estado, redondo)
	Ui.anclar(boton_mapa, Vector2(1, 0), Vector2(-212 - 14 - 72, 28 + 72 + 14), Vector2(72, 72))
	boton_mapa.draw.connect(_dibujar_icono_mapa)
	boton_mapa.pressed.connect(func() -> void:
		if panel_mapa.visible:
			cerrar_mapa()
		else:
			abrir_mapa(0.0))
	boton_mapa.visible = false
	capa.add_child(boton_mapa)
	panel_mapa = Control.new()
	Ui.anclar(panel_mapa, Vector2(0.5, 0.5), Vector2(-220, -220), Vector2(440, 440))
	panel_mapa.draw.connect(_dibujar_mapa)
	panel_mapa.gui_input.connect(func(evento: InputEvent) -> void:
		if evento is InputEventMouseButton and evento.pressed or evento is InputEventScreenTouch and evento.pressed:
			cerrar_mapa())
	panel_mapa.visible = false
	capa.add_child(panel_mapa)


# Con segundos > 0 se cierra solo (al recibir el mapa en el puerto).
func abrir_mapa(segundos: float) -> void:
	if panel_mapa == null or mapa_isla == null:
		return
	panel_mapa.visible = true
	cierre_mapa = segundos
	panel_mapa.queue_redraw()


func cerrar_mapa() -> void:
	if panel_mapa != null:
		panel_mapa.visible = false
	cierre_mapa = 0.0


func _dibujar_icono_mapa() -> void:
	var c := boton_mapa.size / 2.0
	var hoja := PackedVector2Array([c + Vector2(-18, -14), c + Vector2(-6, -18), c + Vector2(6, -14), c + Vector2(18, -18),
		c + Vector2(18, 14), c + Vector2(6, 18), c + Vector2(-6, 14), c + Vector2(-18, 18)])
	boton_mapa.draw_colored_polygon(hoja, COLOR_PAPEL)
	hoja.append(hoja[0])
	boton_mapa.draw_polyline(hoja, COLOR_TINTA, 2.0, true)
	boton_mapa.draw_line(c + Vector2(4, -4), c + Vector2(12, 4), COLOR_X, 3.0, true)
	boton_mapa.draw_line(c + Vector2(12, -4), c + Vector2(4, 4), COLOR_X, 3.0, true)
	boton_mapa.draw_dashed_line(c + Vector2(-12, 8), c + Vector2(2, 2), COLOR_TINTA, 1.5, 3.0)


# Pergamino con la isla del tesoro (y las vecinas para orientarse), la X y la rosa de los vientos.
func _dibujar_mapa() -> void:
	if mapa_isla == null:
		return
	var lado := panel_mapa.size
	var c := lado / 2.0
	var borde := PackedVector2Array()
	for k in 40:
		var a := TAU * k / 40.0
		var p := Vector2(cos(a), sin(a))
		p = p / maxf(absf(p.x), absf(p.y))
		var roto := 1.0 - 0.025 * (0.5 + 0.5 * sin(k * 7.3))
		borde.append(c + p * (lado.x / 2.0 - 6.0) * roto)
	panel_mapa.draw_colored_polygon(borde, COLOR_PAPEL)
	var cerrado := borde.duplicate()
	cerrado.append(borde[0])
	panel_mapa.draw_polyline(cerrado, Color(COLOR_TINTA, 0.8), 3.0, true)
	var fuente := ThemeDB.fallback_font
	panel_mapa.draw_string(fuente, Vector2(0, 46), tr("Mapa del tesoro"), HORIZONTAL_ALIGNMENT_CENTER, lado.x, 28, COLOR_TINTA)
	var escala := (lado.x * 0.38) / VISTA_MAPA
	var centro_mapa := c + Vector2(0, 14)
	# Olas de tinta.
	for k in 9:
		var p := centro_mapa + Vector2(-150 + (k * 97) % 300, -120 + (k * 61) % 240)
		panel_mapa.draw_arc(p, 8.0, PI * 1.1, PI * 1.9, 6, Color(COLOR_TINTA, 0.35), 1.5, true)
		panel_mapa.draw_arc(p + Vector2(14, 0), 8.0, PI * 1.1, PI * 1.9, 6, Color(COLOR_TINTA, 0.35), 1.5, true)
	for isla in mundo.islotes:
		if isla.pos.distance_to(mapa_isla.pos) > VISTA_MAPA + isla.radio:
			continue
		_dibujar_isla_mapa(isla, centro_mapa, escala, isla == mapa_isla)
	var x := centro_mapa + (mapa_punto - mapa_isla.pos) * escala
	for giro in [Vector2(1, 1), Vector2(1, -1)]:
		panel_mapa.draw_line(x - giro * 11.0, x + giro * 11.0, COLOR_X, 5.0, true)
	# Rosa de los vientos: el norte arriba, como en el radar.
	var rosa := Vector2(lado.x - 58, lado.y - 62)
	panel_mapa.draw_circle(rosa, 22.0, Color(COLOR_TINTA, 0.12))
	panel_mapa.draw_colored_polygon(PackedVector2Array([rosa + Vector2(0, -26), rosa + Vector2(-7, 0), rosa + Vector2(7, 0)]), COLOR_X)
	panel_mapa.draw_colored_polygon(PackedVector2Array([rosa + Vector2(0, 26), rosa + Vector2(-7, 0), rosa + Vector2(7, 0)]), COLOR_TINTA)
	panel_mapa.draw_string(fuente, rosa + Vector2(-8, -30), "N", HORIZONTAL_ALIGNMENT_CENTER, 16, 18, COLOR_TINTA)
	panel_mapa.draw_string(fuente, Vector2(0, lado.y - 22), tr("Toca para cerrar"), HORIZONTAL_ALIGNMENT_CENTER, lado.x, 16, Color(COLOR_TINTA, 0.7))


func _dibujar_isla_mapa(isla: Circulo, centro_mapa: Vector2, escala: float, principal: bool) -> void:
	var puntos := PackedVector2Array()
	for k in Circulo.MUESTRAS:
		var a := TAU * k / Circulo.MUESTRAS
		puntos.append(centro_mapa + (isla.pos - mapa_isla.pos + Vector2.from_angle(a) * isla.radio * isla.factor(a)) * escala)
	var relleno := Color("d9b77a") if principal else Color("ddc395")
	if Geometry2D.triangulate_polygon(puntos).is_empty():
		for p in puntos:
			panel_mapa.draw_circle(p, 2.0, relleno)
	else:
		panel_mapa.draw_colored_polygon(puntos, relleno)
	puntos.append(puntos[0])
	panel_mapa.draw_polyline(puntos, COLOR_TINTA, 2.5 if principal else 1.5, true)


func _recoger_gema(cofre: CofreGema) -> void:
	gemas += 1
	mundo.personalizacion.gemas += 1
	mundo.personalizacion.guardar()
	mundo.avisar_premio(cofre.nodo.position + Vector3(0, 1.5, 0), tr("+1 gema"), COLOR_GEMA)
	_anunciar(tr("¡Encontraste una gema!"), COLOR_GEMA)
	for k in 8:
		var vel := Vector3(randf_range(-1.2, 1.2), randf_range(1.5, 3.0), randf_range(-1.2, 1.2))
		mundo.crear_efecto(mundo.malla_gota, COLOR_GEMA, cofre.nodo.position + Vector3(0, 0.6, 0), vel, 0.9, 0.18, -0.1, 3.0)


func _aceptar(puerto: Fondeadero) -> void:
	if completadas >= ORDEN.size() and mundo.modo != "libre":
		if anuncio_vida <= 0.0:
			_anunciar(tr("No quedan encargos en los puertos"), Principal.COLOR_TEXTO)
		return
	var tipo := ORDEN[completadas % ORDEN.size()]
	if tipo == "kraken" and not mundo.peligros.quedan_krakens():
		completadas += 1
		_aceptar(puerto)
		return
	if tipo == "entrega":
		isla_destino = _elegir_isla(puerto.pos)
		if isla_destino == null:
			completadas += 1
			return
		_cargar()
	if tipo == "tesoro":
		var isla := _elegir_isla(puerto.pos)
		if isla == null:
			completadas += 1
			return
		_preparar_mapa(isla)
	base_krakens = mundo.peligros.ahuyentados
	base_tiburones = mundo.tiburones.vencidos
	actual = tipo
	_anunciar(tr("Nueva misión: %s") % tr(TITULOS[tipo]), Principal.COLOR_ORO)
	mundo.voz_equipar.play()
	if tipo == "tesoro":
		abrir_mapa(MUESTRA_MAPA)


func _elegir_isla(desde: Vector2) -> Circulo:
	var candidatas: Array[Circulo] = []
	var cercana: Circulo = null
	var mejor := INF
	for isla in mundo.islotes:
		if isla.radio <= Islas.RADIO_ROCAS + 30.0:
			continue
		var distancia := isla.pos.distance_to(desde)
		var dentro := isla.pos.distance_to(mundo.zona_centro) < mundo.zona_radio * 0.8
		if dentro and distancia > 700.0 and distancia < 2000.0:
			candidatas.append(isla)
		if dentro and distancia < mejor:
			mejor = distancia
			cercana = isla
	return candidatas.pick_random() if not candidatas.is_empty() else cercana


func _completar() -> void:
	var premio: int = RECOMPENSAS[actual]
	mundo.ganar_botin(mundo.jugador, premio, mundo.jugador.position + Vector3(0, 2.5, 0))
	_anunciar(tr("¡Misión cumplida! +%d monedas") % premio, Principal.COLOR_ORO)
	mundo.voz_monedas.play()
	if actual == "entrega":
		_quitar_carga()
	actual = ""
	isla_destino = null
	completadas += 1


func _anunciar(texto: String, color: Color) -> void:
	anuncio = texto
	anuncio_color = color
	anuncio_vida = DURACION_ANUNCIO


# Cajas de mercancía en la cubierta del jugador mientras dura la entrega.
func _cargar() -> void:
	_quitar_carga()
	var jugador := mundo.jugador
	var medidas: Dictionary = ModeloBarco.MEDIDAS[jugador.tipo]
	carga = Node3D.new()
	carga.position = Vector3(0, medidas["alto"], medidas["largo"] * 0.12)
	jugador.add_child(carga)
	var caja := BoxMesh.new()
	var sitios := [Vector3(-0.2, 0.15, 0), Vector3(0.2, 0.15, 0.05), Vector3(0, 0.45, 0.02), Vector3(0, 0.15, 0.4)]
	for sitio in sitios:
		var pieza := _pieza(carga, caja, Color("b08552"), sitio, Vector3.ONE * 0.3, "madera")
		pieza.rotation.y = randf_range(-0.3, 0.3)


func _quitar_carga() -> void:
	if carga != null and is_instance_valid(carga):
		carga.queue_free()
	carga = null


# Punto al que apunta la misión en curso, o Vector2.INF si no hay ninguno.
func objetivo() -> Vector2:
	var jugador := mundo.jugador
	match actual:
		"entrega":
			return isla_destino.pos if isla_destino != null else Vector2.INF
		"kraken":
			var mejor := Vector2.INF
			for kraken in mundo.peligros.krakens:
				if kraken.agonia < 0.0 and kraken.sumergido <= 0.0 and jugador.pos.distance_to(kraken.pos) < jugador.pos.distance_to(mejor):
					mejor = kraken.pos
			return mejor
		"tesoro":
			# Lejos solo se sabe la zona; ya en ella se apunta a la X.
			if jugador.pos.distance_to(mapa_punto) < ZONA_MAPA:
				return mapa_punto
			return mapa_zona
		"tiburon":
			var mejor := Vector2.INF
			for tiburon in mundo.tiburones.vivos():
				if jugador.pos.distance_to(tiburon.pos) < jugador.pos.distance_to(mejor):
					mejor = tiburon.pos
			return mejor
	# Sin misión no se señala nada: los puertos se descubren navegando.
	return Vector2.INF


func texto_hud() -> String:
	if actual == "":
		return "" if completadas < ORDEN.size() or mundo.modo == "libre" else tr("Misiones completadas")
	if actual == "tesoro" and cavado > 0.0:
		return tr("Desenterrando el tesoro… %d%%") % roundi(cavado * 100.0)
	var destino := objetivo()
	var texto := tr("Misión: %s") % tr(TITULOS[actual])
	if destino != Vector2.INF:
		texto += "  (%d m)" % roundi(mundo.jugador.pos.distance_to(destino) / 10.0)
	return texto


func animar(delta: float) -> void:
	var t := mundo.tiempo
	if boton_mapa != null:
		boton_mapa.visible = actual == "tesoro" and mundo.estado == Principal.Estado.JUGANDO and mundo.jugador != null and mundo.jugador.viva
		if not boton_mapa.visible and panel_mapa.visible:
			cerrar_mapa()
		if cierre_mapa > 0.0:
			cierre_mapa -= delta
			if cierre_mapa <= 0.0:
				cerrar_mapa()
	if marca != null and is_instance_valid(marca):
		var latido := 1.0 + 0.08 * sin(t * 4.0)
		marca.scale = Vector3(latido, 1.0, latido)
	var foco_plano := Vector2(mundo.foco.x, mundo.foco.z)
	var hay_encargo := actual == "" and mundo.modo == "libre"
	for puerto in puertos:
		var centro: Vector2 = puerto.pos * Principal.ESCALA
		puerto.nodo.visible = centro.distance_to(foco_plano) < Principal.DISTANCIA_VISIBLE + 10.0
		if not puerto.nodo.visible:
			continue
		# Quieto y por encima de la ola más alta del mar en calma: los barriles quedan
		# medio mojados pero el muelle nunca se cubre.
		puerto.nodo.position = Vector3(centro.x, ALTURA_PUERTO, centro.y)
		puerto.nodo.rotation = Vector3(0.0, puerto.fase, 0.0)
		puerto.aro.visible = hay_encargo
		puerto.aro.position.y = 0.35
		puerto.aro.scale = Vector3(1.0, 0.2, 1.0) * (1.0 + 0.06 * sin(t * 3.0 + puerto.fase))
		var bandera: Node3D = puerto.nodo.get_node("Bandera")
		bandera.rotation.y = sin(t * 2.2 + puerto.fase) * 0.15
	for cofre in cofres:
		var centro: Vector2 = cofre.pos * Principal.ESCALA
		cofre.nodo.visible = centro.distance_to(foco_plano) < Principal.DISTANCIA_VISIBLE + 10.0
		if not cofre.nodo.visible:
			continue
		var h := mundo.altura_mar(centro.x, centro.y)
		cofre.nodo.position = Vector3(centro.x, h - 0.12, centro.y)
		cofre.nodo.rotation = Vector3(sin(t * 1.5 + cofre.fase) * 0.1, cofre.nodo.rotation.y + delta * 0.5, cos(t * 1.2 + cofre.fase) * 0.08)


# Flecha en el borde de la pantalla hacia el objetivo, marca encima si se ve,
# nombre de los puertos y el anuncio grande en el centro.
func dibujar(lienzo: Control, camara: Camera3D) -> void:
	var fuente := ThemeDB.fallback_font
	for puerto in puertos:
		if not puerto.nodo.visible:
			continue
		var arriba: Vector3 = puerto.nodo.position + Vector3(0, 4.6 * ESCALA_PUERTO + 0.8, 0)
		if camara.is_position_behind(arriba):
			continue
		var punto := camara.unproject_position(arriba)
		var nombre := tr("Puerto")
		lienzo.draw_string_outline(fuente, punto + Vector2(-110, 0), nombre, HORIZONTAL_ALIGNMENT_CENTER, 220, 20, 5, Color(0, 0, 0, 0.75))
		lienzo.draw_string(fuente, punto + Vector2(-110, 0), nombre, HORIZONTAL_ALIGNMENT_CENTER, 220, 20, Principal.COLOR_ORO)
	var jugador := mundo.jugador
	var destino := objetivo() if jugador != null and jugador.viva else Vector2.INF
	# Fuera de la pantalla, el rumbo al objetivo lo marca la flecha de la brújula.
	if destino != Vector2.INF:
		var sitio := mundo.a_3d(destino, 1.0)
		if not camara.is_position_behind(sitio):
			var visible_en := camara.unproject_position(sitio)
			var margen := 90.0
			if Rect2(Vector2.ONE * margen, lienzo.size - Vector2.ONE * margen * 2.0).has_point(visible_en):
				if actual == "tesoro" and cavado > 0.0:
					var centro_cava := visible_en + Vector2(0, -40)
					lienzo.draw_circle(centro_cava, 22.0, Color(0, 0, 0, 0.45))
					lienzo.draw_arc(centro_cava, 22.0, -PI / 2.0, -PI / 2.0 + TAU * cavado, 40, Principal.COLOR_ORO, 6.0, true)
				var pulso := 1.0 + 0.12 * sin(mundo.tiempo * 6.0)
				var punta := visible_en + Vector2(0, -40)
				var flecha := PackedVector2Array([punta + Vector2(0, 16) * pulso, punta + Vector2(-13, -6) * pulso, punta + Vector2(13, -6) * pulso])
				lienzo.draw_colored_polygon(flecha, Principal.COLOR_ORO)
				flecha.append(flecha[0])
				lienzo.draw_polyline(flecha, Color(0, 0, 0, 0.7), 2.0, true)
	if anuncio_vida > 0.0:
		var alfa := clampf(anuncio_vida / 0.5, 0.0, 1.0)
		var tam := 34
		var lugar := Vector2(0, lienzo.size.y * 0.3)
		lienzo.draw_string_outline(fuente, lugar, anuncio, HORIZONTAL_ALIGNMENT_CENTER, lienzo.size.x, tam, 8, Color(0, 0, 0, 0.8 * alfa))
		lienzo.draw_string(fuente, lugar, anuncio, HORIZONTAL_ALIGNMENT_CENTER, lienzo.size.x, tam, Color(anuncio_color, alfa))


func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	for puerto in puertos:
		if not mundo.en_mapa(puerto.pos):
			continue
		var punto: Vector2 = centro + puerto.pos * escala
		lienzo.draw_rect(Rect2(punto - Vector2(2.5, 2.5), Vector2(5, 5)), Color("8a5a32"))
		lienzo.draw_rect(Rect2(punto - Vector2(2.5, 2.5), Vector2(5, 5)), Principal.COLOR_ORO, false, 1.0)
	# Solo la isla de la entrega: krakens y tiburones no salen en el mapa.
	var destino := objetivo() if mundo.jugador != null and mundo.jugador.viva and actual == "entrega" else Vector2.INF
	if destino != Vector2.INF and mundo.en_mapa(destino):
		var radio := 6.0 + 2.0 * sin(mundo.tiempo * 5.0)
		lienzo.draw_arc(centro + destino * escala, radio, 0.0, TAU, 24, Principal.COLOR_ORO, 2.0, true)
	# Mapa del tesoro: solo la zona aproximada, en trazos discontinuos.
	if actual == "tesoro" and mapa_zona != Vector2.INF and mundo.jugador != null and mundo.jugador.viva:
		var radio_zona := ZONA_MAPA * escala
		for k in 16:
			var a := TAU * k / 16.0 + mundo.tiempo * 0.3
			lienzo.draw_arc(centro + mapa_zona * escala, radio_zona, a, a + TAU / 32.0, 4, COLOR_X, 2.0, true)


# Flecha dorada que recorre el bisel de la brújula señalando hacia el objetivo de la misión.
func dibujar_brujula(lienzo: Control, centro: Vector2, exterior: float, interior: float) -> void:
	var jugador := mundo.jugador
	var destino := objetivo() if jugador != null and jugador.viva else Vector2.INF
	if destino == Vector2.INF or destino.distance_to(jugador.pos) < 1.0:
		return
	var direccion := (destino - jugador.pos).normalized()
	var lado := direccion.orthogonal()
	var pulso := 1.0 + 0.15 * sin(mundo.tiempo * 6.0)
	var base := centro + direccion * (interior + 2.0)
	var punta := centro + direccion * (exterior + 6.0 * pulso)
	var ancho := 8.0 * pulso
	var flecha := PackedVector2Array([punta, base + lado * ancho, base - direccion * 2.0, base - lado * ancho])
	lienzo.draw_colored_polygon(flecha, Principal.COLOR_ORO)
	flecha.append(flecha[0])
	lienzo.draw_polyline(flecha, Color("08161c"), 2.0, true)
