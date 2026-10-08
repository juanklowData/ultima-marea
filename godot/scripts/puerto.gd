class_name Puerto
extends Node3D

# Decorado del puerto del menú, hijo del nodo de su isla: lo que hay en la arena y el anillo
# de acantilados que cierra la bahía para que no se vea el mar abierto.

const ARENA := 0.45
# Centro de la bahía en el mundo, entre el barco amarrado y la isla.
const CENTRO_BAHIA := Vector3(5.0, 0.0, 1.5)
const RADIO_BAHIA := 42.0
# La boca de la bahía queda a espaldas de la cámara del menú.
const BOCA := -2.45
const ANCHO_BOCA := 0.32
const TONOS_ROCA: Array[Color] = [Color("8b8f8c"), Color("6f7472"), Color("9a9d97"), Color("5d625f"), Color("7d756a")]
const COLOR_MUSGO := Paleta.MUSGO
const COLOR_PARED := Paleta.MADERA
const COLOR_TECHO := Paleta.TEJA
const COLOR_OSCURO := Color("3c2416")
const COLOR_HIERRO := Paleta.HIERRO
const COLOR_ORO := Paleta.ORO

var mundo: Principal
var islas: Islas
var isla: Circulo
var radio := 0.0
var caja: BoxMesh
var cilindro: CylinderMesh
var esfera: SphereMesh
var semiesfera: SphereMesh
var prisma: PrismMesh
var brillo: StandardMaterial3D


func construir(nuevo_mundo: Principal, nuevas_islas: Islas, forma: Circulo, r: float) -> void:
	mundo = nuevo_mundo
	islas = nuevas_islas
	isla = forma
	radio = r
	caja = BoxMesh.new()
	cilindro = CylinderMesh.new()
	cilindro.top_radius = 0.5
	cilindro.bottom_radius = 0.5
	cilindro.height = 1.0
	cilindro.radial_segments = 10
	cilindro.rings = 1
	esfera = SphereMesh.new()
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 9
	esfera.rings = 5
	semiesfera = SphereMesh.new()
	semiesfera.radius = 0.5
	semiesfera.height = 0.5
	semiesfera.radial_segments = 12
	semiesfera.rings = 4
	semiesfera.is_hemisphere = true
	prisma = PrismMesh.new()
	brillo = StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.albedo_color = Muelle.COLOR_LUZ

	_acantilados()
	_bote(PI - 1.15)
	_carga(PI - 0.6)
	for s in [-1.0, 1.0]:
		_farol(_en_orilla(PI + s * 0.2, 0.35))
	_camino(PI, PI + 0.5)
	_cabana(PI + 0.5)
	_bandera(PI + 0.9)
	_canon(PI + 1.75)
	_cofre(PI - 1.6)


# Punto de la arena a cierta distancia hacia dentro desde la orilla.
func _en_orilla(angulo: float, adentro: float) -> Vector3:
	var lejos := radio * isla.factor(angulo) - adentro
	return Vector3(cos(angulo) * lejos, ARENA, sin(angulo) * lejos)


# Pivote en la arena con su +Z mirando al mar.
func _sitio(angulo: float, adentro: float) -> Node3D:
	var pivote := Node3D.new()
	pivote.position = _en_orilla(angulo, adentro)
	pivote.rotation.y = atan2(cos(angulo), sin(angulo))
	add_child(pivote)
	return pivote


func _pieza(padre: Node3D, malla: Mesh, color: Color, pos: Vector3, escala: Vector3, giro := Vector3.ZERO, textura := "general") -> MeshInstance3D:
	var pieza := mundo._malla(padre, malla, color, pos, textura)
	pieza.scale = escala
	pieza.rotation = giro
	return pieza


# Acantilados

