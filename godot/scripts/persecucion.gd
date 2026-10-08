class_name Persecucion
extends Node

# Mar libre: el nivel de Se busca (atacar capitanes y fuertes atrae cazadores que te
# persiguen) y los barcos legendarios, jefes enormes que aparecen de vez en cuando.
# Los barcos de cazadores y legendarios no se destruyen al retirarse: se reutilizan, para
# que nadie se quede apuntando a un barco liberado.

const POR_ESTRELLA := 25.0
const ESTRELLAS := 4
const POR_DANIO := 0.3
const POR_HUNDIR := 15.0
const POR_GOLPE_FUERTE := 1.5
const POR_FUERTE := 20.0
const POR_CAZADOR := 5.0
# Segundos sin atacar a nadie antes de que te empiecen a olvidar, y cuánto se olvida por segundo.
const CALMA := 45.0
const OLVIDO := 0.4
const OLVIDO_BASE := 2.5
const ESPERA_CAZADOR := 25.0
const PRIMER_CAZADOR := 8.0
const RECOMPENSA_CAZADOR := 8
const PRECIO_SOBORNO := 30
const PRIMER_LEGENDARIO := 300.0
const ESPERA_LEGENDARIO := 480.0
const VUELTA_LEGENDARIO := 300.0
# Cada vez que se cumple la espera, solo a veces aparece de verdad.
const PROBABILIDAD_LEGENDARIO := 0.35
const RECOMPENSA_LEGENDARIO := 150
const VIDA_LEGENDARIO := 650.0
const TAMANO_LEGENDARIO := 1.3
const NOMBRES_LEGENDARIOS: Array[String] = [
	"El Holandés Errante", "La Reina de las Tormentas", "El Leviatán de Hierro", "La Dama Escarlata", "El Terror del Caribe",
]
const COLOR_LEGENDARIO := Color("7dffb2")
const COLOR_CAZADOR := Color("ff6b5b")

var mundo: Principal
var notoriedad := 0.0
var calma := 0.0
var cazadores: Array[Barco] = []
var espera_cazador := PRIMER_CAZADOR
var legendario: Barco
var espera_legendario := PRIMER_LEGENDARIO
var legendarios_hundidos := 0


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	var archivo := ConfigFile.new()
	if archivo.load(MarLibre.RUTA) == OK:
		notoriedad = clampf(float(archivo.get_value("persecucion", "notoriedad", 0.0)), 0.0, POR_ESTRELLA * ESTRELLAS)
		legendarios_hundidos = int(archivo.get_value("persecucion", "legendarios", 0))


func escribir(archivo: ConfigFile) -> void:
	archivo.set_value("persecucion", "notoriedad", notoriedad)
	archivo.set_value("persecucion", "legendarios", legendarios_hundidos)


func estrellas() -> int:
	return mini(ESTRELLAS, floori(notoriedad / POR_ESTRELLA))


func precio_soborno() -> int:
	return PRECIO_SOBORNO * maxi(1, ceili(notoriedad / POR_ESTRELLA))


func sobornar() -> void:
	notoriedad = 0.0
	mundo.libre._anunciar(tr("Ya no te buscan"), Principal.COLOR_ORO)


# Los barcos ya no existen (se vacía el mar) o se van a liberar justo después.
func vaciar() -> void:
	cazadores.clear()
	legendario = null
	espera_cazador = PRIMER_CAZADOR
	espera_legendario = PRIMER_LEGENDARIO


func _subir(cantidad: float) -> void:
	var antes := estrellas()
	notoriedad = minf(POR_ESTRELLA * ESTRELLAS, notoriedad + cantidad)
	calma = 0.0
	var ahora := estrellas()
	if ahora > antes:
		mundo.libre._anunciar(tr("¡Se busca! Nivel %d: te persiguen cazadores") % ahora, COLOR_CAZADOR)


# Daño del jugador a otro barco: solo cuenta contra capitanes honrados (no piratas).
func al_golpear(victima: Barco, cantidad: float) -> void:
	if victima.es_pirata or victima.cazador or victima == mundo.jugador:
		return
	_subir(cantidad * POR_DANIO)


func golpe_fuerte() -> void:
	_subir(POR_GOLPE_FUERTE)


func fuerte_rendido() -> void:
	_subir(POR_FUERTE)


func al_morir() -> void:
	notoriedad *= 0.5


# Barco hundido por el jugador (verdugo) o por cualquiera (null).
func al_hundir(barco: Barco, verdugo: Barco) -> void:
	if verdugo == mundo.jugador:
		if barco.cazador:
			_subir(POR_CAZADOR)
		elif not barco.es_pirata:
			_subir(POR_HUNDIR)
	if barco == legendario:
		if verdugo == mundo.jugador:
			legendarios_hundidos += 1
			mundo.libre._anunciar(tr("¡Hundiste a %s!") % barco.nombre, COLOR_LEGENDARIO)
		var botin: Array[String] = [Objetos.de_rareza(3), Objetos.de_rareza(3), Objetos.de_rareza(2)]
		mundo.comercio.soltar_botin(barco.pos, botin, {"madera": 20, "metal": 12, "tela": 12})


