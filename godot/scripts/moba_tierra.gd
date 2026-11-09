class_name MobaTierra
extends Node3D

# MOBA de los dioses en tierra firme: 5 contra 5 a pie, en un mapa cuadrado con cinco
# carriles que unen las dos bases. Cada carril tiene dos torres por bando y por él marchan
# los soldados en oleadas. Gana el primero que derriba el nexo enemigo.
# Los dioses, sus figuras y sus poderes salen de Moba.CAPITANES y Moba.HABILIDADES; aquí se
# adaptan a tierra (distancias en metros y vida de 1000 en adelante).
# Coordenadas del suelo en Vector2 (x, z); y es la altura.

const ESCENA_MENU := "res://escenas/principal.tscn"
const MITAD := 72.0
const BASES: Array[Vector2] = [Vector2(-55.0, 55.0), Vector2(55.0, -55.0)]
const FUENTES: Array[Vector2] = [Vector2(-64.0, 64.0), Vector2(64.0, -64.0)]
const RADIO_FUENTE := 9.0
# Cada carril es una curva de una base a otra; este valor la abomba hacia arriba a la izquierda
# (positivo) o hacia abajo a la derecha (negativo). El del medio va recto.
const CURVA_CARRIL: Array[float] = [106.0, 53.0, 0.0, -53.0, -106.0]
const NOMBRES_CARRIL: Array[String] = ["Arriba", "Alta", "Centro", "Baja", "Abajo"]
const PUNTOS_CARRIL := 90
const ANCHO_CAMINO := 5.5
const POR_EQUIPO := 5
const COLORES: Array[Color] = [Color("4fa8ff"), Color("ff5a4f")]
const NOMBRES_EQUIPO: Array[String] = ["Azul", "Rojo"]
# Torres: por dónde del carril van (desde la base propia) y su vida.
const TRAMOS_TORRE: Array[float] = [0.34, 0.17]
const VIDA_TORRE := 1900.0
const VIDA_NEXO := 3600.0
const ALCANCE_TORRE := 10.0
const ALCANCE_NEXO := 12.0
const DANIO_TORRE := 150.0
const RECARGA_TORRE := 1.3
const RADIO_TORRE := 1.7
const RADIO_NEXO := 3.2
# Soldados.
const PRIMERA_OLEADA := 5.0
const ESPERA_OLEADA := 28.0
const SOLDADOS_POR_OLEADA := 3
const VIDA_SOLDADO := 330.0
const VEL_SOLDADO := 3.4
const VISTA_SOLDADO := 7.0
const ESCALA_SOLDADO := 1.7
# Héroes.
const ESCALA_DIOS := 3.0
const ALCANCE_ATAQUE := 7.5
const RECARGA_ATAQUE := 0.85
const DANIO_ATAQUE := 58.0
const DANIO_POR_NIVEL := 7.0
const NIVEL_MAX := 12
const VISTA_BOT := 11.0
const DURACION_REGRESO := 3.0
# Conversión de las medidas del mar (unidades del MOBA naval) a metros y de daño a vida de tierra.
const METROS := 0.04
const VIDA := 10.0
# Cámara.
const CAMARA := Vector3(0.0, 16.0, 11.5)
# Botones táctiles (desde la esquina inferior derecha).
const BOTON_ATAQUE := Vector2(-118.0, -118.0)
const RADIO_ATAQUE := 60.0
const BOTONES_PODER: Array[Vector2] = [Vector2(-262.0, -100.0), Vector2(-226.0, -226.0), Vector2(-100.0, -262.0)]
const RADIO_PODER := 44.0
const BOTON_CURAR := Vector2(-362.0, -150.0)
const BOTON_REGRESO := Vector2(-372.0, -52.0)
const RADIO_PEQUENO := 32.0
const RADIO_PALANCA := 70.0
const TECLAS_PODER: Array[Key] = [KEY_Q, KEY_E, KEY_R, KEY_F]

enum Estado { ELIGIENDO, JUGANDO, FIN }


class Unidad:
	var tipo := ""
	var equipo := 0
	var pos := Vector2.ZERO
	var vida := 100.0
	var vida_max := 100.0
	var radio := 0.7
	var altura := 2.0
	var nodo: Node3D
	var muerto := false
	var nombre := ""


class Heroe extends Unidad:
	var cap: Dictionary
	var figura: FiguraCapitan
	var carril := 2
	var es_jugador := false
	var vel_base := 4.0
	var vida_base := 1000.0
	var mirando := Vector2(0, -1)
	var fase := 0.0
	var andando := 0.0
	var golpe := 0.0
	var espera_ataque := 0.0
	var esperas: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var nivel := 1
	var xp := 0.0
	var mejoras: Array[Dictionary] = []
	var aturdido := 0.0
	var frenado := 0.0
	var quema := 0.0
	var empuje := Vector2.ZERO
	var revivir := 0.0
	var regreso := -1.0
	var asesinatos := 0
	var muertes := 0
	var ultimo_autor: Heroe
	var tiempo_autor := 0.0
	var retirada := false
	var pensar := 0.0
	var destino := Vector2.ZERO
	var objetivo: Unidad
	var aro: MeshInstance3D
	var brillo: MeshInstance3D

	func mejora(clave: String, neutro: float) -> float:
		var total := neutro
		for m in mejoras:
			if m.has(clave):
				total = total * float(m[clave]) if neutro == 1.0 else total + float(m[clave])
		return total

	func invisible() -> bool:
		for m in mejoras:
			if m.get("invisible", false):
				return true
		return false


class Soldado extends Unidad:
	var carril := 0
	var avance := 0.0
	var a_distancia := false
	var espera := 0.0
	var fase := 0.0
	var danio := 22.0
	var cuerpo: Node3D


class Torre extends Unidad:
	var carril := -1
	var orden := 0
	var espera := 0.0
	var cristal: MeshInstance3D


class Proyectil:
	var pos := Vector2.ZERO
	var dir := Vector2.ZERO
	var vel := 24.0
	var queda := 10.0
	var equipo := 0
	var autor: Unidad
	var objetivo: Unidad
	var danio := 50.0
	var efectos := {}
	var nodo: Node3D
	var altura := 1.6


class Zona:
	var pos := Vector2.ZERO
	var radio := 3.0
	var retardo := 0.5
	var dura := 0.0
	var tic := 0.0
	var equipo := 0
	var autor: Heroe
	var spec := {}
	var nodo: MeshInstance3D
	var golpeo := false


class Mina:
	var pos := Vector2.ZERO
	var equipo := 0
	var autor: Heroe
	var armar := 0.6
	var queda := 25.0
	var danio := 280.0
	var nodo: Node3D


var estado := Estado.ELIGIENDO
var carriles: Array[PackedVector2Array] = []
var heroes: Array[Heroe] = []
var soldados: Array[Soldado] = []
var torres: Array[Torre] = []
var nexos: Array[Torre] = [null, null]
var proyectiles: Array[Proyectil] = []
var zonas: Array[Zona] = []
var minas: Array[Mina] = []
var efectos: Array[Dictionary] = []
var arboles: Array[Vector3] = []
var especs := {}
var jugador: Heroe
var elegido := "ares"
var carril_elegido := 2
var espera_oleada := PRIMERA_OLEADA
var oleada := 0
# Carriles en los que cada bando ya perdió su torre interior: el rival manda un gigante por ellos.
var carriles_rotos := [{}, {}]
var ganador := -1
var tiempo_partida := 0.0
var asesinatos_equipo: Array[int] = [0, 0]
var anuncio := ""
var anuncio_color := Color.WHITE
var anuncio_vida := 0.0
var camara: Camera3D
var mira_camara := Vector3.ZERO
var sol: DirectionalLight3D
var musica: AudioStreamPlayer
# Toques: el dedo de la palanca y el del botón de ataque se siguen por su índice.
var dedo_palanca := -1
var centro_palanca := Vector2.ZERO
var punta_palanca := Vector2.ZERO
var dedo_ataque := -1
var atacando_tecla := false
# Interfaz.
var capa: CanvasLayer
var hud: Control
var panel_eleccion: Control
var panel_fin: Control
var boton_salir: Button
var botones_dios := {}
var botones_carril: Array[Button] = []
var texto_dios: Label
var texto_poderes: Label
var figura_vitrina: FiguraCapitan
var mini_carriles: Array[PackedVector2Array] = []
# Mallas y materiales compartidos.
var mat_suelo: StandardMaterial3D
var malla_bola := SphereMesh.new()
var malla_aro := CylinderMesh.new()


func _ready() -> void:
	randomize()
	especs = _crear_especs()
	_crear_mundo()
	_crear_interfaz()
	_abrir_eleccion()


# ---------------------------------------------------------------------------------------
# Mundo: suelo, caminos, río, árboles, bases, torres y nexos.

func _crear_mundo() -> void:
	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("8fc7e8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c8d8e0")
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_light_color = Color("a8d0e0")
	env.fog_density = 0.004
	ambiente.environment = env
	add_child(ambiente)
	sol = DirectionalLight3D.new()
	sol.rotation = Vector3(-0.95, 0.6, 0.0)
	sol.light_energy = 1.05
	add_child(sol)
	camara = Camera3D.new()
	camara.fov = 50.0
	camara.far = 400.0
	add_child(camara)

	malla_bola.radius = 0.25
	malla_bola.height = 0.5
	malla_bola.radial_segments = 8
	malla_bola.rings = 4
	malla_aro.top_radius = 1.0
	malla_aro.bottom_radius = 1.0
	malla_aro.height = 0.06
	malla_aro.radial_segments = 28
	malla_aro.rings = 1

	for k in CURVA_CARRIL.size():
		carriles.append(_trazar_carril(CURVA_CARRIL[k]))

	# Suelo de hierba con un borde de tierra más oscura fuera del mapa.
	mat_suelo = _mat(Color("6aa84f"))
	var borde := MeshInstance3D.new()
	var plano_borde := PlaneMesh.new()
	plano_borde.size = Vector2(MITAD * 6.0, MITAD * 6.0)
	borde.mesh = plano_borde
	borde.material_override = _mat(Color("4f7f3a"))
	borde.position.y = -0.05
	add_child(borde)
	var suelo := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(MITAD * 2.0, MITAD * 2.0)
	suelo.mesh = plano
	suelo.material_override = mat_suelo
	add_child(suelo)
	# Manchas de hierba de otro tono para que el suelo no se vea liso.
	var manchas := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var disco := CylinderMesh.new()
	disco.top_radius = 1.0
	disco.bottom_radius = 1.0
	disco.height = 0.02
	disco.radial_segments = 12
	mm.mesh = disco
	mm.instance_count = 160
	for i in mm.instance_count:
		var p := Vector2(randf_range(-MITAD, MITAD), randf_range(-MITAD, MITAD))
		var t := Transform3D(Basis().scaled(Vector3(randf_range(2.0, 6.0), 1.0, randf_range(2.0, 6.0))), Vector3(p.x, 0.005, p.y))
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, Color("5f9a45") if i % 2 == 0 else Color("78b85a"))
	manchas.multimesh = mm
	var mat_manchas := _mat(Color.WHITE)
	mat_manchas.vertex_color_use_as_albedo = true
	manchas.material_override = mat_manchas
	add_child(manchas)

	# Río en diagonal que cruza todos los carriles por el centro.
	var rio := PackedVector2Array([Vector2(-MITAD, -MITAD), Vector2(MITAD, MITAD)])
	add_child(_cinta(rio, 9.0, 0.012, Color("4aa8c8"), Color("e0d8a8"), 1.2))
	for k in carriles.size():
		add_child(_cinta(carriles[k], ANCHO_CAMINO, 0.025 + k * 0.001, Color("c9a46a"), Color("a8844e"), 0.6))

	_crear_bosque()
	for equipo in 2:
		_crear_base(equipo)
		for carril in carriles.size():
			for orden in TRAMOS_TORRE.size():
				var tramo: float = TRAMOS_TORRE[orden]
				var donde := _punto_carril(carril, tramo if equipo == 0 else 1.0 - tramo)
				# La torre va al lado del camino para no taparlo.
				var lado := (_punto_carril(carril, 0.5) - donde).orthogonal().normalized()
				_crear_torre(equipo, carril, orden, donde + lado * 3.4)


