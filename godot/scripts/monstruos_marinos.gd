class_name MonstruosMarinos
extends Node3D

# Serpientes marinas del MOBA: viven en guaridas junto a las islas, entre los carriles, y no son
# de ninguna armada. Nadan en corro alrededor de su guarida; si alguien les dispara, se
# revuelven contra él y le escupen agua hasta que se aleja demasiado (entonces vuelven y se
# curan). Quien las hunde se lleva oro, y su armada cercana, experiencia. Reaparecen al rato.

const EQUIPO := 2
# Guaridas de una mitad del mapa; la otra mitad las tiene en espejo. La tercera es la grande.
const GUARIDAS: Array[Vector2] = [Vector2(-780.0, -300.0), Vector2(-300.0, -780.0), Vector2(-620.0, -620.0)]
const TIPOS := {
	"serpiente": {"nombre": "Serpiente marina", "vida": 320.0, "danio": 9.0, "oro": 50, "xp": 40, "escala": 1.0, "radio": 30.0},
	"gran_serpiente": {"nombre": "Gran serpiente", "vida": 560.0, "danio": 14.0, "oro": 100, "xp": 70, "escala": 1.4, "radio": 40.0},
}
const CORRO := 45.0
const VEL_NADO := 0.35
const VEL_CAZA := 70.0
const ALCANCE_ESCUPIR := 210.0
const RECARGA_ESCUPIR := 1.6
# Si su agresor se aleja más que esto de la guarida, lo deja y vuelve a casa.
const CORREA := 420.0
const CURA_EN_CASA := 0.2
const REAPARICION := 90.0
const SEPARACION := 12.0
const COLOR_PIEL := Color("2f8f7f")
const COLOR_VIENTRE := Color("e3c27a")
const COLOR_ALETA := Color("d9a43a")
const COLOR_BARRA := Color("c38bff")


class Monstruo:
	var tipo := ""
	var guarida := Vector2.ZERO
	var pos := Vector2.ZERO
	var rumbo := 0.0
	var vida := 0.0
	var vida_max := 0.0
	var viva := true
	var espera := 0.0
	var recarga := 0.0
	var destello := 0.0
	var furia := 0.0
	var fase := 0.0
	var agresor: Barco
	var nodo: Node3D
	var cabeza: Node3D
	var tramos: Array[Node3D] = []


var moba: Moba
var mundo: Principal
var monstruos: Array[Monstruo] = []
var esfera := SphereMesh.new()
var cono := CylinderMesh.new()
var material_saliva: StandardMaterial3D


func preparar(nuevo_moba: Moba) -> void:
	moba = nuevo_moba
	mundo = moba.mundo
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 12
	esfera.rings = 6
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 6
	material_saliva = StandardMaterial3D.new()
	material_saliva.albedo_color = Color("7fe8d0")
	material_saliva.emission_enabled = true
	material_saliva.emission = Color("3fbfa0")


func empezar() -> void:
	vaciar()
	for punto in GUARIDAS:
		for guarida: Vector2 in [punto, -punto]:
			var tipo := "gran_serpiente" if punto == GUARIDAS[-1] else "serpiente"
			_crear(tipo, _junto_a_isla(guarida, TIPOS[tipo]["radio"]))


func vaciar() -> void:
	for monstruo in monstruos:
		monstruo.nodo.queue_free()
	monstruos.clear()


# La guarida se aparta de las islas hasta quedar pegada a su orilla, en el agua.
func _junto_a_isla(punto: Vector2, radio: float) -> Vector2:
	for _vuelta in 4:
		for isla in mundo.islas.cerca(punto, radio + 60.0):
			var sep: Vector2 = punto - isla.pos
			var minimo: float = isla.borde(punto) + radio + CORRO + 30.0
			if sep.length() < minimo:
				punto = isla.pos + (sep.normalized() if sep != Vector2.ZERO else Vector2.RIGHT) * minimo
	return punto


func _crear(tipo: String, guarida: Vector2) -> void:
	var datos: Dictionary = TIPOS[tipo]
	var monstruo := Monstruo.new()
	monstruo.tipo = tipo
	monstruo.guarida = guarida
	monstruo.fase = randf() * TAU
	monstruo.pos = guarida + Vector2.from_angle(monstruo.fase) * CORRO
	monstruo.vida_max = datos["vida"]
	monstruo.vida = monstruo.vida_max
	monstruo.nodo = Node3D.new()
	monstruo.nodo.scale = Vector3.ONE * datos["escala"]
	add_child(monstruo.nodo)
	_armar(monstruo)
	monstruos.append(monstruo)


