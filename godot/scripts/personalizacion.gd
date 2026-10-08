class_name Personalizacion
extends RefCounted

const RUTA := "user://astillero.cfg"
const MONEDAS_INICIALES := 10
const LARGO_NOMBRE := 16
const NOMBRE_INICIAL := "Mi barco"
# Al subir este número se descarta el volumen de música guardado y vuelve al inicial.
const VERSION_AJUSTES := 4
# [nombre, experiencia mínima, monedas al llegar]. Las monedas se pagan solo la primera vez.
const NIVELES := [
	["Grumete", 0, 0], ["Marinero", 150, 20], ["Corsario", 450, 35],
	["Capitán", 1000, 50], ["Almirante", 1800, 70], ["Leyenda del Mar", 3000, 100],
]
# Según el puesto final: [hasta el puesto, experiencia]. Los peores puestos restan.
const EXPERIENCIA_POR_PUESTO := [[1, 30], [3, 20], [5, 14], [10, 9], [20, 4], [30, 0], [999, -8]]
const EXPERIENCIA_POR_HUNDIDO := 3
const EXPERIENCIA_RETIRADA := -12
# Partidas tras subir de nivel en las que no se puede bajar de él.
const PARTIDAS_PROTEGIDAS := 3

var elegidos := {}
var monedas := MONEDAS_INICIALES
var gemas := 0
var comprados: Array[String] = []
var nombre := NOMBRE_INICIAL
var volumen_musica := 0.1
var volumen_efectos := 1.0
# -1 automático (según el dispositivo); 0 súper bajo, 1 bajo, 2 medio, 3 alto.
var graficos := -1
# Efectos visuales que el jugador encendió o apagó a mano; los que faltan siguen al nivel.
var efectos := {}
# -1 según el nivel de gráficos; 0 plano, 1 suave, 2 con olas, 3 detallado.
var calidad_mar := -1
# Multiplica el tamaño automático de los controles táctiles de la partida (0,7 a 1,5).
var tam_botones := 1.0
var experiencia := 0
var nivel_premiado := 0
var proteccion := 0
var idioma := "es" if OS.get_locale_language() == "es" else "en"

var tipo: String:
	get:
		var barco := pieza("tipo")
		return barco.get("base", barco["id"])


func _init() -> void:
	for categoria in Catalogo.CATEGORIAS:
		elegidos[categoria] = Catalogo.inicial(categoria)


static func al_azar() -> Personalizacion:
	var aspecto := Personalizacion.new()
	for categoria in Catalogo.CATEGORIAS:
		aspecto.elegidos[categoria] = Catalogo.lista(categoria).pick_random()["id"]
	return aspecto


func copia() -> Personalizacion:
	var otra := Personalizacion.new()
	otra.elegidos = elegidos.duplicate()
	otra.monedas = monedas
	otra.comprados = comprados.duplicate()
	otra.nombre = nombre
	otra.experiencia = experiencia
	otra.nivel_premiado = nivel_premiado
	otra.proteccion = proteccion
	return otra


func pieza(categoria: String) -> Dictionary:
	return Catalogo.buscar(categoria, elegidos[categoria])


func tiene(categoria: String, id: String) -> bool:
	return Catalogo.buscar(categoria, id)["precio"] == 0 or comprados.has(categoria + "/" + id)
	var pieza := Catalogo.buscar(categoria, id)
	if comprados.has(categoria + "/" + id):
		return true
	return pieza["precio"] == 0 and pieza.get("gemas", 0) == 0


func comprar(categoria: String, id: String) -> bool:
	var pieza := Catalogo.buscar(categoria, id)
	var precio: int = pieza["precio"]
	var en_gemas: int = pieza.get("gemas", 0)
	if tiene(categoria, id) or monedas < precio or gemas < en_gemas:
		return false
	monedas -= precio
	gemas -= en_gemas
	elegidos[categoria] = id
	guardar()
	return true


func cambiar_nombre(nuevo: String) -> void:
	nombre = nuevo.strip_edges().left(LARGO_NOMBRE)
	guardar()


func nivel() -> int:
	var actual := 0
	for i in NIVELES.size():
		if experiencia >= NIVELES[i][1]:
			actual = i
	return actual


func nombre_nivel() -> String:
	return NIVELES[nivel()][0]


func experiencia_por(puesto: int, hundidos: int, retirada := false) -> int:
	var ganada := hundidos * EXPERIENCIA_POR_HUNDIDO
	if retirada:
		return ganada + EXPERIENCIA_RETIRADA
	for tramo in EXPERIENCIA_POR_PUESTO:
		if puesto <= tramo[0]:
			ganada += tramo[1]
			break
	return ganada