# Curva de Bézier de la base azul a la roja, repartida en puntos a la misma distancia.
func _trazar_carril(curva: float) -> PackedVector2Array:
	var control := Vector2(-curva, -curva) * 0.5
	var finos := PackedVector2Array()
	var total := 0.0
	var largos: Array[float] = [0.0]
	for i in 401:
		var t := i / 400.0
		var p := BASES[0] * (1.0 - t) * (1.0 - t) + control * 2.0 * (1.0 - t) * t + BASES[1] * t * t
		if i > 0:
			total += p.distance_to(finos[i - 1])
			largos.append(total)
		finos.append(p)
	var puntos := PackedVector2Array()
	var j := 0
	for i in PUNTOS_CARRIL:
		var meta := total * i / float(PUNTOS_CARRIL - 1)
		while j < largos.size() - 2 and largos[j + 1] < meta:
			j += 1
		var tramo := (meta - largos[j]) / maxf(0.001, largos[j + 1] - largos[j])
		puntos.append(finos[j].lerp(finos[j + 1], clampf(tramo, 0.0, 1.0)))
	return puntos


func _punto_carril(carril: int, tramo: float) -> Vector2:
	var puntos := carriles[carril]
	var f := clampf(tramo, 0.0, 1.0) * (puntos.size() - 1)
	var i := mini(int(f), puntos.size() - 2)
	return puntos[i].lerp(puntos[i + 1], f - i)


# Cinta plana sobre el suelo siguiendo una línea, con un borde de otro color.
func _cinta(linea: PackedVector2Array, ancho: float, alto: float, color: Color, color_borde: Color, borde: float) -> Node3D:
	var nodo := Node3D.new()
	for capa_cinta in 2:
		var mitad := ancho / 2.0 + (borde if capa_cinta == 0 else 0.0)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_normal(Vector3.UP)
		for i in linea.size() - 1:
			var a := linea[i]
			var b := linea[i + 1]
			var lado_a := _lado(linea, i) * mitad
			var lado_b := _lado(linea, i + 1) * mitad
			var y := alto + capa_cinta * 0.004
			var v := [Vector3(a.x + lado_a.x, y, a.y + lado_a.y), Vector3(a.x - lado_a.x, y, a.y - lado_a.y),
				Vector3(b.x + lado_b.x, y, b.y + lado_b.y), Vector3(b.x - lado_b.x, y, b.y - lado_b.y)]
			for idx: int in [0, 2, 1, 1, 2, 3]:
				st.add_vertex(v[idx])
		var malla := MeshInstance3D.new()
		malla.mesh = st.commit()
		malla.material_override = _mat(color_borde if capa_cinta == 0 else color)
		nodo.add_child(malla)
	return nodo


func _lado(linea: PackedVector2Array, i: int) -> Vector2:
	var a := linea[maxi(0, i - 1)]
	var b := linea[mini(linea.size() - 1, i + 1)]
	return (b - a).normalized().orthogonal()


# Árboles y rocas entre los carriles, puestos en espejo para que las dos bases tengan lo mismo.
func _crear_bosque() -> void:
	var puestos: Array[Vector2] = []
	for _intento in 3000:
		if puestos.size() >= 220:
			break
		var p := Vector2(randf_range(-MITAD + 2.0, MITAD - 2.0), randf_range(-MITAD + 2.0, MITAD - 2.0))
		if p.y > -p.x + 0.5:
			continue
		if _distancia_a_carriles(p) < ANCHO_CAMINO * 0.5 + 2.4 or absf(p.y - p.x) < 7.0:
			continue
		if p.distance_to(BASES[0]) < 18.0 or p.distance_to(BASES[1]) < 18.0:
			continue
		var libre := true
		for otro in puestos:
			if otro.distance_squared_to(p) < 9.0:
				libre = false
				break
		if libre:
			puestos.append(p)
			puestos.append(-p)
	var troncos := MultiMesh.new()
	var copas := MultiMesh.new()
	var rocas := MultiMesh.new()
	for mm in [troncos, copas, rocas]:
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.22
	tronco.bottom_radius = 0.32
	tronco.height = 1.6
	tronco.radial_segments = 6
	troncos.mesh = tronco
	var copa := CylinderMesh.new()
	copa.top_radius = 0.0
	copa.bottom_radius = 1.6
	copa.height = 3.4
	copa.radial_segments = 7
	copas.mesh = copa
	var roca := SphereMesh.new()
	roca.radius = 1.0
	roca.height = 1.4
	roca.radial_segments = 7
	roca.rings = 3
	rocas.mesh = roca
	var n_rocas := 0
	for i in puestos.size():
		if i % 7 == 3:
			n_rocas += 1
	troncos.instance_count = puestos.size() - n_rocas
	copas.instance_count = (puestos.size() - n_rocas) * 2
	rocas.instance_count = n_rocas
	var it := 0
	var ir := 0
	for i in puestos.size():
		var p := puestos[i]
		var s := 0.8 + fmod(absf(p.x * 1.7 + p.y * 3.1), 0.6)
		if i % 7 == 3:
			var b := Basis(Vector3.UP, p.x).scaled(Vector3(s * 1.3, s * 0.8, s))
			rocas.set_instance_transform(ir, Transform3D(b, Vector3(p.x, 0.25 * s, p.y)))
			rocas.set_instance_color(ir, Color("8c8f94").lerp(Color("a8a39a"), fmod(s, 1.0)))
			arboles.append(Vector3(p.x, p.y, 1.2 * s))
			ir += 1
			continue
		troncos.set_instance_transform(it, Transform3D(Basis().scaled(Vector3.ONE * s), Vector3(p.x, 0.8 * s, p.y)))
		troncos.set_instance_color(it, Color("6b4a2a"))
		var verde := Color("2f7a3a").lerp(Color("4f9a3a"), fmod(s * 3.0, 1.0))
		copas.set_instance_transform(it * 2, Transform3D(Basis().scaled(Vector3.ONE * s), Vector3(p.x, 2.6 * s, p.y)))
		copas.set_instance_color(it * 2, verde)
		copas.set_instance_transform(it * 2 + 1, Transform3D(Basis().scaled(Vector3.ONE * s * 0.75), Vector3(p.x, 4.0 * s, p.y)))
		copas.set_instance_color(it * 2 + 1, verde.lightened(0.1))
		arboles.append(Vector3(p.x, p.y, 0.5 * s))
		it += 1
	for mm: MultiMesh in [troncos, copas, rocas]:
		var instancia := MultiMeshInstance3D.new()
		instancia.multimesh = mm
		var m := _mat(Color.WHITE)
		m.vertex_color_use_as_albedo = true
		instancia.material_override = m
		add_child(instancia)


func _distancia_a_carriles(p: Vector2) -> float:
	var mejor := INF
	for puntos in carriles:
		for i in range(0, puntos.size() - 1):
			mejor = minf(mejor, Geometry2D.get_closest_point_to_segment(p, puntos[i], puntos[i + 1]).distance_to(p))
	return mejor


# Punto de aparición: en el borde de la fuente que mira al mapa, no encima de ella.
func _salida(equipo: int) -> Vector2:
	var hacia := (BASES[equipo] - FUENTES[equipo]).normalized()
	return FUENTES[equipo] + hacia.rotated(randf_range(-1.0, 1.0)) * randf_range(4.5, 6.5)


func _crear_base(equipo: int) -> void:
	var color := COLORES[equipo]
	arboles.append(Vector3(FUENTES[equipo].x, FUENTES[equipo].y, 1.8))
	var base := Node3D.new()
	base.position = Vector3(FUENTES[equipo].x, 0, FUENTES[equipo].y)
	add_child(base)
	var losa := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = RADIO_FUENTE + 1.0
	cil.bottom_radius = RADIO_FUENTE + 1.6
	cil.height = 0.4
	cil.radial_segments = 24
	losa.mesh = cil
	losa.material_override = _mat(Color("b8b0a0"))
	losa.position.y = 0.2
	base.add_child(losa)
	var anillo := MeshInstance3D.new()
	anillo.mesh = malla_aro
	anillo.scale = Vector3(RADIO_FUENTE, 1.0, RADIO_FUENTE)
	anillo.position.y = 0.42
	anillo.material_override = _mat_brillo(color, 0.35)
	base.add_child(anillo)
	var fuente := MeshInstance3D.new()
	var copa := CylinderMesh.new()
	copa.top_radius = 1.6
	copa.bottom_radius = 1.1
	copa.height = 1.0
	copa.radial_segments = 12
	fuente.mesh = copa
	fuente.material_override = _mat(Color("d8d0c0"))
	fuente.position.y = 0.9
	base.add_child(fuente)
	var agua := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.7
	bola.height = 1.4
	agua.mesh = bola
	agua.material_override = _mat_brillo(color, 0.9)
	agua.position.y = 2.0
	base.add_child(agua)
	# Nexo.
	var nexo := Torre.new()
	nexo.tipo = "nexo"
	nexo.equipo = equipo
	nexo.pos = BASES[equipo]
	nexo.vida = VIDA_NEXO
	nexo.vida_max = VIDA_NEXO
	nexo.radio = RADIO_NEXO
	nexo.altura = 9.5
	nexo.orden = 2
	nexo.nombre = "Nexo"
	nexo.nodo = Node3D.new()
	nexo.nodo.position = Vector3(nexo.pos.x, 0, nexo.pos.y)
	add_child(nexo.nodo)
	var pie := CylinderMesh.new()
	pie.top_radius = 2.0
	pie.bottom_radius = 3.4
	pie.height = 2.2
	pie.radial_segments = 8
	_pieza(nexo.nodo, pie, Color("d6cfc0"), Vector3(0, 1.1, 0))
	var aguja := CylinderMesh.new()
	aguja.top_radius = 0.0
	aguja.bottom_radius = 1.9
	aguja.height = 4.5
	aguja.radial_segments = 8
	_pieza(nexo.nodo, aguja, Color("e8e0cc"), Vector3(0, 4.4, 0))
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var pilar := CylinderMesh.new()
		pilar.top_radius = 0.3
		pilar.bottom_radius = 0.4
		pilar.height = 3.6
		pilar.radial_segments = 6
		_pieza(nexo.nodo, pilar, Color("c8bfae"), Vector3(cos(a) * 3.0, 1.8, sin(a) * 3.0))
		var punta := SphereMesh.new()
		punta.radius = 0.35
		punta.height = 0.7
		_pieza(nexo.nodo, punta, color, Vector3(cos(a) * 3.0, 3.8, sin(a) * 3.0)).material_override = _mat_brillo(color, 1.0)
	var cristal := MeshInstance3D.new()
	var gema := SphereMesh.new()
	gema.radius = 1.1
	gema.height = 3.0
	gema.radial_segments = 6
	gema.rings = 2
	cristal.mesh = gema
	cristal.material_override = _mat_brillo(color, 1.0)
	cristal.position.y = 8.2
	nexo.nodo.add_child(cristal)
	nexo.cristal = cristal
	nexos[equipo] = nexo
	torres.append(nexo)


func _crear_torre(equipo: int, carril: int, orden: int, donde: Vector2) -> void:
	var color := COLORES[equipo]
	var torre := Torre.new()
	torre.tipo = "torre"
	torre.equipo = equipo
	torre.carril = carril
	torre.orden = orden
	torre.pos = donde
	torre.vida = VIDA_TORRE
	torre.vida_max = VIDA_TORRE
	torre.radio = RADIO_TORRE
	torre.altura = 7.6
	torre.nombre = "Torre"
	torre.nodo = Node3D.new()
	torre.nodo.position = Vector3(donde.x, 0, donde.y)
	add_child(torre.nodo)
	var pie := CylinderMesh.new()
	pie.top_radius = 1.5
	pie.bottom_radius = 1.9
	pie.height = 1.0
	pie.radial_segments = 8
	_pieza(torre.nodo, pie, Color("9a948a"), Vector3(0, 0.5, 0))
	var columna := CylinderMesh.new()
	columna.top_radius = 1.0
	columna.bottom_radius = 1.25
	columna.height = 4.4
	columna.radial_segments = 8
	_pieza(torre.nodo, columna, Color("c8c0b0"), Vector3(0, 3.2, 0))
	var copa := CylinderMesh.new()
	copa.top_radius = 1.7
	copa.bottom_radius = 1.2
	copa.height = 0.9
	copa.radial_segments = 8
	_pieza(torre.nodo, copa, Color("a8a090"), Vector3(0, 5.8, 0))
	var banda := CylinderMesh.new()
	banda.top_radius = 1.27
	banda.bottom_radius = 1.27
	banda.height = 0.35
	banda.radial_segments = 8
	_pieza(torre.nodo, banda, color.darkened(0.2), Vector3(0, 4.6, 0))
	var cristal := MeshInstance3D.new()
	var gema := SphereMesh.new()
	gema.radius = 0.7
	gema.height = 1.8
	gema.radial_segments = 6
	gema.rings = 2
	cristal.mesh = gema
	cristal.material_override = _mat_brillo(color, 1.0)
	cristal.position.y = 7.2
	torre.nodo.add_child(cristal)
	torre.cristal = cristal
	torres.append(torre)