# Cuerpo de anillos que asoman del agua formando jorobas, cada uno con su púa dorada, y una
# cabeza con ojos amarillos, mandíbula y dos aletas a los lados. Mira hacia -Z.
func _armar(monstruo: Monstruo) -> void:
	var piel := mundo.material(COLOR_PIEL)
	var vientre := mundo.material(COLOR_VIENTRE)
	var aleta := mundo.material(COLOR_ALETA)
	for k in 7:
		var tramo := Node3D.new()
		tramo.position = Vector3(0, 0, 0.45 + k * 0.42)
		monstruo.nodo.add_child(tramo)
		var grueso := lerpf(0.62, 0.28, k / 6.0)
		_pieza(tramo, esfera, piel, Vector3.ZERO, Vector3(grueso, grueso, grueso * 1.25))
		_pieza(tramo, esfera, vientre, Vector3(0, -grueso * 0.16, 0), Vector3(grueso * 0.8, grueso * 0.7, grueso * 1.1))
		_pieza(tramo, cono, aleta, Vector3(0, grueso * 0.55, 0), Vector3(0.12, grueso * 0.6, 0.22))
		monstruo.tramos.append(tramo)
	var cola := _pieza(monstruo.tramos[-1], cono, aleta, Vector3(0, 0.05, 0.3), Vector3(0.45, 0.4, 0.05))
	cola.rotation.x = -PI / 2.0
	monstruo.cabeza = Node3D.new()
	monstruo.cabeza.position = Vector3(0, 0.5, 0)
	monstruo.nodo.add_child(monstruo.cabeza)
	var cabeza := monstruo.cabeza
	_pieza(cabeza, esfera, piel, Vector3(0, 0, 0), Vector3(0.72, 0.6, 0.95))
	_pieza(cabeza, esfera, piel, Vector3(0, -0.05, -0.42), Vector3(0.5, 0.36, 0.6))
	_pieza(cabeza, esfera, vientre, Vector3(0, -0.2, -0.32), Vector3(0.44, 0.18, 0.62))
	for lado: float in [-1.0, 1.0]:
		_pieza(cabeza, esfera, mundo.material(Color("ffd84a")), Vector3(lado * 0.24, 0.16, -0.24), Vector3.ONE * 0.18)
		_pieza(cabeza, esfera, mundo.material(Color("141414")), Vector3(lado * 0.28, 0.17, -0.3), Vector3(0.05, 0.12, 0.05))
		var oreja := _pieza(cabeza, cono, aleta, Vector3(lado * 0.36, 0.12, 0.15), Vector3(0.1, 0.42, 0.3))
		oreja.rotation = Vector3(0.5, 0, -lado * 1.1)
		var cuerno := _pieza(cabeza, cono, mundo.material(Color("f2ead8")), Vector3(lado * 0.14, 0.32, 0.05), Vector3(0.09, 0.3, 0.09))
		cuerno.rotation.x = 0.6
	for m in 3:
		_pieza(cabeza, cono, aleta, Vector3(0, 0.3 - m * 0.04, 0.2 + m * 0.18), Vector3(0.08, 0.3 - m * 0.06, 0.18))


