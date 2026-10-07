class_name Fauna
extends Node3D

# Animales y decorados de las islas. Todo cuelga del nodo de su isla (se borra con ella)
# y solo se anima lo que está cerca de la cámara.

const ALTO_ARENA := 0.45
const DISTANCIA_ANIMAR := 75.0
# Metros desde la orilla a los que un barco espanta a los animales.
const ALCANCE_SUSTO := 4.0
const DURACION_SALTO := 0.75
const CICLO_DELFIN := 2.6


class Gaviota:
	var nodo: Node3D
	var alas: Array[Node3D] = []
	var angulo := 0.0
	var giro := 1.0
	var velocidad := 1.2
	var orbita := 4.0
	var alto := 4.0
	var fase := 0.0
	var ala := 0.0


class Cangrejo:
	var nodo: Node3D
	var patas: Array[Node3D] = []
	var pinzas: Array[Node3D] = []
	var angulo := 0.0
	var distancia := 3.0
	var sentido := 1.0
	var andar := 0.0
	var pausa := 0.0
	var fase := 0.0


class Tortuga:
	var nodo: Node3D
	var cabeza: Node3D
	var aletas: Array[Node3D] = []
	var estado := "sol"
	var angulo := 0.0
	var distancia := 3.0
	var espera := 10.0
	var sentido := 1.0
	var fase := 0.0
	var remo := 0.0


class Mono:
	var nodo: Node3D
	var brazos: Array[Node3D] = []
	var piernas: Array[Node3D] = []
	var alto := 2.0
	var altura := 2.0
	var estado := "arriba"
	var espera := 5.0
	var fase := 0.0


class Delfin:
	var nodo: Node3D
	var angulo := 0.0
	var fase := 0.0
	var orbita := 8.0


class Isla:
	var nodo: Node3D
	var radio := 3.0
	var contorno: Circulo
	var susto := 0.0
	var gaviotas: Array[Gaviota] = []
	var cangrejos: Array[Cangrejo] = []
	var tortugas: Array[Tortuga] = []
	var monos: Array[Mono] = []
	var delfines: Array[Delfin] = []
	var giro_delfines := 1.0
	var pez: Node3D
	var salto := -1.0
	var espera_pez := 3.0
	var salto_desde := Vector2.ZERO
	var salto_hacia := Vector2.ZERO
	var llamas: Array[MeshInstance3D] = []
	var fogata := Vector3.ZERO
	var espera_humo := 0.0
	var banderas: Array[Node3D] = []


var mundo: Principal
var islas: Array[Isla] = []
var esfera: SphereMesh
var semiesfera: SphereMesh
var caja: BoxMesh
var cilindro: CylinderMesh
var cono: CylinderMesh
var material_fuego: StandardMaterial3D
var material_llama: StandardMaterial3D
# Forma de la isla que se está poblando o animando; _en_anillo sigue su orilla.
var contorno: Circulo


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	esfera = SphereMesh.new()
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 10
	esfera.rings = 5
	semiesfera = SphereMesh.new()
	semiesfera.radius = 0.5
	semiesfera.height = 0.5
	semiesfera.radial_segments = 12
	semiesfera.rings = 4
	semiesfera.is_hemisphere = true
	caja = BoxMesh.new()
	cilindro = CylinderMesh.new()
	cilindro.top_radius = 0.5
	cilindro.bottom_radius = 0.5
	cilindro.height = 1.0
	cilindro.radial_segments = 10
	cilindro.rings = 1
	cono = CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 8
	cono.rings = 1
	material_fuego = _brillante(Color("ff7a24"))
	material_llama = _brillante(Color("ffd35a"))


func _brillante(color: Color) -> StandardMaterial3D:
	var materia := StandardMaterial3D.new()
	materia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materia.albedo_color = color
	return materia


func limpiar() -> void:
	islas.clear()


func _pieza(padre: Node3D, malla: Mesh, color: Color, pos: Vector3, escala: Vector3, giro := Vector3.ZERO) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = mundo.material(color)
	pieza.position = pos
	pieza.scale = escala
	pieza.rotation = giro
	padre.add_child(pieza)
	return pieza


func _pivote(padre: Node3D, pos: Vector3) -> Node3D:
	var pivote := Node3D.new()
	pivote.position = pos
	padre.add_child(pivote)
	return pivote


# Giro en Y que deja el +Z local mirando hacia fuera de la isla.
func _afuera(angulo: float) -> float:
	return atan2(cos(angulo), sin(angulo))