func _pieza(padre: Node3D, malla: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = _mat(color)
	pieza.position = pos
	padre.add_child(pieza)
	return pieza


var _materiales := {}


func _mat(color: Color) -> StandardMaterial3D:
	var clave := "m" + color.to_html()
	if not _materiales.has(clave):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		_materiales[clave] = m
	return _materiales[clave]


func _mat_brillo(color: Color, alfa: float) -> StandardMaterial3D:
	var clave := "b%s%.2f" % [color.to_html(), alfa]
	if not _materiales.has(clave):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(color, alfa)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if alfa < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materiales[clave] = m
	return _materiales[clave]


# Material propio (no compartido) para efectos que se desvanecen.
func _mat_efecto(color: Color, alfa: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color, alfa)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ---------------------------------------------------------------------------------------
# Poderes: cada habilidad del MOBA naval se pasa a tierra con la misma idea y medidas en metros.

func _crear_especs() -> Dictionary:
	var lista := {}
	for clave: String in Moba.HABILIDADES:
		var d: Dictionary = Moba.HABILIDADES[clave]
		var s := {"nombre": d["nombre"], "corto": d["corto"], "espera": d["espera"], "color": d.get("color", Color("ffe08a"))}
		match str(d.get("tipo", "")):
			"pulso":
				s.merge({"forma": "pulso", "radio": d["radio"] * METROS, "danio": d["danio"] * VIDA, "quema": d.get("quema", 0.0),
					"frena": d.get("frena", 0.0), "aturde": d.get("aturde", 0.0), "empuje": d.get("empuje", 0.0) * METROS})
			"impacto":
				s.merge({"forma": "impacto", "alcance": d["alcance"] * METROS, "area": d["area"] * METROS, "retardo": d["retardo"],
					"danio": d["danio"] * VIDA, "quema": d.get("quema", 0.0), "frena": d.get("frena", 0.0), "aturde": d.get("aturde", 0.0), "rayo": d.get("rayo", false)})
			"mejora":
				s.merge({"forma": "mejora", "dura": d["dura"]})
				for k: String in ["vel", "defensa", "regen", "recarga"]:
					if d.has(k):
						s[k] = d[k]
				if d.has("danio"):
					s["mult"] = d["danio"]
			"balas":
				s.merge({"forma": "balas", "alcance": d["alcance"] * METROS, "balas": d["balas"], "abanico": d["abanico"], "mult": d["danio"]})
			_:
				s.merge(_spec_especial(clave))
		lista[clave] = s
	return lista


func _spec_especial(clave: String) -> Dictionary:
	match clave:
		"impulso":
			return {"forma": "mejora", "dura": 3.0, "vel": 1.8, "color": Color("bfe8ff")}
		"andanada":
			return {"forma": "andanada", "balas": 12, "mult": 1.1, "alcance": 9.0, "color": Color("ff8a5c")}
		"escudo":
			return {"forma": "mejora", "dura": 4.0, "defensa": 0.4, "cura": 0.15, "color": Color("ffe08a")}
		"fuego":
			return {"forma": "proyectil", "alcance": 11.0, "danio": 240.0, "quema": 3.0, "color": Color("ffb02a")}
		"cadenas":
			return {"forma": "proyectil", "alcance": 10.0, "danio": 140.0, "frena": 3.5, "quema": 3.5, "color": Color("d9c49a")}
		"reparar":
			return {"forma": "cura", "cura": 0.3, "aliados": 0.2, "radio": 12.0, "color": Color("7dffb2")}
		"remolino":
			return {"forma": "impacto", "alcance": 10.4, "area": 4.8, "retardo": 0.3, "dura": 4.0, "danio": 70.0, "tiron": 3.0, "color": Color("6fd6ff")}
		"kraken":
			return {"forma": "impacto", "alcance": 10.4, "area": 3.8, "retardo": 0.7, "danio": 300.0, "aturde": 1.6, "color": Color("3fe0d0")}
		"minas":
			return {"forma": "minas", "danio": 280.0, "color": Color("ff6a2a")}
		"niebla":
			return {"forma": "mejora", "dura": 4.0, "vel": 1.3, "invisible": true, "color": Color("9aa0b5")}
		"arpon":
			return {"forma": "proyectil", "alcance": 12.0, "danio": 140.0, "tiron": true, "color": Color("dfe6ee")}
		"rayos":
			return {"forma": "rayos", "balas": 3, "alcance": 13.0, "danio": 220.0, "color": Color("ffe24a")}
		"metralla":
			return {"forma": "balas", "alcance": 10.4, "balas": 5, "abanico": 0.5, "mult": 1.0, "color": Color("e0c080")}
		"curar":
			return {"forma": "cura", "cura": 0.25, "aliados": 0.0, "radio": 0.0, "color": Color("7dffb2")}
	return {"forma": "mejora", "dura": 3.0}


func poderes_de(h: Heroe) -> Array[String]:
	var lista := Moba.habilidades_de(h.cap)
	while lista.size() < 4:
		lista.append(Moba.CURAR)
	return lista


func alcance_poder(clave: String) -> float:
	var s: Dictionary = especs[clave]
	match str(s["forma"]):
		"pulso":
			return float(s["radio"]) * 0.85
		"impacto", "proyectil", "balas", "rayos":
			return float(s["alcance"])
		"andanada":
			return 7.0
	return 9.0


func usar_poder(h: Heroe, ranura: int) -> bool:
	if h.muerto or h.aturdido > 0.0 or h.esperas[ranura] > 0.0:
		return false
	var clave := poderes_de(h)[ranura]
	var s: Dictionary = especs[clave]
	var color: Color = s["color"]
	h.esperas[ranura] = float(s["espera"])
	h.golpe = 1.0
	h.regreso = -1.0
	match str(s["forma"]):
		"cura":
			_curar(h, float(s["cura"]))
			var radio: float = s["radio"]
			if radio > 0.0:
				for otro in heroes:
					if otro != h and otro.equipo == h.equipo and not otro.muerto and otro.pos.distance_to(h.pos) <= radio:
						_curar(otro, float(s["aliados"]))
				_onda(h.pos, radio, color)
			else:
				_onda(h.pos, 2.5, color)
		"mejora":
			var m := s.duplicate()
			m["queda"] = float(s["dura"])
			h.mejoras.append(m)
			if s.has("cura"):
				_curar(h, float(s["cura"]))
			_onda(h.pos, 2.6, color)
		"pulso":
			var radio: float = s["radio"]
			for u in _enemigos_cerca(h.equipo, h.pos, radio, true):
				_aplicar(u, s, h, h.pos)
			_onda(h.pos, radio, color)
		"impacto":
			var zona := Zona.new()
			zona.pos = _apuntar_punto(h, float(s["alcance"]))
			zona.radio = s["area"]
			zona.retardo = s["retardo"]
			zona.dura = s.get("dura", 0.0)
			zona.equipo = h.equipo
			zona.autor = h
			zona.spec = s
			zona.nodo = MeshInstance3D.new()
			zona.nodo.mesh = malla_aro
			zona.nodo.material_override = _mat_efecto(color, 0.35)
			zona.nodo.position = Vector3(zona.pos.x, 0.08, zona.pos.y)
			zona.nodo.scale = Vector3(zona.radio, 1.0, zona.radio)
			add_child(zona.nodo)
			zonas.append(zona)
		"proyectil":
			var dir := _apuntar_dir(h, float(s["alcance"]))
			_disparar(h, h.pos + dir, null, float(s["danio"]), s, color, float(s["alcance"]), 20.0, 0.45)
		"balas":
			var dir := _apuntar_dir(h, float(s["alcance"]))
			var n: int = s["balas"]
			var abanico: float = s["abanico"]
			for k in n:
				var giro := 0.0 if n == 1 else lerpf(-abanico / 2.0, abanico / 2.0, k / float(n - 1))
				_disparar(h, h.pos + dir.rotated(giro), null, _danio_ataque(h) * float(s["mult"]), {}, color, float(s["alcance"]), 24.0, 0.3)
		"andanada":
			var n: int = s["balas"]
			for k in n:
				var dir := Vector2.UP.rotated(TAU * k / n)
				_disparar(h, h.pos + dir, null, _danio_ataque(h) * float(s["mult"]), {}, color, float(s["alcance"]), 20.0, 0.3)
		"minas":
			for k in 3:
				var mina := Mina.new()
				mina.pos = h.pos - h.mirando * (1.5 + k * 1.4) + h.mirando.orthogonal() * (k - 1) * 1.2
				mina.equipo = h.equipo
				mina.autor = h
				mina.danio = s["danio"]
				mina.nodo = Node3D.new()
				mina.nodo.position = Vector3(mina.pos.x, 0, mina.pos.y)
				var roca := SphereMesh.new()
				roca.radius = 0.45
				roca.height = 0.7
				_pieza(mina.nodo, roca, Color("3a2a22"), Vector3(0, 0.3, 0))
				var lava := MeshInstance3D.new()
				var brasa := SphereMesh.new()
				brasa.radius = 0.25
				brasa.height = 0.5
				lava.mesh = brasa
				lava.material_override = _mat_brillo(color, 1.0)
				lava.position.y = 0.55
				mina.nodo.add_child(lava)
				add_child(mina.nodo)
				minas.append(mina)
		"rayos":
			var objetivos := _enemigos_cerca(h.equipo, h.pos, float(s["alcance"]), false)
			objetivos.sort_custom(func(a: Unidad, b: Unidad) -> bool: return a.pos.distance_squared_to(h.pos) < b.pos.distance_squared_to(h.pos))
			var n: int = s["balas"]
			for k in mini(n, objetivos.size()):
				var u: Unidad = objetivos[k]
				_rayo(u.pos, color)
				danar(u, float(s["danio"]), h)
	return true


func _aplicar(u: Unidad, s: Dictionary, autor: Heroe, centro: Vector2) -> void:
	danar(u, float(s.get("danio", 0.0)), autor)
	if u.muerto or not (u is Heroe or u is Soldado):
		return
	var empuje: float = s.get("empuje", 0.0)
	if empuje != 0.0:
		var dir := (u.pos - centro).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		if u is Heroe:
			(u as Heroe).empuje += dir * empuje * 4.0
		else:
			u.pos += dir * empuje * 0.6
	if u is Heroe:
		var h := u as Heroe
		h.quema = maxf(h.quema, float(s.get("quema", 0.0)))
		h.frenado = maxf(h.frenado, float(s.get("frena", 0.0)))
		h.aturdido = maxf(h.aturdido, float(s.get("aturde", 0.0)))
		if s.get("tiron", false) is bool and s.get("tiron", false) and autor != null:
			h.empuje += (autor.pos - h.pos).normalized() * minf(h.pos.distance_to(autor.pos) - 1.5, 9.0) * 5.0


func _curar(h: Heroe, parte: float) -> void:
	if h.muerto:
		return
	h.vida = minf(h.vida_max, h.vida + h.vida_max * parte)


# Para dónde apunta un poder: al héroe enemigo visible más cercano dentro del alcance; si no hay,
# a cualquier enemigo; si tampoco, hacia delante.
func _apuntar_objetivo(h: Heroe, alcance: float) -> Unidad:
	var mejor: Unidad
	var mejor_d := INF
	for u in _enemigos_cerca(h.equipo, h.pos, alcance + 1.0, false):
		var d := u.pos.distance_to(h.pos) - (100.0 if u is Heroe else 0.0)
		if d < mejor_d:
			mejor_d = d
			mejor = u
	return mejor


func _apuntar_punto(h: Heroe, alcance: float) -> Vector2:
	var u := _apuntar_objetivo(h, alcance)
	if u != null:
		return u.pos
	return h.pos + h.mirando * alcance * 0.7


func _apuntar_dir(h: Heroe, alcance: float) -> Vector2:
	var u := _apuntar_objetivo(h, alcance)
	if u != null:
		var d := (u.pos - h.pos).normalized()
		if d != Vector2.ZERO:
			h.mirando = d
			return d
	return h.mirando


func _enemigos_cerca(equipo: int, centro: Vector2, radio: float, con_edificios: bool) -> Array[Unidad]:
	var lista: Array[Unidad] = []
	for h in heroes:
		if h.equipo != equipo and not h.muerto and h.pos.distance_to(centro) <= radio + h.radio and (not h.invisible() or h.pos.distance_to(centro) < 2.5):
			lista.append(h)
	for s in soldados:
		if s.equipo != equipo and not s.muerto and s.pos.distance_to(centro) <= radio + s.radio:
			lista.append(s)
	if con_edificios:
		for t in torres:
			if t.equipo != equipo and not t.muerto and t.pos.distance_to(centro) <= radio + t.radio:
				lista.append(t)
	return lista


# ---------------------------------------------------------------------------------------
# Daño, muertes, experiencia.

func protegida(t: Torre) -> bool:
	if t.orden == 0:
		return false
	if t.orden == 1:
		for otra in torres:
			if otra.equipo == t.equipo and otra.carril == t.carril and otra.orden == 0 and not otra.muerto:
				return true
		return false
	for otra in torres:
		if otra.equipo == t.equipo and otra.orden == 1 and otra.muerto:
			return false
	return true


func danar(u: Unidad, cantidad: float, autor: Unidad) -> void:
	if u.muerto or cantidad <= 0.0:
		return
	if u is Torre:
		if protegida(u as Torre):
			if autor == jugador:
				_anunciar(tr("Protegida: derriba antes la torre de delante"), Color("ffd27a"), 1.2)
			return
	var mult := 1.0
	if u is Heroe:
		var h := u as Heroe
		mult = h.mejora("defensa", 1.0)
		if autor is Soldado or autor is Torre:
			mult *= 0.6 if autor is Soldado else 1.0
		if autor is Heroe:
			h.ultimo_autor = autor as Heroe
			h.tiempo_autor = 8.0
	elif u is Soldado and autor is Heroe:
		mult = 1.4
	elif u is Torre and autor is Soldado:
		mult = 1.8
	u.vida -= cantidad * mult
	if u.vida <= 0.0:
		_morir(u, autor)


func _morir(u: Unidad, autor: Unidad) -> void:
	u.vida = 0.0
	u.muerto = true
	var enemigo := 1 - u.equipo
	if u is Soldado:
		u.nodo.queue_free()
		_xp_cerca(enemigo, u.pos, 40.0)
	elif u is Heroe:
		var h := u as Heroe
		h.muertes += 1
		h.revivir = 4.0 + h.nivel * 1.2
		h.figura.visible = false
		h.aro.visible = false
		h.brillo.visible = false
		h.mejoras.clear()
		h.regreso = -1.0
		asesinatos_equipo[enemigo] += 1
		var asesino: Heroe = autor as Heroe if autor is Heroe else (h.ultimo_autor if h.tiempo_autor > 0.0 else null)
		_onda(h.pos, 3.0, COLORES[h.equipo])
		if asesino != null:
			asesino.asesinatos += 1
			_sumar_xp(asesino, 160.0)
			_anunciar(tr("%s derrotó a %s") % [tr(asesino.nombre), tr(h.nombre)], COLORES[asesino.equipo], 2.5)
		else:
			_anunciar(tr("%s cayó") % tr(h.nombre), COLORES[enemigo], 2.0)
		_xp_cerca(enemigo, h.pos, 60.0)
	elif u is Torre:
		var t := u as Torre
		t.cristal.visible = false
		t.nodo.position.y = -1.6 if t.tipo == "torre" else -3.0
		t.nodo.scale = Vector3(1.0, 0.7, 1.0)
		_onda(t.pos, 6.0, Color("ffb347"))
		for h in heroes:
			if h.equipo == enemigo:
				_sumar_xp(h, 80.0)
		if t.tipo == "nexo":
			_terminar(enemigo)
		else:
			if t.orden == 1:
				carriles_rotos[t.equipo][t.carril] = true
			var de := tr("Torre azul derribada") if t.equipo == 0 else tr("Torre roja derribada")
			_anunciar(de + " (" + tr(NOMBRES_CARRIL[t.carril]) + ")", COLORES[enemigo], 2.5)


func _xp_cerca(equipo: int, centro: Vector2, total: float) -> void:
	var cerca: Array[Heroe] = []
	for h in heroes:
		if h.equipo == equipo and not h.muerto and h.pos.distance_to(centro) < 15.0:
			cerca.append(h)
	for h in cerca:
		_sumar_xp(h, total / cerca.size() * (1.0 + 0.25 * (cerca.size() - 1)))


func _xp_para(nivel: int) -> float:
	return 90.0 + 50.0 * nivel


func _sumar_xp(h: Heroe, cantidad: float) -> void:
	if h.nivel >= NIVEL_MAX:
		return
	h.xp += cantidad
	while h.xp >= _xp_para(h.nivel) and h.nivel < NIVEL_MAX:
		h.xp -= _xp_para(h.nivel)
		h.nivel += 1
		var antes := h.vida_max
		h.vida_max = h.vida_base * (1.0 + 0.09 * (h.nivel - 1))
		h.vida += h.vida_max - antes
		if h == jugador:
			_anunciar(tr("¡Nivel %d!") % h.nivel, Color("ffe08a"), 1.5)
			_onda(h.pos, 2.0, Color("ffe08a"))


func _danio_ataque(h: Heroe) -> float:
	return (DANIO_ATAQUE + DANIO_POR_NIVEL * (h.nivel - 1)) * h.mejora("mult", 1.0)


# ---------------------------------------------------------------------------------------
# Partida: dioses, oleadas y bucle principal.

func _empezar() -> void:
	estado = Estado.JUGANDO
	panel_eleccion.visible = false
	if figura_vitrina != null:
		figura_vitrina.queue_free()
		figura_vitrina = null
	boton_salir.visible = true
	hud.visible = true
	var libres := Moba.CAPITANES.duplicate()
	var mio := Moba.CAPITANES[0]
	for cap: Dictionary in Moba.CAPITANES:
		if cap["id"] == elegido:
			mio = cap
	libres.erase(mio)
	libres.shuffle()
	for equipo in 2:
		var carriles_libres: Array[int] = [0, 1, 2, 3, 4]
		if equipo == 0:
			carriles_libres.erase(carril_elegido)
			jugador = _crear_heroe(mio, 0, carril_elegido, true)
		for k in carriles_libres.size():
			_crear_heroe(libres.pop_back(), equipo, carriles_libres[k], false)
	mira_camara = Vector3(jugador.pos.x, 0, jugador.pos.y)
	_anunciar(tr("¡Derriba el nexo enemigo!"), Color("ffe08a"), 3.0)
	musica = AudioStreamPlayer.new()
	var pista := load("res://musica/batalla.wav") as AudioStream
	if pista != null:
		musica.stream = pista
		musica.volume_db = -12.0
		musica.finished.connect(musica.play)
		add_child(musica)
		musica.play()


func _crear_heroe(cap: Dictionary, equipo: int, carril: int, es_jugador: bool) -> Heroe:
	var h := Heroe.new()
	h.tipo = "heroe"
	h.cap = cap
	h.equipo = equipo
	h.carril = carril
	h.es_jugador = es_jugador
	h.nombre = cap["nombre"]
	h.vida_base = float(cap["vida"]) * VIDA
	h.vida_max = h.vida_base
	h.vida = h.vida_max
	h.vel_base = float(cap["velocidad"]) * 0.105
	h.altura = 4.4
	h.pos = _salida(equipo)
	h.mirando = (BASES[1 - equipo] - BASES[equipo]).normalized()
	h.nodo = Node3D.new()
	add_child(h.nodo)
	h.figura = FiguraCapitan.crear(cap["figura"])
	h.figura.scale = Vector3.ONE * ESCALA_DIOS
	h.figura.set_process(false)
	h.nodo.add_child(h.figura)
	h.aro = MeshInstance3D.new()
	h.aro.mesh = malla_aro
	h.aro.scale = Vector3(1.1, 1.0, 1.1)
	h.aro.position.y = 0.05
	h.aro.material_override = _mat_brillo(Color.WHITE if es_jugador else COLORES[equipo], 0.55)
	h.nodo.add_child(h.aro)
	h.brillo = MeshInstance3D.new()
	h.brillo.mesh = malla_aro
	h.brillo.scale = Vector3(1.6, 1.0, 1.6)
	h.brillo.position.y = 0.07
	h.brillo.visible = false
	h.nodo.add_child(h.brillo)
	heroes.append(h)
	return h


func _lanzar_oleada() -> void:
	oleada += 1
	for equipo in 2:
		for carril in carriles.size():
			for k in SOLDADOS_POR_OLEADA:
				_crear_soldado(equipo, carril, k, k == SOLDADOS_POR_OLEADA - 1)
			if carriles_rotos[1 - equipo].has(carril):
				var gigante := _crear_soldado(equipo, carril, SOLDADOS_POR_OLEADA, false)
				gigante.vida_max *= 3.0
				gigante.vida = gigante.vida_max
				gigante.danio *= 2.5
				gigante.radio = 0.9
				gigante.altura = 4.6
				gigante.cuerpo.scale = Vector3.ONE * ESCALA_SOLDADO * 1.7


func _crear_soldado(equipo: int, carril: int, k: int, a_distancia: bool) -> Soldado:
	var s := Soldado.new()
	s.tipo = "soldado"
	s.equipo = equipo
	s.carril = carril
	s.a_distancia = a_distancia
	s.vida_max = VIDA_SOLDADO * (1.0 + 0.06 * (oleada - 1))
	s.vida = s.vida_max
	s.danio = (16.0 if a_distancia else 24.0) * (1.0 + 0.06 * (oleada - 1))
	s.radio = 0.55
	s.altura = 2.9
	s.avance = 0.035 - k * 0.012
	if equipo == 1:
		s.avance = 1.0 - s.avance
	s.pos = _punto_carril(carril, s.avance) + Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6))
	s.fase = randf() * TAU
	s.nodo = Node3D.new()
	s.nodo.position = Vector3(s.pos.x, 0, s.pos.y)
	add_child(s.nodo)
	s.cuerpo = Node3D.new()
	s.cuerpo.scale = Vector3.ONE * ESCALA_SOLDADO
	s.nodo.add_child(s.cuerpo)
	var color := COLORES[equipo]
	var tronco := CapsuleMesh.new()
	tronco.radius = 0.26
	tronco.height = 0.95
	tronco.radial_segments = 8
	tronco.rings = 2
	_pieza(s.cuerpo, tronco, color.darkened(0.15), Vector3(0, 0.75, 0))
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.2
	cabeza.height = 0.4
	cabeza.radial_segments = 8
	cabeza.rings = 4
	_pieza(s.cuerpo, cabeza, Color("e0b090"), Vector3(0, 1.38, 0))
	var yelmo := SphereMesh.new()
	yelmo.radius = 0.22
	yelmo.height = 0.3
	yelmo.radial_segments = 8
	yelmo.rings = 3
	_pieza(s.cuerpo, yelmo, Color("c8c0b0") if not a_distancia else color, Vector3(0, 1.48, 0.02))
	if a_distancia:
		var vara := CylinderMesh.new()
		vara.top_radius = 0.03
		vara.bottom_radius = 0.03
		vara.height = 1.3
		_pieza(s.cuerpo, vara, Color("6b4a2a"), Vector3(0.32, 0.9, -0.1))
		_pieza(s.cuerpo, malla_bola, color, Vector3(0.32, 1.6, -0.1)).material_override = _mat_brillo(color, 1.0)
	else:
		var lanza := CylinderMesh.new()
		lanza.top_radius = 0.025
		lanza.bottom_radius = 0.025
		lanza.height = 1.6
		_pieza(s.cuerpo, lanza, Color("6b4a2a"), Vector3(0.3, 1.0, -0.2)).rotation.x = -0.4
		var escudo := CylinderMesh.new()
		escudo.top_radius = 0.32
		escudo.bottom_radius = 0.32
		escudo.height = 0.05
		_pieza(s.cuerpo, escudo, color, Vector3(-0.3, 0.85, -0.05)).rotation.z = PI / 2.0
	soldados.append(s)
	return s


