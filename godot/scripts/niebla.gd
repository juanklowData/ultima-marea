class_name Niebla
extends Node3D

# Mar libre: bancos de niebla que van a la deriva. Dentro casi no se ve, el radar se apaga
# y salen barcos fantasma que solo existen en la niebla: si se alejan de ella, se desvanecen.
# Al hundirlos sueltan reliquias. Los barcos fantasma se reutilizan, no se liberan.

const BANCOS := 2
const RADIO := 560.0
const DERIVA := 7.0
const ESPESOR_MAXIMO := 0.032
const COLOR_NIEBLA := Color("c3cdd1")
const COLOR_FANTASMA := Color("b8f3ff")
const MAX_FANTASMAS := 2
const PRIMER_FANTASMA := 5.0
const ESPERA_FANTASMA := 22.0
const RECOMPENSA_FANTASMA := 12
const TRANSPARENCIA := 0.35


class Banco:
	var pos := Vector2.ZERO
	var rumbo := 0.0


var mundo: Principal
var bancos: Array[Banco] = []
var fantasmas: Array[Barco] = []
var espera_fantasma := PRIMER_FANTASMA
# 0 fuera de la niebla, 1 en el corazón del banco (lo usa el ambiente y el radar).
var espesor := 0.0


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo


func vaciar() -> void:
	bancos.clear()
	fantasmas.clear()
	espesor = 0.0
	espera_fantasma = PRIMER_FANTASMA


func empezar() -> void:
	vaciar()
	for _i in BANCOS:
		var banco := Banco.new()
		banco.rumbo = randf() * TAU
		_colocar(banco, true)
		bancos.append(banco)


# Lejos del barco (pero dentro del mar que se simula) y nunca en la zona tranquila de la base.
func _colocar(banco: Banco, al_empezar: bool) -> void:
	var centro := mundo.jugador.pos
	for _intento in 40:
		var punto := centro + Vector2.from_angle(randf() * TAU) * randf_range(1400.0 if al_empezar else 1800.0, MarLibre.ACTIVO)
		if punto.length() > MarLibre.RADIO * 0.9 or mundo.libre.tranquila(punto):
			continue
		var lejos := true
		for otro in bancos:
			if otro != banco and otro.pos.distance_to(punto) < RADIO * 3.0:
				lejos = false
		if lejos:
			banco.pos = punto
			return
	banco.pos = centro + Vector2.from_angle(randf() * TAU) * MarLibre.ACTIVO


func banco_de(punto: Vector2) -> Banco:
	for banco in bancos:
		if banco.pos.distance_to(punto) < RADIO:
			return banco
	return null


func actualizar(delta: float) -> void:
	var jugador := mundo.jugador
	espesor = 0.0
	for banco in bancos:
		banco.pos += Vector2.from_angle(banco.rumbo) * DERIVA * delta
		var d := banco.pos.distance_to(jugador.pos)
		espesor = maxf(espesor, 1.0 - smoothstep(RADIO * 0.55, RADIO, d))
		if d > MarLibre.ACTIVO * 1.3 or (mundo.libre.tranquila(banco.pos) and d > RADIO * 2.0):
			_colocar(banco, false)
	for barco in fantasmas:
		if not barco.viva:
			continue
		var suyo := banco_de(barco.pos)
		if suyo == null:
			_desvanecer(barco)
	var dentro := banco_de(jugador.pos)
	if dentro == null or not jugador.viva or mundo.libre.tranquila(jugador.pos):
		espera_fantasma = PRIMER_FANTASMA
		return
	var activos := 0
	for barco in fantasmas:
		if barco.viva:
			activos += 1
	if activos >= MAX_FANTASMAS:
		return
	espera_fantasma -= delta
	if espera_fantasma > 0.0:
		return
	espera_fantasma = ESPERA_FANTASMA
	_soltar_fantasma(dentro)