func _en_anillo(angulo: float, distancia: float, alto: float) -> Vector3:
	var lejos := distancia * (contorno.factor(angulo) if contorno != null else 1.0)
	return Vector3(cos(angulo) * lejos, alto, sin(angulo) * lejos)


func _al_azar() -> float:
	return -1.0 if randf() < 0.5 else 1.0


# radio: metros 3D de la arena. palmeras: nodos con el meta "alto".
func poblar(nodo: Node3D, radio: float, chica: bool, palmeras: Array[Node3D], forma: Circulo) -> void:
	var isla := Isla.new()
	isla.nodo = nodo
	isla.radio = radio
	isla.contorno = forma
	contorno = forma
	var base := randf() * TAU
	var huecos: Array[float] = []
	for i in 4:
		huecos.append(base + TAU * i / 4.0 + randf_range(-0.3, 0.3))
	if randf() < (0.15 if chica else 0.4):
		_naufragio(nodo, radio, huecos[0], chica)
	if not chica and randf() < 0.45:
		_campamento(isla, huecos[1])
	if randf() < (0.25 if chica else 0.45):
		_calaveras(isla, huecos[2], chica)
	for _i in (randi_range(0, 2) if chica else randi_range(2, 3)):
		isla.gaviotas.append(_gaviota(nodo, radio))
	for _i in (randi_range(1, 2) if chica else randi_range(3, 4)):
		isla.cangrejos.append(_cangrejo(nodo, radio))
	if randf() < (0.3 if chica else 0.7):
		isla.tortugas.append(_tortuga(nodo, radio, huecos[3]))
	for palmera in palmeras:
		if randf() < (0.25 if chica else 0.4):
			isla.monos.append(_mono(palmera))
	if not chica and randf() < 0.4:
		isla.giro_delfines = _al_azar()
		for k in 2:
			isla.delfines.append(_delfin(nodo, radio, k))
	isla.pez = _pez(nodo)
	isla.espera_pez = randf_range(1.0, 6.0)
	islas.append(isla)


# Decorados

func _naufragio(nodo: Node3D, radio: float, angulo: float, chica: bool) -> void:
	var resto := _pivote(nodo, _en_anillo(angulo, radio, 0.15))
	resto.rotation = Vector3(0.0, _afuera(angulo) + randf_range(-0.6, 0.6), 0.32 * _al_azar())
	resto.scale = Vector3.ONE * (0.65 if chica else 1.0)
	var madera := Color("5a3d24")
	var clara := Color("7a5634")
	_pieza(resto, caja, madera, Vector3(0, 0.15, 0.2), Vector3(0.9, 0.42, 1.9))
	_pieza(resto, caja, clara, Vector3(0, 0.37, 0.25), Vector3(0.8, 0.05, 1.3))
	_pieza(resto, caja, madera, Vector3(0, 0.15, 1.15), Vector3(0.64, 0.42, 0.64), Vector3(0, PI / 4.0, 0))
	for k in 3:
		for s in [-1.0, 1.0]:
			_pieza(resto, caja, clara, Vector3(s * 0.4, 0.5, -0.85 - k * 0.24), Vector3(0.07, 0.6, 0.07), Vector3(0, 0, -s * 0.25))
	var mastil := _pivote(resto, Vector3(0, 0.35, 0.35))
	mastil.rotation.x = 0.9
	_pieza(mastil, cilindro, Color("4a3220"), Vector3(0, 0.9, 0), Vector3(0.12, 1.8, 0.12))
	_pieza(mastil, caja, Color("d8ccb0"), Vector3(0.3, 1.25, 0), Vector3(0.6, 0.7, 0.02), Vector3(0, 0, 0.2))
	for s in [-1.0, 1.0]:
		_pieza(resto, caja, clara, Vector3(s * 0.75, 0.32, -1.4), Vector3(0.7, 0.05, 0.15), Vector3(0, randf_range(-1.0, 1.0), 0))


