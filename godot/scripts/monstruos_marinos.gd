class_name MonstruosMarinos
extends Node3D

# Monstruos del MOBA que no son de ninguna armada y viven en guaridas junto a las islas,
# entre los carriles. Nadan alrededor de su guarida; si alguien les ataca, se revuelven contra
# él hasta que se aleja demasiado (entonces vuelven y se curan). Quien los vence se lleva oro,
# y su armada cercana, experiencia.
# Tiburones pequeños (en parejas, caen enseguida) y serpientes marinas (escupen agua).
# Dos jefes, cada uno a un lado del mapa y a la misma distancia de las dos bases: el cangrejo
# gigante y el kraken. Quien los vence se los lleva a su armada un rato: van solos contra los
# fuertes rivales más cercanos y atacan por el camino a barcos y botes enemigos.

const EQUIPO := 2
# Guaridas de una mitad del mapa; la otra mitad las tiene en espejo (salvo los jefes, que
# están uno en cada mitad).
const GUARIDAS := [
	["serpiente", Vector2(-560.0, -170.0)],
	["serpiente", Vector2(-170.0, -560.0)],
	["tiburon", Vector2(-250.0, -250.0)],
	["tiburon", Vector2(-250.0, -250.0)],
	["tiburon", Vector2(-80.0, -620.0)],
	["tiburon", Vector2(-80.0, -620.0)],
]
const GUARIDA_CANGREJO := Vector2(-420.0, -420.0)
const GUARIDA_KRAKEN := Vector2(420.0, 420.0)
# ataque: "escupir" lanza una bola de agua; el resto golpea directo a quien tenga a su alcance.
const TIPOS := {
	"tiburon": {"nombre": "Tiburón", "vida": 110.0, "danio": 6.0, "oro": 18, "xp": 12, "escala": 0.75, "radio": 22.0,
		"ataque": "morder", "alcance": 30.0, "recarga": 1.3, "corro": 35.0, "caza": 90.0, "barra": 1.6, "ancho": 36.0},
	"serpiente": {"nombre": "Serpiente marina", "vida": 320.0, "danio": 5.0, "oro": 50, "xp": 40, "escala": 1.0, "radio": 30.0,
		"ataque": "escupir", "alcance": 210.0, "recarga": 2.0, "corro": 45.0, "caza": 70.0, "barra": 2.4, "ancho": 52.0},
	"cangrejo": {"nombre": "Cangrejo gigante", "vida": 1400.0, "danio": 16.0, "oro": 150, "xp": 120, "escala": 1.0, "radio": 60.0,
		"ataque": "pinzas", "alcance": 150.0, "recarga": 1.6, "corro": 0.0, "caza": 55.0, "barra": 3.6, "ancho": 110.0,
		"jefe": true, "contra_fuerte": 45.0},
	"kraken": {"nombre": "Kraken", "vida": 1600.0, "danio": 18.0, "oro": 150, "xp": 120, "escala": 1.0, "radio": 65.0,
		"ataque": "tentaculo", "alcance": 230.0, "recarga": 2.0, "corro": 0.0, "caza": 50.0, "barra": 5.2, "ancho": 110.0,
		"jefe": true, "contra_fuerte": 55.0},
}
const VEL_NADO := 0.35
# Si su agresor se aleja más que esto de la guarida, lo deja y vuelve a casa.
const CORREA := 300.0
const CURA_EN_CASA := 0.2
const REAPARICION := 90.0
const REAPARICION_JEFE := 150.0
# Un jefe vencido lucha por la armada que lo venció este tiempo, con esta parte de su vida.
const DURACION_ALIADO := 75.0
const VIDA_ALIADO := 0.7
const VISTA_ALIADO := 120.0
const TRAMOS := 13
const SEPARACION_TRAMOS := 0.22
const TENTACULOS := 8
const JUNTAS := 8
const COLOR_PIEL := Color("2f8f7f")
const COLOR_LOMO := Color("1d5f5a")
const COLOR_MANCHA := Color("8fe0c8")
const COLOR_VIENTRE := Color("e3c27a")
const COLOR_ALETA := Color("d9a43a")
const COLOR_BARRA := Color("c38bff")
const COLOR_CANGREJO := Color("d2502e")
const COLOR_CAPARAZON := Color("9e3420")
const COLOR_KRAKEN := Color("7a3f6b")
const COLOR_VENTOSA := Color("e6a8c8")


class Monstruo:
	var tipo := ""
	var guarida := Vector2.ZERO
	var pos := Vector2.ZERO
	var rumbo := 0.0
	var vida := 0.0
	var vida_max := 0.0
	var viva := true
	var espera := 0.0
	var recarga := 0.0
	var destello := 0.0
	var furia := 0.0
	var golpe := 0.0
	var fase := 0.0
	# Armada por la que lucha un jefe vencido (-1: ninguna) y cuánto le queda.
	var aliado := -1
	var tiempo_aliado := 0.0
	# Daño continuo de la bola de fuego (ardiendo) o de las cadenas.
	var ardor := 0.0
	var ardor_danio := 0.0
	var ardor_fuego := false
	var ardor_de: Barco
	var agresor: Barco
	var nodo: Node3D
	var cabeza: Node3D
	var mandibula: Node3D
	var cola: Node3D
	var anillo: MeshInstance3D
	var anillo_materia: StandardMaterial3D
	# Anillos de la serpiente, patas del cangrejo o juntas de los tentáculos del kraken.
	var partes: Array[Node3D] = []
	# Brazos y dedos móviles de las pinzas del cangrejo.
	var brazos: Array[Node3D] = []
	var dedos: Array[Node3D] = []


var moba: Moba
var mundo: Principal
var monstruos: Array[Monstruo] = []
var esfera := SphereMesh.new()
var cono := CylinderMesh.new()
var cilindro := CylinderMesh.new()
var material_saliva: StandardMaterial3D


