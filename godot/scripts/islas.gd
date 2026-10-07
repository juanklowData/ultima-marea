class_name Islas
extends Node3D

# Islas y grupos de rocas del mar: dónde caen, cómo se construyen en 3D, la espuma
# de sus orillas y cuáles se dibujan según la distancia a la cámara.

# Todo el mar se reparte al azar en cada partida.
const ISLAS_CENTRO := 3
const ISLAS_GRANDES := 24
const ARCHIPIELAGOS := 8
const ISLOTES_CHICOS := 40
const GRUPOS_ROCAS := 80
# Hueco mínimo entre orillas: el normal y el de los canales dentro de un archipiélago
# (cabe un galeón con margen).
const SEPARACION_ISLAS := 110.0
const SEPARACION_CANAL := 85.0
const RADIO_ROCAS := 36.0
const ALCANCE_ORILLA := 1.55
const SHADER_ORILLA := preload("res://shaders/orilla.gdshader")

const COLOR_ARENA := Color("e9d6a8")
const COLOR_HIERBA := Color("4f9a55")
const COLOR_HIERBA_OSCURA := Color("2f7a48")
const COLOR_ROCA := Color("8b8f8c")
const COLOR_TRONCO := Color("8a6a45")
const COLOR_HOJA := Color("3f9a4f")

var mundo: Principal
var islotes: Array[Circulo] = []
var materiales_orilla: Array[ShaderMaterial] = []
var malla_musgo: SphereMesh
var malla_mata: SphereMesh
var espera_recorte := 0.0


func _ready() -> void:
	mundo = get_parent()


# Borra el mar anterior y reparte uno nuevo.
func generar() -> void:
	for hijo in get_children():
		hijo.queue_free()
	islotes.clear()
	materiales_orilla.clear()

	# Cerca del centro, donde acaba la tormenta, siempre hay islas para cubrirse.
	_repartir_islotes(ISLAS_CENTRO, 55.0, 85.0, Vector2.ZERO, 650.0)
	_repartir_islotes(ISLAS_GRANDES, 58.0, 96.0)
	_repartir_archipielagos()
	_repartir_islotes(ISLOTES_CHICOS, 40.0, 54.0)
	_repartir_islotes(GRUPOS_ROCAS, 22.0, 34.0, Vector2.ZERO, Principal.RADIO_MUNDO * 0.85, 80.0)
	for isla in islotes:
		if isla.radio <= RADIO_ROCAS:
			add_child(_crear_rocas(isla))
		else:
			isla.radio *= 1.15
			isla.dar_forma()
			add_child(_crear_isla(isla))


# Las islas lejanas no se dibujan (con sus palmeras, animales y sombras).
func recortar(delta: float, foco: Vector3, alcance: float) -> void:
	espera_recorte -= delta
	if espera_recorte > 0.0:
		return
	espera_recorte = 0.2
	var foco_plano := Vector2(foco.x, foco.z)
	for nodo: Node3D in get_children():
		var borde: float = nodo.get_meta("radio", 0.0) * ALCANCE_ORILLA * 1.15
		nodo.visible = Vector2(nodo.position.x, nodo.position.z).distance_to(foco_plano) < alcance + borde


# La espuma de las orillas se mueve con el tiempo y se apaga dentro de la tormenta.
func actualizar_orillas(tiempo: float, zona_centro: Vector2, zona_radio: float) -> void:
	for materia in materiales_orilla:
		materia.set_shader_parameter("tiempo", tiempo)
		materia.set_shader_parameter("zona_centro", zona_centro * Principal.ESCALA)
		materia.set_shader_parameter("zona_radio", zona_radio * Principal.ESCALA)


# Reparto

func _repartir_islotes(cantidad: int, radio_min: float, radio_max: float, centro := Vector2.ZERO,
		alcance := Principal.RADIO_MUNDO * 0.85, separacion := SEPARACION_ISLAS) -> void:
	var puestos := 0
	for _intento in cantidad * 30:
		if puestos >= cantidad:
			return
		var radio := randf_range(radio_min, radio_max)
		var punto := centro + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * alcance
		if punto.length() < 200.0 or punto.length() > Principal.RADIO_MUNDO * 0.88:
			continue
		var libre := true
		for otra in islotes:
			if punto.distance_to(otra.pos) < otra.radio + radio + separacion:
				libre = false
				break
		if libre:
			islotes.append(Circulo.new(punto, radio))
			puestos += 1


