class_name MonedaVoladora
extends Control

# Moneda que salta del premio, gira en el aire y cae con gravedad hasta desvanecerse.

const GRAVEDAD := 1500.0

var velocidad := Vector2.ZERO
var vida := 1.3
var giro := randf() * TAU


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	velocidad.y += GRAVEDAD * delta
	position += velocidad * delta
	giro += delta * 9.0
	vida -= delta
	modulate.a = clampf(vida / 0.4, 0.0, 1.0)
	queue_redraw()
	if vida <= 0.0:
		queue_free()


func _draw() -> void:
	var ancho := absf(cos(giro))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(maxf(ancho, 0.12), 1.0))
	draw_circle(Vector2.ZERO, 15.0, Color("8a6418"))
	draw_circle(Vector2.ZERO, 12.5, Color("e2b13a"))
	draw_circle(Vector2.ZERO, 8.0, Color("f0cd62"))
	draw_circle(Vector2(-4.0, -4.0), 3.0, Color(1, 1, 1, 0.7))