# Aplica la experiencia de una partida (puede ser negativa) y devuelve
# {"cambio": experiencia aplicada, "subio": bool, "bajo": bool, "protegido": bool, "monedas": premio}.
func sumar_experiencia(ganada: int) -> Dictionary:
	var antes := nivel()
	var resultado := {"cambio": 0, "subio": false, "bajo": false, "protegido": false, "monedas": 0}
	var nueva := maxi(0, experiencia + ganada)
	if ganada < 0 and proteccion > 0:
		var suelo: int = NIVELES[antes][1]
		if nueva < suelo:
			nueva = suelo
			resultado["protegido"] = true
	proteccion = maxi(0, proteccion - 1)
	resultado["cambio"] = nueva - experiencia
	experiencia = nueva
	var ahora := nivel()
	if ahora > antes:
		resultado["subio"] = true
		proteccion = PARTIDAS_PROTEGIDAS
	elif ahora < antes:
		resultado["bajo"] = true
	var premio := 0
	while nivel_premiado < ahora:
		nivel_premiado += 1
		premio += NIVELES[nivel_premiado][2]
	monedas += premio
	resultado["monedas"] = premio
	guardar()
	return resultado


func nombre_visible() -> String:
	return nombre if nombre != "" else NOMBRE_INICIAL


func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA) != OK:
		return
	if archivo.has_section_key("tesoro", "monedas"):
		monedas = archivo.get_value("tesoro", "monedas", MONEDAS_INICIALES)
	elif archivo.has_section_key("tesoro", "oro"):
		monedas = ceili(int(archivo.get_value("tesoro", "oro", 0)) / 10.0)
	nombre = str(archivo.get_value("capitan", "nombre", NOMBRE_INICIAL)).left(LARGO_NOMBRE)
	gemas = maxi(0, int(archivo.get_value("tesoro", "gemas", 0)))
	if int(archivo.get_value("ajustes", "version", 0)) >= VERSION_AJUSTES:
		volumen_musica = clampf(float(archivo.get_value("ajustes", "musica", volumen_musica)), 0.0, 1.0)
	volumen_efectos = clampf(float(archivo.get_value("ajustes", "efectos", volumen_efectos)), 0.0, 1.0)
	graficos = clampi(int(archivo.get_value("ajustes", "calidad", graficos)), -1, 3)
	tam_botones = clampf(float(archivo.get_value("ajustes", "botones", tam_botones)), 0.7, 1.5)
	calidad_mar = clampi(int(archivo.get_value("ajustes", "mar", calidad_mar)), -1, 3)
	if archivo.has_section("efectos"):
		for clave in archivo.get_section_keys("efectos"):
			efectos[clave] = bool(archivo.get_value("efectos", clave))
	experiencia = maxi(0, int(archivo.get_value("rango", "experiencia", archivo.get_value("rango", "copas", 0))))
	var guardado := str(archivo.get_value("ajustes", "idioma", idioma))
	if guardado in Idioma.IDIOMAS:
		idioma = guardado
	nivel_premiado = maxi(nivel(), int(archivo.get_value("rango", "nivel_premiado", archivo.get_value("rango", "liga_maxima", 0))))
	proteccion = clampi(int(archivo.get_value("rango", "proteccion", 0)), 0, PARTIDAS_PROTEGIDAS)
	for entrada in archivo.get_value("tesoro", "comprados", []):
		comprados.append(str(entrada))
	for categoria in Catalogo.CATEGORIAS:
		var id := str(archivo.get_value("piezas", categoria, elegidos[categoria]))
		if Catalogo.existe(categoria, id) and tiene(categoria, id):
			elegidos[categoria] = id
	var tipo_viejo := str(archivo.get_value("barco", "tipo", ""))
	if not archivo.has_section("piezas") and Catalogo.existe("tipo", tipo_viejo):
		elegidos["tipo"] = tipo_viejo


func guardar() -> void:
	var archivo := ConfigFile.new()
	archivo.set_value("tesoro", "monedas", monedas)
	archivo.set_value("tesoro", "comprados", comprados)
	archivo.set_value("tesoro", "gemas", gemas)
	archivo.set_value("capitan", "nombre", nombre)
	archivo.set_value("rango", "experiencia", experiencia)
	archivo.set_value("rango", "nivel_premiado", nivel_premiado)
	archivo.set_value("rango", "proteccion", proteccion)
	archivo.set_value("ajustes", "version", VERSION_AJUSTES)
	archivo.set_value("ajustes", "musica", volumen_musica)
	archivo.set_value("ajustes", "efectos", volumen_efectos)
	archivo.set_value("ajustes", "idioma", idioma)
	archivo.set_value("ajustes", "calidad", graficos)
	archivo.set_value("ajustes", "botones", tam_botones)
	archivo.set_value("ajustes", "mar", calidad_mar)
	for clave in efectos:
		archivo.set_value("efectos", clave, efectos[clave])
	for categoria in Catalogo.CATEGORIAS:
		archivo.set_value("piezas", categoria, elegidos[categoria])
	archivo.save(RUTA)
