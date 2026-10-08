class_name PantallaCarga
extends CanvasLayer

# Cubre el arranque mientras se detecta el móvil, se ajustan los gráficos y se arma el mundo:
# un mar de noche animado (estrellas, luna, nubes, relámpagos, olas y un galeón meciéndose),
# el emblema con el título y una tarjeta con el paso, la barra de avance y consejos. También
# tapa la entrada y la salida de las partidas, que arman o desarman el mar entero.

const CIELO_ALTO := Color("07111f")
const CIELO_HORIZONTE := Color("1f4f63")
const OLAS: Array[Color] = [Color("123a4a"), Color("0d2c39"), Color("08202a")]
const CRESTA := Color(0.75, 0.93, 1.0, 0.35)
const ESTRELLAS := 70
const CAMBIO_CONSEJO := 4.0
const CONSEJOS: Array[String] = [
	"Consejo: arrastra el botón Cañones para disparar por la proa o por los costados.",
	"Consejo: mantén pulsada una habilidad para apuntarla y suéltala para lanzarla.",
	"Consejo: Reparar barco te devuelve un 25% de vida; úsalo antes de que sea tarde.",
	"Consejo: con el botón Base tu barco se sumerge y vuelve a tu nexo.",
	"Consejo: en la tienda de la base mejoras el casco, los cañones, las velas y la pólvora.",
	"Consejo: protege a tus botes; abren camino para derribar los fuertes rivales.",
]

var titulo: Label
var detalle: Label
var dispositivo: Label
var porcentaje: Label
var consejo: Label
var fondo: Control
var barra: Control
var emblema: TextureRect
var raiz: Control
var avance := 0.0
var mostrado := 0.0
var tiempo := 0.0
var estrellas: Array[Vector3] = []
var relampago := 0.0
var proximo_rayo := 3.0
var rayo := PackedVector2Array()
var indice_consejo := 0
var reloj_consejo := 0.0