# Barco espectral y medio transparente que surge de la niebla cerca del jugador.
func _soltar_fantasma(banco: Banco) -> void:
	var jugador := mundo.jugador
	var punto := jugador.pos
	for _intento in 20:
		punto = jugador.pos + Vector2.from_angle(randf() * TAU) * randf_range(300.0, 420.0)
		if banco.pos.distance_to(punto) < RADIO * 0.9 and mundo.libre._libre(punto, 90.0):
			break
	var aspecto := Personalizacion.al_azar()
	aspecto.elegidos["tipo"] = "u_espectro" if randf() < 0.5 else "bergantin"
	aspecto.elegidos["casco"] = "fantasma"
	aspecto.elegidos["velas"] = "noche"
	aspecto.elegidos["bandera"] = "jolly_roger"
	var barco: Barco = null
	for viejo in fantasmas:
		if not viejo.viva and (viejo.hundimiento >= 1.0 or not viejo.visible):
			barco = viejo
			break
	if barco == null:
		barco = mundo._crear_barco(aspecto, false, punto)
		fantasmas.append(barco)
	else:
		barco.vestir(aspecto)
		barco.pos = punto
	barco.es_bot = true
	barco.fantasma = true
	barco.es_pirata = true
	barco.agresivo = true
	barco.viva = true
	barco.visible = true
	barco.hundimiento = 0.0
	barco.velocidad = 0.0
	barco.ultimo_atacante = null
	barco.destino_libre = Vector2.INF
	barco.recompensa = RECOMPENSA_FANTASMA
	barco.botin = randi_range(3, 7)
	barco.nombre = tr("Fantasma de %s") % Principal.NOMBRES_SUELTOS.pick_random()
	var hacia := jugador.pos - barco.pos
	barco.rumbo = atan2(hacia.x, -hacia.y)
	_transparentar(barco.modelo)
	barco.colocar(0.0)
	_humo(barco.pos)
	mundo.libre._anunciar(tr("¡Un barco fantasma surge de la niebla!"), COLOR_FANTASMA)


func _transparentar(nodo: Node) -> void:
	if nodo is GeometryInstance3D:
		nodo.transparency = TRANSPARENCIA
	for hijo in nodo.get_children():
		_transparentar(hijo)


func _desvanecer(barco: Barco) -> void:
	_humo(barco.pos)
	barco.viva = false
	barco.hundimiento = 1.0
	barco.visible = false
	mundo.tesoros.quitar(barco)


func _humo(punto: Vector2) -> void:
	var centro := mundo.a_3d(punto, 1.2)
	for _i in 10:
		var vel := Vector3(randf_range(-0.8, 0.8), randf_range(0.3, 1.0), randf_range(-0.8, 0.8))
		mundo.crear_efecto(mundo.malla_humo, Color(0.78, 0.95, 1.0, 0.6), centro + vel, vel, randf_range(1.5, 2.2), 1.2, 2.5, 0.0, true)


# Los fantasmas van a por el jugador si está en su niebla; si no, vagan por ella.
func destino(barco: Barco) -> Vector2:
	var banco := banco_de(barco.pos)
	if banco == null:
		return barco.pos
	if banco_de(mundo.jugador.pos) == banco and mundo.jugador.viva:
		return mundo.jugador.pos
	if barco.destino_libre == Vector2.INF or barco.pos.distance_to(barco.destino_libre) < 120.0 or banco.pos.distance_to(barco.destino_libre) > RADIO * 0.7:
		barco.destino_libre = banco.pos + Vector2.from_angle(randf() * TAU) * randf() * RADIO * 0.6
	return barco.destino_libre


func al_hundir(barco: Barco) -> void:
	if not barco.fantasma:
		return
	var reliquias: Array[String] = []
	for _i in 2:
		reliquias.append("reliquias:%d" % randi_range(0, Objetos.CATEGORIAS["reliquias"]["objetos"].size() - 1))
	mundo.comercio.soltar_botin(barco.pos, reliquias, {"tela": 3})
	_humo(barco.pos)


# Con niebla espesa el radar se nubla.
func dibujar_minimapa(lienzo: Control, centro: Vector2, radio: float) -> void:
	if espesor < 0.2:
		return
	lienzo.draw_circle(centro, radio, Color(COLOR_NIEBLA.darkened(0.25), 0.9 * espesor))
	if espesor > 0.6:
		var fuente := ThemeDB.fallback_font
		var texto := tr("Niebla")
		lienzo.draw_string_outline(fuente, centro + Vector2(-radio, 6), texto, HORIZONTAL_ALIGNMENT_CENTER, radio * 2.0, 18, 4, Color(0, 0, 0, 0.6))
		lienzo.draw_string(fuente, centro + Vector2(-radio, 6), texto, HORIZONTAL_ALIGNMENT_CENTER, radio * 2.0, 18, Color.WHITE)