func _pieza(padre: Node3D, malla: Mesh, materia: Material, pos: Vector3, escala: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = materia
	pieza.position = pos
	pieza.scale = escala
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(pieza)
	return pieza


func actualizar(delta: float) -> void:
	for monstruo in monstruos:
		if not monstruo.viva:
			monstruo.espera -= delta
			if monstruo.espera <= 0.0:
				_revivir(monstruo)
			continue
		monstruo.destello = maxf(0.0, monstruo.destello - delta * 3.0)
		monstruo.recarga -= delta
		var agresor := monstruo.agresor
		if agresor != null and (not is_instance_valid(agresor) or not agresor.viva or agresor.pos.distance_to(monstruo.guarida) > CORREA \
				or moba.escondido(agresor)):
			monstruo.agresor = null
			agresor = null
		if agresor != null:
			_pelear(monstruo, agresor, delta)
		else:
			_nadar(monstruo, delta)
		_apartar_barcos(monstruo)
		_mostrar(monstruo, delta)


func _nadar(monstruo: Monstruo, delta: float) -> void:
	monstruo.furia = maxf(0.0, monstruo.furia - delta)
	monstruo.vida = minf(monstruo.vida_max, monstruo.vida + monstruo.vida_max * CURA_EN_CASA * delta)
	monstruo.fase += VEL_NADO * delta
	var meta := monstruo.guarida + Vector2.from_angle(monstruo.fase) * CORRO
	var hacia := meta - monstruo.pos
	if hacia.length() > 1.0:
		monstruo.rumbo = lerp_angle(monstruo.rumbo, atan2(hacia.x, -hacia.y), minf(1.0, delta * 3.0))
		monstruo.pos = monstruo.pos.move_toward(meta, maxf(VEL_NADO * CORRO, hacia.length() * 0.8) * delta)


func _pelear(monstruo: Monstruo, agresor: Barco, delta: float) -> void:
	monstruo.furia = minf(1.0, monstruo.furia + delta * 3.0)
	var hacia := agresor.pos - monstruo.pos
	monstruo.rumbo = lerp_angle(monstruo.rumbo, atan2(hacia.x, -hacia.y), minf(1.0, delta * 4.0))
	var distancia := hacia.length()
	if distancia > ALCANCE_ESCUPIR * 0.75 and monstruo.pos.distance_to(monstruo.guarida) < CORREA * 0.6:
		monstruo.pos += hacia.normalized() * VEL_CAZA * delta
	if distancia < ALCANCE_ESCUPIR and monstruo.recarga <= 0.0:
		monstruo.recarga = RECARGA_ESCUPIR
		_escupir(monstruo, agresor)


func _escupir(monstruo: Monstruo, blanco: Barco) -> void:
	var desde := monstruo.pos
	var previsto := blanco.pos + blanco.proa() * blanco.velocidad * desde.distance_to(blanco.pos) / Principal.VEL_BALA * 0.5
	var direccion := (previsto - desde).normalized()
	var radio: float = TIPOS[monstruo.tipo]["radio"]
	var bala := mundo.disparar_desde(desde + direccion * (radio + 6.0), direccion, null, null, EQUIPO, TIPOS[monstruo.tipo]["danio"])
	bala.nodo.material_override = material_saliva
	bala.nodo.scale = Vector3.ONE * 1.4
	mundo.salpicar(desde + direccion * radio, 3)


func _apartar_barcos(monstruo: Monstruo) -> void:
	var radio: float = TIPOS[monstruo.tipo]["radio"]
	for heroe in moba.heroes:
		var barco := heroe.barco
		if not barco.viva:
			continue
		var sep := barco.pos - monstruo.pos
		var minimo := radio + barco.radio * 0.6
		if sep.length() < minimo:
			barco.pos = monstruo.pos + (sep.normalized() if sep != Vector2.ZERO else Vector2.RIGHT) * minimo


func _mostrar(monstruo: Monstruo, _delta: float) -> void:
	var nodo := monstruo.nodo
	nodo.visible = mundo.a_3d(monstruo.pos).distance_to(Vector3(mundo.foco.x, 0.0, mundo.foco.z)) < mundo.alcance_vista() + 4.0
	if not nodo.visible:
		return
	var sitio := mundo.a_3d(monstruo.pos)
	var t := mundo.tiempo * (1.0 + monstruo.furia)
	nodo.position = Vector3(sitio.x, mundo.altura_mar(sitio.x, sitio.z) - 0.25, sitio.z)
	nodo.rotation.y = -monstruo.rumbo
	for k in monstruo.tramos.size():
		var tramo := monstruo.tramos[k]
		tramo.position.y = sin(t * 3.0 - k * 0.9) * 0.28
		tramo.position.x = sin(t * 1.6 - k * 0.6) * 0.12 * k / 6.0
	var alza := 0.5 + monstruo.furia * 0.35 + sin(t * 2.0) * 0.08
	monstruo.cabeza.position.y = alza
	monstruo.cabeza.rotation.x = -monstruo.furia * 0.25 + sin(t * 2.0) * 0.06 + (0.35 if monstruo.recarga > RECARGA_ESCUPIR - 0.25 else 0.0)
	monstruo.cabeza.rotation.z = sin(t * 1.3) * 0.12


func _revivir(monstruo: Monstruo) -> void:
	monstruo.viva = true
	monstruo.vida = monstruo.vida_max
	monstruo.pos = monstruo.guarida
	monstruo.agresor = null
	monstruo.furia = 0.0
	monstruo.nodo.visible = true
	mundo.salpicar(monstruo.pos, 10)


# Balas que alcanzan a un monstruo; devuelve true si la bala se detiene.
func recibir_bala(bala: Principal.Bala) -> bool:
	if bala.equipo == EQUIPO:
		return false
	for monstruo in monstruos:
		if monstruo.viva and monstruo.pos.distance_to(bala.pos) < TIPOS[monstruo.tipo]["radio"] + 4.0:
			danar(monstruo, mundo._danio_bala(bala), bala.dueno)
			mundo.salpicar(bala.pos, 4)
			return true
	return false


# Daño de habilidades en área.
func danar_zona(centro: Vector2, alcance: float, cantidad: float, atacante: Barco) -> void:
	for monstruo in monstruos:
		if monstruo.viva and monstruo.pos.distance_to(centro) < alcance + TIPOS[monstruo.tipo]["radio"]:
			danar(monstruo, cantidad, atacante)


func danar(monstruo: Monstruo, cantidad: float, atacante: Barco) -> void:
	monstruo.vida -= cantidad
	monstruo.destello = 1.0
	if is_instance_valid(atacante) and atacante.viva:
		monstruo.agresor = atacante
	if monstruo.vida <= 0.0:
		_vencer(monstruo, atacante)


func _vencer(monstruo: Monstruo, verdugo: Barco) -> void:
	var datos: Dictionary = TIPOS[monstruo.tipo]
	monstruo.viva = false
	monstruo.vida = 0.0
	monstruo.agresor = null
	monstruo.espera = REAPARICION
	monstruo.nodo.visible = false
	mundo.salpicar(monstruo.pos, 16)
	var centro := mundo.a_3d(monstruo.pos, 0.6)
	for _i in 10:
		var vel := Vector3(randf_range(-1.6, 1.6), randf_range(2.0, 4.0), randf_range(-1.6, 1.6))
		mundo.crear_efecto(mundo.malla_gota, Color(COLOR_PIEL.lightened(0.3), 0.9), centro, vel, 1.0, 1.4, 0.0, 9.0)
	var cazador: Moba.Heroe = moba.de_barco.get(verdugo) if verdugo != null else null
	if cazador == null:
		return
	moba._ganar_oro(cazador, datos["oro"], mundo.a_3d(monstruo.pos, 2.0))
	for heroe in moba.heroes:
		if heroe.equipo == cazador.equipo and heroe.barco.viva and heroe.barco.pos.distance_to(monstruo.pos) < Moba.ALCANCE_XP:
			moba._ganar_xp(heroe, datos["xp"])
	if verdugo == mundo.jugador:
		moba._anunciar(tr("¡%s derrotada!") % tr(datos["nombre"]), Principal.COLOR_ORO)


# Barra de vida sobre cada monstruo a la vista.
func dibujar(lienzo: Control, camara: Camera3D) -> void:
	for monstruo in monstruos:
		if not monstruo.viva or not monstruo.nodo.visible:
			continue
		var punto := mundo.a_3d(monstruo.pos, 2.4 * TIPOS[monstruo.tipo]["escala"])
		if camara.is_position_behind(punto):
			continue
		var ancho := 70.0 if monstruo.tipo == "gran_serpiente" else 52.0
		moba._barra(lienzo, camara.unproject_position(punto), ancho, monstruo.vida / monstruo.vida_max, COLOR_BARRA, monstruo.destello)


func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	for monstruo in monstruos:
		var punto := centro + monstruo.guarida * escala
		var grande := monstruo.tipo == "gran_serpiente"
		if monstruo.viva:
			lienzo.draw_circle(punto, 5.0 if grande else 4.0, Color("08161c"))
			lienzo.draw_circle(punto, 3.8 if grande else 2.8, COLOR_BARRA)
		else:
			lienzo.draw_arc(punto, 3.5, 0.0, TAU, 12, Color(COLOR_BARRA, 0.45), 1.5, true)