# Grupos de islas pequeñas parecidas, separadas por canales estrechos.
func _repartir_archipielagos() -> void:
	for _a in ARCHIPIELAGOS:
		var centro := Vector2.ZERO
		for _intento in 40:
			centro = Vector2.from_angle(randf() * TAU) * sqrt(randf()) * Principal.RADIO_MUNDO * 0.78
			var libre := centro.length() > 400.0
			for otra in islotes:
				if centro.distance_to(otra.pos) < otra.radio + 200.0:
					libre = false
					break
			if libre:
				break
		var tamano := randf_range(38.0, 52.0)
		_repartir_islotes(randi_range(3, 6), tamano * 0.85, tamano * 1.15, centro, randf_range(230.0, 320.0), SEPARACION_CANAL)
		_repartir_islotes(randi_range(1, 3), 22.0, 30.0, centro, 300.0, SEPARACION_CANAL)


# Rocas

func _crear_rocas(isla: Circulo) -> Node3D:
	var nodo := Node3D.new()
	nodo.position = mundo.a_3d(isla.pos)
	nodo.rotation.y = randf() * TAU
	var r := isla.radio * Principal.ESCALA
	var roca := SphereMesh.new()
	roca.radius = 0.5
	roca.height = 1.0
	roca.radial_segments = 7
	roca.rings = 4
	var tonos: Array[Color] = [COLOR_ROCA, Color("6f7472"), Color("9a9d97"), Color("5d625f")]
	var piezas := randi_range(3, 5)
	var con_musgo := randf() < 0.6
	for i in piezas:
		var angulo := TAU * i / piezas + randf_range(-0.4, 0.4)
		var lejos := r * randf_range(0.45, 0.8) if i > 0 else 0.0
		var tamano := r * (1.5 if i == 0 else randf_range(0.7, 1.05))
		var piedra := _malla(nodo, roca, tonos[i % tonos.size()], Vector3(cos(angulo) * lejos, tamano * 0.3, sin(angulo) * lejos))
		piedra.scale = Vector3(tamano * randf_range(0.9, 1.2), tamano * randf_range(1.0, 1.6), tamano * randf_range(0.8, 1.1))
		piedra.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
		if con_musgo and (i == 0 or randf() < 0.35):
			_cubrir_musgo(piedra, i == 0)
	nodo.add_child(_orilla(r * 0.95))
	nodo.set_meta("radio", r)
	return nodo


# Casquete de musgo pegado a la cima de la piedra (en su espacio local, radio 0.5) con matas encima.
func _cubrir_musgo(piedra: MeshInstance3D, matas: bool) -> void:
	if malla_musgo == null:
		malla_musgo = SphereMesh.new()
		malla_musgo.radius = 0.5
		malla_musgo.height = 0.5
		malla_musgo.radial_segments = 10
		malla_musgo.rings = 4
		malla_musgo.is_hemisphere = true
		malla_mata = SphereMesh.new()
		malla_mata.radius = 0.5
		malla_mata.height = 1.0
		malla_mata.radial_segments = 6
		malla_mata.rings = 3
	var verde := COLOR_HIERBA_OSCURA.lerp(COLOR_ROCA, 0.35).darkened(0.1)
	var capa := _malla(piedra, malla_musgo, verde, Vector3(0, 0.33, 0))
	capa.scale = Vector3(0.76, 0.36, 0.76)
	if not matas:
		return
	var verdes: Array[Color] = [verde.lightened(0.12), verde.darkened(0.1), verde.lightened(0.22)]
	for k in randi_range(3, 5):
		var a := randf() * TAU
		var d := randf_range(0.0, 0.22)
		var y := 0.33 + 0.18 * sqrt(maxf(0.0, 1.0 - pow(d / 0.38, 2.0)))
		var mata := _malla(piedra, malla_mata, verdes[k % verdes.size()], Vector3(cos(a) * d, y, sin(a) * d))
		mata.scale = Vector3.ONE * randf_range(0.09, 0.15) * Vector3(1.0, 0.75, 1.0)


