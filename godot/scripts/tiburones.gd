class_name Tiburones
extends Node3D

# Tiburones que patrullan su zona con la aleta fuera del agua. Si un barco les pasa cerca,
# lo muerden y se apartan un momento antes de volver: ese es el momento de dispararles.

const CANTIDAD := 10
const VIDA := 44.0
const VEL_PATRULLA := 20.0
const VEL_CAZA := 44.0
const GIRO := 2.4
# Patrulla una zona amplia alrededor de su sitio, pero solo ataca a los barcos que pasan cerca
# y los deja en cuanto se alejan: no persigue sin fin.
const ZONA := 500.0
const ALERTA := 200.0
const ABANDONO := 300.0
const DESINTERES := 5.0
const RADIO_CUERPO := 32.0
const ESCALA_MODELO := 1.6
const DANIO_MORDIDA := 6.0
const ESPERA_MORDIDA := 2.6
const DURACION_MORDIDA := 0.6
const HUIDA := 1.2
const MONEDAS := 3
const REAPARICION := 35.0
const DURACION_MUERTE := 4.0
const COLOR_LOMO := Color("5f7684")
const COLOR_VIENTRE := Color("e8e4da")
# Mar libre: un megalodón, tiburón gigante que caza de lejos, embiste y aguanta mucho.
const VIDA_MEGALODON := 300.0
const TAMANO_MEGALODON := 2.6
const ZONA_MEGALODON := 900.0
const ALERTA_MEGALODON := 380.0
const ABANDONO_MEGALODON := 650.0
const VEL_MEGALODON := 50.0
const DANIO_EMBESTIDA := 16.0
const ESPERA_EMBESTIDA := 3.6
const MONEDAS_MEGALODON := 40
const REAPARICION_MEGALODON := 420.0
const COLOR_MEGALODON := Color("3d4950")


class Tiburon:
	var pos := Vector2.ZERO
	var rumbo := 0.0
	var hogar := Vector2.ZERO
	var vida := VIDA
	var presa: Barco
	var rumbo_a := Vector2.ZERO
	var desinteres := 0.0
	var espera := 0.0
	var huida := 0.0
	var mordida := -1.0
	var muerte := -1.0
	var reaparece := 0.0
	var deriva := 0.0
	var fase := 0.0
	var destello := 0.0
	var altura := 0.0
	var nodo: Node3D
	var cola: Node3D
	var materia: StandardMaterial3D
	var gigante := false
	var color := COLOR_LOMO


var mundo: Principal
var tiburones: Array[Tiburon] = []
# Tiburones que ha vencido el jugador en esta partida.
var vencidos := 0
var esfera := SphereMesh.new()
var caja := BoxMesh.new()
var prisma := PrismMesh.new()
var cono := CylinderMesh.new()


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 12
	esfera.rings = 6
	prisma.left_to_right = 0.85
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 10
	cono.rings = 1


func vaciar() -> void:
	for tiburon in tiburones:
		tiburon.nodo.queue_free()
	tiburones.clear()
	vencidos = 0


func reiniciar() -> void:
	vaciar()
	for _i in CANTIDAD:
		var tiburon := Tiburon.new()
		tiburon.pos = _lugar_libre()
		tiburon.hogar = tiburon.pos
		tiburon.rumbo_a = _punto_patrulla(tiburon)
		tiburon.rumbo = randf() * TAU
		tiburon.deriva = randf() * TAU
		tiburon.fase = randf() * TAU
		_crear_modelo(tiburon)
		tiburones.append(tiburon)
	if mundo.modo == "libre":
		var megalodon := Tiburon.new()
		megalodon.gigante = true
		megalodon.vida = VIDA_MEGALODON
		megalodon.color = COLOR_MEGALODON
		megalodon.pos = _lugar_libre()
		megalodon.hogar = megalodon.pos
		megalodon.rumbo_a = _punto_patrulla(megalodon)
		megalodon.fase = randf() * TAU
		_crear_modelo(megalodon)
		megalodon.nodo.scale *= TAMANO_MEGALODON
		tiburones.append(megalodon)


func _zona(tiburon: Tiburon) -> float:
	return ZONA_MEGALODON if tiburon.gigante else ZONA


func _radio(tiburon: Tiburon) -> float:
	return RADIO_CUERPO * (TAMANO_MEGALODON if tiburon.gigante else 1.0)


