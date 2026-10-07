class_name Insignia
extends Control

# Escudo de cada nivel: [borde, fondo, símbolo, cuántos]. Se dibuja escalado al tamaño del control.
const ESTILOS := [
	[Color("8a6a45"), Color("35505c"), "galon", 1],
	[Color("c07a3c"), Color("1f4f73"), "galon", 2],
	[Color("cfd5dd"), Color("7a2a2a"), "galon", 3],
	[Color("e2b13a"), Color("1d3557"), "estrella", 1],
	[Color("f0c64a"), Color("102a43"), "estrella", 3],
	[Color("ffe08a"), Color("4b2a7a"), "corona", 1],
]
const ESCUDO := [
	Vector2(-0.82, -0.8), Vector2(-0.4, -0.92), Vector2(0.0, -0.82), Vector2(0.4, -0.92), Vector2(0.82, -0.8),
	Vector2(0.82, 0.0), Vector2(0.6, 0.48), Vector2(0.0, 0.96), Vector2(-0.6, 0.48), Vector2(-0.82, 0.0),
]

var nivel := 0:
	set(nuevo):
		nivel = clampi(nuevo, 0, ESTILOS.size() - 1)
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var estilo: Array = ESTILOS[nivel]
	var centro := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	if nivel == ESTILOS.size() - 1:
		draw_circle(centro, r, Color(1.0, 0.85, 0.4, 0.18))
	_poligono(centro, r * 0.98, Color(0, 0, 0, 0.35), Vector2(0, r * 0.06))
	_poligono(centro, r * 0.98, estilo[0])
	_poligono(centro, r * 0.8, estilo[1])
	var claro: Color = estilo[0].lightened(0.35)
	match estilo[2]:
		"galon":
			var cuantos: int = estilo[3]
			for i in cuantos:
				var y := (i - (cuantos - 1) / 2.0) * 0.3 - 0.05
				var trazo := PackedVector2Array([
					centro + Vector2(-0.42, y - 0.14) * r, centro + Vector2(0.0, y + 0.14) * r, centro + Vector2(0.42, y - 0.14) * r])
				draw_polyline(trazo, claro, r * 0.13, true)
		"estrella":
			if estilo[3] == 1:
				_estrella(centro + Vector2(0, 0.02) * r, r * 0.42, claro)
			else:
				_estrella(centro + Vector2(0, -0.2) * r, r * 0.32, claro)
				_estrella(centro + Vector2(-0.34, 0.24) * r, r * 0.2, claro)
				_estrella(centro + Vector2(0.34, 0.24) * r, r * 0.2, claro)
		"corona":
			var base := 0.22
			var corona := PackedVector2Array([
				Vector2(-0.45, base), Vector2(-0.5, -0.28), Vector2(-0.22, -0.02), Vector2(0.0, -0.4),
				Vector2(0.22, -0.02), Vector2(0.5, -0.28), Vector2(0.45, base)])
			for i in corona.size():
				corona[i] = centro + corona[i] * r
			draw_colored_polygon(corona, claro)
			for punta in [Vector2(-0.5, -0.28), Vector2(0.0, -0.4), Vector2(0.5, -0.28)]:
				draw_circle(centro + punta * r, r * 0.07, claro)
			draw_rect(Rect2(centro + Vector2(-0.45, base + 0.06) * r, Vector2(0.9, 0.12) * r), claro)
			draw_circle(centro + Vector2(0, 0.06) * r, r * 0.07, Color("e04a5a"))


func _poligono(centro: Vector2, r: float, color: Color, desvio := Vector2.ZERO) -> void:
	var puntos := PackedVector2Array()
	for punto in ESCUDO:
		puntos.append(centro + desvio + punto * r)
	draw_colored_polygon(puntos, color)


func _estrella(centro: Vector2, r: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + TAU * i / 10.0
		puntos.append(centro + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(puntos, color)
