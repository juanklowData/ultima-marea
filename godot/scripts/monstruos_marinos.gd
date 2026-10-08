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
const TRAMOS := 13
const SEPARACION_TRAMOS := 0.22
const COLOR_PIEL := Color("2f8f7f")
const COLOR_LOMO := Color("1d5f5a")
const COLOR_MANCHA := Color("8fe0c8")
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
	# Daño continuo de la bola de fuego (ardiendo) o de las cadenas.
	var ardor := 0.0
	var ardor_danio := 0.0
	var ardor_fuego := false
	var ardor_de: Barco
	var agresor: Barco
	var nodo: Node3D
	var cabeza: Node3D
	var mandibula: Node3D
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


# Cuerpo continuo de anillos solapados que se afinan hacia la cola: lomo oscuro con manchas
# claras, vientre dorado y una cresta de aletas finas. El cuello sube hasta la cabeza, que
# lleva ojos de reptil, cejas, dientes, mandíbula móvil, aletas a los lados y su cresta.
# Termina en una aleta de cola en abanico. Mira hacia -Z.
func _armar(monstruo: Monstruo) -> void:
	var piel := mundo.material(COLOR_PIEL)
	var lomo := mundo.material(COLOR_LOMO)
	var vientre := mundo.material(COLOR_VIENTRE)
	var aleta := mundo.material(COLOR_ALETA)
	var mancha := mundo.material(COLOR_MANCHA)
	var hueso := mundo.material(Color("f2ead8"))
	var ultimo := TRAMOS - 1
	for k in TRAMOS:
		var tramo := Node3D.new()
		tramo.position = Vector3(0, 0, 0.3 + k * SEPARACION_TRAMOS)
		tramo.set_meta("base", 0.42 * (1.0 - smoothstep(0.0, 4.0, k)) + 0.04)
		monstruo.nodo.add_child(tramo)
		var g := lerpf(0.58, 0.16, float(k) / ultimo)
		_pieza(tramo, esfera, piel, Vector3.ZERO, Vector3(g, g * 0.9, g * 1.45))
		_pieza(tramo, esfera, lomo, Vector3(0, g * 0.2, 0), Vector3(g * 0.7, g * 0.55, g * 1.4))
		_pieza(tramo, esfera, vientre, Vector3(0, -g * 0.2, 0), Vector3(g * 0.78, g * 0.6, g * 1.3))
		if k % 2 == 1:
			for lado: float in [-1.0, 1.0]:
				_pieza(tramo, esfera, mancha, Vector3(lado * g * 0.36, g * 0.12, 0), Vector3(g * 0.22, g * 0.2, g * 0.32))
		var cresta := _pieza(tramo, cono, aleta, Vector3(0, g * 0.5, g * 0.15), Vector3(0.035, g * 0.75, g * 1.1))
		cresta.rotation.x = 0.35
		monstruo.tramos.append(tramo)
	var cola := _pieza(monstruo.tramos[ultimo], cono, aleta, Vector3(0, 0.02, 0.28), Vector3(0.7, 0.5, 0.04))
	cola.rotation.x = -PI / 2.0
	monstruo.cabeza = Node3D.new()
	monstruo.cabeza.position = Vector3(0, 0.5, -0.05)
	monstruo.nodo.add_child(monstruo.cabeza)
	var cabeza := monstruo.cabeza
	_pieza(cabeza, esfera, piel, Vector3.ZERO, Vector3(0.66, 0.52, 0.8))
	_pieza(cabeza, esfera, lomo, Vector3(0, 0.12, 0.04), Vector3(0.5, 0.34, 0.72))
	_pieza(cabeza, esfera, piel, Vector3(0, -0.02, -0.4), Vector3(0.46, 0.3, 0.58))
	for lado: float in [-1.0, 1.0]:
		_pieza(cabeza, esfera, lomo, Vector3(lado * 0.08, 0.06, -0.66), Vector3(0.07, 0.05, 0.06))
		_pieza(cabeza, esfera, mundo.material(Color("ffd84a")), Vector3(lado * 0.25, 0.13, -0.2), Vector3.ONE * 0.2)
		_pieza(cabeza, esfera, mundo.material(Color("141414")), Vector3(lado * 0.33, 0.13, -0.24), Vector3(0.05, 0.15, 0.06))
		_pieza(cabeza, esfera, lomo, Vector3(lado * 0.23, 0.25, -0.2), Vector3(0.18, 0.08, 0.26))
		var oreja := _pieza(cabeza, cono, aleta, Vector3(lado * 0.32, 0.05, 0.18), Vector3(0.04, 0.5, 0.4))
		oreja.rotation = Vector3(0.9, 0, -lado * 1.2)
		var cuerno := _pieza(cabeza, cono, hueso, Vector3(lado * 0.15, 0.3, 0.12), Vector3(0.08, 0.32, 0.08))
		cuerno.rotation.x = 0.8
		for m in 2:
			var diente := _pieza(cabeza, cono, hueso, Vector3(lado * (0.08 + m * 0.08), -0.15, -0.6 + m * 0.1), Vector3(0.05, 0.1, 0.05))
			diente.rotation.x = PI
	for m in 3:
		var pua := _pieza(cabeza, cono, aleta, Vector3(0, 0.3 - m * 0.04, 0.12 + m * 0.16), Vector3(0.035, 0.32 - m * 0.06, 0.24))
		pua.rotation.x = 0.4
	monstruo.mandibula = Node3D.new()
	monstruo.mandibula.position = Vector3(0, -0.14, -0.08)
	cabeza.add_child(monstruo.mandibula)
	_pieza(monstruo.mandibula, esfera, vientre, Vector3(0, -0.02, -0.3), Vector3(0.4, 0.14, 0.58))
	for lado: float in [-1.0, 1.0]:
		_pieza(monstruo.mandibula, cono, hueso, Vector3(lado * 0.1, 0.06, -0.48), Vector3(0.045, 0.09, 0.045))


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
		if monstruo.ardor > 0.0:
			monstruo.ardor -= delta
			if monstruo.ardor_fuego and monstruo.nodo.visible and randf() < delta * 14.0:
				var chispa := Vector3(randf_range(-0.6, 0.6), randf_range(1.0, 2.0), randf_range(-0.6, 0.6))
				mundo.crear_efecto(mundo.malla_humo, Color(1.0, randf_range(0.4, 0.75), 0.1, 0.9), mundo.a_3d(monstruo.pos, 0.8), chispa, 0.5, 0.3, 0.6)
			danar(monstruo, monstruo.ardor_danio * delta, monstruo.ardor_de)
			if not monstruo.viva:
				continue
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
	var ultimo := monstruo.tramos.size() - 1
	for k in monstruo.tramos.size():
		var tramo := monstruo.tramos[k]
		var cuerpo := minf(1.0, k / 3.0)
		tramo.position.y = tramo.get_meta("base") + monstruo.furia * 0.3 * (1.0 - cuerpo) + sin(t * 3.0 - k * 0.5) * 0.16 * cuerpo
		tramo.position.x = sin(t * 1.6 - k * 0.4) * 0.14 * k / ultimo
	var escupe := monstruo.recarga > RECARGA_ESCUPIR - 0.3
	monstruo.cabeza.position.y = 0.5 + monstruo.furia * 0.3 + sin(t * 2.0) * 0.06
	monstruo.cabeza.rotation.x = -monstruo.furia * 0.2 + sin(t * 2.0) * 0.05 + (0.25 if escupe else 0.0)
	monstruo.cabeza.rotation.z = sin(t * 1.3) * 0.1
	monstruo.mandibula.rotation.x = 0.55 if escupe else 0.06 + monstruo.furia * 0.12 + sin(t * 2.4) * 0.04


