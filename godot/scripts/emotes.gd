class_name Emotes
extends Node

# Emotes: caritas con una frase que salen en un bocadillo sobre el barco. El jugador las elige
# con el botón de arriba a la izquierda; los rivales a veces contestan o reaccionan al hundirse.

const DURACION := 3.0
const ESPERA_JUGADOR := 1.5
const ALCANCE_RESPUESTA := 700.0
const ORDEN := ["risa", "enfado", "llanto", "arr", "sorpresa", "guino"]
const FRASES := {
	"risa": "¡Ja, ja, ja!",
	"enfado": "¡Grrr!",
	"llanto": "¡Buaaa!",
	"arr": "¡Arrr!",
	"sorpresa": "¡Oh, no!",
	"guino": "¡Buen tiro!",
}
# Lo que suele contestar un rival a cada emote.
const RESPUESTAS := {
	"risa": ["enfado", "risa"],
	"enfado": ["risa", "arr"],
	"llanto": ["risa"],
	"arr": ["arr", "enfado"],
	"sorpresa": ["risa", "guino"],
	"guino": ["guino", "arr"],
}
const COLOR_CARA := Color("ffd34d")
const COLOR_ENFADO := Color("ff8a5c")
const COLOR_TRAZO := Color("3a2414")
const COLOR_LAGRIMA := Color("5cc8ff")
const COLOR_BOCADILLO := Color("fdf3df")
const LADO_BOTON := 50.0

var mundo: Principal
# Barco -> [emote, segundos que lleva en pantalla].
var activos := {}
# Respuestas de rivales que aún esperan su turno: [barco, emote, segundos].
var pendientes: Array = []
var espera := 0.0
var boton: Button
var menu: HBoxContainer
var estilo_bocadillo := StyleBoxFlat.new()


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	estilo_bocadillo.bg_color = COLOR_BOCADILLO
	estilo_bocadillo.border_color = Principal.COLOR_ORO
	estilo_bocadillo.set_border_width_all(2)
	estilo_bocadillo.set_corner_radius_all(18)


func crear_interfaz(capa: CanvasLayer) -> void:
	boton = _boton_redondo()
	Ui.anclar(boton, Vector2(0, 0), Vector2(16, 98), Vector2(LADO_BOTON, LADO_BOTON))
	boton.draw.connect(func() -> void:
		dibujar_cara(boton, boton.size / 2.0, 16.0, "risa")
		var punta := boton.size / 2.0 + Vector2(14, 14)
		boton.draw_colored_polygon(PackedVector2Array([punta, punta + Vector2(-9, -3), punta + Vector2(-3, -9)]), COLOR_CARA))
	boton.pressed.connect(func() -> void:
		menu.visible = not menu.visible
		mundo.voz_equipar.play())
	boton.visible = false
	capa.add_child(boton)
	menu = HBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	Ui.anclar(menu, Vector2(0, 0), Vector2(16 + LADO_BOTON + 12, 98), Vector2((LADO_BOTON + 8) * ORDEN.size(), LADO_BOTON))
	menu.visible = false
	capa.add_child(menu)
	for tipo in ORDEN:
		var opcion := _boton_redondo()
		opcion.custom_minimum_size = Vector2(LADO_BOTON, LADO_BOTON)
		opcion.tooltip_text = tr(FRASES[tipo])
		opcion.draw.connect(func() -> void: dibujar_cara(opcion, opcion.size / 2.0, 18.0, tipo))
		opcion.pressed.connect(enviar.bind(tipo))
		menu.add_child(opcion)


func _boton_redondo() -> Button:
	var nuevo := Button.new()
	nuevo.focus_mode = Control.FOCUS_NONE
	var redondo := StyleBoxFlat.new()
	redondo.bg_color = Color(0.05, 0.16, 0.2, 0.9)
	redondo.border_color = Color(0.95, 0.88, 0.73, 0.4)
	redondo.set_border_width_all(2)
	redondo.set_corner_radius_all(40)
	var activo := redondo.duplicate() as StyleBoxFlat
	activo.border_color = Principal.COLOR_ORO
	nuevo.add_theme_stylebox_override("normal", redondo)
	nuevo.add_theme_stylebox_override("hover", activo)
	nuevo.add_theme_stylebox_override("pressed", activo)
	return nuevo


