class_name Ui
extends RefCounted

# Piezas de interfaz reutilizables: textos, botones, paneles, barras e iconos con el
# estilo del juego. No guardan estado de la partida.

static var _moneda: ImageTexture
static var _gema: ImageTexture


static func etiqueta(texto: String, tam: int) -> Label:
	var nueva := Label.new()
	nueva.text = texto
	nueva.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nueva.add_theme_font_size_override("font_size", tam)
	nueva.add_theme_color_override("font_color", Principal.COLOR_TEXTO)
	nueva.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	nueva.add_theme_constant_override("outline_size", 6)
	return nueva


# Texto sin contorno que se parte en varias líneas, para dentro de los paneles.
static func etiqueta_panel(texto: String, tam: int, color: Color) -> Label:
	var nueva := etiqueta(texto, tam)
	nueva.add_theme_color_override("font_color", color)
	nueva.add_theme_constant_override("outline_size", 0)
	nueva.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return nueva


static func boton(texto: String, primario: bool) -> Button:
	var nuevo := Button.new()
	nuevo.text = texto
	nuevo.custom_minimum_size = Vector2(0, 76)
	nuevo.focus_mode = Control.FOCUS_NONE
	nuevo.add_theme_font_size_override("font_size", 30)
	estilo_boton(nuevo, primario)
	return nuevo


# Activo: relleno dorado con texto oscuro. Inactivo: cristal con borde claro.
static func estilo_boton(objetivo: Button, activo: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(18)
	normal.set_content_margin_all(10)
	if activo:
		normal.bg_color = Paleta.BOTON
	else:
		normal.bg_color = Paleta.BOTON_CRISTAL
		normal.border_color = Paleta.BOTON_BORDE
		normal.set_border_width_all(2)
	var presionado := normal.duplicate() as StyleBoxFlat
	presionado.bg_color = normal.bg_color.darkened(0.15)
	objetivo.add_theme_stylebox_override("normal", normal)
	objetivo.add_theme_stylebox_override("hover", normal)
	objetivo.add_theme_stylebox_override("pressed", presionado)
	objetivo.add_theme_stylebox_override("disabled", normal)
	var texto := Paleta.TEXTO_OSCURO if activo else Principal.COLOR_TEXTO
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		objetivo.add_theme_color_override(nombre, texto)


# Relleno turquesa con texto claro: para volver atrás, que no se confunda con comprar.
static func estilo_volver(objetivo: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(18)
	normal.set_content_margin_all(10)
	normal.bg_color = Paleta.VOLVER
	normal.border_color = Paleta.VOLVER_BORDE
	normal.set_border_width_all(2)
	var presionado := normal.duplicate() as StyleBoxFlat
	presionado.bg_color = normal.bg_color.darkened(0.2)
	for estado in ["normal", "hover", "disabled"]:
		objetivo.add_theme_stylebox_override(estado, normal)
	objetivo.add_theme_stylebox_override("pressed", presionado)
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		objetivo.add_theme_color_override(nombre, Principal.COLOR_TEXTO)


# Coloca un control de tamaño fijo a partir de un punto de anclaje de la pantalla.
static func anclar(control: Control, ancla: Vector2, desde: Vector2, tam: Vector2) -> void:
	control.anchor_left = ancla.x
	control.anchor_right = ancla.x
	control.anchor_top = ancla.y
	control.anchor_bottom = ancla.y
	control.offset_left = desde.x
	control.offset_top = desde.y
	control.offset_right = desde.x + tam.x
	control.offset_bottom = desde.y + tam.y


static func estilo_panel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Paleta.PANEL
	estilo.border_color = Paleta.PANEL_BORDE
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(26)
	estilo.set_content_margin_all(30)
	return estilo


# Panel pegado al borde derecho de la pantalla. Devuelve [panel, columna de contenido].
static func panel_lateral(capa: CanvasLayer) -> Array:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", estilo_panel())
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -Principal.ANCHO_PANEL - 28.0
	panel.offset_right = -28.0
	panel.offset_top = 28.0
	panel.offset_bottom = -28.0
	capa.add_child(panel)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 14)
	panel.add_child(cuerpo)
	return [panel, cuerpo]


# Barra dorada de avance; el valor (0 a 1) se guarda en la meta "avance".
static func barra_progreso() -> Control:
	var barra := Control.new()
	barra.custom_minimum_size = Vector2(0, 12)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.set_meta("avance", 0.0)
	barra.draw.connect(func() -> void: _dibujar_barra(barra))
	return barra


static func _dibujar_barra(barra: Control) -> void:
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0, 0, 0, 0.4)
	fondo.set_corner_radius_all(6)
	barra.draw_style_box(fondo, Rect2(Vector2.ZERO, barra.size))
	var avance: float = barra.get_meta("avance", 0.0)
	if avance <= 0.0:
		return
	var lleno := fondo.duplicate() as StyleBoxFlat
	lleno.bg_color = Principal.COLOR_ORO
	barra.draw_style_box(lleno, Rect2(Vector2.ZERO, Vector2(maxf(barra.size.x * avance, 12.0), barra.size.y)))