func _campamento(isla: Isla, angulo: float) -> void:
	var campo := _pivote(isla.nodo, _en_anillo(angulo, isla.radio * 0.8, ALTO_ARENA))
	campo.rotation.y = _afuera(angulo)
	for k in 7:
		var a := TAU * k / 7.0
		_pieza(campo, esfera, Color("6f7472"), Vector3(cos(a) * 0.22, 0.03, sin(a) * 0.22), Vector3(0.12, 0.09, 0.12))
	for s in [-1.0, 1.0]:
		_pieza(campo, caja, Color("4a3220"), Vector3(0, 0.05, 0), Vector3(0.06, 0.06, 0.4), Vector3(0, s * 0.6, 0))
	var llama := _pieza(campo, cono, Color.WHITE, Vector3(0, 0.2, 0), Vector3(0.24, 0.36, 0.24))
	llama.material_override = material_fuego
	llama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var centro := _pieza(campo, cono, Color.WHITE, Vector3(0, 0.17, 0), Vector3(0.13, 0.24, 0.13))
	centro.material_override = material_llama
	centro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	isla.llamas = [llama, centro]
	isla.fogata = campo.position + Vector3(0, 0.45, 0)
	_pieza(campo, cilindro, Color("6b4a2e"), Vector3(0, 0.06, -0.45), Vector3(0.12, 0.5, 0.12), Vector3(0, 0, PI / 2.0))

	var carpa := _pivote(campo, Vector3(0.8, 0, -0.15))
	carpa.rotation.y = 0.3
	for s in [-1.0, 1.0]:
		_pieza(carpa, caja, Color("c9b28a"), Vector3(s * 0.2, 0.3, 0), Vector3(0.03, 0.72, 0.9), Vector3(0, 0, s * 0.6))
	_pieza(carpa, caja, Color("b0412e"), Vector3(0, 0.6, 0), Vector3(0.06, 0.06, 0.96))

	for sitio in [Vector3(-0.7, 0, 0.0), Vector3(-0.85, 0, -0.38)]:
		_pieza(campo, cilindro, Color("7a5232"), sitio + Vector3(0, 0.17, 0), Vector3(0.26, 0.34, 0.26))
		for alto in [0.07, 0.27]:
			_pieza(campo, cilindro, Color("3b2a1c"), sitio + Vector3(0, alto, 0), Vector3(0.27, 0.03, 0.27))
	_pieza(campo, caja, Color("9c7448"), Vector3(-0.5, 0.15, -0.6), Vector3(0.3, 0.3, 0.3), Vector3(0, 0.4, 0))


func _calavera(padre: Node3D, pos: Vector3, tam: float) -> void:
	_pieza(padre, esfera, Color("f2efe6"), pos, Vector3(1.0, 0.9, 1.0) * tam)
	for s in [-1.0, 1.0]:
		_pieza(padre, esfera, Color("1a1a1a"), pos + Vector3(s * 0.22, 0.05, 0.38) * tam, Vector3.ONE * 0.28 * tam)


func _calaveras(isla: Isla, angulo: float, chica: bool) -> void:
	var sitio := _pivote(isla.nodo, _en_anillo(angulo, isla.radio * 0.78, ALTO_ARENA))
	sitio.rotation.y = _afuera(angulo)
	var blanco := Color("f2efe6")
	_pieza(sitio, cilindro, Color("3b2a1c"), Vector3(0, 0.9, 0), Vector3(0.06, 1.8, 0.06))
	var bandera := _pivote(sitio, Vector3(0, 1.6, 0))
	_pieza(bandera, caja, Color("1d1d22"), Vector3(0, 0, 0.34), Vector3(0.02, 0.42, 0.64))
	for s in [-1.0, 1.0]:
		_pieza(bandera, caja, blanco, Vector3(0, -0.03, 0.34), Vector3(0.03, 0.035, 0.34), Vector3(s * 0.7, 0, 0))
	_pieza(bandera, esfera, blanco, Vector3(0, 0.04, 0.34), Vector3(0.04, 0.15, 0.14))
	_pieza(bandera, caja, blanco, Vector3(0, -0.05, 0.34), Vector3(0.035, 0.05, 0.09))
	isla.banderas.append(bandera)

	_pieza(sitio, cilindro, Color("6b4a2e"), Vector3(0.5, 0.4, 0.1), Vector3(0.04, 0.8, 0.04))
	_calavera(sitio, Vector3(0.5, 0.85, 0.1), 0.2)
	_calavera(sitio, Vector3(-0.45, 0.06, 0.25), 0.16)
	for s in [-1.0, 1.0]:
		_pieza(sitio, caja, blanco, Vector3(-0.45, 0.02, 0.05), Vector3(0.04, 0.04, 0.3), Vector3(0, s * 0.6, 0))
	if chica:
		return

	# El cartel no gira con la isla: mira siempre hacia la cámara de juego.
	var cartel := _pivote(isla.nodo, _en_anillo(angulo + 0.45, isla.radio * 0.76, ALTO_ARENA))
	_pieza(cartel, caja, Color("5e4028"), Vector3(0, 0.45, 0), Vector3(0.08, 0.9, 0.08))
	_pieza(cartel, caja, Color("e8d7a8"), Vector3(0, 0.78, 0.05), Vector3(0.6, 0.72, 0.02))
	_pieza(cartel, esfera, Color("5a4632"), Vector3(0, 0.76, 0.06), Vector3(0.18, 0.22, 0.01))
	for linea in [["SE BUSCA", 1.04, 34], ["1000", 0.53, 26]]:
		var texto := Label3D.new()
		texto.text = linea[0]
		texto.font_size = linea[2]
		texto.pixel_size = 0.004
		texto.outline_size = 0
		texto.modulate = Color("3b2a1c")
		texto.position = Vector3(0, linea[1], 0.065)
		cartel.add_child(texto)