func enviar(tipo: String) -> void:
	menu.visible = false
	var jugador := mundo.jugador
	if jugador == null or not jugador.viva or espera > 0.0:
		return
	espera = ESPERA_JUGADOR
	mostrar(jugador, tipo)
	# El rival más cercano a veces contesta.
	var cercano: Barco = null
	var menor := ALCANCE_RESPUESTA
	for barco in mundo.barcos:
		if barco.viva and barco.es_bot and barco != jugador and not activos.has(barco):
			var d := barco.pos.distance_to(jugador.pos)
			if d < menor:
				menor = d
				cercano = barco
	if cercano != null and randf() < 0.65:
		pendientes.append([cercano, RESPUESTAS[tipo].pick_random(), randf_range(0.8, 1.8)])


func mostrar(barco: Barco, tipo: String) -> void:
	activos[barco] = [tipo, 0.0]
	if barco.es_jugador or barco.pos.distance_to(mundo.jugador.pos) < ALCANCE_RESPUESTA:
		mundo.voz_equipar.play()


# Reacciones de los rivales cuando alguien se hunde cerca del jugador.
func al_hundirse(barco: Barco, verdugo: Barco) -> void:
	var jugador := mundo.jugador
	if jugador == null:
		return
	if barco.es_bot and barco.pos.distance_to(jugador.pos) < ALCANCE_RESPUESTA and randf() < 0.4:
		mostrar(barco, "llanto" if randf() < 0.7 else "sorpresa")
	if verdugo != null and verdugo.es_bot and verdugo.viva and verdugo.pos.distance_to(jugador.pos) < ALCANCE_RESPUESTA:
		if barco == jugador or randf() < 0.35:
			pendientes.append([verdugo, "risa" if barco == jugador or randf() < 0.6 else "arr", 0.6])


func actualizar(delta: float) -> void:
	var jugando := mundo.estado == Principal.Estado.JUGANDO and not mundo.panel_partida.visible \
			and not mundo.comercio.panel.visible and mundo.jugador != null and mundo.jugador.viva
	boton.visible = jugando
	if not jugando:
		menu.visible = false
	espera = maxf(0.0, espera - delta)
	for clave in activos.keys():
		if not is_instance_valid(clave):
			activos.erase(clave)
			continue
		activos[clave][1] += delta
		if activos[clave][1] >= DURACION:
			activos.erase(clave)
	for i in range(pendientes.size() - 1, -1, -1):
		var pendiente: Array = pendientes[i]
		pendiente[2] -= delta
		if pendiente[2] > 0.0:
			continue
		pendientes.remove_at(i)
		if is_instance_valid(pendiente[0]) and pendiente[0].viva:
			mostrar(pendiente[0], pendiente[1])


func vaciar() -> void:
	activos.clear()
	pendientes.clear()
	if menu != null:
		menu.visible = false