# Disco de un color con borde oscuro, para los tiradores de los deslizadores.
static func textura_circulo(lado: int, color: Color) -> ImageTexture:
	var imagen := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var centro := Vector2(lado, lado) / 2.0
	for y in lado:
		for x in lado:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(centro)
			var borde := clampf(lado / 2.0 - d, 0.0, 1.0)
			var tono := color if d < lado / 2.0 - 4.0 else Color("08161c")
			imagen.set_pixel(x, y, Color(tono, borde))
	return ImageTexture.create_from_image(imagen)


# Moneda de oro: canto oscuro, cara dorada, relieve y brillo. Se dibuja una sola vez.
static func textura_moneda() -> ImageTexture:
	if _moneda != null:
		return _moneda
	var lado := 64
	var imagen := Image.create_empty(lado, lado, false, Image.FORMAT_RGBA8)
	var centro := Vector2(lado, lado) / 2.0
	var r := lado / 2.0 - 1.0
	for y in lado:
		for x in lado:
			var p := Vector2(x + 0.5, y + 0.5) - centro
			var d := p.length() / r
			if d > 1.0:
				continue
			var color := Color("8a6418")
			if d < 0.84:
				color = Color("e2b13a").lerp(Color("f6d978"), clampf(-(p.x + p.y) / (r * 1.4), 0.0, 1.0))
			if d > 0.56 and d < 0.64:
				color = Color("c08a22")
			if d < 0.56:
				color = Color("f0cd62").lerp(Color("fff1b0"), clampf(-(p.x + p.y) / r, 0.0, 1.0) * 0.6)
			color.a = clampf((1.0 - d) * r, 0.0, 1.0)
			imagen.set_pixel(x, y, color)
	_moneda = ImageTexture.create_from_image(imagen)
	return _moneda


# Gema tallada: corona ancha arriba y punta abajo, con facetas claras y oscuras.
static func textura_gema() -> ImageTexture:
	if _gema != null:
		return _gema
	var lado := 64
	var imagen := Image.create_empty(lado, lado, false, Image.FORMAT_RGBA8)
	var corona := 24.0
	for y in lado:
		for x in lado:
			var px := x + 0.5 - lado / 2.0
			var py := y + 0.5
			var mitad := 0.0
			if py >= 8.0 and py < corona:
				mitad = lerpf(18.0, 30.0, (py - 8.0) / (corona - 8.0))
			elif py >= corona and py < 60.0:
				mitad = 30.0 * (60.0 - py) / (60.0 - corona)
			var dentro := absf(px) < mitad
			if not dentro:
				continue
			var borde := clampf(mitad - absf(px), 0.0, 1.0)
			var color := Color("8f4fd6")
			if py < corona:
				color = Color("e2b8ff") if absf(px) < mitad * 0.45 else Color("b57cf0")
			elif px < 0.0:
				color = Color("a565ea") if px > -mitad * 0.5 else Color("6b2fb0")
			else:
				color = Color("7a3cc4")
			if mitad - absf(px) < 2.0 or absf(py - corona) < 1.2:
				color = Color("3a1460")
			color.a = borde
			imagen.set_pixel(x, y, color)
	_gema = ImageTexture.create_from_image(imagen)
	return _gema


static func icono_gema(tam: float) -> TextureRect:
	var icono := icono_moneda(tam)
	icono.texture = textura_gema()
	return icono


static func icono_moneda(tam: float) -> TextureRect:
	var icono := TextureRect.new()
	icono.texture = textura_moneda()
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.custom_minimum_size = Vector2(tam, tam)
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icono