func _process(delta: float) -> void:
	match estado:
		Estado.ELIGIENDO:
			_vitrina(delta)
		Estado.JUGANDO:
			_jugar(minf(delta, 0.05))
		Estado.FIN:
			for h in heroes:
				if not h.muerto:
					h.figura.posar(h.equipo == ganador)
	anuncio_vida -= delta
	hud.queue_redraw()


func _jugar(delta: float) -> void:
	tiempo_partida += delta
	espera_oleada -= delta
	if espera_oleada <= 0.0:
		espera_oleada = ESPERA_OLEADA
		_lanzar_oleada()
	_mover_jugador(delta)
	for h in heroes:
		_actualizar_heroe(h, delta)
	for s in soldados:
		_actualizar_soldado(s, delta)
	soldados = soldados.filter(func(s: Soldado) -> bool: return not s.muerto)
	_separar_soldados()
	for t in torres:
		_actualizar_torre(t, delta)
	_actualizar_proyectiles(delta)
	_actualizar_zonas(delta)
	_actualizar_minas(delta)
	_actualizar_efectos(delta)
	_mover_camara(delta)


func _mover_jugador(_delta: float) -> void:
	if jugador.muerto or not jugador.es_jugador:
		return
	var mover := Vector2.ZERO
	if dedo_palanca >= 0:
		var d := punta_palanca - centro_palanca
		mover = d / RADIO_PALANCA
		if mover.length() > 1.0:
			mover = mover.normalized()
		if d.length() < 8.0:
			mover = Vector2.ZERO
	var teclado := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	for par: Array in [[KEY_A, Vector2.LEFT], [KEY_D, Vector2.RIGHT], [KEY_W, Vector2.UP], [KEY_S, Vector2.DOWN]]:
		if Input.is_physical_key_pressed(par[0]):
			teclado += par[1]
	if teclado != Vector2.ZERO:
		mover = teclado.normalized()
	jugador.destino = mover
	if (dedo_ataque >= 0 or atacando_tecla) and jugador.espera_ataque <= 0.0:
		var u := _objetivo_ataque(jugador)
		if u != null:
			_atacar(jugador, u)


