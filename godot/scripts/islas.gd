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
const RADIO_PUERTO := 150.0
const ALCANCE_ORILLA := 1.55
const SHADER_ORILLA := preload("res://shaders/orilla.gdshader")
const SHADER_PALMERA := preload("res://shaders/palmera.gdshader")
const SHADER_ALGA := preload("res://shaders/alga.gdshader")
# Islas cuyo bajío deja ver el fondo a la vez (debe coincidir con agua.gdshader).
const BAJIOS := 8
const VARIANTES_ALGA := 5
const COLORES_CORAL: Array[Color] = [Color("ff6f91"), Color("ff9a4d"), Color("b06cff"), Color("ffd24d"), Color("4fd1c5"), Color("ff4f5e"), Color("f2a7d8")]
const COLORES_ESTRELLA: Array[Color] = [Color("ff7a2f"), Color("e8433b"), Color("9b59d0"), Color("f5c542")]
# Copas distintas que se reparten entre todas las palmeras.
const VARIANTES_COPA := 6

const COLOR_ARENA := Paleta.ARENA
const COLOR_HIERBA := Paleta.HIERBA
const COLOR_HIERBA_OSCURA := Paleta.HIERBA_OSCURA
const COLOR_ROCA := Paleta.ROCA
const COLOR_TRONCO := Paleta.TRONCO
const COLOR_HOJA := Paleta.HOJA
const COLOR_COCO := Paleta.COCO

var mundo: Principal
var islotes: Array[Circulo] = []
var materiales_orilla: Array[ShaderMaterial] = []
var malla_musgo: SphereMesh
var malla_mata: SphereMesh
var malla_coco: SphereMesh
var material_tronco: StandardMaterial3D
var material_hojas: ShaderMaterial
var copas: Array[ArrayMesh] = []
var material_fondo: StandardMaterial3D
var material_alga: ShaderMaterial
var algas: Array[ArrayMesh] = []
# Mallas sueltas del fondo: rama, esfera, semiesfera, caja, cono.
var piezas_fondo := {}
var espera_recorte := 0.0
# Solo en el puerto: el muelle y el ángulo de la orilla de donde sale (NAN en partida).
var muelle: Muelle
var angulo_muelle := NAN


func _ready() -> void:
	mundo = get_parent()


# Borra el mar anterior y reparte uno nuevo.
func generar() -> void:
	_vaciar()
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


# El puerto del menú: una sola isla con su muelle, que sale de su orilla oeste, su
# decorado y los acantilados que cierran la bahía.
func generar_puerto() -> void:
	_vaciar()
	var isla := Circulo.new(Vector2.ZERO, RADIO_PUERTO)
	isla.dar_forma()
	var orilla := isla.radio * isla.factor(PI)
	isla.pos = Vector2(Muelle.TIERRA / Principal.ESCALA + orilla, Muelle.LADO / Principal.ESCALA)
	islotes.append(isla)
	angulo_muelle = PI
	var nodo := _crear_isla(isla)
	angulo_muelle = NAN
	add_child(nodo)
	muelle = Muelle.new()
	muelle.position = -nodo.position
	nodo.add_child(muelle)
	muelle.construir(mundo)
	var decorado := Puerto.new()
	nodo.add_child(decorado)
	decorado.construir(mundo, self, isla, isla.radio * Principal.ESCALA)


func _vaciar() -> void:
	for hijo in get_children():
		hijo.queue_free()
	islotes.clear()
	materiales_orilla.clear()
	muelle = null


# Aparta del muelle lo que se reparte por la orilla.
func _lejos_del_muelle(angulo: float) -> float:
	if is_nan(angulo_muelle) or absf(angle_difference(angulo, angulo_muelle)) > 0.7:
		return angulo
	return angulo + PI