# Animales

func _gaviota(nodo: Node3D, radio: float) -> Gaviota:
	var g := Gaviota.new()
	g.nodo = _pivote(nodo, Vector3.ZERO)
	g.angulo = randf() * TAU
	g.giro = _al_azar()
	g.velocidad = randf_range(0.9, 1.4)
	g.orbita = radio * randf_range(1.2, 2.2)
	g.alto = randf_range(3.5, 5.5)
	g.fase = randf() * 100.0
	var blanco := Color("f4f4ef")
	_pieza(g.nodo, esfera, blanco, Vector3.ZERO, Vector3(0.18, 0.16, 0.48))
	_pieza(g.nodo, esfera, blanco, Vector3(0, 0.06, -0.24), Vector3.ONE * 0.15)
	_pieza(g.nodo, caja, Color("f0b43a"), Vector3(0, 0.04, -0.35), Vector3(0.04, 0.04, 0.1))
	_pieza(g.nodo, caja, blanco, Vector3(0, 0.0, 0.27), Vector3(0.14, 0.02, 0.14))
	for s in [-1.0, 1.0]:
		var ala := _pivote(g.nodo, Vector3(s * 0.07, 0.03, -0.02))
		_pieza(ala, caja, Color("b9c0c6"), Vector3(s * 0.27, 0, 0), Vector3(0.5, 0.02, 0.18))
		_pieza(ala, caja, Color("3a3d42"), Vector3(s * 0.56, 0, 0.02), Vector3(0.14, 0.021, 0.13))
		g.alas.append(ala)
	g.nodo.scale = Vector3.ONE * 0.3
	_mover_gaviota(g, 0.0, 0.0)
	var rumbo := Vector3(-sin(g.angulo), 0.0, cos(g.angulo)) * g.giro
	g.nodo.rotation.y = atan2(-rumbo.x, -rumbo.z)
	return g


# Planea en círculos amplios que se deforman despacio; solo aletea a ratos o si se espanta.
func _mover_gaviota(g: Gaviota, delta: float, susto: float) -> void:
	var reloj := mundo.tiempo + g.fase
	var orbita := g.orbita * (1.0 + 0.22 * sin(reloj * 0.17) + susto * 0.6)
	g.angulo += g.giro * g.velocidad * (1.0 + susto * 0.8) / orbita * delta
	var alto := g.alto + 0.6 * sin(reloj * 0.23) + susto * 2.5
	var centro := Vector2(cos(reloj * 0.05), sin(reloj * 0.07)) * g.orbita * 0.25
	var antes := g.nodo.position
	g.nodo.position = Vector3(centro.x + cos(g.angulo) * orbita, alto, centro.y + sin(g.angulo) * orbita)
	var paso := g.nodo.position - antes
	var plano := Vector2(paso.x, paso.z).length()
	if delta > 0.0 and plano > 0.0001:
		g.nodo.rotation.y = lerp_angle(g.nodo.rotation.y, atan2(-paso.x, -paso.z), minf(1.0, delta * 4.0))
		g.nodo.rotation.x = lerpf(g.nodo.rotation.x, clampf(atan2(paso.y, plano), -0.35, 0.35), minf(1.0, delta * 3.0))
	g.nodo.rotation.z = -g.giro * (0.22 + susto * 0.15)
	var abre := 0.1 + sin(reloj * 1.3) * 0.04
	if susto > 0.3 or sin(reloj * 0.6) > 0.55 or paso.y > delta * 0.4:
		g.ala += delta * (15.0 if susto > 0.3 else 11.0)
		abre = sin(g.ala) * 0.5
	for i in g.alas.size():
		g.alas[i].rotation.z = (-1.0 if i == 0 else 1.0) * abre