# El objetivo del ataque normal: el héroe enemigo más cercano en alcance; si no, el soldado
# más cercano; si no, la torre o el nexo que se pueda dañar.
func _objetivo_ataque(h: Heroe) -> Unidad:
	var mejor: Unidad
	var mejor_d := INF
	for u in _enemigos_cerca(h.equipo, h.pos, ALCANCE_ATAQUE, true):
		if u is Torre and protegida(u as Torre):
			continue
		var d := u.pos.distance_to(h.pos) - u.radio
		if u is Heroe:
			d -= 30.0
		elif u is Torre:
			d += 30.0
		if d < mejor_d:
			mejor_d = d
			mejor = u
	return mejor


func _atacar(h: Heroe, u: Unidad) -> void:
	h.espera_ataque = RECARGA_ATAQUE * h.mejora("recarga", 1.0)
	h.golpe = 1.0
	h.regreso = -1.0
	var d := (u.pos - h.pos).normalized()
	if d != Vector2.ZERO:
		h.mirando = d
	var color := Color(h.cap["figura"].get("aura", "ffe08a"))
	_disparar(h, u.pos, u, _danio_ataque(h), {}, color, ALCANCE_ATAQUE + 4.0, 26.0, 0.32)


func _actualizar_heroe(h: Heroe, delta: float) -> void:
	if h.muerto:
		h.revivir -= delta
		if h.revivir <= 0.0:
			h.muerto = false
			h.vida = h.vida_max
			h.pos = _salida(h.equipo)
			h.figura.visible = true
			h.aro.visible = true
			h.retirada = false
			h.aturdido = 0.0
			h.frenado = 0.0
			h.quema = 0.0
			h.empuje = Vector2.ZERO
			if h == jugador:
				_anunciar(tr("¡De vuelta a la batalla!"), Color("ffe08a"), 1.5)
		return
	h.espera_ataque -= delta
	for k in 4:
		h.esperas[k] = maxf(0.0, h.esperas[k] - delta)
	h.tiempo_autor -= delta
	h.golpe = maxf(0.0, h.golpe - delta * 3.0)
	for m in h.mejoras:
		m["queda"] = float(m["queda"]) - delta
	h.mejoras = h.mejoras.filter(func(m: Dictionary) -> bool: return float(m["queda"]) > 0.0)
	if h.quema > 0.0:
		h.quema -= delta
		danar(h, 35.0 * delta, h.ultimo_autor)
		if h.muerto:
			return
	var regen := h.mejora("regen", 0.0)
	if regen > 0.0:
		h.vida = minf(h.vida_max, h.vida + h.vida_max * regen * delta)
	h.vida = minf(h.vida_max, h.vida + h.vida_max * 0.004 * delta)
	if h.pos.distance_to(FUENTES[h.equipo]) < RADIO_FUENTE:
		h.vida = minf(h.vida_max, h.vida + h.vida_max * 0.15 * delta)
	if h.pos.distance_to(FUENTES[1 - h.equipo]) < RADIO_FUENTE:
		danar(h, 400.0 * delta, nexos[1 - h.equipo])
		if h.muerto:
			return
	if not h.es_jugador:
		_pensar_bot(h, delta)
	# Regreso a la base: quieto unos segundos y aparece en la fuente.
	if h.regreso >= 0.0:
		h.regreso += delta
		if h.destino.length() > 0.1:
			h.regreso = -1.0
		elif h.regreso >= DURACION_REGRESO:
			h.regreso = -1.0
			h.pos = _salida(h.equipo)
			_onda(h.pos, 2.5, COLORES[h.equipo])
	var vel := h.vel_base * h.mejora("vel", 1.0) * (0.55 if h.frenado > 0.0 else 1.0)
	h.frenado = maxf(0.0, h.frenado - delta)
	var mover := h.destino
	if h.aturdido > 0.0:
		h.aturdido -= delta
		mover = Vector2.ZERO
	var paso := mover * vel * delta + h.empuje * delta
	h.empuje = h.empuje.move_toward(Vector2.ZERO, delta * 30.0)
	h.pos = _deslizar(h.pos, paso, h.radio)
	if mover.length() > 0.05:
		h.mirando = h.mirando.slerp(mover.normalized(), minf(1.0, delta * 12.0))
	h.andando = move_toward(h.andando, minf(1.0, mover.length()), delta * 6.0)
	h.fase += delta * vel * 2.2 * h.andando
	h.nodo.position = Vector3(h.pos.x, 0, h.pos.y)
	h.nodo.rotation.y = atan2(-h.mirando.x, -h.mirando.y)
	h.figura.andar(h.fase, h.andando, h.golpe)
	var invisible := h.invisible()
	h.figura.visible = not (invisible and h.equipo != jugador.equipo)
	h.aro.visible = h.figura.visible
	if h.mejoras.is_empty() and h.aturdido <= 0.0:
		h.brillo.visible = false
	else:
		h.brillo.visible = h.figura.visible
		var color: Color = Color("ffe24a") if h.aturdido > 0.0 else h.mejoras[-1].get("color", Color.WHITE)
		h.brillo.material_override = _mat_brillo(color, 0.5)


# Mueve rodeando obstáculos: si de frente casi no avanza, prueba girando el paso a los lados.
func _deslizar(desde: Vector2, paso: Vector2, radio: float) -> Vector2:
	var largo := paso.length()
	var directo := _mover_libre(desde + paso, radio)
	if largo < 0.0001 or (directo - desde).dot(paso) > largo * largo * 0.4:
		return directo
	var mejor := directo
	var mejor_avance := (directo - desde).dot(paso)
	for giro: float in [0.7, -0.7, 1.3, -1.3]:
		var prueba := _mover_libre(desde + paso.rotated(giro), radio)
		var avance := (prueba - desde).dot(paso) + 0.0001 * giro
		if avance > mejor_avance:
			mejor_avance = avance
			mejor = prueba
	return mejor


# Mantiene a una unidad dentro del mapa y fuera de árboles, rocas, torres y nexos.
func _mover_libre(p: Vector2, radio: float) -> Vector2:
	p.x = clampf(p.x, -MITAD + 1.0, MITAD - 1.0)
	p.y = clampf(p.y, -MITAD + 1.0, MITAD - 1.0)
	for a in arboles:
		var c := Vector2(a.x, a.y)
		var minimo := a.z + radio
		var d := p.distance_squared_to(c)
		if d < minimo * minimo:
			p = c + (p - c).normalized() * minimo
	for t in torres:
		if t.muerto:
			continue
		var minimo := t.radio + radio
		if p.distance_squared_to(t.pos) < minimo * minimo:
			p = t.pos + (p - t.pos).normalized() * minimo
	return p


# Bots: siguen su carril detrás de sus soldados, pelean lo que tienen cerca, no se meten solos
# bajo una torre enemiga y se retiran a curarse cuando van mal de vida.
func _pensar_bot(h: Heroe, delta: float) -> void:
	h.pensar -= delta
	if h.pensar > 0.0:
		return
	h.pensar = randf_range(0.18, 0.3)
	var poderes := poderes_de(h)
	if h.vida < h.vida_max * 0.28:
		h.retirada = true
	if h.retirada:
		if h.vida >= h.vida_max * 0.92:
			h.retirada = false
		if h.esperas[3] <= 0.0 and h.vida < h.vida_max * 0.6:
			usar_poder(h, 3)
		var hacia_casa := FUENTES[h.equipo] - h.pos
		if hacia_casa.length() > 30.0 and _enemigos_cerca(h.equipo, h.pos, 12.0, false).is_empty():
			if h.regreso < 0.0:
				h.regreso = 0.0
			h.destino = Vector2.ZERO
			return
		h.destino = hacia_casa.normalized() if hacia_casa.length() > 4.5 else Vector2.ZERO
		return
	if h.regreso >= 0.0:
		h.destino = Vector2.ZERO
		return
	if h.esperas[3] <= 0.0 and h.vida < h.vida_max * 0.5:
		usar_poder(h, 3)
	# Poderes contra el héroe enemigo cercano.
	var rival: Heroe
	var rival_d := INF
	for otro in heroes:
		if otro.equipo != h.equipo and not otro.muerto and not otro.invisible():
			var d := otro.pos.distance_to(h.pos)
			if d < rival_d:
				rival_d = d
				rival = otro
	if rival != null and rival_d < 11.0:
		for ranura in 3:
			if h.esperas[ranura] > 0.0 or randf() < 0.35:
				continue
			var clave := poderes[ranura]
			var s: Dictionary = especs[clave]
			var forma: String = s["forma"]
			if forma == "mejora" or forma == "cura":
				if rival_d < 9.0 and not (forma == "cura" and h.vida > h.vida_max * 0.8):
					usar_poder(h, ranura)
					break
			elif forma == "minas":
				if rival_d < 5.0:
					usar_poder(h, ranura)
					break
			elif rival_d <= alcance_poder(clave):
				h.mirando = (rival.pos - h.pos).normalized()
				usar_poder(h, ranura)
				break
	# Objetivo para el ataque normal.
	var objetivo: Unidad
	var objetivo_d := INF
	for u in _enemigos_cerca(h.equipo, h.pos, VISTA_BOT, true):
		if u is Torre:
			if protegida(u as Torre) or not (_hay_soldados_cerca(h.equipo, u.pos, ALCANCE_NEXO) or _asedio(h)):
				continue
		var d := u.pos.distance_to(h.pos)
		if u is Heroe:
			d -= 4.0 + (1.0 - u.vida / u.vida_max) * 5.0
		if d < objetivo_d:
			objetivo_d = d
			objetivo = u
	var frente := _frente_carril(h)
	if objetivo != null:
		var lejos := objetivo.pos.distance_to(h.pos)
		var deseo := ALCANCE_ATAQUE * 0.8
		if objetivo is Heroe and h.vida < objetivo.vida * 0.6:
			deseo = ALCANCE_ATAQUE * 0.95
		var dir := (objetivo.pos - h.pos).normalized()
		if lejos > deseo:
			h.destino = dir
		elif lejos < deseo * 0.6:
			h.destino = -dir * 0.6
		else:
			h.destino = dir.orthogonal() * (0.4 if int(tiempo_partida / 2.0) % 2 == 0 else -0.4)
		if not _asedio(h) and _bajo_torre_enemiga(h.pos + h.destino * 2.0, h.equipo):
			h.destino = (frente - h.pos).normalized()
		if lejos <= ALCANCE_ATAQUE and h.espera_ataque <= 0.0:
			_atacar(h, objetivo)
		return
	var hacia := frente - h.pos
	h.destino = hacia.normalized() if hacia.length() > 2.0 else Vector2.ZERO