func _acantilados() -> void:
	var anillo := Node3D.new()
	anillo.position = CENTRO_BAHIA - get_parent().position
	add_child(anillo)
	var angulo := BOCA + ANCHO_BOCA
	var k := 0
	while angulo < BOCA + TAU - ANCHO_BOCA:
		_pena(anillo, angulo, RADIO_BAHIA + randf_range(-1.5, 1.5), randf_range(7.0, 10.0), randf_range(4.0, 8.5), k)
		if k % 2 == 0:
			_pena(anillo, angulo + 0.06, RADIO_BAHIA + randf_range(6.0, 9.0), randf_range(10.0, 14.0), randf_range(7.0, 12.0), -1)
		# Peñascos sueltos al pie del murallón.
		if randf() < 0.6:
			var suelto := angulo + randf_range(-0.05, 0.05)
			_pena(anillo, suelto, RADIO_BAHIA - randf_range(4.0, 6.0), randf_range(1.8, 3.2), randf_range(1.2, 2.6), -1)
		angulo += randf_range(0.15, 0.2)
		k += 1
	# Las dos puntas de la boca bajan hacia el agua.
	for s in [-1.0, 1.0]:
		var punta: float = BOCA + s * (ANCHO_BOCA - 0.04)
		_pena(anillo, punta, RADIO_BAHIA - 3.0, 6.0, 4.0, -1)
		_pena(anillo, punta, RADIO_BAHIA - 7.0, 3.5, 2.0, -1)


# Una peña del acantilado; las de delante (k >= 0) a veces llevan musgo y palmeras encima.
func _pena(anillo: Node3D, angulo: float, lejos: float, ancho: float, alto: float, k: int) -> void:
	var pos := Vector3(cos(angulo) * lejos, alto * 0.18, sin(angulo) * lejos)
	var roca := _pieza(anillo, esfera, TONOS_ROCA[randi() % TONOS_ROCA.size()], pos,
		Vector3(ancho * randf_range(0.7, 0.95), alto, ancho), Vector3(randf_range(-0.12, 0.12), -angulo, randf_range(-0.12, 0.12)), "roca")
	roca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Un bulto pegado a un lado para que no parezca una bola.
	if ancho > 4.0:
		var lado := Vector3(-sin(angulo), 0, cos(angulo)) * ancho * randf_range(-0.4, 0.4)
		var bulto := _pieza(anillo, esfera, TONOS_ROCA[randi() % TONOS_ROCA.size()], pos + lado + Vector3(0, alto * 0.1, 0),
			Vector3(ancho * 0.55, alto * randf_range(0.6, 0.85), ancho * 0.6), Vector3(0, randf() * TAU, randf_range(-0.2, 0.2)), "roca")
		bulto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if k < 0 or k % 4 == 3:
		return
	var cima := pos + Vector3(0, alto * 0.42, 0)
	var musgo := _pieza(anillo, semiesfera, COLOR_MUSGO, cima - Vector3(0, alto * 0.06, 0), Vector3(ancho * 0.5, alto * 0.22, ancho * 0.62), Vector3(0, -angulo, 0), "hierba")
	musgo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if k % 3 == 0:
		var palmera := islas._palmera(anillo, cima + Vector3(0, alto * 0.03, 0), randf_range(2.2, 3.0))
		palmera.scale = Vector3.ONE * 1.8


# Arena

func _cabana(angulo: float) -> void:
	var casa := _sitio(angulo, 1.7)
	_pieza(casa, caja, COLOR_OSCURO, Vector3(0, 0.06, 0), Vector3(1.75, 0.12, 1.45), Vector3.ZERO, "madera")
	_pieza(casa, caja, COLOR_PARED, Vector3(0, 0.6, 0), Vector3(1.5, 0.95, 1.2), Vector3.ZERO, "madera")
	_pieza(casa, prisma, COLOR_PARED, Vector3(0, 1.3, 0), Vector3(1.5, 0.45, 1.2), Vector3.ZERO, "madera")
	for s in [-1.0, 1.0]:
		_pieza(casa, caja, COLOR_TECHO, Vector3(s * 0.43, 1.33, 0), Vector3(1.02, 0.07, 1.42), Vector3(0, 0, -s * 0.55))
		for z in [-0.6, 0.6]:
			_pieza(casa, caja, COLOR_OSCURO, Vector3(s * 0.74, 0.6, z), Vector3(0.1, 1.0, 0.1), Vector3.ZERO, "madera")
	_pieza(casa, caja, COLOR_OSCURO, Vector3(0, 1.56, 0), Vector3(0.08, 0.08, 1.44))
	_pieza(casa, caja, COLOR_OSCURO, Vector3(-0.3, 0.42, 0.61), Vector3(0.36, 0.62, 0.04))
	var ventana := _pieza(casa, caja, Color.WHITE, Vector3(0.38, 0.62, 0.61), Vector3(0.3, 0.24, 0.03))
	ventana.material_override = brillo
	_pieza(casa, caja, COLOR_OSCURO, Vector3(0.38, 0.47, 0.64), Vector3(0.36, 0.05, 0.06))
	# Letrero colgado junto a la puerta.
	_pieza(casa, caja, Color("c99a5e"), Vector3(-0.3, 0.86, 0.66), Vector3(0.5, 0.18, 0.03), Vector3.ZERO, "madera")
	_pieza(casa, cilindro, COLOR_PARED, Vector3(0.95, 0.2, 0.3), Vector3(0.34, 0.4, 0.34), Vector3.ZERO, "madera")