# Las islas lejanas no se dibujan (con sus palmeras, animales y sombras).
func recortar(delta: float, foco: Vector3, alcance: float) -> void:
	espera_recorte -= delta
	if espera_recorte > 0.0:
		return
	espera_recorte = 0.2
	var foco_plano := Vector2(foco.x, foco.z)
	var cercanas: Array = []
	for nodo: Node3D in get_children():
		var r: float = nodo.get_meta("radio", 0.0)
		var lejos := Vector2(nodo.position.x, nodo.position.z).distance_to(foco_plano)
		nodo.visible = lejos < alcance + maxf(r * ALCANCE_ORILLA * 1.15, r + alcance_fondo(r))
		if nodo.visible:
			cercanas.append([lejos, nodo])
	cercanas.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	# El agua se aclara sobre el fondo de las islas más cercanas.
	var bajios := PackedVector4Array()
	for k in BAJIOS:
		if k < cercanas.size():
			var nodo: Node3D = cercanas[k][1]
			var r: float = nodo.get_meta("radio")
			bajios.append(Vector4(nodo.position.x, nodo.position.z, r * 0.9, r + alcance_fondo(r) * 0.95))
		else:
			bajios.append(Vector4.ZERO)
	mundo.material_agua.set_shader_parameter("bajios", bajios)


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
	var tonos: Array[Color] = [COLOR_ROCA, Color("7d7068"), Color("b3a596"), Color("685c55")]
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
	_fondo(nodo, r * 0.8, isla, randi_range(5, 9))
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
	var centro_libre := false
	if relieve < 0.35:
		sitio_palmeras = _relieve_colinas(nodo, r_centro, chica)
	elif relieve < 0.55:
		sitio_palmeras = _relieve_pico(nodo, r_centro)
	elif relieve < 0.7:
		sitio_palmeras = _relieve_atolon(nodo, r_centro)
		centro_libre = true
	elif relieve < 0.85 and not chica:
		sitio_palmeras = _relieve_meseta(nodo, r_centro)
	else:
		sitio_palmeras = _relieve_rocoso(nodo, r_centro)

	var palmeras: Array[Node3D] = []
	for i in (randi_range(1, 2) if chica else randi_range(2, 3)):
		var angulo := _lejos_del_muelle(randf() * TAU)
		var base := Vector3(cos(angulo), 0.0, sin(angulo)) * r_centro * randf_range(sitio_palmeras[0], sitio_palmeras[1])
		palmeras.append(_palmera(nodo, base + Vector3(0, sitio_palmeras[2], 0), _alto_palmera(chica)))
	palmeras.append_array(_poner_lomas(nodo, isla, r, r_centro, chica, centro_libre))
	_poner_rocas_costa(nodo, isla, r, chica)

	nodo.add_child(_orilla(r * 1.15, isla.forma))
	_fondo(nodo, r, isla, int(10 + r * 2.5))
	nodo.set_meta("radio", r)
	mundo.fauna.poblar(nodo, r, chica, palmeras, isla, angulo_muelle)
	return nodo


func _alto_palmera(chica: bool) -> float:
	return randf_range(1.6, 2.2) if chica else randf_range(2.0, 2.8)


# Una loma verde en cada lóbulo alejado del centro, a veces con su palmera.
func _poner_lomas(nodo: Node3D, isla: Circulo, r: float, r_centro: float, chica: bool, centro_libre: bool) -> Array[Node3D]:
	var palmeras: Array[Node3D] = []
	var verdes: Array[Color] = [COLOR_HIERBA, COLOR_HIERBA_OSCURA, COLOR_HIERBA.lerp(COLOR_HOJA, 0.5)]
	for k in isla.lobulos.size():
		var lobulo := isla.lobulos[k]
		var centro_lobulo := Vector2(lobulo.x, lobulo.y) * r
		if centro_lobulo.length() < r * 0.22 or (centro_libre and centro_lobulo.length() < r_centro * 0.8):
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
		var angulo := _lejos_del_muelle(randf() * TAU)
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


# Fondo marino

# Metros que se extiende el fondo visible más allá de la orilla.
static func alcance_fondo(r: float) -> float:
	return clampf(r * 1.1, 2.0, 5.0)


# Altura del fondo según lo lejos que esté de la orilla (0 en la orilla, 1 en el borde).
static func hondura_fondo(t: float) -> float:
	return -0.3 - 1.3 * pow(t, 0.8)