# Un bot sano y sin dioses enemigos cerca se atreve a atacar torres y nexo sin soldados.
func _asedio(h: Heroe) -> bool:
	if h.vida < h.vida_max * 0.65:
		return false
	for otro in heroes:
		if otro.equipo != h.equipo and not otro.muerto and otro.pos.distance_to(h.pos) < 14.0:
			return false
	return true


func _hay_soldados_cerca(equipo: int, centro: Vector2, radio: float) -> bool:
	for s in soldados:
		if s.equipo == equipo and not s.muerto and s.pos.distance_to(centro) < radio:
			return true
	return false


func _bajo_torre_enemiga(p: Vector2, equipo: int) -> bool:
	for t in torres:
		if t.equipo != equipo and not t.muerto:
			var alcance := ALCANCE_NEXO if t.tipo == "nexo" else ALCANCE_TORRE
			if p.distance_to(t.pos) < alcance + 1.0 and not _hay_soldados_cerca(equipo, t.pos, alcance):
				return true
	return false


# Dónde se coloca un bot en su carril: un poco detrás del soldado propio más avanzado; si no hay
# soldados, junto a la torre propia más adelantada que siga en pie.
func _frente_carril(h: Heroe) -> Vector2:
	var mejor := -1.0
	for s in soldados:
		if s.equipo == h.equipo and s.carril == h.carril and not s.muerto:
			var avance := s.avance if h.equipo == 0 else 1.0 - s.avance
			mejor = maxf(mejor, avance)
	if mejor < 0.0:
		mejor = 0.08
		for t in torres:
			if t.equipo == h.equipo and t.carril == h.carril and not t.muerto:
				mejor = maxf(mejor, TRAMOS_TORRE[t.orden] - 0.03)
	else:
		mejor -= 0.04
	return _punto_carril(h.carril, mejor if h.equipo == 0 else 1.0 - mejor)


func _actualizar_soldado(s: Soldado, delta: float) -> void:
	if s.muerto:
		return
	s.espera -= delta
	var alcance := 6.0 if s.a_distancia else 1.6
	var objetivo: Unidad
	var objetivo_d := INF
	for u in _enemigos_cerca(s.equipo, s.pos, VISTA_SOLDADO, true):
		if u is Torre and protegida(u as Torre):
			continue
		var d := u.pos.distance_to(s.pos) - u.radio + (3.0 if u is Heroe else 0.0)
		if d < objetivo_d:
			objetivo_d = d
			objetivo = u
	var andando := false
	if objetivo != null:
		var lejos := objetivo.pos.distance_to(s.pos) - objetivo.radio
		if lejos > alcance:
			s.pos += (objetivo.pos - s.pos).normalized() * VEL_SOLDADO * delta
			andando = true
		elif s.espera <= 0.0:
			s.espera = 1.2 if s.a_distancia else 1.0
			if s.a_distancia:
				_disparar(s, objetivo.pos, objetivo, s.danio, {}, COLORES[s.equipo], 9.0, 18.0, 0.2)
			else:
				danar(objetivo, s.danio, s)
			_mirar(s.nodo, objetivo.pos - s.pos)
	else:
		# Avanza por el carril hacia la base enemiga.
		var sentido := 1.0 if s.equipo == 0 else -1.0
		var meta := _punto_carril(s.carril, s.avance + sentido * 0.02)
		if s.pos.distance_to(meta) < 1.5:
			s.avance = clampf(s.avance + sentido * 0.01, 0.0, 1.0)
		var dir := (meta - s.pos).normalized()
		s.pos += dir * VEL_SOLDADO * delta
		andando = dir != Vector2.ZERO
		_mirar(s.nodo, dir)
	# El avance sigue al soldado aunque se desvíe a pelear.
	var mas_cerca := s.avance
	var mejor := INF
	for paso in range(-3, 4):
		var t := clampf(s.avance + paso * 0.01, 0.0, 1.0)
		var d := _punto_carril(s.carril, t).distance_squared_to(s.pos)
		if d < mejor:
			mejor = d
			mas_cerca = t
	s.avance = mas_cerca
	s.pos = _mover_libre(s.pos, s.radio)
	if andando:
		s.fase += delta * 9.0
	s.nodo.position = Vector3(s.pos.x, absf(sin(s.fase)) * 0.12, s.pos.y)
	s.cuerpo.rotation.z = sin(s.fase) * 0.08


func _mirar(nodo: Node3D, dir: Vector2) -> void:
	if dir.length() > 0.01:
		nodo.rotation.y = atan2(-dir.x, -dir.y)


func _separar_soldados() -> void:
	for i in soldados.size():
		var a := soldados[i]
		for j in range(i + 1, soldados.size()):
			var b := soldados[j]
			var d := a.pos - b.pos
			var l := d.length()
			if l < 1.1 and l > 0.001:
				var empuje := d / l * (1.1 - l) * 0.5
				a.pos += empuje
				b.pos -= empuje


func _actualizar_torre(t: Torre, delta: float) -> void:
	if t.muerto:
		return
	t.cristal.rotation.y += delta * 1.5
	t.cristal.position.y = (8.2 if t.tipo == "nexo" else 7.2) + sin(tiempo_partida * 2.0 + t.pos.x) * 0.2
	t.espera -= delta
	if t.espera > 0.0:
		return
	var alcance := ALCANCE_NEXO if t.tipo == "nexo" else ALCANCE_TORRE
	var objetivo: Unidad
	var objetivo_d := INF
	for u in _enemigos_cerca(t.equipo, t.pos, alcance, false):
		var d := u.pos.distance_to(t.pos) + (20.0 if u is Heroe else 0.0)
		# Si un héroe ataca a un héroe aliado bajo la torre, la torre va a por él.
		if u is Heroe:
			for aliado in heroes:
				if aliado.equipo == t.equipo and aliado.ultimo_autor == u and aliado.tiempo_autor > 6.5 and aliado.pos.distance_to(t.pos) < alcance:
					d -= 40.0
		if d < objetivo_d:
			objetivo_d = d
			objetivo = u
	if objetivo == null:
		return
	t.espera = RECARGA_TORRE if t.tipo == "torre" else 1.0
	var danio := DANIO_TORRE * (1.25 if t.tipo == "nexo" else 1.0) * ((0.45 if t.tipo == "nexo" else 0.8) if objetivo is Soldado else 1.0)
	var p := _disparar(t, objetivo.pos, objetivo, danio, {}, COLORES[t.equipo], alcance + 6.0, 22.0, 0.5)
	p.altura = t.cristal.position.y


func _disparar(autor: Unidad, hacia: Vector2, objetivo: Unidad, danio: float, efectos_extra: Dictionary, color: Color, alcance: float, vel: float, tam: float) -> Proyectil:
	var p := Proyectil.new()
	p.pos = autor.pos
	p.dir = (hacia - autor.pos).normalized()
	if p.dir == Vector2.ZERO:
		p.dir = Vector2.UP
	p.vel = vel
	p.queda = alcance
	p.equipo = autor.equipo
	p.autor = autor
	p.objetivo = objetivo
	p.danio = danio
	p.efectos = efectos_extra
	p.altura = 2.2 if autor is Heroe else 1.6
	var bola := MeshInstance3D.new()
	bola.mesh = malla_bola
	bola.scale = Vector3.ONE * tam / 0.25
	bola.material_override = _mat_brillo(color, 1.0)
	bola.position = Vector3(p.pos.x, p.altura, p.pos.y)
	add_child(bola)
	p.nodo = bola
	proyectiles.append(p)
	return p


func _actualizar_proyectiles(delta: float) -> void:
	for p in proyectiles:
		if p.objetivo != null:
			if p.objetivo.muerto:
				p.queda = 0.0
			else:
				p.dir = (p.objetivo.pos - p.pos).normalized()
		var paso := p.vel * delta
		p.pos += p.dir * paso
		p.queda -= paso
		p.altura = move_toward(p.altura, 1.8, delta * 4.0)
		p.nodo.position = Vector3(p.pos.x, p.altura, p.pos.y)
		if p.objetivo != null:
			if not p.objetivo.muerto and p.pos.distance_to(p.objetivo.pos) < p.objetivo.radio + 0.3:
				danar(p.objetivo, p.danio, p.autor)
				p.queda = 0.0
		else:
			for u in _enemigos_cerca(p.equipo, p.pos, 0.7, true):
				if p.efectos.is_empty():
					danar(u, p.danio, p.autor)
				else:
					var s := p.efectos.duplicate()
					s["danio"] = p.danio
					_aplicar(u, s, p.autor as Heroe, p.pos)
				p.queda = 0.0
				break
		if p.queda <= 0.0:
			p.nodo.queue_free()
	proyectiles = proyectiles.filter(func(p: Proyectil) -> bool: return p.queda > 0.0)


func _actualizar_zonas(delta: float) -> void:
	for z in zonas:
		if z.retardo > 0.0:
			z.retardo -= delta
			var m := z.nodo.material_override as StandardMaterial3D
			m.albedo_color.a = 0.25 + 0.25 * sin(tiempo_partida * 20.0)
			if z.retardo <= 0.0:
				if z.spec.get("rayo", false):
					_rayo(z.pos, z.spec["color"])
				_onda(z.pos, z.radio, z.spec["color"])
				if z.dura <= 0.0:
					for u in _enemigos_cerca(z.equipo, z.pos, z.radio, true):
						_aplicar(u, z.spec, z.autor, z.pos)
				m.albedo_color.a = 0.45
			continue
		if z.dura > 0.0:
			z.dura -= delta
			z.tic -= delta
			z.nodo.rotation.y += delta * 4.0
			var tiron: float = z.spec.get("tiron", 0.0)
			for u in _enemigos_cerca(z.equipo, z.pos, z.radio, false):
				if u is Heroe:
					(u as Heroe).pos = (u as Heroe).pos.move_toward(z.pos, tiron * delta)
				elif u is Soldado:
					u.pos = u.pos.move_toward(z.pos, tiron * delta)
				if z.tic <= 0.0:
					danar(u, float(z.spec["danio"]) * 0.5, z.autor)
			if z.tic <= 0.0:
				z.tic = 0.5
		z.golpeo = z.dura <= 0.0
		if z.golpeo:
			z.nodo.queue_free()
	zonas = zonas.filter(func(z: Zona) -> bool: return not z.golpeo)


func _actualizar_minas(delta: float) -> void:
	for m in minas:
		m.armar -= delta
		m.queda -= delta
		if m.armar <= 0.0 and m.queda > 0.0:
			var cerca := _enemigos_cerca(m.equipo, m.pos, 1.6, false)
			if not cerca.is_empty():
				for u in _enemigos_cerca(m.equipo, m.pos, 3.2, false):
					danar(u, m.danio, m.autor)
				_onda(m.pos, 3.2, Color("ff6a2a"))
				m.queda = 0.0
		if m.queda <= 0.0:
			m.nodo.queue_free()
	minas = minas.filter(func(m: Mina) -> bool: return m.queda > 0.0)


