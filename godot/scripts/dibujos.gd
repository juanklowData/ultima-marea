class_name Dibujos
extends RefCounted

static var _texturas := {}


static func textura(pieza: Dictionary, ancho: int, alto: int) -> ImageTexture:
	var diseno: String = pieza.get("diseno", "lisa")
	var fondo: Color = pieza["color"]
	var figura: Color = pieza.get("color2", fondo)
	var clave := "%s|%s|%s|%d|%d" % [diseno, fondo.to_html(), figura.to_html(), ancho, alto]
	if _texturas.has(clave):
		return _texturas[clave]

	var imagen := Image.create(ancho, alto, false, Image.FORMAT_RGBA8)
	imagen.fill(fondo)
	_pintar(imagen, diseno, fondo, figura)
	var nueva := ImageTexture.create_from_image(imagen)
	_texturas[clave] = nueva
	return nueva


# Dibuja el diseño de la vela o bandera con el color de figura sobre el fondo ya pintado.
static func _pintar(imagen: Image, diseno: String, fondo: Color, figura: Color) -> void:
	var ancho := imagen.get_width()
	var alto := imagen.get_height()
	var centro := Vector2(ancho, alto) / 2.0
	var s := float(mini(ancho, alto))
	match diseno:
		"franjas":
			var bandas := 6
			for i in bandas:
				if i % 2 == 1:
					var x0 := ancho * i / bandas
					imagen.fill_rect(Rect2i(x0, 0, ancho * (i + 1) / bandas - x0, alto), figura)
		"cruz":
			var grueso := int(s * 0.16)
			imagen.fill_rect(Rect2i(int(centro.x) - grueso / 2, 0, grueso, alto), figura)
			imagen.fill_rect(Rect2i(0, int(centro.y) - grueso / 2, ancho, grueso), figura)
		"diagonal":
			for y in alto:
				for x in ancho:
					if float(x) / ancho + float(y) / alto > 1.0:
						imagen.set_pixel(x, y, figura)
		"parches":
			var azar := RandomNumberGenerator.new()
			azar.seed = 7
			for _i in 7:
				var w := int(s * azar.randf_range(0.12, 0.24))
				var h := int(s * azar.randf_range(0.1, 0.2))
				imagen.fill_rect(Rect2i(azar.randi_range(0, ancho - w), azar.randi_range(0, alto - h), w, h), figura)
		"calavera":
			_tibias(imagen, centro + Vector2(0, s * 0.1), s * 0.3, s * 0.07, figura)
			_calavera(imagen, centro + Vector2(0, -s * 0.06), s * 0.2, figura, fondo)
		"tibias":
			_tibias(imagen, centro, s * 0.36, s * 0.08, figura)
		"sol":
			var radio := s * 0.15
			for i in 12:
				var direccion := Vector2.from_angle(TAU * i / 12.0)
				_linea(imagen, centro + direccion * radio * 1.35, centro + direccion * radio * 2.2, s * 0.04, figura)
			_disco(imagen, centro, radio, figura)
		"estrella":
			_estrella(imagen, centro, s * 0.36, figura)
		"ancla":
			_ancla(imagen, centro, s, figura, fondo)
		"circulo":
			_disco(imagen, centro, s * 0.28, figura)
		"marco":
			var borde := maxi(2, int(s * 0.12))
			imagen.fill_rect(Rect2i(0, 0, ancho, borde), figura)
			imagen.fill_rect(Rect2i(0, alto - borde, ancho, borde), figura)
			imagen.fill_rect(Rect2i(0, 0, borde, alto), figura)
			imagen.fill_rect(Rect2i(ancho - borde, 0, borde, alto), figura)
		"mitad":
			imagen.fill_rect(Rect2i(ancho / 2, 0, ancho - ancho / 2, alto), figura)
		"cuadros":
			var lado := maxi(2, int(s / 4.0))
			for y in range(0, alto, lado):
				for x in range(0, ancho, lado):
					if (x / lado + y / lado) % 2 == 1:
						imagen.fill_rect(Rect2i(x, y, lado, lado), figura)
		"luna":
			_disco(imagen, centro, s * 0.3, figura)
			_disco(imagen, centro + Vector2(s * 0.14, -s * 0.06), s * 0.27, fondo)
		"rombo":
			var media := Vector2(ancho * 0.38, alto * 0.38)
			for y in alto:
				for x in ancho:
					var d := Vector2(absf(x + 0.5 - centro.x) / media.x, absf(y + 0.5 - centro.y) / media.y)
					if d.x + d.y <= 1.0:
						imagen.set_pixel(x, y, figura)