# Islas

func _crear_isla(isla: Circulo) -> Node3D:
	var nodo := Node3D.new()
	nodo.position = mundo.a_3d(isla.pos)
	var r := isla.radio * Principal.ESCALA
	var chica := isla.radio < 56.0 * 1.15
	# El relieve central cabe en la parte más estrecha de la isla.
	var r_centro := r * isla.factor_minimo()

	_malla(nodo, _arena(r, isla), COLOR_ARENA, Vector3.ZERO)

	# Cada forma devuelve dónde caben las palmeras: [distancia mínima, máxima, altura del suelo].
	var sitio_palmeras: Array
	var relieve := randf()
	var con_laguna := false
	if relieve < 0.35:
		sitio_palmeras = _relieve_colinas(nodo, r_centro, chica)
	elif relieve < 0.55:
		sitio_palmeras = _relieve_pico(nodo, r_centro)
	elif relieve < 0.7:
		sitio_palmeras = _relieve_atolon(nodo, r_centro)
		con_laguna = true
	elif relieve < 0.85 and not chica:
		sitio_palmeras = _relieve_meseta(nodo, r_centro)
	else:
		sitio_palmeras = _relieve_rocoso(nodo, r_centro)

	var palmeras: Array[Node3D] = []
	for i in (randi_range(1, 2) if chica else randi_range(2, 3)):
		var angulo := randf() * TAU
		var base := Vector3(cos(angulo), 0.0, sin(angulo)) * r_centro * randf_range(sitio_palmeras[0], sitio_palmeras[1])
		palmeras.append(_palmera(nodo, base + Vector3(0, sitio_palmeras[2], 0), _alto_palmera(chica)))
	palmeras.append_array(_poner_lomas(nodo, isla, r, r_centro, chica, con_laguna))
	_poner_rocas_costa(nodo, isla, r, chica)

	nodo.add_child(_orilla(r * 1.15, isla.forma))
	nodo.set_meta("radio", r)
	mundo.fauna.poblar(nodo, r, chica, palmeras, isla)
	return nodo


func _alto_palmera(chica: bool) -> float:
	return randf_range(1.6, 2.2) if chica else randf_range(2.0, 2.8)


# Una loma verde en cada lóbulo alejado del centro, a veces con su palmera.
func _poner_lomas(nodo: Node3D, isla: Circulo, r: float, r_centro: float, chica: bool, con_laguna: bool) -> Array[Node3D]:
	var palmeras: Array[Node3D] = []
	var verdes: Array[Color] = [COLOR_HIERBA, COLOR_HIERBA_OSCURA, COLOR_HIERBA.lerp(COLOR_HOJA, 0.5)]
	for k in isla.lobulos.size():
		var lobulo := isla.lobulos[k]
		var centro_lobulo := Vector2(lobulo.x, lobulo.y) * r
		if centro_lobulo.length() < r * 0.22 or (con_laguna and centro_lobulo.length() < r_centro * 0.8):
			continue
		var loma := SphereMesh.new()
		loma.radius = lobulo.z * r * randf_range(0.5, 0.62)
		loma.height = loma.radius * randf_range(0.5, 0.8)
		loma.is_hemisphere = true
		_malla(nodo, loma, verdes[k % verdes.size()], Vector3(centro_lobulo.x, 0.43, centro_lobulo.y))
		if randf() < 0.65:
			var a := randf() * TAU
			var sitio := centro_lobulo + Vector2(cos(a), sin(a)) * loma.radius * 0.45
			palmeras.append(_palmera(nodo, Vector3(sitio.x, 0.45 + loma.height * 0.35, sitio.y), _alto_palmera(chica)))
	return palmeras


func _poner_rocas_costa(nodo: Node3D, isla: Circulo, r: float, chica: bool) -> void:
	var roca := SphereMesh.new()
	roca.radius = 0.4
	roca.height = 0.6
	roca.radial_segments = 7
	roca.rings = 4
	for i in (2 if chica else 4):
		var angulo := randf() * TAU
		var lejos := r * isla.factor(angulo) * 1.02
		var piedra := _malla(nodo, roca, COLOR_ROCA, Vector3(cos(angulo) * lejos, 0.25, sin(angulo) * lejos))
		piedra.scale = Vector3.ONE * randf_range(0.6, 1.3)