# Lecho de arena que baja desde la orilla, con corales, algas, anémonas y estrellas.
func _fondo(nodo: Node3D, r: float, isla: Circulo, cantidad: int) -> void:
	if material_fondo == null:
		_preparar_fondo()
	var ancho := alcance_fondo(r)
	var lados := Circulo.MUESTRAS
	var pasos: Array[float] = [0.1, 0.35, 0.65, 1.0]
	var aros: Array[PackedVector3Array] = []
	var tonos: Array[PackedColorArray] = []
	for t in pasos:
		var aro := PackedVector3Array()
		var colores := PackedColorArray()
		for i in lados:
			var a := TAU * i / lados
			var d := r * isla.factor(a) + ancho * t
			aro.append(Vector3(cos(a) * d, hondura_fondo(t), sin(a) * d))
			colores.append(COLOR_ARENA.lerp(Color("3f8f8c"), 0.2 + 0.45 * t).darkened(randf_range(0.0, 0.1)))
		aros.append(aro)
		tonos.append(colores)
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in pasos.size() - 1:
		for i in lados:
			var j := (i + 1) % lados
			for e in [[k, i], [k + 1, i], [k + 1, j], [k, i], [k + 1, j], [k, j]]:
				superficie.set_color(tonos[e[0]][e[1]])
				superficie.add_vertex(aros[e[0]][e[1]])
	superficie.generate_normals()
	var lecho := MeshInstance3D.new()
	lecho.mesh = superficie.commit()
	lecho.material_override = material_fondo
	lecho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nodo.add_child(lecho)

	for _n in cantidad:
		var a := randf() * TAU
		var t := randf_range(0.18, 0.85)
		var d := r * isla.factor(a) + ancho * t
		var sitio := Vector3(cos(a) * d, hondura_fondo(t), sin(a) * d)
		# Cerca de la orilla hay poca agua: lo que crece ahí es más bajo.
		var tam := clampf(-sitio.y - 0.25, 0.2, 0.9)
		var grupo := Node3D.new()
		grupo.position = sitio
		grupo.rotation.y = randf() * TAU
		grupo.scale = Vector3.ONE * 1.35
		nodo.add_child(grupo)
		var sorteo := randf()
		if sorteo < 0.25:
			_coral_ramas(grupo, tam)
		elif sorteo < 0.4:
			_coral_cerebro(grupo, tam)
		elif sorteo < 0.52:
			_coral_abanico(grupo, tam)
		elif sorteo < 0.75:
			var alga := MeshInstance3D.new()
			alga.mesh = algas.pick_random()
			alga.material_override = material_alga
			alga.scale = Vector3.ONE * (0.6 + tam)
			alga.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			grupo.add_child(alga)
		elif sorteo < 0.87:
			_anemona(grupo)
		else:
			_estrella(grupo)


func _preparar_fondo() -> void:
	material_fondo = StandardMaterial3D.new()
	material_fondo.vertex_color_use_as_albedo = true
	material_fondo.vertex_color_is_srgb = true
	material_fondo.roughness = 0.95
	Texturas.aplicar(material_fondo, "arena")
	material_alga = ShaderMaterial.new()
	material_alga.shader = SHADER_ALGA
	var rama := CylinderMesh.new()
	rama.top_radius = 0.6
	rama.bottom_radius = 1.0
	rama.height = 1.0
	rama.radial_segments = 6
	rama.rings = 1
	var esfera := SphereMesh.new()
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 10
	esfera.rings = 5
	var semiesfera := SphereMesh.new()
	semiesfera.radius = 0.5
	semiesfera.height = 0.5
	semiesfera.radial_segments = 12
	semiesfera.rings = 5
	semiesfera.is_hemisphere = true
	var caja := BoxMesh.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 5
	cono.rings = 1
	piezas_fondo = {"rama": rama, "esfera": esfera, "semiesfera": semiesfera, "caja": caja, "cono": cono}
	for _variante in VARIANTES_ALGA:
		algas.append(_matojo_algas())


func _pieza_fondo(padre: Node3D, malla: String, color: Color, pos: Vector3, escala: Vector3, textura := "general") -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = piezas_fondo[malla]
	pieza.material_override = mundo.material(color, textura)
	pieza.position = pos
	pieza.scale = escala
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(pieza)
	return pieza