func _lugar_libre() -> Vector2:
	var punto := Vector2.ZERO
	for _intento in 40:
		punto = mundo.centro_juego() + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * mundo.alcance_juego() * 0.85
		var libre := true
		for isla in mundo.islotes:
			if punto.distance_to(isla.pos) < isla.radio + 120.0:
				libre = false
		for barco in mundo.barcos:
			if barco.viva and punto.distance_to(barco.pos) < 700.0:
				libre = false
		if libre and _tranquila(punto, ZONA):
			libre = false
		if libre:
			return punto
	return punto


# Tiburón con morro afilado, branquias, aletas barridas hacia atrás y cola en media luna que
# se mueve junto con el tramo final del cuerpo. La cabeza mira a -Z.
func _crear_modelo(tiburon: Tiburon) -> void:
	var nodo := Node3D.new()
	add_child(nodo)
	tiburon.nodo = nodo
	tiburon.materia = StandardMaterial3D.new()
	tiburon.materia.albedo_color = tiburon.color
	tiburon.materia.roughness = 0.45
	var lomo := tiburon.materia
	var vientre := mundo.material(COLOR_VIENTRE)
	var oscuro := mundo.material(Color("15181b"))
	var atras := Vector3(0, 0, 1)
	_pieza(nodo, esfera, lomo, Vector3(0, 0, -0.1), Vector3(0.48, 0.42, 1.35))
	_pieza(nodo, esfera, lomo, Vector3(0, -0.01, -0.72), Vector3(0.4, 0.32, 0.75))
	var morro := _pieza(nodo, cono, lomo, Vector3(0, -0.03, -1.17), Vector3(0.36, 0.34, 0.26))
	morro.rotation.x = -PI / 2.0
	_pieza(nodo, esfera, vientre, Vector3(0, -0.11, -0.4), Vector3(0.42, 0.26, 1.55))
	_pieza(nodo, caja, oscuro, Vector3(0, -0.15, -0.95), Vector3(0.24, 0.02, 0.12))
	for lado in [-1.0, 1.0]:
		_pieza(nodo, esfera, oscuro, Vector3(lado * 0.17, 0.05, -0.93), Vector3.ONE * 0.065)
		for k in 4:
			var branquia := _pieza(nodo, caja, oscuro, Vector3(lado * 0.215, -0.02, -0.6 + k * 0.07), Vector3(0.012, 0.17 - k * 0.015, 0.014))
			branquia.rotation.x = 0.2
		_aleta(nodo, lomo, Vector3(lado * 0.2, -0.13, -0.42), atras, Vector3(lado, -0.35, 0), Vector3(0.42, 0.55, 0.03))
	_aleta(nodo, lomo, Vector3(0, 0.18, -0.12), atras, Vector3.UP, Vector3(0.62, 0.62, 0.05))
	tiburon.cola = Node3D.new()
	tiburon.cola.position = Vector3(0, 0, 0.45)
	nodo.add_child(tiburon.cola)
	_pieza(tiburon.cola, esfera, lomo, Vector3(0, 0.0, 0.0), Vector3(0.4, 0.36, 0.7))
	_pieza(tiburon.cola, esfera, lomo, Vector3(0, 0.0, 0.35), Vector3(0.26, 0.24, 0.8))
	_pieza(tiburon.cola, esfera, vientre, Vector3(0, -0.07, 0.15), Vector3(0.3, 0.18, 0.75))
	_aleta(tiburon.cola, lomo, Vector3(0, 0.1, 0.35), atras, Vector3.UP, Vector3(0.18, 0.18, 0.03))
	_aleta(tiburon.cola, lomo, Vector3(0, -0.1, 0.4), atras, Vector3.DOWN, Vector3(0.15, 0.13, 0.02))
	for lado in [-1.0, 1.0]:
		_aleta(tiburon.cola, lomo, Vector3(lado * 0.08, -0.12, 0.08), atras, Vector3(lado, -0.6, 0), Vector3(0.18, 0.16, 0.02))
	_aleta(tiburon.cola, lomo, Vector3(0, -0.06, 0.62), Vector3(0, 1, 0.75), Vector3(0, 0.6, -1), Vector3(0.8, 0.2, 0.03))
	_aleta(tiburon.cola, lomo, Vector3(0, 0.04, 0.62), Vector3(0, -1, 0.6), Vector3(0, -0.5, -1), Vector3(0.46, 0.16, 0.03))
	nodo.scale = Vector3.ONE * ESCALA_MODELO


