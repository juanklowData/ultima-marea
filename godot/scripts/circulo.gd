class_name Circulo
extends RefCounted

# Isla o roca en el mapa 2D. radio es el máximo; forma guarda, por ángulo, qué parte
# de ese radio llega a la orilla (vacía = círculo). La forma siempre se ve desde el centro.

const MUESTRAS := 64

var pos: Vector2
var radio: float
var forma := PackedFloat32Array()
# Centros de los lóbulos en fracción del radio: (x, y, radio del lóbulo).
var lobulos: Array[Vector3] = []


func _init(p: Vector2, r: float) -> void:
	pos = p
	radio = r


func factor(angulo: float) -> float:
	if forma.is_empty():
		return 1.0
	var u := fposmod(angulo, TAU) / TAU * MUESTRAS
	var i := int(u) % MUESTRAS
	return lerpf(forma[i], forma[(i + 1) % MUESTRAS], u - floorf(u))


# Distancia del centro a la orilla en la dirección del punto.
func borde(punto: Vector2) -> float:
	return radio * factor((punto - pos).angle())


func dentro(punto: Vector2, margen := 0.0) -> bool:
	return punto.distance_to(pos) < borde(punto) + margen


func factor_minimo() -> float:
	if forma.is_empty():
		return 1.0
	var menor := 1.0
	for f in forma:
		menor = minf(menor, f)
	return menor


# Unión de lóbulos que contienen el centro, con costa rota y a veces una bahía.
func dar_forma() -> void:
	# Las alargadas salen más a menudo que el resto.
	var sorteo := randf()
	var tipo := 0 if sorteo < 0.4 else 1 + int((sorteo - 0.4) / 0.6 * 4.0)
	var giro := randf() * TAU
	_elegir_lobulos(tipo, giro)
	_trazar_contorno(randf() < 0.45 and tipo != 1, giro + PI * 0.5 + randf_range(-0.6, 0.6))
	_suavizar()


func _elegir_lobulos(tipo: int, giro: float) -> void:
	lobulos.clear()
	match tipo:
		0:
			# Alargada: a veces una franja larga y fina, a veces más gruesa.
			var fina := randf() < 0.5
			var d := randf_range(0.5, 0.6) if fina else randf_range(0.35, 0.5)
			var r := randf_range(0.36, 0.44) if fina else randf_range(0.5, 0.62)
			var curva := randf_range(-0.15, 0.15)
			lobulos.append(Vector3(cos(giro) * d, sin(giro) * d, r))
			lobulos.append(Vector3(-cos(giro) * d, -sin(giro) * d, r * randf_range(0.8, 1.0)))
			lobulos.append(Vector3(-sin(giro) * curva, cos(giro) * curva, r * 1.05))
			if fina:
				for s in [-0.5, 0.5]:
					lobulos.append(Vector3(cos(giro) * d * s - sin(giro) * curva * 0.6, sin(giro) * d * s + cos(giro) * curva * 0.6, r * 1.02))
		1:
			# Cacahuete: dos bultos con cintura.
			var d := randf_range(0.42, 0.52)
			lobulos.append(Vector3(cos(giro) * d, sin(giro) * d, d + randf_range(0.08, 0.14)))
			var d2 := randf_range(0.36, 0.48)
			lobulos.append(Vector3(-cos(giro) * d2, -sin(giro) * d2, d2 + randf_range(0.08, 0.14)))
		2:
			# Bumerán o L.
			var abre := randf_range(1.3, 2.0)
			for s in [-0.5, 0.5]:
				var a: float = giro + s * abre
				var d := randf_range(0.4, 0.5)
				lobulos.append(Vector3(cos(a) * d, sin(a) * d, d + randf_range(0.08, 0.13)))
			lobulos.append(Vector3(0, 0, 0.4))
		3:
			# Tres o cuatro lóbulos.
			var n := randi_range(3, 4)
			for k in n:
				var a := giro + TAU * k / n + randf_range(-0.35, 0.35)
				var d := randf_range(0.3, 0.45)
				lobulos.append(Vector3(cos(a) * d, sin(a) * d, d + randf_range(0.12, 0.25)))
		_:
			# Redondeada pero torcida, con un cabo saliente.
			lobulos.append(Vector3(0, 0, randf_range(0.62, 0.72)))
			var d := randf_range(0.38, 0.48)
			lobulos.append(Vector3(cos(giro) * d, sin(giro) * d, randf_range(0.35, 0.45)))


# Hasta dónde llega la unión de lóbulos en cada ángulo, con la costa algo rota.
func _trazar_contorno(bahia: bool, donde_bahia: float) -> void:
	var hondura := randf_range(0.2, 0.32)
	var fases := [randf() * TAU, randf() * TAU, randf() * TAU]
	forma.resize(MUESTRAS)
	for i in MUESTRAS:
		var a := TAU * i / MUESTRAS
		var dir := Vector2(cos(a), sin(a))
		var f := 0.0
		for l in lobulos:
			var c := Vector2(l.x, l.y)
			var proy := c.dot(dir)
			var resto := l.z * l.z - (c.length_squared() - proy * proy)
			if resto > 0.0:
				f = maxf(f, proy + sqrt(resto))
		f *= 1.0 + 0.05 * sin(5.0 * a + fases[0]) + 0.035 * sin(8.0 * a + fases[1]) + 0.02 * sin(13.0 * a + fases[2])
		if bahia:
			f *= 1.0 - hondura * exp(-pow(angle_difference(a, donde_bahia) / 0.4, 2.0))
		forma[i] = f


# Suaviza las cinturas para que no queden picos y deja el punto más lejano en 1.
func _suavizar() -> void:
	for _vuelta in 2:
		var previa := forma.duplicate()
		for i in MUESTRAS:
			forma[i] = (previa[(i + MUESTRAS - 1) % MUESTRAS] + previa[i] * 2.0 + previa[(i + 1) % MUESTRAS]) / 4.0
	var mayor := 0.0
	for f in forma:
		mayor = maxf(mayor, f)
	for i in MUESTRAS:
		forma[i] /= mayor
	for i in lobulos.size():
		lobulos[i] /= mayor