func _init() -> void:
	layer = 128
	for _i in ESTRELLAS:
		estrellas.append(Vector3(randf(), randf() * 0.55, randf() * TAU))
	indice_consejo = randi() % CONSEJOS.size()
	raiz = Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(raiz)
	fondo = Control.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.draw.connect(_dibujar_fondo)
	raiz.add_child(fondo)

	var centro := VBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 4)
	Ui.anclar(centro, Vector2(0.5, 0.0), Vector2(-400, 40), Vector2(800, 330))
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(centro)
	emblema = TextureRect.new()
	emblema.texture = load("res://interfaz/emblema.svg")
	emblema.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblema.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblema.custom_minimum_size = Vector2(170, 170)
	emblema.pivot_offset = Vector2(85, 85)
	centro.add_child(emblema)
	var gruesa := FontVariation.new()
	gruesa.base_font = ThemeDB.fallback_font
	gruesa.variation_embolden = 1.1
	gruesa.spacing_glyph = 4
	var nombre := _etiqueta("ÚLTIMA MAREA", 66, Principal.COLOR_ORO)
	nombre.add_theme_font_override("font", gruesa)
	nombre.add_theme_color_override("font_outline_color", Color("08161c"))
	nombre.add_theme_constant_override("outline_size", 14)
	nombre.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	nombre.add_theme_constant_override("shadow_offset_x", 3)
	nombre.add_theme_constant_override("shadow_offset_y", 5)
	centro.add_child(nombre)

	var tarjeta := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.07, 0.1, 0.82)
	estilo.border_color = Color(Principal.COLOR_ORO, 0.55)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(22)
	estilo.content_margin_left = 30
	estilo.content_margin_right = 30
	estilo.content_margin_top = 16
	estilo.content_margin_bottom = 14
	estilo.shadow_color = Color(0, 0, 0, 0.4)
	estilo.shadow_size = 18
	tarjeta.add_theme_stylebox_override("panel", estilo)
	Ui.anclar(tarjeta, Vector2(0.5, 1.0), Vector2(-360, -214), Vector2(720, 186))
	tarjeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(tarjeta)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	tarjeta.add_child(columna)
	var cabeza := HBoxContainer.new()
	columna.add_child(cabeza)
	titulo = _etiqueta(tr("Optimizando para tu dispositivo..."), 24, Principal.COLOR_ORO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabeza.add_child(titulo)
	porcentaje = _etiqueta("0%", 24, Principal.COLOR_TEXTO)
	porcentaje.autowrap_mode = TextServer.AUTOWRAP_OFF
	cabeza.add_child(porcentaje)
	barra = Control.new()
	barra.custom_minimum_size = Vector2(0, 30)
	barra.draw.connect(_dibujar_barra)
	columna.add_child(barra)
	detalle = _etiqueta("", 17, Principal.COLOR_TEXTO)
	detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	columna.add_child(detalle)
	consejo = _etiqueta(tr(CONSEJOS[indice_consejo]), 15, Color("9fc3cc"))
	consejo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	columna.add_child(consejo)
	dispositivo = _etiqueta("", 13, Color(0.79, 0.82, 0.83, 0.7))
	Ui.anclar(dispositivo, Vector2(0.5, 1.0), Vector2(-360, -24), Vector2(720, 20))
	raiz.add_child(dispositivo)


func _etiqueta(texto: String, tam: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	etiqueta.add_theme_constant_override("outline_size", 5)
	return etiqueta


func titular(texto: String) -> void:
	titulo.text = texto


func paso(texto: String, parte: float, info := "") -> void:
	detalle.text = texto
	if info != "":
		dispositivo.text = info
	avance = parte


func _process(delta: float) -> void:
	tiempo += delta
	mostrado = move_toward(mostrado, avance, delta * 1.6) if mostrado < avance else avance
	porcentaje.text = "%d%%" % roundi(mostrado * 100.0)
	emblema.scale = Vector2.ONE * (1.0 + sin(tiempo * 1.8) * 0.025)
	emblema.rotation = sin(tiempo * 0.9) * 0.03
	relampago = maxf(0.0, relampago - delta * 2.5)
	proximo_rayo -= delta
	if proximo_rayo <= 0.0:
		proximo_rayo = randf_range(4.0, 8.0)
		relampago = 1.0
		_trazar_rayo()
	reloj_consejo += delta
	if reloj_consejo >= CAMBIO_CONSEJO:
		reloj_consejo = 0.0
		indice_consejo = (indice_consejo + 1) % CONSEJOS.size()
		consejo.text = tr(CONSEJOS[indice_consejo])
	consejo.modulate.a = clampf(minf(reloj_consejo, CAMBIO_CONSEJO - reloj_consejo) / 0.35, 0.0, 1.0)
	fondo.queue_redraw()
	barra.queue_redraw()


func _trazar_rayo() -> void:
	var tam := fondo.size
	var x := randf_range(0.1, 0.9) * tam.x
	rayo = PackedVector2Array([Vector2(x, 0.0)])
	var y := 0.0
	while y < tam.y * 0.45:
		y += randf_range(20.0, 45.0)
		x += randf_range(-28.0, 28.0)
		rayo.append(Vector2(x, y))


func _dibujar_fondo() -> void:
	var tam := fondo.size
	var horizonte := tam.y * 0.62
	var flash := Color(0.75, 0.85, 1.0) * relampago * 0.35
	fondo.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(tam.x, 0), Vector2(tam.x, horizonte), Vector2(0, horizonte)]),
			PackedColorArray([CIELO_ALTO + flash, CIELO_ALTO + flash, CIELO_HORIZONTE + flash, CIELO_HORIZONTE + flash]))
	for estrella in estrellas:
		var brillo := 0.35 + 0.65 * (0.5 + 0.5 * sin(tiempo * 2.0 + estrella.z))
		fondo.draw_circle(Vector2(estrella.x * tam.x, estrella.y * horizonte), 1.0 + brillo * 0.8, Color(1, 1, 0.92, brillo * 0.8))
	var luna := Vector2(tam.x * 0.82, tam.y * 0.17)
	for k in 14:
		fondo.draw_circle(luna, 40.0 + k * 9.0, Color(1.0, 0.92, 0.7, 0.018))
	fondo.draw_circle(luna, 34.0, Color("fdf1cf"))
	fondo.draw_circle(luna + Vector2(-9, -6), 6.0, Color("ead9ad"))
	fondo.draw_circle(luna + Vector2(10, 9), 4.0, Color("ead9ad"))
	var halo := emblema.get_global_rect().get_center()
	for k in 18:
		fondo.draw_circle(halo, 90.0 + k * 9.0 + sin(tiempo * 1.8) * 4.0, Color(Principal.COLOR_ORO, 0.012))
	for k in 4:
		var paso_nube := fmod(tiempo * (8.0 + k * 3.0) + k * 340.0, tam.x + 400.0) - 200.0
		var nube := Vector2(paso_nube, tam.y * (0.12 + k * 0.08))
		for j in 4:
			fondo.draw_circle(nube + Vector2(j * 38.0 - 57.0, absf(j - 1.5) * 8.0), 30.0 - absf(j - 1.5) * 6.0, Color(0.6, 0.7, 0.8, 0.07 + relampago * 0.1))
	if relampago > 0.3 and rayo.size() > 1:
		fondo.draw_polyline(rayo, Color(0.85, 0.92, 1.0, relampago), 3.0, true)
		fondo.draw_polyline(rayo, Color(0.6, 0.75, 1.0, relampago * 0.3), 9.0, true)
	var islas := PackedVector2Array([Vector2(0, horizonte)])
	for k in 25:
		var x := tam.x * k / 24.0
		var monte := maxf(0.0, sin(k * 0.9) * 26.0 + sin(k * 0.37 + 1.0) * 18.0)
		islas.append(Vector2(x, horizonte - monte))
	islas.append(Vector2(tam.x, horizonte))
	fondo.draw_colored_polygon(islas, Color("0f2e3c"))
	for capa in OLAS.size():
		var base := horizonte + 8.0 + capa * tam.y * 0.11
		var alto := 7.0 + capa * 5.0
		var ola := PackedVector2Array([Vector2(0, tam.y)])
		var cresta := PackedVector2Array()
		for k in 65:
			var x := tam.x * k / 64.0
			var y := base + sin(x * 0.012 + tiempo * (1.2 + capa * 0.5) + capa) * alto + sin(x * 0.031 - tiempo * 0.9) * alto * 0.35
			ola.append(Vector2(x, y))
			cresta.append(Vector2(x, y))
		ola.append(Vector2(tam.x, tam.y))
		if capa == 1:
			_dibujar_galeon(Vector2(maxf(80.0, tam.x * 0.5 - 450.0), base), alto)
		fondo.draw_colored_polygon(ola, OLAS[capa])
		fondo.draw_polyline(cresta, Color(CRESTA, CRESTA.a * (1.0 - capa * 0.25)), 2.0, true)