# Aleta triangular: la base sigue "base" y la punta sale hacia "punta", inclinada hacia el
# final de la base (el prisma tiene el vértice corrido).
func _aleta(padre: Node3D, materia: Material, pos: Vector3, base: Vector3, punta: Vector3, escala: Vector3) -> MeshInstance3D:
	var pieza := _pieza(padre, prisma, materia, pos, Vector3.ONE)
	var x := base.normalized()
	var y := (punta - x * punta.dot(x)).normalized()
	pieza.basis = Basis(x * escala.x, y * escala.y, x.cross(y) * escala.z)
	pieza.position += y * escala.y * 0.5
	return pieza

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
	for tiburon in tiburones:
		if tiburon.muerte >= 0.0:
			tiburon.muerte += delta
			if tiburon.muerte >= DURACION_MUERTE:
				tiburon.reaparece -= delta
				if tiburon.reaparece <= 0.0:
					_revivir(tiburon)
			continue
		_mover(tiburon, delta)


func _revivir(tiburon: Tiburon) -> void:
	tiburon.pos = _lugar_libre()
	tiburon.hogar = tiburon.pos
	tiburon.rumbo_a = _punto_patrulla(tiburon)
	tiburon.vida = VIDA_MEGALODON if tiburon.gigante else VIDA
	tiburon.muerte = -1.0
	tiburon.mordida = -1.0
	tiburon.presa = null
	tiburon.nodo.rotation = Vector3.ZERO


func _mover(tiburon: Tiburon, delta: float) -> void:
	tiburon.espera = maxf(0.0, tiburon.espera - delta)
	tiburon.huida = maxf(0.0, tiburon.huida - delta)
	tiburon.destello = maxf(0.0, tiburon.destello - delta * 3.0)
	if tiburon.mordida >= 0.0:
		tiburon.mordida += delta / DURACION_MORDIDA
		if tiburon.mordida >= 1.0:
			tiburon.mordida = -1.0

	tiburon.desinteres = maxf(0.0, tiburon.desinteres - delta)
	if _tranquila(tiburon.hogar, _zona(tiburon)):
		var fuera := (tiburon.hogar - mundo.libre.centro_calma(tiburon.hogar, _zona(tiburon))).normalized()
		tiburon.hogar += (fuera if fuera != Vector2.ZERO else Vector2.RIGHT) * VEL_CAZA * delta
		tiburon.rumbo_a = tiburon.hogar
	var zona := _zona(tiburon)
	var presa: Barco = tiburon.presa
	var abandono := ABANDONO_MEGALODON if tiburon.gigante else ABANDONO
	if presa != null and (_tranquila(presa.pos) or not presa.viva or presa.pos.distance_to(tiburon.pos) > abandono or presa.pos.distance_to(tiburon.hogar) > zona + 100.0):
		presa = null
		tiburon.desinteres = DESINTERES
	if presa == null and tiburon.desinteres <= 0.0:
		var cercania := ALERTA_MEGALODON if tiburon.gigante else ALERTA
		for barco in mundo.barcos:
			if barco.viva and barco.pos.distance_to(tiburon.pos) < cercania and barco.pos.distance_to(tiburon.hogar) < zona and not _tranquila(barco.pos):
				cercania = barco.pos.distance_to(tiburon.pos)
				presa = barco
		if tiburon.gigante and presa == mundo.jugador and mundo.modo == "libre":
			mundo.libre._anunciar(tr("¡Un megalodón viene a por ti!"), Principal.COLOR_PELIGRO)
	tiburon.presa = presa
	var mejor := presa.pos.distance_to(tiburon.pos) if presa != null else INF

	var deseado: Vector2
	var velocidad := VEL_PATRULLA
	if presa != null and tiburon.huida > 0.0:
		deseado = (tiburon.pos - presa.pos).normalized()
		velocidad = (VEL_MEGALODON if tiburon.gigante else VEL_CAZA) * 1.1
	elif presa != null:
		deseado = (presa.pos - tiburon.pos).normalized()
		velocidad = VEL_MEGALODON if tiburon.gigante else VEL_CAZA
		if mejor < presa.radio + (60.0 if tiburon.gigante else 22.0) and tiburon.espera <= 0.0:
			_morder(tiburon, presa)
	else:
		if tiburon.pos.distance_to(tiburon.rumbo_a) < 50.0:
			tiburon.rumbo_a = _punto_patrulla(tiburon)
		tiburon.deriva += randf_range(-1.0, 1.0) * delta
		deseado = (tiburon.rumbo_a - tiburon.pos).normalized().rotated(sin(tiburon.deriva) * 0.3)
	for isla in mundo.islotes:
		var sep: Vector2 = tiburon.pos - isla.pos
		var limite: float = isla.radio + 90.0
		if sep.length() < limite and sep != Vector2.ZERO:
			deseado += sep.normalized() * (1.5 - sep.length() / limite)
	if deseado != Vector2.ZERO:
		var angulo := atan2(deseado.x, -deseado.y)
		var diferencia := angle_difference(tiburon.rumbo, angulo)
		tiburon.rumbo = wrapf(tiburon.rumbo + clampf(diferencia, -GIRO * delta, GIRO * delta), -PI, PI)
	tiburon.pos += Vector2.UP.rotated(tiburon.rumbo) * velocidad * delta
	tiburon.pos = tiburon.hogar + (tiburon.pos - tiburon.hogar).limit_length(zona + 60.0)
	for isla in mundo.islotes:
		var sep: Vector2 = tiburon.pos - isla.pos
		var minimo: float = isla.borde(tiburon.pos) + 20.0
		if sep.length() < minimo and sep != Vector2.ZERO:
			tiburon.pos = isla.pos + sep.normalized() * minimo
	if presa != null:
		var sep := tiburon.pos - presa.pos
		var minimo := presa.radio * 0.7 + (45.0 if tiburon.gigante else 14.0)
		if sep.length() < minimo and sep != Vector2.ZERO:
			tiburon.pos = presa.pos + sep.normalized() * minimo