func _cangrejo(nodo: Node3D, radio: float) -> Cangrejo:
	var c := Cangrejo.new()
	c.nodo = _pivote(nodo, Vector3.ZERO)
	c.angulo = randf() * TAU
	c.distancia = radio * randf_range(0.76, 0.86)
	c.sentido = _al_azar()
	c.pausa = randf_range(0.0, 3.0)
	c.fase = randf() * TAU
	var rojo := Color("d9452b")
	_pieza(c.nodo, esfera, rojo, Vector3(0, 0.08, 0), Vector3(0.3, 0.12, 0.22))
	for s in [-1.0, 1.0]:
		_pieza(c.nodo, cilindro, rojo, Vector3(s * 0.06, 0.15, 0.07), Vector3(0.02, 0.08, 0.02))
		_pieza(c.nodo, esfera, Color("1a1a1a"), Vector3(s * 0.06, 0.2, 0.07), Vector3.ONE * 0.045)
		var pinza := _pivote(c.nodo, Vector3(s * 0.13, 0.08, 0.1))
		_pieza(pinza, esfera, Color("ef7350"), Vector3(s * 0.04, 0, 0.06), Vector3(0.1, 0.07, 0.12))
		c.pinzas.append(pinza)
		for k in 3:
			var pata := _pivote(c.nodo, Vector3(s * 0.13, 0.06, -0.06 + k * 0.06))
			_pieza(pata, caja, rojo, Vector3(s * 0.07, -0.03, 0), Vector3(0.14, 0.025, 0.025), Vector3(0, 0, -s * 0.5))
			c.patas.append(pata)
	c.nodo.scale = Vector3.ONE * 0.4
	_mover_cangrejo(c, 0.0, 0.0)
	return c


func _mover_cangrejo(c: Cangrejo, delta: float, susto: float) -> void:
	var anda := c.andar > 0.0
	if anda:
		c.andar -= delta
		c.angulo += c.sentido * (0.4 + susto * 0.6) / c.distancia * delta
		c.fase += delta * 18.0
		if c.andar <= 0.0:
			c.pausa = randf_range(0.8, 3.5)
	else:
		c.pausa -= delta * (1.0 + susto * 4.0)
		c.fase += delta * 3.0
		if c.pausa <= 0.0:
			c.andar = randf_range(0.8, 2.5)
			if randf() < 0.5:
				c.sentido = -c.sentido
	c.nodo.position = _en_anillo(c.angulo, c.distancia, ALTO_ARENA)
	c.nodo.rotation.y = _afuera(c.angulo)
	for i in c.patas.size():
		c.patas[i].rotation.y = sin(c.fase + i * 1.3) * 0.35 if anda else 0.0
	for i in c.pinzas.size():
		c.pinzas[i].rotation.x = 0.0 if anda else maxf(0.0, sin(c.fase + i)) * -0.4


func _tortuga(nodo: Node3D, radio: float, angulo: float) -> Tortuga:
	var t := Tortuga.new()
	t.nodo = _pivote(nodo, Vector3.ZERO)
	t.angulo = angulo
	t.distancia = radio * 0.82
	t.espera = randf_range(6.0, 18.0)
	t.sentido = _al_azar()
	var piel := Color("8fa66a")
	_pieza(t.nodo, esfera, Color("d8c79a"), Vector3(0, 0.03, 0), Vector3(0.5, 0.06, 0.6))
	_pieza(t.nodo, semiesfera, Color("5f7a3a"), Vector3(0, 0.02, 0), Vector3(0.52, 0.4, 0.64))
	_pieza(t.nodo, semiesfera, Color("7d9a4e"), Vector3(0, 0.03, 0), Vector3(0.36, 0.44, 0.46))
	t.cabeza = _pivote(t.nodo, Vector3(0, 0.07, 0.3))
	_pieza(t.cabeza, esfera, piel, Vector3(0, 0.02, 0.08), Vector3(0.14, 0.12, 0.18))
	for s in [-1.0, 1.0]:
		_pieza(t.cabeza, esfera, Color("1a1a1a"), Vector3(s * 0.05, 0.05, 0.13), Vector3.ONE * 0.03)
	for fila in [[0.18, Vector3(0.24, 0.03, 0.11)], [-0.22, Vector3(0.15, 0.03, 0.09)]]:
		for s in [-1.0, 1.0]:
			var largo: Vector3 = fila[1]
			var aleta := _pivote(t.nodo, Vector3(s * 0.2, 0.04, fila[0]))
			_pieza(aleta, caja, piel, Vector3(s * largo.x / 2.0, 0, 0), largo, Vector3(0, -s * 0.4, 0))
			t.aletas.append(aleta)
	t.nodo.scale = Vector3.ONE * 0.33
	t.nodo.position = _en_anillo(t.angulo, t.distancia, ALTO_ARENA)
	t.nodo.rotation.y = _afuera(t.angulo)
	return t