func _carga(angulo: float) -> void:
	var sitio := _sitio(angulo, 1.0)
	for pos in [Vector3(0, 0, 0), Vector3(0.42, 0, 0.1), Vector3(0.2, 0, -0.38)]:
		_pieza(sitio, cilindro, Color("8a5a32"), pos + Vector3(0, 0.25, 0), Vector3(0.38, 0.5, 0.38), Vector3.ZERO, "madera")
		for y in [0.08, 0.42]:
			_pieza(sitio, cilindro, COLOR_HIERRO, pos + Vector3(0, y, 0), Vector3(0.4, 0.04, 0.4))
	for pos in [Vector3(-0.55, 0.21, -0.1), Vector3(-0.55, 0.63, -0.08), Vector3(-0.98, 0.21, 0.05)]:
		_pieza(sitio, caja, Color("b08552"), pos, Vector3.ONE * 0.42, Vector3(0, randf_range(-0.3, 0.3), 0), "madera")
	for pos in [Vector3(0.75, 0.13, -0.25), Vector3(0.62, 0.13, 0.35)]:
		_pieza(sitio, esfera, Color("d8c69a"), pos, Vector3(0.36, 0.3, 0.3), Vector3(0, randf() * TAU, 0))


func _farol(pos: Vector3) -> void:
	_pieza(self, caja, Muelle.COLOR_PILOTE, pos + Vector3(0, 0.6, 0), Vector3(0.1, 1.2, 0.1), Vector3.ZERO, "madera")
	_pieza(self, caja, COLOR_HIERRO, pos + Vector3(0, 1.26, 0), Vector3(0.2, 0.24, 0.2))
	var luz := _pieza(self, caja, Color.WHITE, pos + Vector3(0, 1.26, 0), Vector3(0.22, 0.16, 0.22))
	luz.material_override = brillo
	_pieza(self, caja, COLOR_HIERRO, pos + Vector3(0, 1.41, 0), Vector3(0.26, 0.05, 0.26))


# Piedras planas desde el muelle hasta la puerta de la cabaña.
func _camino(desde: float, hasta: float) -> void:
	var inicio := _en_orilla(desde, 0.2)
	var fin := _en_orilla(hasta, 1.7) + Vector3(cos(hasta), 0, sin(hasta)) * 0.8
	for k in 6:
		var t := (k + 0.5) / 6.0
		var pos := inicio.lerp(fin, t) + Vector3(randf_range(-0.08, 0.08), 0.01, randf_range(-0.08, 0.08))
		_pieza(self, esfera, Color("a9a39a"), pos, Vector3(0.36, 0.06, 0.3), Vector3(0, randf() * TAU, 0), "roca")