# Silueta de un galeón que cabecea sobre la segunda capa de olas.
func _dibujar_galeon(sitio: Vector2, alto: float) -> void:
	var y := sitio.y + sin(sitio.x * 0.012 + tiempo * 1.7 + 1.0) * alto - 6.0
	var inclinacion := sin(tiempo * 1.7) * 0.06
	var t := Transform2D(inclinacion, Vector2(sitio.x, y))
	var casco := PackedVector2Array([Vector2(-62, -6), Vector2(62, -10), Vector2(48, 14), Vector2(-48, 14)])
	var oscuro := Color("061820")
	fondo.draw_colored_polygon(t * casco, oscuro)
	for palo: Array in [[-24.0, 74.0], [16.0, 92.0]]:
		var x: float = palo[0]
		var largo: float = palo[1]
		fondo.draw_line(t * Vector2(x, -6), t * Vector2(x, -6 - largo), oscuro, 3.0)
		for vela in 2:
			var arriba := -14.0 - largo * (0.5 * vela) - 4.0
			var abajo := arriba - largo * 0.4
			var hinchado := 6.0 + sin(tiempo * 2.0 + vela) * 1.5
			fondo.draw_colored_polygon(t * PackedVector2Array([Vector2(x - 22, abajo), Vector2(x + 22, abajo),
					Vector2(x + 22 + hinchado, arriba), Vector2(x - 22 + hinchado, arriba)]), Color(0.88, 0.85, 0.76, 0.85))
	fondo.draw_colored_polygon(t * PackedVector2Array([Vector2(16, -98), Vector2(36, -93), Vector2(16, -88)]), Color("c0392b"))
	for k in 3:
		fondo.draw_circle(t * Vector2(-30 + k * 26, 2), 2.5, Color(1.0, 0.8, 0.4, 0.85))


func _dibujar_barra() -> void:
	var tam := barra.size
	var pista := Rect2(Vector2(0, 9), Vector2(tam.x, 12))
	var redondo := StyleBoxFlat.new()
	redondo.set_corner_radius_all(6)
	redondo.bg_color = Color(0, 0, 0, 0.45)
	redondo.border_color = Color(1, 1, 1, 0.08)
	redondo.set_border_width_all(1)
	barra.draw_style_box(redondo, pista)
	var lleno := pista.size.x * clampf(mostrado, 0.0, 1.0)
	if lleno > 2.0:
		var relleno := redondo.duplicate() as StyleBoxFlat
		relleno.bg_color = Principal.COLOR_ORO
		relleno.set_border_width_all(0)
		barra.draw_style_box(relleno, Rect2(pista.position, Vector2(lleno, pista.size.y)))
		barra.draw_rect(Rect2(pista.position + Vector2(3, 2), Vector2(maxf(0.0, lleno - 6.0), 3)), Color(1, 1, 1, 0.3))
		var brillo := fmod(tiempo * 220.0, lleno + 60.0) - 30.0
		if brillo > 0.0 and brillo < lleno:
			barra.draw_rect(Rect2(pista.position + Vector2(brillo, 0), Vector2(minf(18.0, lleno - brillo), pista.size.y)), Color(1, 1, 1, 0.22))
	var punta := Vector2(clampf(lleno, 12.0, tam.x - 12.0), 6.0 + sin(tiempo * 4.0) * 1.5)
	barra.draw_colored_polygon(PackedVector2Array([punta + Vector2(-12, 2), punta + Vector2(12, 2), punta + Vector2(8, 8), punta + Vector2(-8, 8)]), Color("8a5a32"))
	barra.draw_line(punta + Vector2(0, 2), punta + Vector2(0, -14), Color("5a3a1e"), 2.0)
	barra.draw_colored_polygon(PackedVector2Array([punta + Vector2(1, -13), punta + Vector2(11, 0), punta + Vector2(1, 0)]), Color("f3ecdf"))


func cerrar(espera := 0.5, fundir := 0.4) -> void:
	avance = 1.0
	var fundido := create_tween()
	fundido.tween_interval(espera)
	fundido.tween_property(raiz, "modulate:a", 0.0, fundir)
	fundido.tween_callback(queue_free)