# Bocadillo sobre cada barco con emote: la cara y la frase. Aparece con un saltito y se apaga.
func dibujar(lienzo: Control, camara: Camera3D) -> void:
	var fuente := ThemeDB.fallback_font
	for clave in activos:
		if not is_instance_valid(clave):
			continue
		var barco: Barco = clave
		if not barco.visible:
			continue
		var punto := barco.position + Vector3(0.0, barco.altura, 0.0)
		if camara.is_position_behind(punto):
			continue
		var tipo: String = activos[barco][0]
		var t: float = activos[barco][1]
		var escala := minf(1.0, t * 7.0) * (1.0 + 0.15 * sin(minf(t * 7.0, PI)))
		var alfa := clampf((DURACION - t) / 0.4, 0.0, 1.0)
		var frase := tr(FRASES[tipo])
		var ancho := fuente.get_string_size(frase, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var caja := Vector2(ancho + 58.0, 44.0)
		var base := camara.unproject_position(punto) + Vector2(0.0, -48.0 - 8.0 * sin(t * 3.0) * 0.3)
		lienzo.draw_set_transform(base, 0.0, Vector2(escala, escala))
		var rect := Rect2(Vector2(-caja.x / 2.0, -caja.y - 10.0), caja)
		var estilo := estilo_bocadillo.duplicate() as StyleBoxFlat
		estilo.bg_color.a = alfa
		estilo.border_color.a = alfa
		lienzo.draw_colored_polygon(PackedVector2Array([Vector2(-8, -11), Vector2(8, -11), Vector2(0, 0)]), Color(Principal.COLOR_ORO, alfa))
		lienzo.draw_style_box(estilo, rect)
		dibujar_cara(lienzo, rect.position + Vector2(24, caja.y / 2.0), 16.0, tipo, alfa)
		lienzo.draw_string(fuente, rect.position + Vector2(46, caja.y / 2.0 + 6.0), frase, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(COLOR_TRAZO, alfa))
		lienzo.draw_set_transform(Vector2.ZERO)


# Carita dibujada a mano (sin fuentes de emoji) para cada emote.
static func dibujar_cara(lienzo: CanvasItem, c: Vector2, r: float, tipo: String, alfa := 1.0) -> void:
	var trazo := Color(COLOR_TRAZO, alfa)
	var grosor := maxf(1.5, r * 0.12)
	var ojo_i := c + Vector2(-r * 0.36, -r * 0.2)
	var ojo_d := c + Vector2(r * 0.36, -r * 0.2)
	lienzo.draw_circle(c, r + 1.5, Color(COLOR_TRAZO, alfa * 0.8))
	lienzo.draw_circle(c, r, Color(COLOR_ENFADO if tipo == "enfado" else COLOR_CARA, alfa))
	match tipo:
		"risa":
			for ojo in [ojo_i, ojo_d]:
				lienzo.draw_arc(ojo, r * 0.16, PI, TAU, 8, trazo, grosor, true)
			_boca_abierta(lienzo, c + Vector2(0, r * 0.12), r * 0.5, trazo, alfa)
			for lado in [-1.0, 1.0]:
				lienzo.draw_circle(c + Vector2(lado * r * 0.78, r * 0.05), r * 0.13, Color(COLOR_LAGRIMA, alfa))
		"enfado":
			for lado in [-1.0, 1.0]:
				var ojo := c + Vector2(lado * r * 0.36, -r * 0.12)
				lienzo.draw_circle(ojo, r * 0.11, trazo)
				lienzo.draw_line(ojo + Vector2(-lado * r * 0.22, -r * 0.32), ojo + Vector2(lado * r * 0.18, -r * 0.16), trazo, grosor, true)
			lienzo.draw_arc(c + Vector2(0, r * 0.62), r * 0.32, PI * 1.15, PI * 1.85, 10, trazo, grosor, true)
		"llanto":
			for ojo in [ojo_i, ojo_d]:
				lienzo.draw_arc(ojo, r * 0.16, 0.0, PI, 8, trazo, grosor, true)
				lienzo.draw_rect(Rect2(ojo + Vector2(-r * 0.08, r * 0.1), Vector2(r * 0.16, r * 0.62)), Color(COLOR_LAGRIMA, alfa))
			lienzo.draw_arc(c + Vector2(0, r * 0.62), r * 0.3, PI * 1.1, PI * 1.9, 10, trazo, grosor, true)
		"arr":
			lienzo.draw_line(c + Vector2(-r * 0.95, -r * 0.55), c + Vector2(r * 0.9, -r * 0.05), trazo, grosor * 0.8, true)
			lienzo.draw_circle(ojo_d, r * 0.24, trazo)
			lienzo.draw_circle(ojo_i, r * 0.11, trazo)
			lienzo.draw_arc(c + Vector2(0, r * 0.05), r * 0.5, PI * 0.15, PI * 0.85, 12, trazo, grosor, true)
			lienzo.draw_rect(Rect2(c + Vector2(r * 0.08, r * 0.47), Vector2(r * 0.14, r * 0.14)), Color(1, 1, 1, alfa))
		"sorpresa":
			for ojo in [ojo_i, ojo_d]:
				lienzo.draw_circle(ojo, r * 0.2, Color(1, 1, 1, alfa))
				lienzo.draw_circle(ojo, r * 0.1, trazo)
			lienzo.draw_circle(c + Vector2(0, r * 0.42), r * 0.2, trazo)
		_:
			lienzo.draw_circle(ojo_i, r * 0.11, trazo)
			lienzo.draw_line(ojo_d + Vector2(-r * 0.16, 0), ojo_d + Vector2(r * 0.16, 0), trazo, grosor, true)
			lienzo.draw_arc(c + Vector2(0, r * 0.05), r * 0.5, PI * 0.15, PI * 0.85, 12, trazo, grosor, true)


static func _boca_abierta(lienzo: CanvasItem, c: Vector2, r: float, trazo: Color, alfa: float) -> void:
	var puntos := PackedVector2Array()
	for k in 13:
		puntos.append(c + Vector2.from_angle(PI * k / 12.0) * r)
	lienzo.draw_colored_polygon(puntos, trazo)
	lienzo.draw_circle(c + Vector2(0, r * 0.62), r * 0.3, Color(Color("e8605c"), alfa))