func preparar(nuevo_moba: Moba) -> void:
	moba = nuevo_moba
	mundo = moba.mundo
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 12
	esfera.rings = 6
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 6
	cilindro.top_radius = 0.5
	cilindro.bottom_radius = 0.5
	cilindro.height = 1.0
	cilindro.radial_segments = 8
	material_saliva = StandardMaterial3D.new()
	material_saliva.albedo_color = Color("7fe8d0")
	material_saliva.emission_enabled = true
	material_saliva.emission = Color("3fbfa0")


func empezar() -> void:
	vaciar()
	for guarida: Array in GUARIDAS:
		for punto: Vector2 in [guarida[1], -guarida[1]]:
			_crear(guarida[0], _junto_a_isla(punto, TIPOS[guarida[0]]))
	_crear("cangrejo", _junto_a_isla(GUARIDA_CANGREJO, TIPOS["cangrejo"]))
	_crear("kraken", _junto_a_isla(GUARIDA_KRAKEN, TIPOS["kraken"]))


func vaciar() -> void:
	for monstruo in monstruos:
		monstruo.nodo.queue_free()
	monstruos.clear()


func _datos(monstruo: Monstruo) -> Dictionary:
	return TIPOS[monstruo.tipo]


func _radio(monstruo: Monstruo) -> float:
	return TIPOS[monstruo.tipo]["radio"]


func es_jefe(monstruo: Monstruo) -> bool:
	return TIPOS[monstruo.tipo].get("jefe", false)


# La guarida se aparta de las islas hasta quedar pegada a su orilla, en el agua.
func _junto_a_isla(punto: Vector2, datos: Dictionary) -> Vector2:
	var radio: float = datos["radio"] + datos["corro"] + 30.0
	for _vuelta in 4:
		for isla in mundo.islas.cerca(punto, radio + 30.0):
			var sep: Vector2 = punto - isla.pos
			var minimo: float = isla.borde(punto) + radio
			if sep.length() < minimo:
				punto = isla.pos + (sep.normalized() if sep != Vector2.ZERO else Vector2.RIGHT) * minimo
	return punto


func _crear(tipo: String, guarida: Vector2) -> void:
	var datos: Dictionary = TIPOS[tipo]
	var monstruo := Monstruo.new()
	monstruo.tipo = tipo
	monstruo.guarida = guarida
	monstruo.fase = randf() * TAU
	monstruo.pos = guarida + Vector2.from_angle(monstruo.fase) * datos["corro"]
	monstruo.rumbo = randf() * TAU
	monstruo.vida_max = datos["vida"]
	monstruo.vida = monstruo.vida_max
	monstruo.nodo = Node3D.new()
	monstruo.nodo.scale = Vector3.ONE * datos["escala"]
	add_child(monstruo.nodo)
	match tipo:
		"tiburon":
			_armar_tiburon(monstruo)
		"serpiente":
			_armar_serpiente(monstruo)
		"cangrejo":
			_armar_cangrejo(monstruo)
		"kraken":
			_armar_kraken(monstruo)
	if datos.get("jefe", false):
		_crear_anillo(monstruo)
	monstruos.append(monstruo)