# Efectos: ondas que se abren y se desvanecen, y rayos que caen del cielo.
func _onda(centro: Vector2, radio: float, color: Color) -> void:
	var aro := MeshInstance3D.new()
	aro.mesh = malla_aro
	aro.material_override = _mat_efecto(color, 0.55)
	aro.position = Vector3(centro.x, 0.12, centro.y)
	aro.scale = Vector3(0.3, 1.0, 0.3)
	add_child(aro)
	efectos.append({"nodo": aro, "vida": 0.45, "total": 0.45, "radio": radio, "tipo": "onda"})


func _rayo(donde: Vector2, color: Color) -> void:
	var rayo := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.35, 22.0, 0.35)
	rayo.mesh = caja
	rayo.material_override = _mat_efecto(color.lightened(0.4), 0.95)
	rayo.position = Vector3(donde.x, 11.0, donde.y)
	add_child(rayo)
	efectos.append({"nodo": rayo, "vida": 0.25, "total": 0.25, "radio": 1.0, "tipo": "rayo"})


func _actualizar_efectos(delta: float) -> void:
	for e in efectos:
		e["vida"] = float(e["vida"]) - delta
		var nodo: MeshInstance3D = e["nodo"]
		var t := 1.0 - float(e["vida"]) / float(e["total"])
		var m := nodo.material_override as StandardMaterial3D
		if e["tipo"] == "onda":
			var r: float = e["radio"]
			nodo.scale = Vector3(r * (0.3 + 0.7 * t), 1.0, r * (0.3 + 0.7 * t))
			m.albedo_color.a = 0.55 * (1.0 - t)
		else:
			m.albedo_color.a = 0.95 * (1.0 - t)
			nodo.scale.x = 1.0 + t * 2.0
		if float(e["vida"]) <= 0.0:
			nodo.queue_free()
	efectos = efectos.filter(func(e: Dictionary) -> bool: return float(e["vida"]) > 0.0)


func _mover_camara(delta: float) -> void:
	var meta := Vector3(jugador.pos.x, 0, jugador.pos.y)
	mira_camara = mira_camara.lerp(meta, minf(1.0, delta * 6.0))
	camara.position = mira_camara + CAMARA
	camara.look_at(mira_camara + Vector3(0, 1.0, 0))


func _terminar(equipo_ganador: int) -> void:
	ganador = equipo_ganador
	estado = Estado.FIN
	hud.visible = true
	boton_salir.visible = false
	for p in proyectiles:
		p.nodo.queue_free()
	proyectiles.clear()
	var gane := ganador == jugador.equipo
	_anunciar(tr("¡Victoria!") if gane else tr("Derrota"), Color("ffe08a") if gane else Color("ff8a7a"), 999.0)
	var nexo := nexos[1 - ganador]
	mira_camara = Vector3(nexo.pos.x, 0, nexo.pos.y)
	camara.position = mira_camara + CAMARA * 1.3
	camara.look_at(mira_camara)
	_mostrar_fin(gane)


func _anunciar(texto: String, color: Color, dura: float) -> void:
	anuncio = texto
	anuncio_color = color
	anuncio_vida = dura


# ---------------------------------------------------------------------------------------
# Controles táctiles y de teclado.

func _input(evento: InputEvent) -> void:
	if estado != Estado.JUGANDO:
		return
	var tam := get_viewport().get_visible_rect().size
	if evento is InputEventScreenTouch:
		var toque := evento as InputEventScreenTouch
		if toque.pressed:
			if toque.position.y < 100.0 and toque.position.x < 220.0:
				return
			var boton := _boton_en(toque.position, tam)
			if boton == "ataque":
				dedo_ataque = toque.index
			elif boton.begins_with("poder"):
				usar_poder(jugador, int(boton.substr(5)))
			elif boton == "regreso":
				_pedir_regreso()
			elif boton == "" and toque.position.x < tam.x * 0.5 and dedo_palanca < 0:
				dedo_palanca = toque.index
				centro_palanca = toque.position
				punta_palanca = toque.position
		else:
			if toque.index == dedo_palanca:
				dedo_palanca = -1
			if toque.index == dedo_ataque:
				dedo_ataque = -1
	elif evento is InputEventScreenDrag:
		var arrastre := evento as InputEventScreenDrag
		if arrastre.index == dedo_palanca:
			punta_palanca = arrastre.position
			var d := punta_palanca - centro_palanca
			if d.length() > RADIO_PALANCA * 1.6:
				centro_palanca = punta_palanca - d.normalized() * RADIO_PALANCA * 1.6
	elif evento is InputEventKey:
		var tecla := evento as InputEventKey
		if tecla.echo:
			return
		if tecla.physical_keycode == KEY_SPACE:
			atacando_tecla = tecla.pressed
		elif tecla.pressed:
			var k := TECLAS_PODER.find(tecla.physical_keycode)
			if k >= 0:
				usar_poder(jugador, k)
			elif tecla.physical_keycode == KEY_B:
				_pedir_regreso()


func _pedir_regreso() -> void:
	if not jugador.muerto and jugador.regreso < 0.0:
		jugador.regreso = 0.0
		_anunciar(tr("Volviendo a la base..."), COLORES[0], DURACION_REGRESO)


func _boton_en(p: Vector2, tam: Vector2) -> String:
	if p.distance_to(tam + BOTON_ATAQUE) < RADIO_ATAQUE + 10.0:
		return "ataque"
	for k in 3:
		if p.distance_to(tam + BOTONES_PODER[k]) < RADIO_PODER + 8.0:
			return "poder%d" % k
	if p.distance_to(tam + BOTON_CURAR) < RADIO_PEQUENO + 8.0:
		return "poder3"
	if p.distance_to(tam + BOTON_REGRESO) < RADIO_PEQUENO + 8.0:
		return "regreso"
	return ""


# ---------------------------------------------------------------------------------------
# Interfaz: elección de dios y carril, marcador, botones, barras de vida, minimapa y final.

func _crear_interfaz() -> void:
	capa = CanvasLayer.new()
	add_child(capa)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_dibujar_hud)
	hud.visible = false
	capa.add_child(hud)
	boton_salir = Button.new()
	boton_salir.text = tr("Salir")
	boton_salir.focus_mode = Control.FOCUS_NONE
	boton_salir.add_theme_font_size_override("font_size", 22)
	Ui.estilo_boton(boton_salir, false)
	Ui.anclar(boton_salir, Vector2(0, 0), Vector2(16, 16), Vector2(120, 56))
	boton_salir.pressed.connect(_volver_menu)
	boton_salir.visible = false
	capa.add_child(boton_salir)
	for k in carriles.size():
		var mini := PackedVector2Array()
		for p in carriles[k]:
			mini.append(p)
		mini_carriles.append(mini)
	_crear_panel_eleccion()


func _crear_panel_eleccion() -> void:
	var partes := Ui.panel_lateral_desplazable(capa)
	panel_eleccion = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_child(Ui.etiqueta_panel(tr("Dioses en Tierra"), 34, Principal.COLOR_ORO))
	cuerpo.add_child(Ui.etiqueta_panel(tr("5 contra 5 a pie, con cinco carriles. Elige tu dios y tu carril."), 17, Color("c9d1d3")))
	var rejilla := GridContainer.new()
	rejilla.columns = 6
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	cuerpo.add_child(rejilla)
	for cap: Dictionary in Moba.CAPITANES:
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(70, 84)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.focus_mode = Control.FOCUS_NONE
		Ui.estilo_boton(boton, false)
		boton.draw.connect(_dibujar_tarjeta.bind(boton, cap))
		boton.pressed.connect(_elegir_dios.bind(str(cap["id"])))
		rejilla.add_child(boton)
		botones_dios[cap["id"]] = boton
	texto_dios = Ui.etiqueta_panel("", 20, Principal.COLOR_TEXTO)
	cuerpo.add_child(texto_dios)
	texto_poderes = Ui.etiqueta_panel("", 15, Color("c9d1d3"))
	cuerpo.add_child(texto_poderes)
	cuerpo.add_child(Ui.etiqueta_panel(tr("Tu carril"), 18, Principal.COLOR_ORO))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	cuerpo.add_child(fila)
	for k in NOMBRES_CARRIL.size():
		var boton := Button.new()
		boton.text = tr(NOMBRES_CARRIL[k])
		boton.custom_minimum_size = Vector2(0, 52)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.focus_mode = Control.FOCUS_NONE
		boton.add_theme_font_size_override("font_size", 16)
		boton.pressed.connect(_elegir_carril.bind(k))
		fila.add_child(boton)
		botones_carril.append(boton)
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 10)
	(partes[2] as VBoxContainer).add_child(pie)
	var volver := Ui.boton(tr("Volver"), false)
	volver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volver.pressed.connect(_volver_menu)
	pie.add_child(volver)
	var jugar := Ui.boton(tr("¡A la batalla!"), true)
	jugar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jugar.pressed.connect(_empezar)
	pie.add_child(jugar)


func _dibujar_tarjeta(boton: Button, cap: Dictionary) -> void:
	Moba.dibujar_retrato(boton, Vector2(boton.size.x / 2.0, 34.0), 27.0, cap["figura"])
	var claro: bool = cap["id"] == elegido
	boton.draw_string(ThemeDB.fallback_font, Vector2(2, boton.size.y - 7), tr(cap["corto"]), HORIZONTAL_ALIGNMENT_CENTER, boton.size.x - 4, 13,
		Color("2a1a0c") if claro else Principal.COLOR_TEXTO)


func _abrir_eleccion() -> void:
	estado = Estado.ELIGIENDO
	panel_eleccion.visible = true
	# La cámara mira a la fuente azul, donde el dios elegido espera de pie.
	var c := FUENTES[0] + Vector2(16.0, -16.0)
	camara.position = Vector3(c.x + 1.5, 3.4, c.y + 9.0)
	camara.look_at(Vector3(c.x + 3.6, 2.2, c.y))
	_elegir_dios(elegido)
	_elegir_carril(carril_elegido)


func _elegir_dios(id: String) -> void:
	elegido = id
	var cap: Dictionary = Moba.CAPITANES[0]
	for otro: Dictionary in Moba.CAPITANES:
		if otro["id"] == id:
			cap = otro
	for clave in botones_dios:
		Ui.estilo_boton(botones_dios[clave], clave == id)
		botones_dios[clave].queue_redraw()
	texto_dios.text = tr(cap["nombre"]) + " (" + tr(cap["panteon"]) + ")\n" + tr(cap["info"])
	var lineas: Array[String] = []
	var lista := Moba.habilidades_de(cap)
	var teclas := ["Q", "E", "R", "F"]
	for k in lista.size():
		var s: Dictionary = Moba.HABILIDADES[lista[k]]
		lineas.append("%s · %s: %s" % [teclas[k], tr(s["nombre"]), tr(s["info"])])
	texto_poderes.text = "\n".join(lineas)
	if figura_vitrina != null:
		figura_vitrina.queue_free()
	figura_vitrina = FiguraCapitan.crear(cap["figura"])
	figura_vitrina.scale = Vector3.ONE * ESCALA_DIOS
	var c := FUENTES[0] + Vector2(16.0, -16.0)
	figura_vitrina.position = Vector3(c.x, 0.0, c.y)
	figura_vitrina.rotation.y = PI + 0.4
	figura_vitrina.set_process(true)
	add_child(figura_vitrina)


func _elegir_carril(k: int) -> void:
	carril_elegido = k
	for i in botones_carril.size():
		Ui.estilo_boton(botones_carril[i], i == k)


func _vitrina(delta: float) -> void:
	if figura_vitrina != null:
		figura_vitrina.rotation.y = PI + 0.4 + sin(Time.get_ticks_msec() / 1500.0) * 0.5


func _mostrar_fin(gane: bool) -> void:
	var partes := Ui.panel_lateral(capa)
	panel_fin = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_child(Ui.etiqueta_panel(tr("¡Victoria!") if gane else tr("Derrota"), 40, Principal.COLOR_ORO if gane else Color("ff8a7a")))
	var lineas: Array[String] = []
	lineas.append(tr("Duración: %d:%02d") % [int(tiempo_partida) / 60, int(tiempo_partida) % 60])
	lineas.append(tr("Derrotas de dioses: %d azul · %d rojo") % [asesinatos_equipo[0], asesinatos_equipo[1]])
	lineas.append(tr("Tú (%s): %d derrotados, %d caídas, nivel %d") % [tr(jugador.nombre), jugador.asesinatos, jugador.muertes, jugador.nivel])
	cuerpo.add_child(Ui.etiqueta_panel("\n".join(lineas), 19, Principal.COLOR_TEXTO))
	var hueco := Control.new()
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(hueco)
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 10)
	cuerpo.add_child(pie)
	var menu := Ui.boton(tr("Menú"), false)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(_volver_menu)
	pie.add_child(menu)
	var otra := Ui.boton(tr("Otra vez"), true)
	otra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	otra.pressed.connect(func() -> void: get_tree().reload_current_scene())
	pie.add_child(otra)