func _tranquila(punto: Vector2, margen := 0.0) -> bool:
	return mundo.modo == "libre" and mundo.libre.tranquila(punto, margen)


# Un punto de agua libre dentro de la zona, hacia el que nada mientras patrulla.
func _punto_patrulla(tiburon: Tiburon) -> Vector2:
	var punto := tiburon.hogar
	for _intento in 8:
		punto = tiburon.hogar + Vector2.from_angle(randf() * TAU) * sqrt(randf_range(0.15, 1.0)) * _zona(tiburon)
		var libre := true
		for isla in mundo.islotes:
			if punto.distance_to(isla.pos) < isla.radio + 100.0:
				libre = false
		if libre:
			return punto
	return punto


# El megalodón no muerde: embiste, frena en seco el barco y lo empuja de lado.
func _morder(tiburon: Tiburon, presa: Barco) -> void:
	tiburon.espera = ESPERA_EMBESTIDA if tiburon.gigante else ESPERA_MORDIDA
	tiburon.huida = HUIDA
	tiburon.mordida = 0.0
	presa.recibir_danio(DANIO_EMBESTIDA if tiburon.gigante else DANIO_MORDIDA, true)
	presa.velocidad *= 0.25 if tiburon.gigante else 0.6
	if tiburon.gigante:
		presa.pos += (presa.pos - tiburon.pos).normalized() * 25.0
	mundo.salpicar(presa.pos.lerp(tiburon.pos, 0.5), 24 if tiburon.gigante else 10)
	if presa.es_jugador:
		mundo.golpe = maxf(mundo.golpe, 0.5 if tiburon.gigante else 0.25)
		mundo.avisar_combate()


# Las balas que alcanzan a un tiburón; devuelve true si la bala se detiene.
func recibir_bala(punto: Vector2, dueno: Barco) -> bool:
	for tiburon in tiburones:
		if tiburon.muerte >= 0.0 or punto.distance_to(tiburon.pos) > _radio(tiburon):
			continue
		tiburon.vida -= Principal.DANIO_BALA
		tiburon.destello = 1.0
		if not tiburon.gigante:
			tiburon.huida = maxf(tiburon.huida, 0.5)
		mundo.salpicar(punto, 6)
		if tiburon.vida <= 0.0:
			_vencer(tiburon, dueno)
		return true
	return false