func _mover_tortuga(t: Tortuga, isla: Isla, delta: float) -> void:
	var r := isla.radio
	var rumbo := _afuera(t.angulo)
	var paleo := 0.0
	match t.estado:
		"sol":
			t.espera -= delta
			t.fase += delta * 1.2
			t.cabeza.rotation.x = sin(t.fase) * 0.15
			if t.espera <= 0.0 or isla.susto > 0.5:
				t.estado = "entrar"
		"entrar":
			t.distancia += (0.45 + isla.susto * 0.4) * delta
			paleo = 1.0
			if t.distancia >= r * 1.4:
				t.estado = "nadar"
				t.espera = randf_range(10.0, 20.0)
		"nadar":
			t.angulo += t.sentido * 0.35 / t.distancia * delta
			paleo = 0.6
			var avance := Vector2(-sin(t.angulo), cos(t.angulo)) * t.sentido
			rumbo = atan2(avance.x, avance.y)
			t.espera -= delta
			if t.espera <= 0.0 and isla.susto < 0.2:
				t.estado = "salir"
		"salir":
			t.distancia -= 0.35 * delta
			paleo = 1.0
			rumbo = atan2(-cos(t.angulo), -sin(t.angulo))
			if t.distancia <= r * 0.82:
				t.estado = "sol"
				t.espera = randf_range(10.0, 25.0)
	t.remo += delta * 6.0 * paleo
	var plano := _en_anillo(t.angulo, t.distancia, 0.0)
	var centro := isla.nodo.position
	var mar := mundo.altura_mar(centro.x + plano.x, centro.z + plano.z) - 0.12
	var mojada := clampf((t.distancia - r * 0.98) / (r * 0.3), 0.0, 1.0)
	t.nodo.position = Vector3(plano.x, lerpf(ALTO_ARENA, mar, mojada), plano.z)
	t.nodo.rotation.y = lerp_angle(t.nodo.rotation.y, rumbo, minf(1.0, delta * 3.0))
	for i in t.aletas.size():
		var lado := -1.0 if i % 2 == 0 else 1.0
		t.aletas[i].rotation.y = lado * sin(t.remo + (0.0 if i < 2 else PI)) * 0.5 * signf(paleo)


func _mono(palmera: Node3D) -> Mono:
	var m := Mono.new()
	m.alto = palmera.get_meta("alto")
	m.altura = m.alto
	m.espera = randf_range(2.0, 8.0)
	m.fase = randf() * TAU
	m.nodo = _pivote(palmera, Vector3.ZERO)
	var pelo := Color("6b4a2e")
	var cara := Color("d9b48a")
	_pieza(m.nodo, esfera, pelo, Vector3.ZERO, Vector3(0.22, 0.28, 0.2))
	_pieza(m.nodo, esfera, pelo, Vector3(0, 0.22, 0), Vector3.ONE * 0.19)
	_pieza(m.nodo, esfera, cara, Vector3(0, 0.21, 0.07), Vector3(0.13, 0.11, 0.08))
	for s in [-1.0, 1.0]:
		_pieza(m.nodo, esfera, cara, Vector3(s * 0.1, 0.25, 0), Vector3(0.06, 0.07, 0.03))
		_pieza(m.nodo, esfera, Color("1a1a1a"), Vector3(s * 0.035, 0.24, 0.105), Vector3.ONE * 0.03)
		var brazo := _pivote(m.nodo, Vector3(s * 0.1, 0.1, 0))
		_pieza(brazo, caja, pelo, Vector3(0, -0.1, 0), Vector3(0.06, 0.22, 0.06))
		m.brazos.append(brazo)
		var pierna := _pivote(m.nodo, Vector3(s * 0.07, -0.1, 0))
		_pieza(pierna, caja, pelo, Vector3(0, -0.09, 0), Vector3(0.07, 0.18, 0.07))
		m.piernas.append(pierna)
	_pieza(m.nodo, caja, pelo, Vector3(0, -0.12, -0.15), Vector3(0.04, 0.04, 0.3), Vector3(0.6, 0, 0))
	m.nodo.scale = Vector3.ONE * 0.4
	_mover_mono(m, 0.0, 0.0)
	return m