func actualizar(delta: float) -> void:
	var jugador := mundo.jugador
	calma += delta
	var base: MarLibre.Base = mundo.libre._mi_base()
	if base != null and jugador.viva and jugador.pos.distance_to(base.pos) < MarLibre.ALCANCE_BASE:
		_bajar(OLVIDO_BASE * delta)
	elif calma > CALMA:
		_bajar(OLVIDO * delta)
	_atender_cazadores(delta)
	_atender_legendario(delta)


func _bajar(cantidad: float) -> void:
	if notoriedad <= 0.0:
		return
	var antes := estrellas()
	notoriedad = maxf(0.0, notoriedad - cantidad)
	if antes > 0 and estrellas() == 0:
		mundo.libre._anunciar(tr("Ya no te buscan"), Principal.COLOR_ORO)


func _libre_para_usar(barco: Barco) -> bool:
	return not barco.viva and (barco.hundimiento >= 1.0 or barco.pos.distance_to(mundo.jugador.pos) > MarLibre.ACTIVO)


func _retirar(barco: Barco) -> void:
	barco.viva = false
	barco.hundimiento = 1.0
	barco.visible = false
	mundo.tesoros.quitar(barco)


func _atender_cazadores(delta: float) -> void:
	var jugador := mundo.jugador
	var nivel := estrellas()
	var activos := 0
	for barco in cazadores:
		if not barco.viva:
			continue
		if barco.pos.distance_to(jugador.pos) > MarLibre.ACTIVO * 1.4:
			_retirar(barco)
			continue
		activos += 1
	if nivel == 0 or not jugador.viva:
		espera_cazador = PRIMER_CAZADOR
		return
	if activos >= nivel:
		return
	espera_cazador -= delta
	if espera_cazador > 0.0:
		return
	espera_cazador = ESPERA_CAZADOR
	_soltar_cazador(nivel)


func _soltar_cazador(nivel: int) -> void:
	var aspecto := Personalizacion.al_azar()
	aspecto.elegidos["tipo"] = "galeon" if nivel >= 3 else "bergantin"
	var barco: Barco = null
	for viejo in cazadores:
		if _libre_para_usar(viejo):
			barco = viejo
			break
	var punto := mundo.libre._punto_aparicion()
	if barco == null:
		barco = mundo._crear_barco(aspecto, false, punto)
		cazadores.append(barco)
	else:
		barco.vestir(aspecto)
		barco.pos = punto
	barco.es_bot = true
	barco.cazador = true
	barco.es_pirata = false
	barco.agresivo = true
	barco.viva = true
	barco.visible = true
	barco.hundimiento = 0.0
	barco.velocidad = 0.0
	barco.ultimo_atacante = null
	barco.destino_libre = Vector2.INF
	barco.recompensa = RECOMPENSA_CAZADOR
	barco.botin = randi_range(2, 5)
	barco.factor_danio = 1.0 + 0.1 * nivel
	barco.nombre = tr("Cazador %s") % Principal.NOMBRES_SUELTOS.pick_random()
	var hacia := mundo.jugador.pos - barco.pos
	barco.rumbo = atan2(hacia.x, -hacia.y)
	barco.colocar(0.0)


func _atender_legendario(delta: float) -> void:
	var jugador := mundo.jugador
	if legendario != null and legendario.viva:
		if legendario.pos.distance_to(jugador.pos) > MarLibre.ACTIVO * 1.8:
			_retirar(legendario)
			espera_legendario = VUELTA_LEGENDARIO
		return
	espera_legendario -= delta
	if espera_legendario > 0.0 or not jugador.viva:
		return
	if legendario != null and not _libre_para_usar(legendario):
		return
	espera_legendario = ESPERA_LEGENDARIO
	if randf() < PROBABILIDAD_LEGENDARIO:
		_soltar_legendario()


