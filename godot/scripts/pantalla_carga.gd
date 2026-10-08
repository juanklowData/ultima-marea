class_name PantallaCarga
extends CanvasLayer

# Cubre el arranque con la misma imagen del splash mientras se detecta el móvil, se ajustan los
# gráficos y se arma el mundo; muestra cada paso y una barra de avance. También tapa la entrada
# y la salida de las partidas, que arman o desarman el mar entero.

var titulo: Label
var detalle: Label
var dispositivo: Label
var barra: ColorRect
var fondo_barra: ColorRect
var raiz: Control
var avance := 0.0


func _init() -> void:
	layer = 128
	raiz = Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(raiz)
	var cielo := ColorRect.new()
	cielo.color = Color(0.043, 0.141, 0.188)
	cielo.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(cielo)
	var imagen := TextureRect.new()
	imagen.texture = load("res://interfaz/pantalla_carga.png")
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	imagen.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(imagen)

	var franja := ColorRect.new()
	franja.color = Color(0.02, 0.07, 0.1, 0.72)
	Ui.anclar(franja, Vector2(0, 1), Vector2(0, -150), Vector2(0, 150))
	franja.anchor_right = 1.0
	franja.offset_right = 0.0
	raiz.add_child(franja)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	franja.add_child(columna)
	columna.set_anchors_preset(Control.PRESET_FULL_RECT)
	columna.offset_left = 80
	columna.offset_right = -80
	titulo = _etiqueta(tr("Optimizando para tu dispositivo..."), 28, Principal.COLOR_ORO)
	columna.add_child(titulo)
	detalle = _etiqueta("", 19, Principal.COLOR_TEXTO)
	columna.add_child(detalle)
	fondo_barra = ColorRect.new()
	fondo_barra.color = Color(0, 0, 0, 0.5)
	fondo_barra.custom_minimum_size = Vector2(0, 12)
	columna.add_child(fondo_barra)
	barra = ColorRect.new()
	barra.color = Principal.COLOR_ORO
	fondo_barra.add_child(barra)
	dispositivo = _etiqueta("", 15, Color("c9d1d3"))
	columna.add_child(dispositivo)


func _etiqueta(texto: String, tam: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	etiqueta.add_theme_constant_override("outline_size", 6)
	return etiqueta


func titular(texto: String) -> void:
	titulo.text = texto


func paso(texto: String, parte: float, info := "") -> void:
	detalle.text = texto
	if info != "":
		dispositivo.text = info
	avance = parte
	barra.size = Vector2(fondo_barra.size.x * avance, fondo_barra.size.y)


func _process(_delta: float) -> void:
	barra.size = Vector2(fondo_barra.size.x * avance, fondo_barra.size.y)


func cerrar(espera := 0.5, fundir := 0.4) -> void:
	var fundido := create_tween()
	fundido.tween_interval(espera)
	fundido.tween_property(raiz, "modulate:a", 0.0, fundir)
	fundido.tween_callback(queue_free)