func _mover_mono(m: Mono, delta: float, susto: float) -> void:
	var trepa := false
	match m.estado:
		"arriba":
			m.espera -= delta
			if m.espera <= 0.0 and susto < 0.3:
				m.estado = "bajar"
				m.altura = m.alto - 0.35
		"bajar":
			m.altura -= 0.7 * delta
			trepa = true
			if susto > 0.5:
				m.estado = "subir"
			elif m.altura <= 0.35:
				m.estado = "abajo"
				m.espera = randf_range(1.5, 4.0)
		"abajo":
			m.espera -= delta
			if m.espera <= 0.0 or susto > 0.5:
				m.estado = "subir"
		"subir":
			m.altura += (0.6 + susto * 0.8) * delta
			trepa = true
			if m.altura >= m.alto - 0.35:
				m.estado = "arriba"
				m.espera = randf_range(4.0, 10.0)
	m.fase += delta * (9.0 if trepa else 2.0)
	if m.estado == "arriba":
		m.nodo.position = Vector3(0, m.alto + 0.07 + absf(sin(m.fase)) * 0.02, 0)
		m.nodo.rotation.y = 0.0
		var saluda := fmod(m.fase, 9.0) < 2.5
		for i in 2:
			m.brazos[i].rotation = Vector3(-0.3, 0, 0)
			m.piernas[i].rotation = Vector3(-1.4, 0, 0)
		if saluda:
			m.brazos[1].rotation = Vector3(-2.8, 0, sin(m.fase * 6.0) * 0.5)
	else:
		# De cara al tronco, que queda hacia su +Z.
		m.nodo.position = Vector3(0, m.altura, 0.11)
		m.nodo.rotation.y = PI
		for i in 2:
			var paso := sin(m.fase + i * PI) * 0.4 if trepa else 0.0
			m.brazos[i].rotation = Vector3(-2.4 + paso, 0, 0)
			m.piernas[i].rotation = Vector3(-0.9 - paso, 0, 0)


func _delfin(nodo: Node3D, radio: float, k: int) -> Delfin:
	var d := Delfin.new()
	d.nodo = _pivote(nodo, Vector3.ZERO)
	d.angulo = randf() * TAU + k * 0.35
	d.fase = k * 0.6
	d.orbita = radio * 2.3 + k * 0.7
	var gris := Color("6d8597")
	_pieza(d.nodo, esfera, gris, Vector3.ZERO, Vector3(0.32, 0.3, 1.2))
	_pieza(d.nodo, esfera, Color("c9d3da"), Vector3(0, -0.06, 0.02), Vector3(0.26, 0.2, 1.0))
	_pieza(d.nodo, esfera, gris, Vector3(0, -0.03, 0.62), Vector3(0.1, 0.08, 0.24))
	_pieza(d.nodo, caja, gris, Vector3(0, 0.2, -0.05), Vector3(0.04, 0.26, 0.22), Vector3(-0.5, 0, 0))
	_pieza(d.nodo, caja, gris, Vector3(0, 0, -0.6), Vector3(0.46, 0.03, 0.14))
	for s in [-1.0, 1.0]:
		_pieza(d.nodo, caja, gris, Vector3(s * 0.17, -0.08, 0.2), Vector3(0.22, 0.02, 0.1), Vector3(0, 0, -s * 0.4))
	d.nodo.scale = Vector3.ONE * 0.35
	d.nodo.visible = false
	return d


func _mover_delfin(d: Delfin, isla: Isla, delta: float) -> void:
	var antes := fmod(d.fase, CICLO_DELFIN)
	d.fase += delta
	d.angulo += isla.giro_delfines * 1.6 / d.orbita * delta
	var u := fmod(d.fase, CICLO_DELFIN)
	var plano := _en_anillo(d.angulo, d.orbita, 0.0)
	var centro := isla.nodo.position
	var mundo_plano := Vector2(centro.x + plano.x, centro.z + plano.z)
	if u < antes or (antes < 1.0 and u >= 1.0):
		mundo.salpicar(mundo_plano / Principal.ESCALA, 3)
	d.nodo.visible = u < 1.0
	if not d.nodo.visible:
		return
	var mar := mundo.altura_mar(mundo_plano.x, mundo_plano.y)
	var avance := Vector2(-sin(d.angulo), cos(d.angulo)) * isla.giro_delfines
	d.nodo.position = Vector3(plano.x, mar - 0.14 + 0.4 * sin(PI * u), plano.z)
	d.nodo.rotation = Vector3(-cos(PI * u) * 0.8, atan2(avance.x, avance.y), 0.0)