# Coral de cuerno: ramas que salen del pie y a veces se bifurcan.
func _coral_ramas(grupo: Node3D, tam: float) -> void:
	var color: Color = COLORES_CORAL.pick_random()
	var talla := maxf(tam, 0.5)
	var grueso := 0.035 * talla
	for k in randi_range(4, 7):
		var largo := randf_range(0.18, 0.38) * talla
		var giro := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.RIGHT, randf_range(0.1, 0.65))
		var punta := giro * Vector3(0, largo, 0)
		var rama := _pieza_fondo(grupo, "rama", color.darkened(0.1 * (k % 2)), punta * 0.5, Vector3.ONE)
		rama.basis = giro * Basis.from_scale(Vector3(grueso, largo, grueso))
		if randf() < 0.6:
			var ramita := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.RIGHT, randf_range(0.4, 0.9))
			var corto := largo * 0.5
			var pieza := _pieza_fondo(grupo, "rama", color.lightened(0.1), punta + ramita * Vector3(0, corto * 0.5, 0), Vector3.ONE)
			pieza.basis = ramita * Basis.from_scale(Vector3(grueso * 0.7, corto, grueso * 0.7))
		_pieza_fondo(grupo, "esfera", color.lightened(0.25), punta, Vector3.ONE * grueso * 1.5)


# Coral cerebro: bola achatada y rugosa.
func _coral_cerebro(grupo: Node3D, tam: float) -> void:
	var color: Color = [Color("e0c45a"), Color("a8c76a"), Color("d98c5f"), Color("c9a3e0")].pick_random()
	var ancho := randf_range(0.25, 0.45) * maxf(tam, 0.5)
	_pieza_fondo(grupo, "semiesfera", color, Vector3.ZERO, Vector3(ancho, ancho * randf_range(0.9, 1.4), ancho * randf_range(0.8, 1.0)), "roca")
	if randf() < 0.5:
		var chico := ancho * 0.55
		_pieza_fondo(grupo, "semiesfera", color.lightened(0.15), Vector3(ancho * 0.55, 0, 0), Vector3(chico, chico * 1.2, chico), "roca")


# Abanico de mar: lámina fina y ancha sobre un tallo corto.
func _coral_abanico(grupo: Node3D, tam: float) -> void:
	var color: Color = [Color("b04ad6"), Color("e8435a"), Color("ff8f3f")].pick_random()
	var alto := randf_range(0.3, 0.5) * maxf(tam, 0.5)
	_pieza_fondo(grupo, "rama", color.darkened(0.3), Vector3(0, alto * 0.15, 0), Vector3(0.03, alto * 0.3, 0.03))
	var lamina := _pieza_fondo(grupo, "esfera", color, Vector3(0, alto * 0.6, 0), Vector3(alto * 1.1, alto, 0.025))
	lamina.rotation.z = randf_range(-0.2, 0.2)


# Anémona: corona de tentáculos alrededor de un pie.
func _anemona(grupo: Node3D) -> void:
	var color: Color = [Color("ff8fb8"), Color("f4f0e8"), Color("8fe0d0"), Color("ffb36b")].pick_random()
	_pieza_fondo(grupo, "rama", color.darkened(0.35), Vector3(0, 0.04, 0), Vector3(0.09, 0.08, 0.09))
	for k in 9:
		var a := TAU * k / 9.0
		var tentaculo := _pieza_fondo(grupo, "cono", color, Vector3(cos(a) * 0.05, 0.13, sin(a) * 0.05), Vector3(0.03, 0.12, 0.03))
		tentaculo.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)


# Estrella de mar: cinco brazos planos.
func _estrella(grupo: Node3D) -> void:
	var color: Color = COLORES_ESTRELLA.pick_random()
	var tam := randf_range(0.8, 1.3)
	for k in 5:
		var brazo := Node3D.new()
		brazo.rotation.y = TAU * k / 5.0
		grupo.add_child(brazo)
		_pieza_fondo(brazo, "esfera", color, Vector3(0, 0.015, 0.06 * tam), Vector3(0.045, 0.025, 0.13) * tam)
	_pieza_fondo(grupo, "esfera", color.lightened(0.15), Vector3(0, 0.02, 0), Vector3(0.07, 0.03, 0.07) * tam)


