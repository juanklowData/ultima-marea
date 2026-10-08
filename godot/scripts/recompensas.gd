class_name Recompensas
extends Node

# Mar libre: tablón de recompensas. Siempre hay unos cuantos encargos (hundir a un pirata con
# nombre, hundir piratas o fantasmas, vencer tiburones, el megalodón, un kraken...). Al
# cumplir uno se cobra desde el tablón y sale otro nuevo. Se guardan con el mar libre.

const ACTIVAS := 4
const COLOR_OBJETIVO := Color("ffcf6b")
# Encargos posibles: texto, cuántos piden (mínimo y máximo), pago por cada uno y lo a menudo
# que salen (los grandes, menos).
const TIPOS := {
	"objetivo": {"texto": "Hunde a %s", "min": 1, "max": 1, "pago": 60, "peso": 3, "icono": "buscado"},
	"piratas": {"texto": "Hunde %d piratas", "min": 3, "max": 5, "pago": 12, "peso": 4, "icono": "canones"},
	"fantasmas": {"texto": "Hunde %d barcos fantasma", "min": 1, "max": 2, "pago": 30, "peso": 2, "icono": "velas"},
	"cazadores": {"texto": "Hunde %d cazadores", "min": 1, "max": 2, "pago": 25, "peso": 1, "icono": "cazador"},
	"tiburones": {"texto": "Vence a %d tiburones", "min": 2, "max": 4, "pago": 10, "peso": 3, "icono": "recarga"},
	"kraken": {"texto": "Vence a un kraken", "min": 1, "max": 1, "pago": 80, "peso": 2, "icono": "casco"},
	"megalodon": {"texto": "Vence al megalodón", "min": 1, "max": 1, "pago": 120, "peso": 1, "icono": "arsenal"},
	"legendario": {"texto": "Hunde un barco legendario", "min": 1, "max": 1, "pago": 200, "peso": 1, "icono": "legendario"},
}

var mundo: Principal
# Cada encargo: {"tipo", "meta", "hecho", "pago", "nombre"} (nombre solo para "objetivo").
var lista: Array[Dictionary] = []
var espera_asignar := 0.0


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	var archivo := ConfigFile.new()
	if archivo.load(MarLibre.RUTA) == OK:
		for guardado in archivo.get_value("recompensas", "lista", []):
			if guardado is Dictionary and TIPOS.has(guardado.get("tipo", "")):
				lista.append(guardado)
	_rellenar()


func escribir(archivo: ConfigFile) -> void:
	archivo.set_value("recompensas", "lista", lista.duplicate(true))


func _rellenar() -> void:
	while lista.size() < ACTIVAS:
		lista.append(_nuevo())


# Un encargo al azar que no repita tipo con los que ya hay (salvo que no quede otro).
func _nuevo() -> Dictionary:
	var usados := lista.map(func(encargo: Dictionary) -> String: return encargo["tipo"])
	var total := 0
	for tipo in TIPOS:
		if not tipo in usados:
			total += TIPOS[tipo]["peso"]
	var tirada := randi_range(1, maxi(1, total))
	var elegido := "piratas"
	for tipo in TIPOS:
		if tipo in usados:
			continue
		tirada -= TIPOS[tipo]["peso"]
		if tirada <= 0:
			elegido = tipo
			break
	var datos: Dictionary = TIPOS[elegido]
	var meta := randi_range(datos["min"], datos["max"])
	var nombre := ""
	if elegido == "objetivo":
		nombre = "%s %s" % [Principal.TITULOS_PIRATAS.pick_random(), Principal.NOMBRES_SUELTOS.pick_random()]
	return {"tipo": elegido, "meta": meta, "hecho": 0, "pago": datos["pago"] * meta, "nombre": nombre}


func texto(encargo: Dictionary) -> String:
	var plantilla := tr(TIPOS[encargo["tipo"]]["texto"])
	if encargo["tipo"] == "objetivo":
		return plantilla % encargo["nombre"]
	if "%d" in plantilla:
		return plantilla % encargo["meta"]
	return plantilla


func listos() -> int:
	return lista.filter(func(encargo: Dictionary) -> bool: return encargo["hecho"] >= encargo["meta"]).size()


func _sumar(tipo: String, nombre := "") -> void:
	for encargo in lista:
		if encargo["tipo"] != tipo or encargo["hecho"] >= encargo["meta"]:
			continue
		if tipo == "objetivo" and encargo["nombre"] != nombre:
			continue
		encargo["hecho"] += 1
		if encargo["hecho"] >= encargo["meta"]:
			mundo.libre._anunciar(tr("¡Recompensa lista: %s! Cóbrala en un mercado o en tu base") % texto(encargo), COLOR_OBJETIVO)
		_refrescar()
		return


# Barco hundido por el jugador.
func al_hundir(barco: Barco) -> void:
	if barco.objetivo != "":
		_sumar("objetivo", barco.objetivo)
	if barco.fantasma:
		_sumar("fantasmas")
	elif barco.legendario:
		_sumar("legendario")
	elif barco.cazador:
		_sumar("cazadores")
	elif barco.es_pirata:
		_sumar("piratas")


# Monstruo vencido por el jugador: "tiburones", "megalodon" o "kraken".
func al_vencer(tipo: String) -> void:
	if mundo.modo == "libre":
		_sumar(tipo)


func actualizar(delta: float) -> void:
	espera_asignar -= delta
	if espera_asignar > 0.0:
		return
	espera_asignar = 2.0
	_asignar_objetivos()