func _pez(nodo: Node3D) -> Node3D:
	var pez := _pivote(nodo, Vector3.ZERO)
	_pieza(pez, esfera, Color("9fc4d8"), Vector3.ZERO, Vector3(0.08, 0.1, 0.28))
	_pieza(pez, caja, Color("7fa6bd"), Vector3(0, 0, -0.17), Vector3(0.02, 0.12, 0.1))
	pez.scale = Vector3.ONE * 0.4
	pez.visible = false
	return pez


func _saltar_pez(isla: Isla, delta: float) -> void:
	var centro := isla.nodo.position
	if isla.salto < 0.0:
		isla.espera_pez -= delta
		if isla.espera_pez > 0.0:
			return
		var a := randf() * TAU
		isla.salto_desde = Vector2(cos(a), sin(a)) * isla.radio * randf_range(1.4, 2.2)
		isla.salto_hacia = isla.salto_desde + Vector2.from_angle(randf() * TAU) * 0.55
		isla.salto = 0.0
		isla.pez.visible = true
		mundo.salpicar((Vector2(centro.x, centro.z) + isla.salto_desde) / Principal.ESCALA, 2)
	isla.salto += delta / DURACION_SALTO
	var u := minf(isla.salto, 1.0)
	var plano := isla.salto_desde.lerp(isla.salto_hacia, u)
	var mar := mundo.altura_mar(centro.x + plano.x, centro.z + plano.y)
	isla.pez.position = Vector3(plano.x, mar - 0.04 + 0.35 * 4.0 * u * (1.0 - u), plano.y)
	var avance := isla.salto_hacia - isla.salto_desde
	isla.pez.rotation = Vector3(-atan2(1.4 * (1.0 - 2.0 * u), 0.55), atan2(avance.x, avance.y), 0.0)
	if isla.salto >= 1.0:
		isla.salto = -1.0
		isla.espera_pez = randf_range(2.0, 6.0)
		isla.pez.visible = false
		mundo.salpicar((Vector2(centro.x, centro.z) + isla.salto_hacia) / Principal.ESCALA, 3)


func _espantar(isla: Isla, delta: float) -> void:
	var centro := isla.nodo.position
	var alcance := isla.radio + ALCANCE_SUSTO
	var cerca := false
	for barco in mundo.barcos:
		if barco.viva and Vector2(barco.position.x - centro.x, barco.position.z - centro.z).length() < alcance:
			cerca = true
			break
	isla.susto = move_toward(isla.susto, 1.0 if cerca else 0.0, delta * (2.0 if cerca else 0.3))


func animar(delta: float) -> void:
	var foco := mundo.foco
	var reloj := mundo.tiempo
	for isla in islas:
		var centro := isla.nodo.position
		if Vector2(centro.x - foco.x, centro.z - foco.z).length() > DISTANCIA_ANIMAR:
			continue
		contorno = isla.contorno
		_espantar(isla, delta)
		for g in isla.gaviotas:
			_mover_gaviota(g, delta, isla.susto)
		for c in isla.cangrejos:
			_mover_cangrejo(c, delta, isla.susto)
		for t in isla.tortugas:
			_mover_tortuga(t, isla, delta)
		for m in isla.monos:
			_mover_mono(m, delta, isla.susto)
		for d in isla.delfines:
			_mover_delfin(d, isla, delta)
		_saltar_pez(isla, delta)
		for i in isla.banderas.size():
			isla.banderas[i].rotation.y = sin(reloj * 2.2 + i) * 0.3
		if not isla.llamas.is_empty():
			var chispa := 1.0 + sin(reloj * 13.0) * 0.1 + sin(reloj * 23.0) * 0.06
			isla.llamas[0].scale = Vector3(0.24, 0.36 * chispa, 0.24)
			isla.llamas[1].scale = Vector3(0.13, 0.24 * (2.0 - chispa), 0.13)
			isla.espera_humo -= delta
			if isla.espera_humo <= 0.0:
				isla.espera_humo = 0.45
				var vel := Vector3(randf_range(-0.1, 0.1), 0.6, randf_range(-0.1, 0.1))
				mundo.crear_efecto(mundo.malla_humo, Color(0.55, 0.55, 0.55, 0.4), centro + isla.fogata, vel, 2.5, 0.22, 0.9, 0.0, true)