# Matojo de algas: cintas que salen del suelo; el shader las mece con la corriente.
func _matojo_algas() -> ArrayMesh:
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verdes: Array[Color] = [Color("3f8f4a"), Color("6a9a3a"), Color("8a7a3a"), Color("2f7a5a")]
	var cintas := randi_range(3, 6)
	for c in cintas:
		var pie := Vector3(randf_range(-0.1, 0.1), 0.0, randf_range(-0.1, 0.1))
		var alto := randf_range(0.35, 0.7)
		var ancho := randf_range(0.04, 0.07)
		var giro := randf() * TAU
		var lado := Vector3(cos(giro), 0.0, sin(giro)) * ancho
		var curva := Vector3(randf_range(-0.12, 0.12), 0.0, randf_range(-0.12, 0.12))
		var color: Color = verdes.pick_random()
		var tramos := 5
		for i in tramos:
			var u0 := float(i) / tramos
			var u1 := float(i + 1) / tramos
			var p0 := pie + Vector3(0, alto * u0, 0) + curva * u0 * u0
			var p1 := pie + Vector3(0, alto * u1, 0) + curva * u1 * u1
			var a0 := lado * (1.0 - u0 * 0.6)
			var a1 := lado * (1.0 - u1 * 0.6)
			var esquinas := [[p0 - a0, u0], [p0 + a0, u0], [p1 + a1, u1], [p0 - a0, u0], [p1 + a1, u1], [p1 - a1, u1]]
			for e in esquinas:
				superficie.set_color(color.lerp(color.lightened(0.3), e[1]).srgb_to_linear())
				superficie.set_uv(Vector2(e[1], float(c) / cintas))
				superficie.add_vertex(e[0])
	superficie.generate_normals()
	return superficie.commit()


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
	var tonos: Array[Color] = [COLOR_ROCA, Color("7d7068"), Color("b3a596")]
	for i in 3:
		var a := lado + randf_range(-0.5, 0.5)
		var tam := r * randf_range(0.32, 0.5)
		var piedra := _malla(nodo, roca, tonos[i], Vector3(cos(a), 0.0, sin(a)) * r * randf_range(0.2, 0.42) + Vector3(0, 0.45 + tam * 0.3, 0))
		piedra.scale = Vector3(tam, tam * randf_range(1.1, 1.7), tam * randf_range(0.8, 1.1))
		piedra.rotation = Vector3(randf_range(-0.2, 0.2), randf() * TAU, randf_range(-0.2, 0.2))
	return [0.15, 0.4, 0.5]


# Palmera de tronco curvo y anillado con una copa de hojas que se mecen (shader) y cocos.
# Guarda en metas "alto" e "inclina" la curva del tronco, que siguen los monos al trepar.
func _palmera(padre: Node3D, base: Vector3, alto: float) -> Node3D:
	var palmera := Node3D.new()
	var inclina := Vector2.from_angle(randf() * TAU) * alto * randf_range(0.08, 0.22)
	palmera.set_meta("alto", alto)
	palmera.set_meta("inclina", inclina)
	palmera.position = base
	palmera.rotation.y = randf() * TAU
	padre.add_child(palmera)
	if material_tronco == null:
		_preparar_palmeras()

	var tronco := MeshInstance3D.new()
	tronco.mesh = _tronco(alto, inclina)
	tronco.material_override = material_tronco
	palmera.add_child(tronco)
	var cima := punto_tronco(alto, inclina, 1.0)
	var copa := MeshInstance3D.new()
	copa.mesh = copas.pick_random()
	copa.material_override = material_hojas
	copa.position = cima
	copa.rotation.y = randf() * TAU
	copa.scale = Vector3.ONE * randf_range(0.85, 1.1)
	palmera.add_child(copa)
	for k in randi_range(2, 4):
		var a := TAU * k / 3.0 + randf_range(-0.4, 0.4)
		_malla(palmera, malla_coco, COLOR_COCO, cima + Vector3(cos(a) * 0.08, -0.1, sin(a) * 0.08))
	return palmera


# Centro del tronco a la altura s (0 = pie, 1 = copa); se curva más arriba.
static func punto_tronco(alto: float, inclina: Vector2, s: float) -> Vector3:
	return Vector3(inclina.x * s * s, alto * s, inclina.y * s * s)


func _preparar_palmeras() -> void:
	material_tronco = StandardMaterial3D.new()
	material_tronco.vertex_color_use_as_albedo = true
	material_tronco.vertex_color_is_srgb = true
	material_tronco.roughness = 0.9
	Texturas.aplicar(material_tronco, "madera")
	material_hojas = ShaderMaterial.new()
	material_hojas.shader = SHADER_PALMERA
	malla_coco = SphereMesh.new()
	malla_coco.radius = 0.065
	malla_coco.height = 0.13
	malla_coco.radial_segments = 8
	malla_coco.rings = 4
	for _variante in VARIANTES_COPA:
		copas.append(_copa())


