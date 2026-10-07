class_name BotonIdioma
extends Button

# Muestra la bandera del idioma actual; al tocarla pasa al siguiente.

var idioma := "es"


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.05, 0.16, 0.2, 0.9)
	fondo.border_color = Color(0.95, 0.88, 0.73, 0.4)
	fondo.set_border_width_all(2)
	fondo.set_corner_radius_all(14)
	var activo := fondo.duplicate() as StyleBoxFlat
	activo.border_color = Color("e2b15a")
	add_theme_stylebox_override("normal", fondo)
	add_theme_stylebox_override("hover", activo)
	add_theme_stylebox_override("pressed", activo)


func _draw() -> void:
	var marco := Rect2(Vector2(10, 10), size - Vector2(20, 20))
	if idioma == "es":
		_espana(marco)
	else:
		_reino_unido(marco)
	draw_rect(marco, Color(0, 0, 0, 0.35), false, 1.5)


func _espana(r: Rect2) -> void:
	draw_rect(r, Color("c60b1e"))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.25), Vector2(r.size.x, r.size.y * 0.5)), Color("ffc400"))


func _reino_unido(r: Rect2) -> void:
	var azul := Color("012169")
	var rojo := Color("c8102e")
	draw_rect(r, azul)
	_aspa(r, r.size.y * 0.2, Color.WHITE)
	_aspa(r, r.size.y * 0.07, rojo)
	var centro := r.get_center()
	var blanca := r.size.y * 0.34
	var roja := r.size.y * 0.2
	draw_rect(Rect2(r.position.x, centro.y - blanca / 2.0, r.size.x, blanca), Color.WHITE)
	draw_rect(Rect2(centro.x - blanca / 2.0, r.position.y, blanca, r.size.y), Color.WHITE)
	draw_rect(Rect2(r.position.x, centro.y - roja / 2.0, r.size.x, roja), rojo)
	draw_rect(Rect2(centro.x - roja / 2.0, r.position.y, roja, r.size.y), rojo)


# Las dos diagonales recortadas al rectángulo, con media anchura "grosor".
func _aspa(r: Rect2, grosor: float, color: Color) -> void:
	var w := r.size.x
	var h := r.size.y
	var dy := grosor * sqrt(1.0 + pow(h / w, 2.0))
	var dx := dy * w / h
	var o := r.position
	draw_colored_polygon(PackedVector2Array([o, o + Vector2(dx, 0), o + Vector2(w, h - dy), o + Vector2(w, h), o + Vector2(w - dx, h), o + Vector2(0, dy)]), color)
	draw_colored_polygon(PackedVector2Array([o + Vector2(w, 0), o + Vector2(w, dy), o + Vector2(dx, h), o + Vector2(0, h), o + Vector2(0, h - dy), o + Vector2(w - dx, 0)]), color)
