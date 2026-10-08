class_name Barriles
extends Node3D

# Barriles de pólvora a la deriva. Revientan si un barco los toca o si les alcanza una bala,
# dañando y empujando todo lo que haya cerca (barcos, krakens y tiburones), y hacen estallar
# a los barriles vecinos: dispararles junto a un rival es una buena trampa.

const CANTIDAD := 12
const RADIO := 14.0
const VEL := 5.0
const RADIO_EXPLOSION := 120.0
const DANIO_MAX := 24.0
const DANIO_MIN := 6.0
const EMPUJE := 40.0
const REAPARICION := 30.0
const MECHA_CADENA := 0.2
const AVISO := 110.0
const GRACIA_LANZADO := 2.0
const VIDA_LANZADO := 45.0
const COLOR_MADERA := Color("7a2a1c")
const COLOR_HIERRO := Color("262322")
const COLOR_FRANJA := Color("e8b828")
const COLOR_LUZ := Color("ff3b2a")


class Barril:
	var pos := Vector2.ZERO
	var pendiente := 0.0
	var rumbo := 0.0
	var fase := 0.0
	# -1 mientras flota; si no, segundos que faltan para que aparezca otro.
	var espera := -1.0
	# -1 sin encender; si no, segundos que faltan para que reviente.
	var mecha := -1.0
	var dueno: Barco
	var altura := 0.0
	var nodo: Node3D
	var luz: StandardMaterial3D
	# Tirado por la popa (mar libre): no reaparece, se hunde al rato y quien lo tira no lo
	# hace estallar mientras dure la gracia.
	var lanzado := false
	var gracia := 0.0
	var vida := 0.0


var mundo: Principal
var barriles: Array[Barril] = []
var cilindro := CylinderMesh.new()
var esfera := SphereMesh.new()


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	cilindro.top_radius = 0.5
	cilindro.bottom_radius = 0.5
	cilindro.height = 1.0
	cilindro.radial_segments = 12
	cilindro.rings = 1
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 8
	esfera.rings = 4


func vaciar() -> void:
	for barril in barriles:
		barril.nodo.queue_free()
	barriles.clear()


func reiniciar() -> void:
	vaciar()
	for _i in CANTIDAD:
		var barril := Barril.new()
		barril.pos = _lugar_libre()
		barril.rumbo = randf() * TAU
		barril.fase = randf() * TAU
		_crear_modelo(barril)
		barriles.append(barril)


func _lugar_libre() -> Vector2:
	var punto := Vector2.ZERO
	for _intento in 40:
		punto = mundo.centro_juego() + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * mundo.alcance_juego() * 0.85
		var libre := not mundo.peligros.cerca(punto, 150.0)
		for isla in mundo.islotes:
			if punto.distance_to(isla.pos) < isla.radio + 80.0:
				libre = false
		for barco in mundo.barcos:
			if barco.viva and punto.distance_to(barco.pos) < 450.0:
				libre = false
		for otro in barriles:
			if otro.espera < 0.0 and punto.distance_to(otro.pos) < 250.0:
				libre = false
		if libre:
			return punto
	return punto


# Barril rojo oscuro con aros de hierro, franja amarilla de aviso y una luz roja que parpadea.
func _crear_modelo(barril: Barril) -> void:
	var nodo := Node3D.new()
	add_child(nodo)
	barril.nodo = nodo
	var madera := mundo.material(COLOR_MADERA, "madera")
	var hierro := mundo.material(COLOR_HIERRO)
	_pieza(nodo, cilindro, madera, Vector3(0, 0.0, 0), Vector3(0.7, 0.9, 0.7))
	_pieza(nodo, esfera, madera, Vector3(0, 0.0, 0), Vector3(0.78, 0.6, 0.78))
	for y in [-0.3, 0.3]:
		_pieza(nodo, cilindro, hierro, Vector3(0, y, 0), Vector3(0.75, 0.05, 0.75))
	_pieza(nodo, cilindro, mundo.material(COLOR_FRANJA), Vector3(0, 0.0, 0), Vector3(0.8, 0.12, 0.8))
	_pieza(nodo, cilindro, hierro, Vector3(0, 0.46, 0), Vector3(0.6, 0.03, 0.6))
	_pieza(nodo, cilindro, hierro, Vector3(0, 0.56, 0), Vector3(0.04, 0.2, 0.04))
	barril.luz = StandardMaterial3D.new()
	barril.luz.albedo_color = COLOR_LUZ
	barril.luz.emission_enabled = true
	barril.luz.emission = COLOR_LUZ
	_pieza(nodo, esfera, barril.luz, Vector3(0, 0.7, 0), Vector3.ONE * 0.16)
	nodo.scale = Vector3.ONE * 1.3