# Galeón Leviatán con velas del kraken y casco abisal: más grande, más duro y con más
# cañones; ataca a todo lo que no sea pirata y lleva tesoros a la vista.
func _soltar_legendario() -> void:
	var aspecto := Personalizacion.al_azar()
	aspecto.elegidos["tipo"] = "u_leviatan"
	aspecto.elegidos["velas"] = "u_kraken"
	aspecto.elegidos["casco"] = "u_abisal"
	var punto := mundo.libre._punto_aparicion()
	if legendario == null:
		legendario = mundo._crear_barco(aspecto, false, punto)
	else:
		legendario.vestir(aspecto)
		legendario.pos = punto
	var barco := legendario
	barco.es_bot = true
	barco.legendario = true
	barco.es_pirata = true
	barco.agresivo = true
	barco.viva = true
	barco.visible = true
	barco.hundimiento = 0.0
	barco.velocidad = 0.0
	barco.ultimo_atacante = null
	barco.destino_libre = Vector2.INF
	barco.recompensa = RECOMPENSA_LEGENDARIO
	barco.botin = 25
	barco.nombre = tr(NOMBRES_LEGENDARIOS.pick_random())
	barco.vida_max = VIDA_LEGENDARIO
	barco.vida = VIDA_LEGENDARIO
	barco.factor_danio = 1.6
	barco.factor_recarga = 0.6
	barco.radio *= TAMANO_LEGENDARIO
	barco.altura *= TAMANO_LEGENDARIO
	barco.vel_max *= 1.05
	barco.modelo.scale = Vector3.ONE * TAMANO_LEGENDARIO
	mundo.tesoros.cargar(barco, "cofre")
	mundo.tesoros.cargar(barco, "calavera")
	barco.colocar(0.0)
	mundo.libre._anunciar(tr("¡Barco legendario a la vista: %s!") % barco.nombre, COLOR_LEGENDARIO)


# Los cazadores van a por el jugador mientras le busquen, salvo en la zona tranquila de su base.
func persigue(barco: Barco) -> bool:
	return barco.cazador and estrellas() > 0 and mundo.jugador.viva and barco.pos.distance_to(mundo.jugador.pos) < 3000.0 \
			and not mundo.libre.tranquila(mundo.jugador.pos)


# Calaveras de Se busca bajo el minimapa, con la siguiente llenándose.
func dibujar(lienzo: Control) -> void:
	if notoriedad <= 0.0:
		return
	var icono := Objetos.icono_mejora("buscado")
	var lado := 34.0
	var centro_x := lienzo.size.x - 114.0
	var arriba := 222.0
	var inicio := centro_x - (lado + 6.0) * ESTRELLAS / 2.0 + 3.0
	var fuente := ThemeDB.fallback_font
	var rotulo := tr("Se busca")
	lienzo.draw_string_outline(fuente, Vector2(inicio, arriba + lado + 18.0), rotulo, HORIZONTAL_ALIGNMENT_CENTER, (lado + 6.0) * ESTRELLAS, 15, 4, Color(0, 0, 0, 0.75))
	lienzo.draw_string(fuente, Vector2(inicio, arriba + lado + 18.0), rotulo, HORIZONTAL_ALIGNMENT_CENTER, (lado + 6.0) * ESTRELLAS, 15, COLOR_CAZADOR)
	for k in ESTRELLAS:
		var marco := Rect2(Vector2(inicio + k * (lado + 6.0), arriba), Vector2(lado, lado))
		var lleno := clampf(notoriedad / POR_ESTRELLA - k, 0.0, 1.0)
		lienzo.draw_rect(marco.grow(2.0), Color(0, 0, 0, 0.55))
		lienzo.draw_texture_rect(icono, marco, false, Color(0.3, 0.3, 0.3, 0.8))
		if lleno > 0.0:
			var parte := Rect2(marco.position + Vector2(0, lado * (1.0 - lleno)), Vector2(lado, lado * lleno))
			var origen := Rect2(Vector2(0, 256.0 * (1.0 - lleno)), Vector2(256.0, 256.0 * lleno))
			lienzo.draw_texture_rect_region(icono, parte, origen)
		if lleno >= 1.0:
			lienzo.draw_rect(marco.grow(2.0), COLOR_CAZADOR, false, 2.0)


func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	for barco in cazadores:
		if barco.viva and mundo.en_mapa(barco.pos):
			var punto: Vector2 = centro + barco.pos * escala
			lienzo.draw_circle(punto, 4.5, Color("08161c"))
			lienzo.draw_circle(punto, 3.5, COLOR_CAZADOR)
	if legendario != null and legendario.viva and mundo.en_mapa(legendario.pos):
		var punto: Vector2 = centro + legendario.pos * escala
		lienzo.draw_circle(punto, 7.0, Color("08161c"))
		lienzo.draw_circle(punto, 5.5, COLOR_LEGENDARIO)
		lienzo.draw_circle(punto, 2.0, Color("08161c"))


# Flecha verde en el bisel hacia el barco legendario cuando está fuera del radar.
func dibujar_brujula(lienzo: Control, centro: Vector2, exterior: float, interior: float) -> void:
	var jugador := mundo.jugador
	if legendario == null or not legendario.viva or jugador == null or not jugador.viva or mundo.en_mapa(legendario.pos):
		return
	var direccion := (legendario.pos - jugador.pos).normalized()
	var lado := direccion.orthogonal()
	var base := centro + direccion * (interior + 2.0)
	var punta := centro + direccion * (exterior + 4.0)
	var flecha := PackedVector2Array([punta, base + lado * 6.0, base - direccion * 2.0, base - lado * 6.0])
	lienzo.draw_colored_polygon(flecha, COLOR_LEGENDARIO)
	flecha.append(flecha[0])
	lienzo.draw_polyline(flecha, Color("08161c"), 1.5, true)