func _revivir(monstruo: Monstruo) -> void:
	monstruo.viva = true
	monstruo.vida = monstruo.vida_max
	monstruo.pos = monstruo.guarida
	monstruo.agresor = null
	monstruo.furia = 0.0
	monstruo.ardor = 0.0
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
			if monstruo.viva and bala.tipo == "bola_fuego":
				_encender(monstruo, Comercio.DURACION_FUEGO, Comercio.DANIO_FUEGO, true, bala.dueno)
			elif monstruo.viva and bala.tipo == "cadenas":
				_encender(monstruo, Moba.DURACION_ATRAPADO, Moba.DANIO_ATRAPADO, false, bala.dueno)
			return true
	return false


func _encender(monstruo: Monstruo, dura: float, por_segundo: float, fuego: bool, atacante: Barco) -> void:
	monstruo.ardor = dura
	monstruo.ardor_danio = por_segundo * (atacante.factor_danio if is_instance_valid(atacante) else 1.0)
	monstruo.ardor_fuego = fuego
	monstruo.ardor_de = atacante


func vivos_cerca(punto: Vector2, alcance: float) -> Array[Monstruo]:
	var lista: Array[Monstruo] = []
	for monstruo in monstruos:
		if monstruo.viva and monstruo.pos.distance_to(punto) < alcance + TIPOS[monstruo.tipo]["radio"]:
			lista.append(monstruo)
	return lista


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
	monstruo.ardor = 0.0
	monstruo.espera = REAPARICION
	monstruo.nodo.visible = false
	mundo.salpicar(monstruo.pos, 16)
	var centro := mundo.a_3d(monstruo.pos, 0.6)
	for _i in 10:
		var vel := Vector3(randf_range(-1.6, 1.6), randf_range(2.0, 4.0), randf_range(-1.6, 1.6))
		mundo.crear_efecto(mundo.malla_gota, Color(COLOR_PIEL.lightened(0.3), 0.9), centro, vel, 1.0, 1.4, 0.0, 9.0)
	var cazador: Moba.Heroe = moba.de_barco.get(verdugo) if is_instance_valid(verdugo) else null
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