func _bandera(angulo: float) -> void:
	var sitio := _sitio(angulo, 1.3)
	_pieza(sitio, cilindro, Muelle.COLOR_PILOTE, Vector3(0, 1.5, 0), Vector3(0.08, 3.0, 0.08), Vector3.ZERO, "madera")
	_pieza(sitio, esfera, COLOR_ORO, Vector3(0, 3.04, 0), Vector3.ONE * 0.12)
	var tela := Node3D.new()
	tela.position = Vector3(0, 2.62, 0)
	sitio.add_child(tela)
	_pieza(tela, caja, Color("161616"), Vector3(0.48, 0.0, 0), Vector3(0.9, 0.56, 0.03))
	_pieza(tela, esfera, Color("f2efe6"), Vector3(0.48, 0.07, 0.02), Vector3(0.2, 0.2, 0.04))
	for s in [-1.0, 1.0]:
		_pieza(tela, caja, Color("f2efe6"), Vector3(0.48, -0.12, 0.02), Vector3(0.36, 0.05, 0.03), Vector3(0, 0, s * 0.6))


func _canon(angulo: float) -> void:
	var sitio := _sitio(angulo, 1.0)
	_pieza(sitio, caja, COLOR_PARED, Vector3(0, 0.22, 0), Vector3(0.5, 0.18, 0.75), Vector3.ZERO, "madera")
	for s in [-1.0, 1.0]:
		for z in [-0.24, 0.24]:
			_pieza(sitio, cilindro, COLOR_OSCURO, Vector3(s * 0.28, 0.14, z), Vector3(0.26, 0.06, 0.26), Vector3(0, 0, PI / 2.0))
	_pieza(sitio, cilindro, COLOR_HIERRO, Vector3(0, 0.42, 0.12), Vector3(0.2, 1.0, 0.2), Vector3(PI / 2.0 - 0.12, 0, 0))
	_pieza(sitio, esfera, COLOR_HIERRO, Vector3(0, 0.42, -0.36), Vector3.ONE * 0.24)
	for pos in [Vector3(0.55, 0.08, -0.2), Vector3(0.7, 0.08, -0.05), Vector3(0.62, 0.21, -0.12)]:
		_pieza(sitio, esfera, COLOR_HIERRO, pos, Vector3.ONE * 0.16)


func _bote(angulo: float) -> void:
	var sitio := _sitio(angulo, 0.2)
	var bote := Node3D.new()
	bote.rotation = Vector3(0, 1.2, 0.12)
	sitio.add_child(bote)
	_pieza(bote, semiesfera, Color("7a5232"), Vector3(0, 0.2, 0), Vector3(0.7, 0.55, 1.7), Vector3(PI, 0, 0), "madera")
	_pieza(bote, caja, Color("5a3d26"), Vector3(0, 0.21, 0), Vector3(0.62, 0.03, 1.5), Vector3.ZERO, "madera")
	for z in [-0.35, 0.3]:
		_pieza(bote, caja, Color("9c7048"), Vector3(0, 0.25, z), Vector3(0.6, 0.05, 0.16), Vector3.ZERO, "madera")
	for s in [-1.0, 1.0]:
		_pieza(bote, caja, Color("c9a26e"), Vector3(s * 0.22, 0.29, 0.05), Vector3(0.05, 0.03, 1.3), Vector3(0, s * 0.15, 0), "madera")


func _cofre(angulo: float) -> void:
	var sitio := _sitio(angulo, 1.0)
	sitio.rotation.y += 0.5
	_pieza(sitio, caja, Color("7a4a26"), Vector3(0, 0.17, 0), Vector3(0.6, 0.34, 0.4), Vector3.ZERO, "madera")
	_pieza(sitio, cilindro, Color("7a4a26"), Vector3(0, 0.34, 0), Vector3(0.4, 0.6, 0.4), Vector3(0, 0, PI / 2.0), "madera")
	for x in [-0.22, 0.22]:
		_pieza(sitio, caja, COLOR_ORO, Vector3(x, 0.27, 0), Vector3(0.05, 0.4, 0.42))
	for _moneda in 6:
		var a := randf() * TAU
		_pieza(sitio, cilindro, COLOR_ORO, Vector3(cos(a) * randf_range(0.4, 0.6), 0.015, sin(a) * randf_range(0.35, 0.5)), Vector3(0.12, 0.02, 0.12), Vector3(randf_range(-0.2, 0.2), 0, 0))