# Tubo que sigue la curva, con anillos que abultan y alternan de tono.
func _tronco(alto: float, inclina: Vector2) -> ArrayMesh:
	var anillos := maxi(8, int(alto / 0.2))
	var lados := 7
	var aros: Array[PackedVector3Array] = []
	var tonos: Array[Color] = []
	for i in anillos + 1:
		var s := float(i) / anillos
		var centro := punto_tronco(alto, inclina, s)
		var radio := lerpf(0.13, 0.075, s) * (1.08 if i % 2 == 0 else 0.96)
		var aro := PackedVector3Array()
		for j in lados:
			var a := TAU * j / lados
			aro.append(centro + Vector3(cos(a), 0.0, sin(a)) * radio)
		aros.append(aro)
		tonos.append(COLOR_TRONCO if i % 2 == 0 else COLOR_TRONCO.darkened(0.25))
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in anillos:
		for j in lados:
			var k := (j + 1) % lados
			var esquinas := [[i + 1, j], [i, j], [i, k], [i + 1, j], [i, k], [i + 1, k]]
			for e: Array in esquinas:
				superficie.set_color(tonos[e[0]])
				superficie.add_vertex(aros[e[0]][e[1]])
	superficie.generate_normals()
	return superficie.commit()


# Copa: hojas largas que salen hacia arriba y se arquean hasta colgar, y unas
# pocas jóvenes más cortas y erguidas en el centro.
func _copa() -> ArrayMesh:
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := COLOR_HOJA.darkened(randf_range(0.15, 0.3))
	var punta := COLOR_HOJA.lightened(randf_range(0.05, 0.2)).lerp(Color("c9c25a"), randf_range(0.0, 0.25))
	var hojas := randi_range(7, 9)
	for k in hojas:
		var giro := TAU * k / hojas + randf_range(-0.25, 0.25)
		_hoja(superficie, giro, randf_range(1.1, 1.5), randf_range(0.3, 0.6), randf_range(1.0, 1.5), base, punta, float(k) / hojas)
	for k in 3:
		_hoja(superficie, randf() * TAU, randf_range(0.5, 0.7), randf_range(1.2, 1.6), randf_range(0.5, 0.8), base, punta, randf())
	return superficie.commit()


# Nervio arqueado con foliolos a cada lado que caen un poco: forma de pluma.
func _hoja(superficie: SurfaceTool, giro: float, largo: float, alza: float, caida: float, base: Color, punta: Color, fase: float) -> void:
	var tramos := 9
	var dir := Vector3(cos(giro), 0.0, sin(giro))
	var lado := Vector3(-dir.z, 0.0, dir.x)
	var nervio: Array[Vector3] = []
	for i in tramos + 1:
		var u := float(i) / tramos
		nervio.append(dir * largo * u + Vector3(0, largo * (alza * u - caida * u * u * 0.6), 0))
	for i in tramos:
		var u_medio := (i + 0.5) / tramos
		var ancho := largo * (0.05 + 0.2 * sin(PI * clampf(u_medio * 1.15, 0.0, 1.0)))
		var medio := (nervio[i] + nervio[i + 1]) * 0.5
		for s: float in [-1.0, 1.0]:
			var foliolo := medio + lado * s * ancho + dir * ancho * 0.4 - Vector3(0, ancho * 0.5, 0)
			var tono := base.lerp(punta, u_medio).darkened(0.08 if (i + int(s > 0.0)) % 2 == 0 else 0.0)
			for v in [[nervio[i], float(i) / tramos], [nervio[i + 1], float(i + 1) / tramos], [foliolo, u_medio]]:
				superficie.set_color(tono.srgb_to_linear())
				superficie.set_normal(Vector3.UP)
				superficie.set_uv(Vector2(v[1], fase))
				superficie.add_vertex(v[0])


func _malla(padre: Node3D, forma: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = forma
	pieza.material_override = mundo.material(color, _textura_de(color))
	pieza.position = pos
	padre.add_child(pieza)
	return pieza


func _textura_de(color: Color) -> String:
	if color == COLOR_ARENA:
		return "arena"
	if color.s < 0.15:
		return "roca"
	if color.h > 0.2 and color.h < 0.45:
		return "hierba"
	return "general"