static func _disco(imagen: Image, centro: Vector2, radio: float, color: Color) -> void:
	for y in range(maxi(0, int(centro.y - radio)), mini(imagen.get_height(), int(centro.y + radio) + 2)):
		for x in range(maxi(0, int(centro.x - radio)), mini(imagen.get_width(), int(centro.x + radio) + 2)):
			if Vector2(x + 0.5, y + 0.5).distance_to(centro) <= radio:
				imagen.set_pixel(x, y, color)


static func _linea(imagen: Image, a: Vector2, b: Vector2, grosor: float, color: Color) -> void:
	var mitad := grosor / 2.0
	var minimo := a.min(b) - Vector2.ONE * mitad
	var maximo := a.max(b) + Vector2.ONE * mitad
	for y in range(maxi(0, int(minimo.y)), mini(imagen.get_height(), int(maximo.y) + 2)):
		for x in range(maxi(0, int(minimo.x)), mini(imagen.get_width(), int(maximo.x) + 2)):
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) <= mitad:
				imagen.set_pixel(x, y, color)


static func _calavera(imagen: Image, centro: Vector2, radio: float, color: Color, fondo: Color) -> void:
	_disco(imagen, centro, radio, color)
	imagen.fill_rect(Rect2i(int(centro.x - radio * 0.55), int(centro.y + radio * 0.5), int(radio * 1.1), int(radio * 0.6)), color)
	for lado in [-1.0, 1.0]:
		_disco(imagen, centro + Vector2(lado * radio * 0.4, -radio * 0.05), radio * 0.27, fondo)
	_disco(imagen, centro + Vector2(0, radio * 0.42), radio * 0.11, fondo)
	for i in 3:
		var x := centro.x + (i - 1) * radio * 0.3
		_linea(imagen, Vector2(x, centro.y + radio * 0.75), Vector2(x, centro.y + radio * 1.05), maxf(1.0, radio * 0.08), fondo)


static func _tibias(imagen: Image, centro: Vector2, largo: float, grosor: float, color: Color) -> void:
	for lado in [-1.0, 1.0]:
		var a := centro + Vector2(-largo, -largo * 0.6 * lado)
		var b := centro + Vector2(largo, largo * 0.6 * lado)
		_linea(imagen, a, b, grosor, color)
		var normal := (b - a).normalized().orthogonal() * grosor * 0.6
		for punta in [a, b]:
			_disco(imagen, punta + normal, grosor * 0.75, color)
			_disco(imagen, punta - normal, grosor * 0.75, color)


static func _estrella(imagen: Image, centro: Vector2, radio: float, color: Color) -> void:
	for y in imagen.get_height():
		for x in imagen.get_width():
			var d := Vector2(x + 0.5, y + 0.5) - centro
			var angulo := atan2(d.y, d.x) + PI / 2.0
			var limite := lerpf(radio * 0.42, radio, pow(0.5 + 0.5 * cos(angulo * 5.0), 3.0))
			if d.length() <= limite:
				imagen.set_pixel(x, y, color)


static func _ancla(imagen: Image, centro: Vector2, s: float, color: Color, fondo: Color) -> void:
	var grosor := s * 0.065
	_linea(imagen, centro + Vector2(0, -s * 0.28), centro + Vector2(0, s * 0.3), grosor, color)
	_linea(imagen, centro + Vector2(-s * 0.15, -s * 0.17), centro + Vector2(s * 0.15, -s * 0.17), grosor, color)
	_disco(imagen, centro + Vector2(0, -s * 0.34), s * 0.075, color)
	_disco(imagen, centro + Vector2(0, -s * 0.34), s * 0.035, fondo)
	var radio := s * 0.25
	var base := centro + Vector2(0, s * 0.05)
	var anterior := base + Vector2.from_angle(deg_to_rad(15.0)) * radio
	for i in range(1, 11):
		var punto := base + Vector2.from_angle(deg_to_rad(lerpf(15.0, 165.0, i / 10.0))) * radio
		_linea(imagen, anterior, punto, grosor, color)
		anterior = punto
	for lado in [-1.0, 1.0]:
		var punta := base + Vector2.from_angle(deg_to_rad(90.0 - 75.0 * lado)) * radio
		_linea(imagen, punta, punta + Vector2(lado * s * 0.02, -s * 0.09), grosor, color)