func _pieza(padre: Node3D, malla: Mesh, materia: Material, pos: Vector3, escala: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = materia
	pieza.position = pos
	pieza.scale = escala
	padre.add_child(pieza)
	return pieza


func lanzar(punto: Vector2, dueno: Barco) -> void:
	var barril := Barril.new()
	barril.pos = punto
	barril.rumbo = randf() * TAU
	barril.fase = randf() * TAU
	barril.dueno = dueno
	barril.lanzado = true
	barril.gracia = GRACIA_LANZADO
	barril.vida = VIDA_LANZADO
	_crear_modelo(barril)
	barril.altura = 1.6
	barriles.append(barril)


func actualizar(delta_cuadro: float) -> void:
	for i in range(barriles.size() - 1, -1, -1):
		var barril := barriles[i]
		var delta := mundo.paso_lejano(barril, i, delta_cuadro)
		if delta <= 0.0:
			continue
		if barril.lanzado:
			barril.gracia -= delta
			barril.vida -= delta
			if barril.espera >= 0.0 or barril.vida <= 0.0:
				barril.nodo.queue_free()
				barriles.remove_at(i)
				continue
		if barril.espera >= 0.0:
			barril.espera -= delta
			if barril.espera < 0.0:
				barril.pos = _lugar_libre()
				barril.mecha = -1.0
				barril.dueno = null
				barril.espera = -1.0
			continue
		if barril.mecha >= 0.0:
			barril.mecha -= delta
			if barril.mecha < 0.0:
				_explotar(barril)
			continue
		_derivar(barril, delta)
		for barco in mundo.barcos:
			if barril.lanzado and barco == barril.dueno and barril.gracia > 0.0:
				continue
			# Fuera de este radio el casco no puede tocar el barril (medio eje 0,83 + media manga 0,5).
			var cerca := barco.radio * 1.4 + RADIO
			if barco.pos.distance_squared_to(barril.pos) > cerca * cerca:
				continue
			if barco.viva and _distancia_casco(barco, barril.pos) < barco.radio * Principal.MEDIA_MANGA_CASCO + RADIO:
				if not barril.lanzado:
					barril.dueno = null
				_explotar(barril)
				break
		if barril.mecha < 0.0 and barril.espera < 0.0 and (mundo.tiburones.toca(barril.pos, RADIO) or mundo.peligros.toca(barril.pos, RADIO)):
			_explotar(barril)


func _derivar(barril: Barril, delta: float) -> void:
	barril.rumbo += sin(mundo.tiempo * 0.2 + barril.fase) * 0.3 * delta
	var empuje := Vector2.from_angle(barril.rumbo)
	if barril.pos.distance_to(mundo.zona_centro) > mundo.zona_radio * 0.85:
		empuje += (mundo.zona_centro - barril.pos).normalized() * 2.0
	for isla in mundo.islas.cerca(barril.pos, 60.0):
		var sep: Vector2 = barril.pos - isla.pos
		if sep.length() >= isla.radio + 60.0:
			continue
		var limite: float = isla.borde(barril.pos) + 60.0
		if sep.length() < limite and sep != Vector2.ZERO:
			empuje += sep.normalized() * 2.0
	barril.rumbo = lerp_angle(barril.rumbo, empuje.angle(), minf(1.0, delta * 0.5))
	barril.pos += Vector2.from_angle(barril.rumbo) * VEL * delta
	barril.pos += mundo.peligros.arrastre(barril.pos) * delta
	for isla in mundo.islas.cerca(barril.pos, RADIO):
		var sep: Vector2 = barril.pos - isla.pos
		var minimo: float = isla.borde(barril.pos) + RADIO
		if sep.length() < minimo and sep != Vector2.ZERO:
			barril.pos = isla.pos + sep.normalized() * minimo


# Distancia del punto al eje del casco (la misma cápsula que usan los choques entre barcos).
func _distancia_casco(barco: Barco, punto: Vector2) -> float:
	var eje := barco.proa() * barco.radio * Principal.MEDIO_EJE_CASCO
	var desde := barco.pos - eje
	var tramo := eje * 2.0
	var t := clampf((punto - desde).dot(tramo) / tramo.length_squared(), 0.0, 1.0)
	return punto.distance_to(desde + tramo * t)


# Las balas que alcanzan un barril lo hacen estallar; devuelve true si la bala se detiene.
func recibir_bala(punto: Vector2, dueno: Barco) -> bool:
	for barril in barriles:
		if barril.espera >= 0.0 or barril.mecha >= 0.0:
			continue
		if punto.distance_to(barril.pos) < RADIO + 8.0:
			barril.dueno = dueno
			barril.mecha = 0.0
			return true
	return false


func _explotar(barril: Barril) -> void:
	barril.espera = REAPARICION
	barril.mecha = -1.0
	barril.nodo.visible = false
	var dueno := barril.dueno if barril.dueno != null and barril.dueno.viva else null
	for barco in mundo.barcos:
		if not barco.viva:
			continue
		var distancia := maxf(0.0, _distancia_casco(barco, barril.pos) - barco.radio * Principal.MEDIA_MANGA_CASCO)
		if distancia >= RADIO_EXPLOSION:
			continue
		var fuerza := 1.0 - distancia / RADIO_EXPLOSION
		barco.recibir_danio(lerpf(DANIO_MIN, DANIO_MAX, fuerza), false, dueno if dueno != barco else null)
		var sep := barco.pos - barril.pos
		if sep != Vector2.ZERO:
			barco.pos += sep.normalized() * EMPUJE * fuerza
		barco.velocidad *= 1.0 - 0.6 * fuerza
		if barco.es_jugador:
			mundo.golpe = maxf(mundo.golpe, 0.15 + 0.35 * fuerza)
			mundo.avisar_combate()
	mundo.peligros.explosion(barril.pos, RADIO_EXPLOSION, DANIO_MAX, dueno)
	mundo.tiburones.explosion(barril.pos, RADIO_EXPLOSION, DANIO_MAX, dueno)
	for otro in barriles:
		if otro != barril and otro.espera < 0.0 and otro.mecha < 0.0 and otro.pos.distance_to(barril.pos) < RADIO_EXPLOSION:
			otro.mecha = MECHA_CADENA
			otro.dueno = dueno
	_efectos(barril.pos)


# Destello, bola de fuego breve, humo oscuro, duelas que saltan y una columna de agua.
func _efectos(pos: Vector2) -> void:
	var centro := mundo.a_3d(pos, 0.5)
	mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.93, 0.7, 0.95), centro, Vector3.ZERO, 0.22, 1.6, 6.0)
	mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.55, 0.15, 0.9), centro, Vector3(0, 0.8, 0), 0.5, 1.4, 4.5)
	for _i in 6:
		var vel := Vector3(randf_range(-0.8, 0.8), randf_range(1.0, 2.2), randf_range(-0.8, 0.8))
		mundo.crear_efecto(mundo.malla_humo, Color(0.18, 0.16, 0.15, 0.7), centro + vel * 0.3, vel, randf_range(1.6, 2.4), 1.0, 2.6, 0.0, true)
	for _i in 12:
		var vel := Vector3(randf_range(-4.0, 4.0), randf_range(3.0, 7.0), randf_range(-4.0, 4.0))
		mundo.crear_efecto(mundo.malla_astilla, COLOR_MADERA.darkened(randf() * 0.3), centro, vel, 1.6, 1.4, 0.0, 10.0, true)
	mundo.salpicar(pos, 26)
	mundo.crear_efecto(mundo.malla_espuma, Color(1, 1, 1, 0.8), mundo.a_3d(pos, 0.17), Vector3.ZERO, 1.4, 1.5, 7.0)
	mundo.sonar_explosion(centro)