# Un tiburón vivo que pasa por encima del punto (para que revienten los barriles).
func toca(punto: Vector2, margen: float) -> bool:
	for tiburon in tiburones:
		if tiburon.muerte < 0.0 and punto.distance_to(tiburon.pos) < _radio(tiburon) + margen:
			return true
	return false


# Un barril que revienta cerca también hiere a los tiburones.
func explosion(punto: Vector2, radio: float, danio: float, dueno: Barco) -> void:
	for tiburon in tiburones:
		if tiburon.muerte >= 0.0:
			continue
		var distancia := punto.distance_to(tiburon.pos)
		if distancia >= radio:
			continue
		tiburon.vida -= danio * (1.0 - distancia / radio)
		tiburon.destello = 1.0
		tiburon.huida = maxf(tiburon.huida, 1.0)
		if tiburon.vida <= 0.0:
			_vencer(tiburon, dueno)


func _vencer(tiburon: Tiburon, dueno: Barco) -> void:
	tiburon.muerte = 0.0
	tiburon.reaparece = REAPARICION_MEGALODON if tiburon.gigante else REAPARICION
	tiburon.presa = null
	tiburon.desinteres = 0.0
	mundo.salpicar(tiburon.pos, 16)
	if dueno == mundo.jugador:
		vencidos += 1
		mundo.recompensas.al_vencer("megalodon" if tiburon.gigante else "tiburones")
	# El botín queda flotando en el mar: se lo lleva quien pase a recogerlo.
	if tiburon.gigante:
		mundo.soltar_cofre(tiburon.pos, MONEDAS_MEGALODON)
		if mundo.modo == "libre":
			var botin: Array[String] = [Objetos.de_rareza(2), Objetos.de_rareza(3)]
			mundo.comercio.soltar_botin(tiburon.pos + Vector2(40, 0), botin, {"metal": 6})
			if dueno == mundo.jugador:
				mundo.libre._anunciar(tr("¡Venciste al megalodón!"), Principal.COLOR_ORO)
		return
	mundo.soltar_cofre(tiburon.pos, MONEDAS)


func vivos() -> Array[Tiburon]:
	var lista: Array[Tiburon] = []
	for tiburon in tiburones:
		if tiburon.muerte < 0.0:
			lista.append(tiburon)
	return lista


func aviso(barco: Barco) -> String:
	for tiburon in tiburones:
		if tiburon.muerte < 0.0 and tiburon.presa == barco and tiburon.pos.distance_to(barco.pos) < 350.0:
			return "¡Megalodón al acecho!" if tiburon.gigante else "¡Tiburón al acecho!"
	return ""


func animar(delta: float) -> void:
	var t := mundo.tiempo
	var foco_plano := Vector2(mundo.foco.x, mundo.foco.z)
	for tiburon in tiburones:
		var centro := tiburon.pos * Principal.ESCALA
		var cerca := centro.distance_to(foco_plano) < Principal.DISTANCIA_VISIBLE
		tiburon.nodo.visible = cerca and tiburon.muerte < DURACION_MUERTE
		if not tiburon.nodo.visible:
			continue
		var h := mundo.altura_mar(centro.x, centro.y)
		tiburon.altura = lerpf(tiburon.altura, h, minf(1.0, delta * 4.0))
		var y := tiburon.altura - (0.7 if tiburon.gigante else 0.2)
		var cabeceo := 0.0
		var vuelco := sin(t * 1.3 + tiburon.fase) * 0.05
		if tiburon.mordida >= 0.0:
			var salto := sin(PI * tiburon.mordida)
			y += salto * (1.4 if tiburon.gigante else 0.5)
			cabeceo = salto * 0.5
		if tiburon.muerte >= 0.0:
			vuelco = minf(tiburon.muerte * 2.0, PI)
			y = tiburon.altura - 0.1 - maxf(0.0, tiburon.muerte - 1.5) * 0.4
		tiburon.nodo.position = Vector3(centro.x, y, centro.y)
		tiburon.nodo.rotation = Vector3(cabeceo, -tiburon.rumbo, vuelco)
		var ritmo := 9.0 if tiburon.presa != null and tiburon.muerte < 0.0 else 4.0
		tiburon.cola.rotation.y = sin(t * ritmo + tiburon.fase) * (0.45 if tiburon.muerte < 0.0 else 0.05)
		tiburon.materia.albedo_color = tiburon.color.lerp(Color("ff8a7a"), tiburon.destello * 0.7)