# Arena que sigue la forma de la isla; la orilla baja en talud bajo el agua.
func _arena(r: float, isla: Circulo) -> ArrayMesh:
	var lados := Circulo.MUESTRAS
	var arriba: Array[Vector3] = []
	var abajo: Array[Vector3] = []
	for i in lados:
		var a := TAU * i / lados
		var dir := Vector3(cos(a), 0.0, sin(a))
		var radial := dir * r * isla.factor(a)
		arriba.append(radial + Vector3(0, 0.45, 0))
		abajo.append(radial + dir * r * 0.16 + Vector3(0, -0.35, 0))
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centro := Vector3(0, 0.45, 0)
	for i in lados:
		var j := (i + 1) % lados
		for punto in [centro, arriba[i], arriba[j], arriba[i], abajo[i], abajo[j], arriba[i], abajo[j], arriba[j]]:
			superficie.add_vertex(punto)
	superficie.generate_normals()
	return superficie.commit()


func _orilla(radio_orilla: float, forma := PackedFloat32Array()) -> MeshInstance3D:
	var exterior := radio_orilla * ALCANCE_ORILLA
	var plano := PlaneMesh.new()
	plano.size = Vector2.ONE * exterior * 2.0
	plano.subdivide_width = 14
	plano.subdivide_depth = 14
	var materia := ShaderMaterial.new()
	materia.shader = SHADER_ORILLA
	materia.set_shader_parameter("orilla", 1.0 / ALCANCE_ORILLA)
	if forma.is_empty():
		forma.resize(Circulo.MUESTRAS)
		forma.fill(1.0)
	materia.set_shader_parameter("forma", forma)
	materiales_orilla.append(materia)
	var espuma := MeshInstance3D.new()
	espuma.mesh = plano
	espuma.material_override = materia
	espuma.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return espuma


# Relieves del centro de la isla

func _relieve_colinas(nodo: Node3D, r: float, chica: bool) -> Array:
	var colores: Array[Color] = [COLOR_HIERBA, COLOR_HIERBA_OSCURA, COLOR_HIERBA.lerp(COLOR_HOJA, 0.5)]
	for i in (randi_range(1, 2) if chica else randi_range(2, 3)):
		var colina := SphereMesh.new()
		colina.radius = r * randf_range(0.36, 0.6 if i == 0 else 0.45)
		colina.height = colina.radius * randf_range(0.8, 1.15)
		var lugar := Vector2.from_angle(randf() * TAU) * r * (0.0 if i == 0 else randf_range(0.2, 0.35))
		_malla(nodo, colina, colores[i % colores.size()], Vector3(lugar.x, 0.4, lugar.y))
	return [0.15, 0.45, 0.5]


func _relieve_pico(nodo: Node3D, r: float) -> Array:
	var alto := r * randf_range(0.7, 1.0)
	var monte := CylinderMesh.new()
	monte.top_radius = r * 0.07
	monte.bottom_radius = r * 0.55
	monte.height = alto
	monte.radial_segments = 9
	monte.rings = 1
	var ladera := _malla(nodo, monte, COLOR_HIERBA_OSCURA, Vector3(0, 0.45 + alto / 2.0, 0))
	ladera.rotation.y = randf() * TAU
	var cima := CylinderMesh.new()
	cima.top_radius = r * 0.075
	cima.bottom_radius = r * 0.24
	cima.height = alto * 0.32
	cima.radial_segments = 9
	cima.rings = 1
	_malla(nodo, cima, COLOR_ROCA, Vector3(0, 0.45 + alto * 0.84, 0))
	var falda := SphereMesh.new()
	falda.radius = r * 0.35
	falda.height = r * 0.3
	var lado := Vector2.from_angle(randf() * TAU) * r * 0.35
	_malla(nodo, falda, COLOR_HIERBA, Vector3(lado.x, 0.45, lado.y))
	return [0.55, 0.68, 0.45]