# Hacia dónde debería apartarse un bot para no chocar con un barril; Vector2.ZERO si no hay.
func evitar(barco: Barco) -> Vector2:
	var huida := Vector2.ZERO
	for barril in barriles:
		if barril.espera >= 0.0 or barril.lanzado:
			continue
		var sep := barco.pos - barril.pos
		var limite := barco.radio + RADIO + 90.0
		if sep.length() < limite and sep != Vector2.ZERO:
			huida += sep.normalized() * (1.2 - sep.length() / limite)
	return huida


func aviso(barco: Barco) -> String:
	for barril in barriles:
		if barril.espera < 0.0 and not barril.lanzado and barco.pos.distance_to(barril.pos) < barco.radio + AVISO:
			return "¡Cuidado: barril explosivo!"
	return ""


func animar(_delta: float) -> void:
	var t := mundo.tiempo
	var foco_plano := Vector2(mundo.foco.x, mundo.foco.z)
	for barril in barriles:
		var centro := barril.pos * Principal.ESCALA
		barril.nodo.visible = barril.espera < 0.0 and centro.distance_to(foco_plano) < Principal.DISTANCIA_VISIBLE
		if not barril.nodo.visible:
			continue
		barril.altura = lerpf(barril.altura, mundo.altura_mar(centro.x, centro.y), 0.2)
		barril.nodo.position = Vector3(centro.x, barril.altura - 0.15, centro.y)
		barril.nodo.rotation = Vector3(sin(t * 1.4 + barril.fase) * 0.18, barril.fase, cos(t * 1.1 + barril.fase) * 0.15)
		# Parpadeo lento; con la mecha encendida, rapidísimo.
		var ritmo := 14.0 if barril.mecha >= 0.0 else 1.6
		var encendida := fmod(t * ritmo + barril.fase, 1.0) < 0.35
		barril.luz.emission_energy_multiplier = 3.0 if encendida else 0.2
		barril.luz.albedo_color = COLOR_LUZ if encendida else COLOR_LUZ.darkened(0.6)