func _pieza(padre: Node3D, malla: Mesh, materia: Material, pos: Vector3, escala: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = materia
	pieza.position = pos
	pieza.scale = escala
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(pieza)
	return pieza


# El mismo tiburón del mar abierto, más pequeño.
func _armar_tiburon(monstruo: Monstruo) -> void:
	var modelo := Tiburones.Tiburon.new()
	mundo.tiburones._crear_modelo(modelo)
	modelo.nodo.get_parent().remove_child(modelo.nodo)
	monstruo.nodo.add_child(modelo.nodo)
	monstruo.cola = modelo.cola


# Cuerpo continuo de anillos solapados que se afinan hacia la cola: lomo oscuro con manchas
# claras, vientre dorado y una cresta de aletas finas. El cuello sube hasta la cabeza, que
# lleva ojos de reptil, cejas, dientes, mandíbula móvil, aletas a los lados y su cresta.
# Termina en una aleta de cola en abanico. Mira hacia -Z.
func _armar_serpiente(monstruo: Monstruo) -> void:
	var piel := mundo.material(COLOR_PIEL)
	var lomo := mundo.material(COLOR_LOMO)
	var vientre := mundo.material(COLOR_VIENTRE)
	var aleta := mundo.material(COLOR_ALETA)
	var mancha := mundo.material(COLOR_MANCHA)
	var hueso := mundo.material(Color("f2ead8"))
	var ultimo := TRAMOS - 1
	for k in TRAMOS:
		var tramo := Node3D.new()
		tramo.position = Vector3(0, 0, 0.3 + k * SEPARACION_TRAMOS)
		tramo.set_meta("base", 0.42 * (1.0 - smoothstep(0.0, 4.0, k)) + 0.04)
		monstruo.nodo.add_child(tramo)
		var g := lerpf(0.58, 0.16, float(k) / ultimo)
		_pieza(tramo, esfera, piel, Vector3.ZERO, Vector3(g, g * 0.9, g * 1.45))
		_pieza(tramo, esfera, lomo, Vector3(0, g * 0.2, 0), Vector3(g * 0.7, g * 0.55, g * 1.4))
		_pieza(tramo, esfera, vientre, Vector3(0, -g * 0.2, 0), Vector3(g * 0.78, g * 0.6, g * 1.3))
		if k % 2 == 1:
			for lado: float in [-1.0, 1.0]:
				_pieza(tramo, esfera, mancha, Vector3(lado * g * 0.36, g * 0.12, 0), Vector3(g * 0.22, g * 0.2, g * 0.32))
		var cresta := _pieza(tramo, cono, aleta, Vector3(0, g * 0.5, g * 0.15), Vector3(0.035, g * 0.75, g * 1.1))
		cresta.rotation.x = 0.35
		monstruo.partes.append(tramo)
	var cola := _pieza(monstruo.partes[ultimo], cono, aleta, Vector3(0, 0.02, 0.28), Vector3(0.7, 0.5, 0.04))
	cola.rotation.x = -PI / 2.0
	monstruo.cabeza = Node3D.new()
	monstruo.cabeza.position = Vector3(0, 0.5, -0.05)
	monstruo.nodo.add_child(monstruo.cabeza)
	var cabeza := monstruo.cabeza
	_pieza(cabeza, esfera, piel, Vector3.ZERO, Vector3(0.66, 0.52, 0.8))
	_pieza(cabeza, esfera, lomo, Vector3(0, 0.12, 0.04), Vector3(0.5, 0.34, 0.72))
	_pieza(cabeza, esfera, piel, Vector3(0, -0.02, -0.4), Vector3(0.46, 0.3, 0.58))
	for lado: float in [-1.0, 1.0]:
		_pieza(cabeza, esfera, lomo, Vector3(lado * 0.08, 0.06, -0.66), Vector3(0.07, 0.05, 0.06))
		_pieza(cabeza, esfera, mundo.material(Color("ffd84a")), Vector3(lado * 0.25, 0.13, -0.2), Vector3.ONE * 0.2)
		_pieza(cabeza, esfera, mundo.material(Color("141414")), Vector3(lado * 0.33, 0.13, -0.24), Vector3(0.05, 0.15, 0.06))
		_pieza(cabeza, esfera, lomo, Vector3(lado * 0.23, 0.25, -0.2), Vector3(0.18, 0.08, 0.26))
		var oreja := _pieza(cabeza, cono, aleta, Vector3(lado * 0.32, 0.05, 0.18), Vector3(0.04, 0.5, 0.4))
		oreja.rotation = Vector3(0.9, 0, -lado * 1.2)
		var cuerno := _pieza(cabeza, cono, hueso, Vector3(lado * 0.15, 0.3, 0.12), Vector3(0.08, 0.32, 0.08))
		cuerno.rotation.x = 0.8
		for m in 2:
			var diente := _pieza(cabeza, cono, hueso, Vector3(lado * (0.08 + m * 0.08), -0.15, -0.6 + m * 0.1), Vector3(0.05, 0.1, 0.05))
			diente.rotation.x = PI
	for m in 3:
		var pua := _pieza(cabeza, cono, aleta, Vector3(0, 0.3 - m * 0.04, 0.12 + m * 0.16), Vector3(0.035, 0.32 - m * 0.06, 0.24))
		pua.rotation.x = 0.4
	monstruo.mandibula = Node3D.new()
	monstruo.mandibula.position = Vector3(0, -0.14, -0.08)
	cabeza.add_child(monstruo.mandibula)
	_pieza(monstruo.mandibula, esfera, vientre, Vector3(0, -0.02, -0.3), Vector3(0.4, 0.14, 0.58))
	for lado: float in [-1.0, 1.0]:
		_pieza(monstruo.mandibula, cono, hueso, Vector3(lado * 0.1, 0.06, -0.48), Vector3(0.045, 0.09, 0.045))


# Cangrejo gigante: caparazón ancho con manchas, ojos sobre pedúnculos, seis patas a los
# lados y dos pinzas enormes delante con el dedo de arriba móvil. Mira hacia -Z.
func _armar_cangrejo(monstruo: Monstruo) -> void:
	var piel := mundo.material(COLOR_CANGREJO)
	var caparazon := mundo.material(COLOR_CAPARAZON)
	var mancha := mundo.material(Color("f08a5a"))
	var vientre := mundo.material(Color("f2d2a8"))
	var negro := mundo.material(Color("141414"))
	var blanco := mundo.material(Color("f6f1e6"))
	_pieza(monstruo.nodo, esfera, vientre, Vector3(0, 0.2, 0), Vector3(2.5, 0.7, 2.0))
	_pieza(monstruo.nodo, esfera, piel, Vector3(0, 0.42, 0), Vector3(2.6, 0.9, 2.05))
	_pieza(monstruo.nodo, esfera, caparazon, Vector3(0, 0.62, 0.05), Vector3(2.2, 0.62, 1.7))
	for k in 5:
		var a := TAU * k / 5.0
		_pieza(monstruo.nodo, esfera, mancha, Vector3(cos(a) * 0.55, 0.88, sin(a) * 0.4 + 0.05), Vector3(0.32, 0.12, 0.28))
	for k in 6:
		var pua := _pieza(monstruo.nodo, cono, caparazon, Vector3(lerpf(-1.0, 1.0, k / 5.0), 0.55, -0.98), Vector3(0.14, 0.24, 0.14))
		pua.rotation.x = -0.9
	for lado: float in [-1.0, 1.0]:
		var tallo := _pieza(monstruo.nodo, cilindro, piel, Vector3(lado * 0.32, 0.95, -0.72), Vector3(0.1, 0.5, 0.1))
		tallo.rotation.x = -0.3
		_pieza(monstruo.nodo, esfera, blanco, Vector3(lado * 0.32, 1.22, -0.8), Vector3.ONE * 0.24)
		_pieza(monstruo.nodo, esfera, negro, Vector3(lado * 0.32, 1.24, -0.9), Vector3.ONE * 0.12)
		for k in 3:
			var pata := Node3D.new()
			pata.position = Vector3(lado * 1.05, 0.35, -0.35 + k * 0.45)
			pata.rotation = Vector3(0, 0, -lado * 0.5)
			pata.set_meta("lado", lado)
			monstruo.nodo.add_child(pata)
			var muslo := _pieza(pata, cilindro, piel, Vector3(lado * 0.4, 0.15, 0), Vector3(0.16, 0.85, 0.16))
			muslo.rotation.z = -lado * 1.1
			var pie := _pieza(pata, cono, caparazon, Vector3(lado * 0.88, -0.2, 0), Vector3(0.14, 0.7, 0.14))
			pie.rotation.z = PI + lado * 0.5
			monstruo.partes.append(pata)
		var brazo := Node3D.new()
		brazo.position = Vector3(lado * 0.9, 0.5, -0.8)
		monstruo.nodo.add_child(brazo)
		_pieza(brazo, esfera, piel, Vector3(lado * 0.2, 0, -0.25), Vector3(0.38, 0.32, 0.7))
		var mano := Node3D.new()
		mano.position = Vector3(lado * 0.35, 0.1, -0.75)
		brazo.add_child(mano)
		_pieza(mano, esfera, piel, Vector3.ZERO, Vector3(0.7, 0.55, 0.85))
		_pieza(mano, esfera, caparazon, Vector3(0, 0.12, 0.05), Vector3(0.55, 0.35, 0.65))
		var abajo := _pieza(mano, cono, caparazon, Vector3(0, -0.08, -0.6), Vector3(0.28, 0.6, 0.2))
		abajo.rotation.x = -PI / 2.0
		var dedo := Node3D.new()
		dedo.position = Vector3(0, 0.12, -0.3)
		mano.add_child(dedo)
		var arriba := _pieza(dedo, cono, piel, Vector3(0, 0, -0.32), Vector3(0.26, 0.6, 0.22))
		arriba.rotation.x = -PI / 2.0
		monstruo.brazos.append(brazo)
		monstruo.dedos.append(dedo)


# Kraken: un manto alto y moteado echado hacia atrás, ojos dorados con pupila de raya y ocho
# tentáculos articulados que salen del agua y se enroscan, con ventosas por dentro.
func _armar_kraken(monstruo: Monstruo) -> void:
	var piel := mundo.material(COLOR_KRAKEN)
	var oscura := mundo.material(COLOR_KRAKEN.darkened(0.3))
	var ventosa := mundo.material(COLOR_VENTOSA)
	var mancha := mundo.material(Color("a8679a"))
	var negro := mundo.material(Color("141414"))
	var brillo := StandardMaterial3D.new()
	brillo.albedo_color = Color(1.0, 0.8, 0.25)
	brillo.emission_enabled = true
	brillo.emission = Color(1.0, 0.65, 0.1)
	monstruo.cabeza = Node3D.new()
	monstruo.nodo.add_child(monstruo.cabeza)
	var cabeza := monstruo.cabeza
	_pieza(cabeza, esfera, piel, Vector3(0, 0.45, 0.1), Vector3(2.1, 1.4, 1.9))
	var manto := _pieza(cabeza, esfera, piel, Vector3(0, 1.6, 0.75), Vector3(1.8, 2.6, 1.8))
	manto.rotation.x = 0.45
	_pieza(cabeza, esfera, oscura, Vector3(0, 2.5, 1.2), Vector3(1.2, 1.0, 1.1))
	for k in 7:
		var a := TAU * k / 7.0
		_pieza(cabeza, esfera, mancha, Vector3(cos(a) * 0.7, 1.4 + sin(a * 2.0) * 0.4, 0.6 + sin(a) * 0.65), Vector3.ONE * 0.28)
	for lado: float in [-1.0, 1.0]:
		_pieza(cabeza, esfera, oscura, Vector3(lado * 0.62, 0.95, -0.62), Vector3(0.62, 0.3, 0.5))
		_pieza(cabeza, esfera, brillo, Vector3(lado * 0.6, 0.72, -0.7), Vector3.ONE * 0.48)
		_pieza(cabeza, esfera, negro, Vector3(lado * 0.64, 0.72, -0.93), Vector3(0.08, 0.36, 0.06))
	for j in TENTACULOS:
		var a := TAU * (j + 0.5) / TENTACULOS
		var raiz := Node3D.new()
		raiz.position = Vector3(sin(a) * 1.0, 0.1, -cos(a) * 1.0)
		raiz.rotation.y = atan2(sin(a), -cos(a))
		monstruo.nodo.add_child(raiz)
		var junta := raiz
		for k in JUNTAS:
			var nueva := Node3D.new()
			nueva.position = Vector3(0, 0.0 if k == 0 else 0.38, 0)
			nueva.set_meta("k", k)
			nueva.set_meta("fase", j * 0.8)
			nueva.set_meta("delantero", j == 0 or j == TENTACULOS - 1)
			junta.add_child(nueva)
			var g := lerpf(0.5, 0.14, float(k) / (JUNTAS - 1))
			_pieza(nueva, esfera, piel, Vector3(0, 0.19, 0), Vector3(g, 0.52, g))
			if k % 2 == 1:
				_pieza(nueva, esfera, ventosa, Vector3(0, 0.19, -g * 0.42), Vector3.ONE * g * 0.4)
			monstruo.partes.append(nueva)
			junta = nueva


func _crear_anillo(monstruo: Monstruo) -> void:
	monstruo.anillo_materia = StandardMaterial3D.new()
	monstruo.anillo_materia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	monstruo.anillo_materia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	monstruo.anillo = MeshInstance3D.new()
	monstruo.anillo.mesh = moba.toro
	monstruo.anillo.material_override = monstruo.anillo_materia
	monstruo.anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var r := _radio(monstruo) * Principal.ESCALA * 1.2
	monstruo.anillo.scale = Vector3(r, 1.0, r)
	monstruo.anillo.position.y = 0.3
	monstruo.anillo.visible = false
	monstruo.nodo.add_child(monstruo.anillo)


# Comportamiento

func actualizar(delta: float) -> void:
	for monstruo in monstruos:
		if not monstruo.viva:
			monstruo.espera -= delta
			if monstruo.espera <= 0.0:
				_revivir(monstruo)
			continue
		monstruo.destello = maxf(0.0, monstruo.destello - delta * 3.0)
		monstruo.golpe = maxf(0.0, monstruo.golpe - delta)
		monstruo.recarga -= delta
		if monstruo.ardor > 0.0:
			monstruo.ardor -= delta
			if monstruo.ardor_fuego and monstruo.nodo.visible and randf() < delta * 14.0:
				var chispa := Vector3(randf_range(-0.6, 0.6), randf_range(1.0, 2.0), randf_range(-0.6, 0.6))
				mundo.crear_efecto(mundo.malla_humo, Color(1.0, randf_range(0.4, 0.75), 0.1, 0.9), mundo.a_3d(monstruo.pos, 0.8), chispa, 0.5, 0.3, 0.6)
			danar(monstruo, monstruo.ardor_danio * delta, monstruo.ardor_de)
			if not monstruo.viva:
				continue
		if monstruo.aliado >= 0:
			monstruo.tiempo_aliado -= delta
			if monstruo.tiempo_aliado <= 0.0:
				_retirar(monstruo)
				continue
			_asaltar(monstruo, delta)
		else:
			var agresor := monstruo.agresor
			if agresor != null and (not is_instance_valid(agresor) or not agresor.viva or agresor.pos.distance_to(monstruo.guarida) > CORREA \
					or moba.escondido(agresor)):
				monstruo.agresor = null
				agresor = null
			if agresor != null:
				_pelear(monstruo, agresor, delta)
			else:
				_nadar(monstruo, delta)
		_apartar_barcos(monstruo)
		_mostrar(monstruo)


func _nadar(monstruo: Monstruo, delta: float) -> void:
	monstruo.furia = maxf(0.0, monstruo.furia - delta)
	monstruo.vida = minf(monstruo.vida_max, monstruo.vida + monstruo.vida_max * CURA_EN_CASA * delta)
	var corro: float = _datos(monstruo)["corro"]
	if corro <= 0.0:
		monstruo.pos = monstruo.pos.move_toward(monstruo.guarida, 40.0 * delta)
		monstruo.rumbo += 0.12 * delta
		return
	monstruo.fase += VEL_NADO * delta * 45.0 / corro
	var meta := monstruo.guarida + Vector2.from_angle(monstruo.fase) * corro
	var hacia := meta - monstruo.pos
	if hacia.length() > 1.0:
		monstruo.rumbo = lerp_angle(monstruo.rumbo, atan2(hacia.x, -hacia.y), minf(1.0, delta * 3.0))
		monstruo.pos = monstruo.pos.move_toward(meta, maxf(VEL_NADO * 45.0, hacia.length() * 0.8) * delta)


func _pelear(monstruo: Monstruo, agresor: Barco, delta: float) -> void:
	var datos := _datos(monstruo)
	monstruo.furia = minf(1.0, monstruo.furia + delta * 3.0)
	var hacia := agresor.pos - monstruo.pos
	monstruo.rumbo = lerp_angle(monstruo.rumbo, atan2(hacia.x, -hacia.y), minf(1.0, delta * 4.0))
	var alcance: float = datos["alcance"] + _radio(monstruo) + agresor.radio * 0.6
	var distancia := hacia.length()
	if distancia > alcance * 0.75 and monstruo.pos.distance_to(monstruo.guarida) < CORREA * 0.6:
		monstruo.pos += hacia.normalized() * datos["caza"] * delta
	if distancia < alcance and monstruo.recarga <= 0.0:
		monstruo.recarga = datos["recarga"]
		_atacar(monstruo, agresor)


# Jefe aliado: va hacia el fuerte rival vulnerable más cercano y lo golpea; si por el camino
# tiene cerca barcos o botes enemigos, se ocupa antes de ellos.
func _asaltar(monstruo: Monstruo, delta: float) -> void:
	var datos := _datos(monstruo)
	monstruo.furia = minf(1.0, monstruo.furia + delta * 2.0)
	var blanco = _blanco_aliado(monstruo)
	if blanco == null:
		return
	var punto: Vector2 = blanco.pos
	var hueco: float = _radio(monstruo) + (blanco.isla.radio if blanco is Moba.Torre else blanco.radio * 0.6 if blanco is Barco else Moba.RADIO_BOTE)
	var hacia := punto - monstruo.pos
	monstruo.rumbo = lerp_angle(monstruo.rumbo, atan2(hacia.x, -hacia.y), minf(1.0, delta * 3.0))
	var alcance: float = datos["alcance"] + hueco
	if hacia.length() > alcance * 0.8:
		_avanzar(monstruo, punto, datos["caza"] * 1.3, delta)
	elif monstruo.recarga <= 0.0:
		monstruo.recarga = datos["recarga"]
		_atacar(monstruo, blanco)


func _blanco_aliado(monstruo: Monstruo):
	var vista: float = _datos(monstruo)["alcance"] + _radio(monstruo) + VISTA_ALIADO
	var mejor = null
	var menor := vista
	for heroe in moba.heroes:
		var barco := heroe.barco
		if heroe.equipo != monstruo.aliado and barco.viva and not moba.escondido(barco) and barco.pos.distance_to(monstruo.pos) < menor:
			menor = barco.pos.distance_to(monstruo.pos)
			mejor = barco
	for bote in moba.botes:
		if bote.equipo != monstruo.aliado and bote.pos.distance_to(monstruo.pos) < menor:
			menor = bote.pos.distance_to(monstruo.pos)
			mejor = bote
	if mejor != null:
		return mejor
	menor = INF
	for torre in moba.torres:
		if torre.viva and torre.equipo != monstruo.aliado and moba.vulnerable(torre) and torre.pos.distance_to(monstruo.pos) < menor:
			menor = torre.pos.distance_to(monstruo.pos)
			mejor = torre
	return mejor


# Avanza hacia un punto rodeando las islas que se cruzan.
func _avanzar(monstruo: Monstruo, destino: Vector2, velocidad: float, delta: float) -> void:
	var radio := _radio(monstruo)
	var avance := (destino - monstruo.pos).normalized()
	for isla in mundo.islas.cerca(monstruo.pos, radio + 60.0):
		var sep: Vector2 = monstruo.pos - isla.pos
		var limite: float = isla.radio + radio + 60.0
		var d := sep.length()
		if d < limite and d > 0.0 and avance.dot(-sep / d) > 0.0:
			avance += sep / d * (1.0 - d / limite) * 2.0
	monstruo.pos += avance.normalized() * velocidad * delta
	for isla in mundo.islas.cerca(monstruo.pos, radio):
		var sep: Vector2 = monstruo.pos - isla.pos
		var minimo: float = isla.borde(monstruo.pos) + radio
		if sep.length() < minimo and sep != Vector2.ZERO:
			monstruo.pos = isla.pos + sep.normalized() * minimo


func _atacar(monstruo: Monstruo, blanco) -> void:
	var datos := _datos(monstruo)
	monstruo.golpe = 0.45
	if datos["ataque"] == "escupir":
		_escupir(monstruo, blanco)
		return
	var punto: Vector2 = blanco.pos
	var danio: float = datos["danio"]
	if blanco is Moba.Torre:
		blanco.vida -= datos.get("contra_fuerte", danio)
		blanco.destello = 1.0
		mundo.astillas(mundo.a_3d(punto, 1.5))
		if blanco.vida <= 0.0:
			moba._derribar(blanco)
	elif blanco is Barco:
		blanco.recibir_danio(danio, true, null)
		if blanco.es_jugador:
			mundo.golpe = 0.22
			mundo.avisar_combate()
	elif blanco is Moba.Bote:
		blanco.vida -= danio * 2.0
		blanco.destello = 1.0
		if blanco.vida <= 0.0:
			var i := moba.botes.find(blanco)
			if i >= 0:
				moba._hundir_bote(i, null)
	mundo.salpicar(punto, 8 if es_jefe(monstruo) else 4)
	if datos["ataque"] == "tentaculo":
		var centro := mundo.a_3d(punto, 0.6)
		for _i in 6:
			var gota := Vector3(randf_range(-2.0, 2.0), randf_range(2.0, 4.0), randf_range(-2.0, 2.0))
			mundo.crear_efecto(mundo.malla_gota, Color(COLOR_VENTOSA, 0.9), centro, gota, 1.0, 1.2, 0.0, 9.0)
	if es_jefe(monstruo):
		mundo._sonar_en_vista(mundo.voces_explosion, mundo.a_3d(punto), -10.0, -26.0, 50.0)


func _escupir(monstruo: Monstruo, blanco) -> void:
	var desde := monstruo.pos
	var previsto: Vector2 = blanco.pos
	if blanco is Barco:
		previsto += blanco.proa() * blanco.velocidad * desde.distance_to(blanco.pos) / Principal.VEL_BALA * 0.5
	var direccion := (previsto - desde).normalized()
	var radio := _radio(monstruo)
	var bala := mundo.disparar_desde(desde + direccion * (radio + 6.0), direccion, null, null, EQUIPO, _datos(monstruo)["danio"])
	bala.nodo.material_override = material_saliva
	bala.nodo.scale = Vector3.ONE * 1.4
	mundo.salpicar(desde + direccion * radio, 3)


func _apartar_barcos(monstruo: Monstruo) -> void:
	var radio := _radio(monstruo)
	for heroe in moba.heroes:
		var barco := heroe.barco
		if not barco.viva:
			continue
		var sep := barco.pos - monstruo.pos
		var minimo := radio + barco.radio * 0.6
		if sep.length() < minimo:
			barco.pos = monstruo.pos + (sep.normalized() if sep != Vector2.ZERO else Vector2.RIGHT) * minimo


# Animación

func _mostrar(monstruo: Monstruo) -> void:
	var nodo := monstruo.nodo
	nodo.visible = mundo.a_3d(monstruo.pos).distance_to(Vector3(mundo.foco.x, 0.0, mundo.foco.z)) < mundo.alcance_vista() + 6.0
	if not nodo.visible:
		return
	var sitio := mundo.a_3d(monstruo.pos)
	var t := mundo.tiempo * (1.0 + monstruo.furia * 0.6) + monstruo.fase
	var hundido: float = {"tiburon": -0.1, "serpiente": -0.25, "cangrejo": -0.25, "kraken": -0.35}[monstruo.tipo]
	nodo.position = Vector3(sitio.x, mundo.altura_mar(sitio.x, sitio.z) + hundido, sitio.z)
	nodo.rotation.y = -monstruo.rumbo
	if monstruo.anillo != null:
		monstruo.anillo.visible = monstruo.aliado >= 0
		if monstruo.aliado >= 0:
			monstruo.anillo_materia.albedo_color = Color(Moba.COLORES[monstruo.aliado], 0.55 + 0.25 * sin(mundo.tiempo * 4.0))
	match monstruo.tipo:
		"tiburon":
			monstruo.cola.rotation.y = sin(t * (6.0 + monstruo.furia * 6.0)) * 0.35
			nodo.rotation.z = sin(t * 1.3) * 0.06
		"serpiente":
			_animar_serpiente(monstruo, t)
		"cangrejo":
			_animar_cangrejo(monstruo, t)
		"kraken":
			_animar_kraken(monstruo, t)


func _animar_serpiente(monstruo: Monstruo, t: float) -> void:
	var ultimo := monstruo.partes.size() - 1
	for k in monstruo.partes.size():
		var tramo := monstruo.partes[k]
		var cuerpo := minf(1.0, k / 3.0)
		tramo.position.y = tramo.get_meta("base") + monstruo.furia * 0.3 * (1.0 - cuerpo) + sin(t * 3.0 - k * 0.5) * 0.16 * cuerpo
		tramo.position.x = sin(t * 1.6 - k * 0.4) * 0.14 * k / ultimo
	var escupe := monstruo.golpe > 0.15
	monstruo.cabeza.position.y = 0.5 + monstruo.furia * 0.3 + sin(t * 2.0) * 0.06
	monstruo.cabeza.rotation.x = -monstruo.furia * 0.2 + sin(t * 2.0) * 0.05 + (0.25 if escupe else 0.0)
	monstruo.cabeza.rotation.z = sin(t * 1.3) * 0.1
	monstruo.mandibula.rotation.x = 0.55 if escupe else 0.06 + monstruo.furia * 0.12 + sin(t * 2.4) * 0.04


func _animar_cangrejo(monstruo: Monstruo, t: float) -> void:
	monstruo.nodo.position.y += sin(t * 1.8) * 0.05
	for k in monstruo.partes.size():
		var pata := monstruo.partes[k]
		var lado: float = pata.get_meta("lado")
		pata.rotation.x = sin(t * (3.0 + monstruo.furia * 5.0) + k * 1.3) * 0.25
		pata.rotation.z = -lado * (0.5 + sin(t * 2.0 + k) * 0.08)
	var alzada := monstruo.furia * 0.45 + (0.6 * sin(monstruo.golpe / 0.45 * PI) if monstruo.golpe > 0.0 else 0.0)
	for k in monstruo.brazos.size():
		monstruo.brazos[k].rotation.x = alzada + sin(t * 1.5 + k) * 0.08
		var abre := 0.55 if monstruo.golpe > 0.2 else (0.25 + sin(t * 4.0 + k) * 0.2) * monstruo.furia + 0.05
		monstruo.dedos[k].rotation.x = abre


func _animar_kraken(monstruo: Monstruo, t: float) -> void:
	monstruo.cabeza.rotation.x = sin(t * 0.9) * 0.06 - monstruo.furia * 0.08
	monstruo.cabeza.position.y = sin(t * 1.2) * 0.08 + monstruo.furia * 0.2
	var azote := sin(monstruo.golpe / 0.45 * PI) if monstruo.golpe > 0.0 else 0.0
	for junta in monstruo.partes:
		var k: int = junta.get_meta("k")
		var fase: float = junta.get_meta("fase")
		var curva := 0.55 if k == 0 else 0.16 + monstruo.furia * 0.06
		if junta.get_meta("delantero"):
			curva -= azote * (0.9 if k == 0 else 0.12)
		junta.rotation.x = curva + sin(t * 2.0 + fase - k * 0.55) * (0.08 if k == 0 else 0.22)
		junta.rotation.z = sin(t * 1.3 + fase + k * 0.3) * 0.1


# Vida y daño

func _revivir(monstruo: Monstruo) -> void:
	monstruo.viva = true
	monstruo.vida = monstruo.vida_max
	monstruo.pos = monstruo.guarida
	monstruo.agresor = null
	monstruo.aliado = -1
	monstruo.furia = 0.0
	monstruo.ardor = 0.0
	monstruo.nodo.visible = true
	mundo.salpicar(monstruo.pos, 10)


# Puede recibir daño de ese equipo: los neutrales, de cualquiera menos de sí mismos; un jefe
# aliado, solo de la armada rival.
func _atacable(monstruo: Monstruo, equipo: int) -> bool:
	if not monstruo.viva:
		return false
	if monstruo.aliado >= 0:
		return equipo >= 0 and equipo != monstruo.aliado and equipo != EQUIPO
	return equipo != EQUIPO


# Balas que alcanzan a un monstruo; devuelve true si la bala se detiene.
func recibir_bala(bala: Principal.Bala) -> bool:
	for monstruo in monstruos:
		if _atacable(monstruo, bala.equipo) and monstruo.pos.distance_to(bala.pos) < _radio(monstruo) + 4.0:
			danar(monstruo, mundo._danio_bala(bala), bala.dueno)
			mundo.salpicar(bala.pos, 4)
			if monstruo.viva and bala.tipo == "bola_fuego":
				_encender(monstruo, Comercio.DURACION_FUEGO, Comercio.DANIO_FUEGO, true, bala.dueno)
			elif monstruo.viva and bala.tipo == "cadenas":
				_encender(monstruo, Moba.DURACION_ATRAPADO, Moba.DANIO_ATRAPADO, false, bala.dueno)
			return true
	return false


func _encender(monstruo: Monstruo, dura: float, por_segundo: float, fuego: bool, atacante: Barco) -> void:
	monstruo.ardor = dura
	monstruo.ardor_danio = por_segundo * (atacante.factor_danio if is_instance_valid(atacante) else 1.0)
	monstruo.ardor_fuego = fuego
	monstruo.ardor_de = atacante


# Monstruos que puede dañar ese equipo cerca de un punto.
func vivos_cerca(punto: Vector2, alcance: float, equipo: int) -> Array[Monstruo]:
	var lista: Array[Monstruo] = []
	for monstruo in monstruos:
		if _atacable(monstruo, equipo) and monstruo.pos.distance_to(punto) < alcance + _radio(monstruo):
			lista.append(monstruo)
	return lista


# Daño de habilidades en área.
func danar_zona(centro: Vector2, alcance: float, cantidad: float, atacante: Barco) -> void:
	for monstruo in vivos_cerca(centro, alcance, atacante.equipo):
		danar(monstruo, cantidad, atacante)


# Jefe aliado de una armada a tiro de un fuerte de la otra (para que el fuerte le dispare).
func aliado_rival_cerca(punto: Vector2, alcance: float, equipo: int) -> Monstruo:
	for monstruo in monstruos:
		if monstruo.viva and monstruo.aliado >= 0 and monstruo.aliado != equipo and monstruo.pos.distance_to(punto) < alcance:
			return monstruo
	return null


func danar(monstruo: Monstruo, cantidad: float, atacante: Barco) -> void:
	monstruo.vida -= cantidad
	monstruo.destello = 1.0
	if monstruo.aliado < 0 and is_instance_valid(atacante) and atacante.viva:
		monstruo.agresor = atacante
	if monstruo.vida <= 0.0:
		_vencer(monstruo, atacante)


func _vencer(monstruo: Monstruo, verdugo: Barco) -> void:
	var datos := _datos(monstruo)
	var cazador: Moba.Heroe = moba.de_barco.get(verdugo) if is_instance_valid(verdugo) else null
	if monstruo.aliado >= 0:
		_retirar(monstruo)
		if cazador != null:
			moba._ganar_oro(cazador, datos["oro"] / 2, mundo.a_3d(monstruo.pos, 3.0))
		return
	monstruo.agresor = null
	monstruo.ardor = 0.0
	_estallar(monstruo)
	if cazador != null:
		moba._ganar_oro(cazador, datos["oro"], mundo.a_3d(monstruo.pos, 2.0))
		for heroe in moba.heroes:
			if heroe.equipo == cazador.equipo and heroe.barco.viva and heroe.barco.pos.distance_to(monstruo.pos) < Moba.ALCANCE_XP:
				moba._ganar_xp(heroe, datos["xp"])
	if es_jefe(monstruo) and cazador != null:
		monstruo.aliado = cazador.equipo
		monstruo.tiempo_aliado = DURACION_ALIADO
		monstruo.vida = monstruo.vida_max * VIDA_ALIADO
		monstruo.furia = 1.0
		var nombre := tr(datos["nombre"])
		var propio := moba.heroe_jugador()
		if propio != null and cazador.equipo == propio.equipo:
			moba._anunciar(tr("¡El %s lucha por tu armada!") % nombre, Principal.COLOR_ORO)
		else:
			moba._anunciar(tr("¡El %s lucha por la armada enemiga!") % nombre, Principal.COLOR_PELIGRO)
		return
	monstruo.viva = false
	monstruo.vida = 0.0
	monstruo.espera = REAPARICION_JEFE if es_jefe(monstruo) else REAPARICION
	monstruo.nodo.visible = false
	if verdugo == mundo.jugador and monstruo.tipo == "serpiente":
		moba._anunciar(tr("¡%s derrotada!") % tr(datos["nombre"]), Principal.COLOR_ORO)


# El jefe aliado se hunde (vencido o porque se le acabó el tiempo) y vuelve más tarde a su guarida.
func _retirar(monstruo: Monstruo) -> void:
	_estallar(monstruo)
	var propia := moba.heroe_jugador() != null and monstruo.aliado == moba.heroe_jugador().equipo
	moba._anunciar(tr("El %s vuelve a las profundidades") % tr(_datos(monstruo)["nombre"]), Moba.COLOR_NOMBRE_ALIADO if propia else Color(1, 1, 1, 0.9))
	monstruo.viva = false
	monstruo.vida = 0.0
	monstruo.aliado = -1
	monstruo.agresor = null
	monstruo.ardor = 0.0
	monstruo.espera = REAPARICION_JEFE
	monstruo.nodo.visible = false


func _estallar(monstruo: Monstruo) -> void:
	var grande := 2.0 if es_jefe(monstruo) else 1.0
	mundo.salpicar(monstruo.pos, int(16 * grande))
	var color: Color = {"tiburon": Color("9fb4c0"), "serpiente": COLOR_PIEL.lightened(0.3), "cangrejo": COLOR_CANGREJO.lightened(0.2), "kraken": COLOR_VENTOSA}[monstruo.tipo]
	var centro := mundo.a_3d(monstruo.pos, 0.6)
	for _i in int(10 * grande):
		var vel := Vector3(randf_range(-1.6, 1.6), randf_range(2.0, 4.0), randf_range(-1.6, 1.6)) * grande
		mundo.crear_efecto(mundo.malla_gota, Color(color, 0.9), centro, vel, 1.0, 1.4 * grande, 0.0, 9.0)


# Dibujo

# Barra de vida sobre cada monstruo a la vista; los jefes llevan además su nombre y, si
# luchan por una armada, la barra es de su color.
func dibujar(lienzo: Control, camara: Camera3D) -> void:
	var fuente := ThemeDB.fallback_font
	for monstruo in monstruos:
		if not monstruo.viva or not monstruo.nodo.visible:
			continue
		var datos := _datos(monstruo)
		var punto := mundo.a_3d(monstruo.pos, datos["barra"] * datos["escala"])
		if camara.is_position_behind(punto):
			continue
		var pantalla := camara.unproject_position(punto)
		var color := Moba.COLORES[monstruo.aliado] if monstruo.aliado >= 0 else COLOR_BARRA
		moba._barra(lienzo, pantalla, datos["ancho"], monstruo.vida / monstruo.vida_max, color, monstruo.destello)
		if es_jefe(monstruo):
			var nombre := tr(datos["nombre"])
			if monstruo.aliado >= 0:
				nombre += "  %d s" % ceili(monstruo.tiempo_aliado)
			var ancho := fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			var base := pantalla + Vector2(-ancho / 2.0, -11.0)
			lienzo.draw_string_outline(fuente, base, nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color(0, 0, 0, 0.8))
			lienzo.draw_string(fuente, base, nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color.lightened(0.3))


func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	for monstruo in monstruos:
		var jefe := es_jefe(monstruo)
		var color: Color = {"tiburon": Color("9fb4c0"), "serpiente": COLOR_BARRA, "cangrejo": Color("ff7a45"), "kraken": Color("d070c0")}[monstruo.tipo]
		if monstruo.viva and monstruo.aliado >= 0:
			var punto := centro + monstruo.pos * escala
			lienzo.draw_circle(punto, 6.5, Color("08161c"))
			lienzo.draw_circle(punto, 5.0, Moba.COLORES[monstruo.aliado])
			lienzo.draw_circle(punto, 2.2, color)
			continue
		var punto := centro + monstruo.guarida * escala
		var r := 5.5 if jefe else 3.0 if monstruo.tipo == "serpiente" else 2.2
		if monstruo.viva:
			lienzo.draw_circle(punto, r + 1.3, Color("08161c"))
			lienzo.draw_circle(punto, r, color)
		else:
			lienzo.draw_arc(punto, r, 0.0, TAU, 12, Color(color, 0.45), 1.5, true)