func _relieve_atolon(nodo: Node3D, r: float) -> Array:
	var laguna := CylinderMesh.new()
	laguna.top_radius = r * 0.5
	laguna.bottom_radius = r * 0.5
	laguna.height = 0.02
	laguna.radial_segments = 24
	_malla(nodo, laguna, Color("4cc9c0"), Vector3(0, 0.455, 0))
	var hondo := CylinderMesh.new()
	hondo.top_radius = r * 0.3
	hondo.bottom_radius = r * 0.3
	hondo.height = 0.02
	hondo.radial_segments = 20
	_malla(nodo, hondo, Color("2aa1ad"), Vector3(0.05 * r, 0.46, -0.04 * r))
	var mata := SphereMesh.new()
	mata.radius = r * 0.16
	mata.height = r * 0.12
	mata.is_hemisphere = true
	for i in 4:
		var a := TAU * i / 4.0 + randf_range(-0.4, 0.4)
		_malla(nodo, mata, COLOR_HIERBA, Vector3(cos(a), 0.0, sin(a)) * r * 0.66 + Vector3(0, 0.45, 0))
	return [0.6, 0.74, 0.45]


func _relieve_meseta(nodo: Node3D, r: float) -> Array:
	var risco := CylinderMesh.new()
	risco.top_radius = r * 0.52
	risco.bottom_radius = r * 0.62
	risco.height = 0.5
	risco.radial_segments = 9
	risco.rings = 1
	var pared := _malla(nodo, risco, COLOR_ROCA, Vector3(0, 0.7, 0))
	pared.rotation.y = randf() * TAU
	var pasto := CylinderMesh.new()
	pasto.top_radius = r * 0.46
	pasto.bottom_radius = r * 0.53
	pasto.height = 0.28
	pasto.radial_segments = 9
	pasto.rings = 1
	var cima := _malla(nodo, pasto, COLOR_HIERBA, Vector3(0, 1.09, 0))
	cima.rotation.y = randf() * TAU
	return [0.0, 0.32, 1.2]


func _relieve_rocoso(nodo: Node3D, r: float) -> Array:
	var colina := SphereMesh.new()
	colina.radius = r * 0.5
	colina.height = r * 0.45
	_malla(nodo, colina, COLOR_HIERBA, Vector3(0, 0.4, 0))
	var roca := SphereMesh.new()
	roca.radius = 0.5
	roca.height = 1.0
	roca.radial_segments = 7
	roca.rings = 4
	var lado := randf() * TAU
	var tonos: Array[Color] = [COLOR_ROCA, Color("6f7472"), Color("9a9d97")]
	for i in 3:
		var a := lado + randf_range(-0.5, 0.5)
		var tam := r * randf_range(0.32, 0.5)
		var piedra := _malla(nodo, roca, tonos[i], Vector3(cos(a), 0.0, sin(a)) * r * randf_range(0.2, 0.42) + Vector3(0, 0.45 + tam * 0.3, 0))
		piedra.scale = Vector3(tam, tam * randf_range(1.1, 1.7), tam * randf_range(0.8, 1.1))
		piedra.rotation = Vector3(randf_range(-0.2, 0.2), randf() * TAU, randf_range(-0.2, 0.2))
	return [0.15, 0.4, 0.5]


func _palmera(padre: Node3D, base: Vector3, alto: float) -> Node3D:
	var palmera := Node3D.new()
	palmera.set_meta("alto", alto)
	palmera.position = base
	palmera.rotation = Vector3(randf_range(-0.25, 0.25), randf() * TAU, randf_range(-0.25, 0.25))
	padre.add_child(palmera)
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.07
	tronco.bottom_radius = 0.12
	tronco.height = alto
	tronco.radial_segments = 8
	_malla(palmera, tronco, COLOR_TRONCO, Vector3(0, alto / 2.0, 0))
	var hoja := BoxMesh.new()
	hoja.size = Vector3(0.26, 0.04, 1.2)
	for i in 6:
		var pivote := Node3D.new()
		pivote.position.y = alto
		pivote.rotation.y = TAU * i / 6.0
		palmera.add_child(pivote)
		var pieza := _malla(pivote, hoja, COLOR_HOJA, Vector3(0, -0.15, 0.55))
		pieza.rotation.x = 0.4
	return palmera


func _malla(padre: Node3D, forma: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = forma
	pieza.material_override = mundo.material(color)
	pieza.position = pos
	padre.add_child(pieza)
	return pieza