# El pirata con nombre de un encargo es un pirata cualquiera del mar al que se le pone ese
# nombre (si se recicla lejos, otro toma el relevo).
func _asignar_objetivos() -> void:
	for barco in mundo.barcos:
		if barco.objetivo != "" and not objetivo_activo(barco):
			barco.objetivo = ""
	for encargo in lista:
		if encargo["tipo"] != "objetivo" or encargo["hecho"] >= encargo["meta"]:
			continue
		var asignado := false
		for barco in mundo.barcos:
			if barco.viva and barco.objetivo == encargo["nombre"]:
				asignado = true
				break
		if asignado:
			continue
		var mejor: Barco = null
		var lejos := 900.0
		for barco in mundo.barcos:
			if not barco.viva or not barco.es_bot or not barco.es_pirata or barco.objetivo != "" \
					or barco.legendario or barco.fantasma or barco.cazador:
				continue
			var d := barco.pos.distance_to(mundo.jugador.pos)
			if d > lejos:
				lejos = d
				mejor = barco
		if mejor != null:
			mejor.objetivo = encargo["nombre"]
			mejor.nombre = encargo["nombre"]
			mejor.recompensa = maxi(mejor.recompensa, MarLibre.RECOMPENSA_PIRATA)


func objetivo_activo(barco: Barco) -> bool:
	return barco.objetivo != "" and lista.any(func(encargo: Dictionary) -> bool:
		return encargo["tipo"] == "objetivo" and encargo["nombre"] == barco.objetivo and encargo["hecho"] < encargo["meta"])


func _cobrar(i: int) -> void:
	var encargo := lista[i]
	if encargo["hecho"] < encargo["meta"]:
		return
	mundo.personalizacion.monedas += encargo["pago"]
	mundo.personalizacion.guardar()
	mundo.voz_monedas.play()
	mundo.libre._anunciar(tr("Recompensa cobrada: +%d monedas") % encargo["pago"], Principal.COLOR_ORO)
	lista[i] = _nuevo()
	mundo.libre.guardar()
	_refrescar()


func _cambiar(i: int) -> void:
	if lista[i]["hecho"] >= lista[i]["meta"]:
		return
	var viejo := lista[i]
	lista.remove_at(i)
	var nuevo := _nuevo()
	if nuevo["tipo"] == viejo["tipo"] and nuevo["tipo"] != "objetivo":
		nuevo = _nuevo()
	lista.insert(i, nuevo)
	mundo.voz_equipar.play()
	mundo.libre.guardar()
	_refrescar()


# Pestaña «Recompensas» del mercado y de tu base: una fila por encargo.
func llenar(contenido: VBoxContainer) -> void:
	contenido.add_child(Ui.etiqueta_panel(tr("Cumple los encargos y cobra aquí las monedas"), 17, Color("c9d1d3")))
	for i in lista.size():
		var encargo := lista[i]
		var listo: bool = encargo["hecho"] >= encargo["meta"]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 14)
		contenido.add_child(fila)
		var icono := TextureRect.new()
		icono.texture = Objetos.icono_mejora(TIPOS[encargo["tipo"]]["icono"])
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.custom_minimum_size = Vector2(58, 58)
		icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(icono)
		var columna := VBoxContainer.new()
		columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columna.add_theme_constant_override("separation", 4)
		fila.add_child(columna)
		columna.add_child(Ui.etiqueta_panel(texto(encargo), 22, COLOR_OBJETIVO if encargo["tipo"] == "objetivo" else Principal.COLOR_TEXTO))
		columna.add_child(Ui.etiqueta_panel(tr("%d de %d  ·  Paga %d monedas") % [encargo["hecho"], encargo["meta"], encargo["pago"]], 16, Principal.COLOR_ORO))
		var barra := Ui.barra_progreso()
		barra.set_meta("avance", float(encargo["hecho"]) / float(encargo["meta"]))
		columna.add_child(barra)
		var accion := Ui.boton(tr("Cobrar") if listo else tr("Cambiar"), listo)
		accion.custom_minimum_size = Vector2(210, 60)
		accion.add_theme_font_size_override("font_size", 22)
		accion.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		accion.pressed.connect(_cobrar.bind(i) if listo else _cambiar.bind(i))
		fila.add_child(accion)


func _refrescar() -> void:
	var comercio := mundo.comercio
	if comercio.panel != null and comercio.panel.visible and comercio.pestana == "recompensas":
		comercio.refrescar_pestanas()
		comercio._refrescar()

# El pirata con nombre sale en el radar y, si está lejos, con una flecha dorada en la brújula.
func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	for barco in mundo.barcos:
		if barco.viva and objetivo_activo(barco) and mundo.en_mapa(barco.pos):
			var punto: Vector2 = centro + barco.pos * escala
			lienzo.draw_circle(punto, 6.0, Color("08161c"))
			lienzo.draw_circle(punto, 4.5, COLOR_OBJETIVO)


func dibujar_brujula(lienzo: Control, centro: Vector2, exterior: float, interior: float) -> void:
	var jugador := mundo.jugador
	if jugador == null or not jugador.viva:
		return
	for barco in mundo.barcos:
		if not barco.viva or not objetivo_activo(barco) or mundo.en_mapa(barco.pos):
			continue
		var direccion := (barco.pos - jugador.pos).normalized()
		var lado := direccion.orthogonal()
		var base := centro + direccion * (interior + 2.0)
		var punta := centro + direccion * (exterior + 4.0)
		var flecha := PackedVector2Array([punta, base + lado * 6.0, base - direccion * 2.0, base - lado * 6.0])
		lienzo.draw_colored_polygon(flecha, COLOR_OBJETIVO)
		flecha.append(flecha[0])
		lienzo.draw_polyline(flecha, Color("08161c"), 1.5, true)