func _volver_menu() -> void:
	get_tree().change_scene_to_file(ESCENA_MENU)


func _dibujar_hud() -> void:
	if estado == Estado.ELIGIENDO:
		return
	var tam := hud.size
	var fuente := ThemeDB.fallback_font
	# Barras de vida sobre cada unidad que se ve en pantalla.
	for u in _unidades_visibles():
		var p3 := Vector3(u.pos.x, u.altura, u.pos.y)
		if u is Torre:
			p3.y = (u.altura if not u.muerto else 2.0)
		if camara.is_position_behind(p3):
			continue
		var p := camara.unproject_position(p3)
		if p.x < -80 or p.y < -40 or p.x > tam.x + 80 or p.y > tam.y + 40:
			continue
		var ancho := 70.0 if u is Heroe else (34.0 if u is Soldado else 96.0)
		var alto := 9.0 if u is Heroe else (5.0 if u is Soldado else 10.0)
		var color := Color("6fd06b") if u == jugador else (COLORES[u.equipo] if u.equipo == 0 else COLORES[1])
		var caja := Rect2(p - Vector2(ancho / 2.0, 0), Vector2(ancho, alto))
		hud.draw_rect(caja.grow(1.5), Color(0, 0, 0, 0.7))
		hud.draw_rect(Rect2(caja.position, Vector2(ancho * clampf(u.vida / u.vida_max, 0.0, 1.0), alto)), color)
		if u is Heroe:
			var h := u as Heroe
			hud.draw_circle(caja.position + Vector2(-9, alto / 2.0), 10.0, Color(0, 0, 0, 0.75))
			hud.draw_string(fuente, caja.position + Vector2(-19, alto / 2.0 + 5), str(h.nivel), HORIZONTAL_ALIGNMENT_CENTER, 20, 13, Color.WHITE)
			hud.draw_string(fuente, caja.position + Vector2(-20, -5), tr(h.cap["corto"]), HORIZONTAL_ALIGNMENT_CENTER, ancho + 40, 14,
				Color.WHITE if h == jugador else COLORES[h.equipo].lightened(0.4))
			if h.regreso >= 0.0:
				hud.draw_rect(Rect2(caja.position + Vector2(0, alto + 4), Vector2(ancho * h.regreso / DURACION_REGRESO, 4)), Color("8fd8ff"))
		elif u is Torre and protegida(u as Torre) and not u.muerto:
			hud.draw_string(fuente, caja.position + Vector2(0, -4), "🔒", HORIZONTAL_ALIGNMENT_CENTER, ancho, 16, Color.WHITE)
	if estado == Estado.FIN:
		_dibujar_anuncio(tam, fuente)
		return
	# Marcador arriba al centro.
	var marcador := Rect2(Vector2(tam.x / 2.0 - 150, 10), Vector2(300, 52))
	hud.draw_rect(marcador, Color(0, 0, 0, 0.45))
	hud.draw_string(fuente, marcador.position + Vector2(0, 30), str(asesinatos_equipo[0]), HORIZONTAL_ALIGNMENT_CENTER, 90, 28, COLORES[0])
	hud.draw_string(fuente, marcador.position + Vector2(210, 30), str(asesinatos_equipo[1]), HORIZONTAL_ALIGNMENT_CENTER, 90, 28, COLORES[1])
	var minutos := "%d:%02d" % [int(tiempo_partida) / 60, int(tiempo_partida) % 60]
	hud.draw_string(fuente, marcador.position + Vector2(90, 24), minutos, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color.WHITE)
	var torres_vivas: Array[int] = [0, 0]
	for t in torres:
		if t.tipo == "torre" and not t.muerto:
			torres_vivas[t.equipo] += 1
	hud.draw_string(fuente, marcador.position + Vector2(90, 45), tr("Torres %d · %d") % [torres_vivas[0], torres_vivas[1]], HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color("c9d1d3"))
	# Nivel y experiencia del jugador.
	var info := Vector2(16, 78)
	hud.draw_string(fuente, info + Vector2(0, 16), tr("Nivel %d") % jugador.nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffe08a"))
	hud.draw_rect(Rect2(info + Vector2(0, 24), Vector2(150, 7)), Color(0, 0, 0, 0.5))
	var parte := 1.0 if jugador.nivel >= NIVEL_MAX else jugador.xp / _xp_para(jugador.nivel)
	hud.draw_rect(Rect2(info + Vector2(0, 24), Vector2(150 * parte, 7)), Color("ffe08a"))
	hud.draw_string(fuente, info + Vector2(0, 52), tr("Derrotados %d · Caídas %d") % [jugador.asesinatos, jugador.muertes], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	if jugador.muerto:
		hud.draw_string(fuente, Vector2(0, tam.y / 2.0), tr("Reapareces en %d") % ceili(jugador.revivir), HORIZONTAL_ALIGNMENT_CENTER, tam.x, 34, Color("ff8a7a"))
	_dibujar_minimapa(tam)
	_dibujar_botones(tam, fuente)
	if dedo_palanca >= 0:
		hud.draw_circle(centro_palanca, RADIO_PALANCA, Color(1, 1, 1, 0.12))
		hud.draw_arc(centro_palanca, RADIO_PALANCA, 0, TAU, 40, Color(1, 1, 1, 0.35), 3.0, true)
		var d := punta_palanca - centro_palanca
		if d.length() > RADIO_PALANCA:
			d = d.normalized() * RADIO_PALANCA
		hud.draw_circle(centro_palanca + d, 30.0, Color(1, 1, 1, 0.45))
	else:
		var sitio := Vector2(150, tam.y - 150)
		hud.draw_arc(sitio, RADIO_PALANCA, 0, TAU, 40, Color(1, 1, 1, 0.15), 3.0, true)
		hud.draw_circle(sitio, 26.0, Color(1, 1, 1, 0.12))
	_dibujar_anuncio(tam, fuente)


func _dibujar_anuncio(tam: Vector2, fuente: Font) -> void:
	if anuncio_vida > 0.0:
		var a := clampf(anuncio_vida * 2.0, 0.0, 1.0)
		hud.draw_string_outline(fuente, Vector2(0, 150), anuncio, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 30, 8, Color(0, 0, 0, 0.6 * a))
		hud.draw_string(fuente, Vector2(0, 150), anuncio, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 30, Color(anuncio_color, a))


func _unidades_visibles() -> Array[Unidad]:
	var lista: Array[Unidad] = []
	for t in torres:
		if not t.muerto:
			lista.append(t)
	for s in soldados:
		lista.append(s)
	for h in heroes:
		if not h.muerto and h.figura.visible:
			lista.append(h)
	return lista


func _dibujar_minimapa(tam: Vector2) -> void:
	var lado := 176.0
	var caja := Rect2(Vector2(tam.x - lado - 14, 14), Vector2(lado, lado))
	var a_mini := func(p: Vector2) -> Vector2:
		return caja.position + (p + Vector2(MITAD, MITAD)) / (MITAD * 2.0) * lado
	hud.draw_rect(caja.grow(3), Color(0, 0, 0, 0.55))
	hud.draw_rect(caja, Color("4f8a3a"))
	hud.draw_line(a_mini.call(Vector2(-MITAD, -MITAD)), a_mini.call(Vector2(MITAD, MITAD)), Color("4aa8c8"), 5.0)
	for puntos in mini_carriles:
		var linea := PackedVector2Array()
		for p in puntos:
			linea.append(a_mini.call(p))
		hud.draw_polyline(linea, Color("d9b880"), 3.0)
	for t in torres:
		if t.muerto:
			continue
		var p: Vector2 = a_mini.call(t.pos)
		var r := 6.0 if t.tipo == "nexo" else 4.0
		hud.draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2, r * 2)), COLORES[t.equipo])
		hud.draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2, r * 2)), Color(0, 0, 0, 0.6), false, 1.0)
	for s in soldados:
		hud.draw_circle(a_mini.call(s.pos), 1.6, COLORES[s.equipo].lightened(0.3))
	for h in heroes:
		if h.muerto or (h.equipo != jugador.equipo and not h.figura.visible):
			continue
		var p: Vector2 = a_mini.call(h.pos)
		hud.draw_circle(p, 5.5 if h == jugador else 4.5, Color.WHITE if h == jugador else Color(0, 0, 0, 0.7))
		hud.draw_circle(p, 3.8 if h == jugador else 3.4, COLORES[h.equipo])


func _dibujar_botones(tam: Vector2, fuente: Font) -> void:
	var lista := poderes_de(jugador)
	var c := tam + BOTON_ATAQUE
	var atacando := dedo_ataque >= 0 or atacando_tecla
	hud.draw_circle(c, RADIO_ATAQUE, Color("d0533f") if atacando else Color("a8402f"))
	hud.draw_arc(c, RADIO_ATAQUE, 0, TAU, 48, Color("ffe08a"), 3.0, true)
	# Dibujo de un rayo de poder en el botón de ataque.
	hud.draw_colored_polygon(PackedVector2Array([c + Vector2(6, -30), c + Vector2(-14, 4), c + Vector2(0, 4), c + Vector2(-6, 30), c + Vector2(16, -6), c + Vector2(2, -6)]), Color("fff3dc"))
	for k in 4:
		var centro := tam + (BOTONES_PODER[k] if k < 3 else BOTON_CURAR)
		var radio := RADIO_PODER if k < 3 else RADIO_PEQUENO
		var s: Dictionary = especs[lista[k]]
		var color: Color = s["color"]
		var espera := jugador.esperas[k]
		var lista_ok := espera <= 0.0 and not jugador.muerto
		hud.draw_circle(centro, radio, Color(0.05, 0.08, 0.1, 0.8))
		hud.draw_circle(centro, radio - 5.0, color.darkened(0.25) if lista_ok else color.darkened(0.7))
		hud.draw_arc(centro, radio, 0, TAU, 40, Color("ffe08a") if lista_ok else Color(1, 1, 1, 0.3), 3.0, true)
		if not lista_ok and espera > 0.0:
			var parte := espera / float(s["espera"])
			hud.draw_arc(centro, radio - 3.0, -PI / 2.0, -PI / 2.0 + TAU * parte, 32, Color(0, 0, 0, 0.6), 5.0, true)
			hud.draw_string(fuente, centro + Vector2(-radio, 8), str(ceili(espera)), HORIZONTAL_ALIGNMENT_CENTER, radio * 2.0, 24, Color.WHITE)
		hud.draw_string_outline(fuente, centro + Vector2(-radio - 10, radio + 16), tr(s["corto"]), HORIZONTAL_ALIGNMENT_CENTER, radio * 2.0 + 20, 13, 4, Color(0, 0, 0, 0.8))
		hud.draw_string(fuente, centro + Vector2(-radio - 10, radio + 16), tr(s["corto"]), HORIZONTAL_ALIGNMENT_CENTER, radio * 2.0 + 20, 13, Color.WHITE)
	# Botón de volver a la base.
	var r := tam + BOTON_REGRESO
	hud.draw_circle(r, RADIO_PEQUENO, Color(0.05, 0.08, 0.1, 0.8))
	hud.draw_arc(r, RADIO_PEQUENO, 0, TAU, 32, Color("8fd8ff"), 2.5, true)
	hud.draw_colored_polygon(PackedVector2Array([r + Vector2(0, -14), r + Vector2(13, -2), r + Vector2(8, -2), r + Vector2(8, 12), r + Vector2(-8, 12), r + Vector2(-8, -2), r + Vector2(-13, -2)]), Color("8fd8ff"))
	hud.draw_string(fuente, r + Vector2(-50, RADIO_PEQUENO + 15), tr("Base"), HORIZONTAL_ALIGNMENT_CENTER, 100, 13, Color.WHITE)
