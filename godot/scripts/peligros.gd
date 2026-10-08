class_name Peligros
extends Node3D

# Remolinos y krakens. Se mueven muy despacio, en unidades del mapa 2D como los barcos.

const SHADER_REMOLINO := preload("res://shaders/remolino.gdshader")
const SHADER_TENTACULO := preload("res://shaders/tentaculo.gdshader")
const SHADER_KRAKEN := preload("res://shaders/kraken.gdshader")
const SHADER_RACHA := preload("res://shaders/racha.gdshader")

const TOTAL_REMOLINOS := 9
const TOTAL_KRAKENS := 3
# Cuántos remolinos (los más cercanos a la cámara) hunden la malla del agua.
const REMOLINOS_EN_AGUA := 6
# Con la zona más chica que esto los peligros se retiran para no arruinar el final.
const ZONA_RETIRADA := 700.0
const VEL_REMOLINO := 6.0
const ARRASTRE_GIRO := 62.0
const ARRASTRE_CENTRO := 26.0
const DANIO_REMOLINO := 12.0
const HONDURA_REMOLINO := 0.24
# Los remolinos se buscan poco a poco; si dos se juntan nace un tornado pequeño que daña más.
const ATRACCION_REMOLINOS := 1100.0
const SHADER_TORNADO := preload("res://shaders/tornado.gdshader")
const MAX_TORNADOS := 2
const RADIO_TORNADO := 46.0
const VEL_TORNADO := 16.0
const DURACION_TORNADO := 35.0
const DANIO_TORNADO := 18.0
const ARRASTRE_TORNADO := 24.0
const GIRO_TORNADO := 120.0
const ALTO_TORNADO := 5.5

const VEL_KRAKEN := 16.0
# Escala del modelo 3D; los radios de juego van en proporción.
const TAM_KRAKEN := 0.45
const RADIO_KRAKEN := 28.0
const ALCANCE_KRAKEN := 125.0
# Cada kraken patrulla una zona amplia alrededor de su sitio y solo va a por los barcos que
# pasan cerca; la emboscada a un barco malherido sí lo lleva lejos y allí queda su nueva zona.
const ZONA_KRAKEN := 300.0
# Distancia mínima entre los sitios de dos krakens y a los barcos al aparecer.
const SEPARACION_KRAKENS := 1300.0
const LEJOS_KRAKEN := 650.0
const ALERTA_KRAKEN := 200.0
const VISTA_KRAKEN := 1100.0
const VIDA_KRAKEN := 176.0
const DANIO_TENTACULO := 16.0
const RADIO_GOLPE := 27.0
# Al vencerlo: monedas para quien lo hunde y cofres flotando para quien llegue antes.
const MONEDAS_KRAKEN := 2
const COFRES_KRAKEN := 2
const DURACION_AGONIA := 2.6
const ESPERA_ATAQUE := 3.0
const DURACION_ATAQUE := 2.4
# Al emerger junto a un barco, el primer golpe tarda más para que pueda escapar.
const ESPERA_EMERGER := 1.6
const LENTITUD_EMERGER := 1.8
# Emboscada: el kraken se esconde y emerge junto a un barco que ya va a media vida o menos.
const VIDA_PRESA := 0.5
const ALCANCE_EMBOSCADA := 1500.0
const ESCONDIDO := 3.5
const ESPERA_EMBOSCADA := Vector2(16.0, 26.0)
# Agarre: el tentáculo sujeta el barco y no lo deja moverse.
const DURACION_AGARRE := 3.0
const DANIO_AGARRE := 4.0
const PROBABILIDAD_AGARRE := 0.3
# Fracciones del ataque: apunta mientras carga, el látigo cae en MOMENTO_GOLPE,
# se queda arrastrando hasta FIN_ARRASTRE y luego se recoge.
const FIN_PUNTERIA := 0.35
const INICIO_LATIGO := 0.5
const MOMENTO_GOLPE := 0.6
const FIN_ARRASTRE := 0.78
const TENTACULOS := 8
const RAIZ_TENTACULO := 1.5
# Ventiscas: zonas de viento que empujan y, a favor, aceleran por encima del máximo.
const TOTAL_VENTISCAS := 7
const VEL_VENTISCA := 9.0
const EMPUJE_VIENTO := 34.0
const IMPULSO_VIENTO := 26.0
const TOPE_VIENTO := 1.45
const RACHAS := 22
const VEL_RACHA := 9.0


class Remolino:
	var pos := Vector2.ZERO
	var radio := 55.0
	var giro := 1.0
	var rumbo := 0.0
	var fase := 0.0
	var fuerza := 1.0
	var espera_gotas := 0.0
	# Segundos que sigue fundido en un tornado; al acabar reaparece en otro sitio.
	var fundido := 0.0
	var nodo: MeshInstance3D
	var materia: ShaderMaterial


class Tornado:
	var pos := Vector2.ZERO
	var radio := RADIO_TORNADO
	var giro := 1.0
	var rumbo := 0.0
	var fase := 0.0
	var fuerza := 0.0
	var vida := DURACION_TORNADO
	var espera_gotas := 0.0
	var nodo: Node3D
	var capas: Array[ShaderMaterial] = []

class Kraken:
	var pos := Vector2.ZERO
	var hogar := Vector2.ZERO
	var rumbo_a := Vector2.ZERO
	var radio := RADIO_KRAKEN
	var rumbo := 0.0
	var mirada := 0.0
	var fase := 0.0
	var vida := VIDA_KRAKEN
	var fuerza := 1.0
	var sumergido := 0.0
	var espera := ESPERA_ATAQUE
	var ataque := -1.0
	var duracion_ataque := DURACION_ATAQUE
	var recien_emergido := false
	var tentaculo := 0
	var blanco: Barco
	var punto_golpe := Vector2.ZERO
	var golpeado := false
	var destello := 0.0
	var parpadeo := 3.0
	var espera_espuma := 0.0
	var espera_rugido := 0.0
	var altura := 0.0
	var nodo: Node3D
	var cuerpo: MeshInstance3D
	var piel: ShaderMaterial
	var ojos: Array[Node3D] = []
	var tentaculos: Array[MeshInstance3D] = []
	var materiales: Array[ShaderMaterial] = []
	var angulos: Array[float] = []
	var largos: Array[float] = []
	var fases: Array[float] = []
	# Pose actual de cada tentáculo (inclinación, curva, punta, largo) y su giro;
	# se acercan a la pose deseada con suavidad para que nada salte.
	var poses: Array[Vector4] = []
	var giros: Array[float] = []
	var embestida := 0.0
	# Segundos desde que lo vencieron (-1 mientras vive). Vencido no vuelve en la partida.
	var agonia := -1.0
	var aviso: MeshInstance3D
	var aviso_materia: StandardMaterial3D
	var aviso_espuma: StandardMaterial3D
	var espera_emboscada := randf_range(ESPERA_EMBOSCADA.x, ESPERA_EMBOSCADA.y) * 0.5
	# Barco tras el que va escondido; al emerger ataca enseguida y su golpe agarra.
	var presa: Barco
	var emboscada := false
	var agarra_al_golpe := false
	var agarrado: Barco
	var agarre := 0.0
	var pos_agarre := Vector2.ZERO


class Ventisca:
	var pos := Vector2.ZERO
	var radio := 110.0
	var rumbo := 0.0
	var fase := 0.0
	var fuerza := 1.0
	var nodo: MultiMeshInstance3D
	# Por racha: x e y relativas al centro en unidades de radio, altura y velocidad.
	var rachas: Array[Vector4] = []


var mundo: Principal
var remolinos: Array = []
var tornados: Array = []
var krakens: Array = []
var ventiscas: Array = []
var material_racha: ShaderMaterial
var ahuyentados := 0
var activos := true
var malla_tentaculo: CylinderMesh
var rumor: AudioStreamPlayer
var aullido: AudioStreamPlayer
var voz_kraken: AudioStreamPlayer


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	malla_tentaculo = CylinderMesh.new()
	malla_tentaculo.top_radius = 1.0
	malla_tentaculo.bottom_radius = 1.0
	malla_tentaculo.height = 1.0
	malla_tentaculo.radial_segments = 14
	malla_tentaculo.rings = 48
	malla_tentaculo.cap_top = false
	malla_tentaculo.cap_bottom = false

	rumor = AudioStreamPlayer.new()
	rumor.stream = Sonidos.rumor_remolino()
	rumor.bus = "Efectos"
	rumor.volume_db = -60.0
	add_child(rumor)
	aullido = AudioStreamPlayer.new()
	aullido.stream = Sonidos.viento_tornado()
	aullido.bus = "Efectos"
	aullido.volume_db = -60.0
	add_child(aullido)
	voz_kraken = AudioStreamPlayer.new()
	voz_kraken.stream = load("res://sonidos/kraken.wav")
	voz_kraken.bus = "Efectos"
	add_child(voz_kraken)
	material_racha = ShaderMaterial.new()
	material_racha.shader = SHADER_RACHA


func vaciar() -> void:
	for remolino in remolinos:
		remolino.nodo.queue_free()
	for tornado in tornados:
		tornado.nodo.queue_free()
	for kraken in krakens:
		kraken.nodo.queue_free()
		kraken.aviso.queue_free()
	for ventisca in ventiscas:
		ventisca.nodo.queue_free()
	remolinos.clear()
	tornados.clear()
	krakens.clear()
	ventiscas.clear()
	ahuyentados = 0
	activos = true


func reiniciar() -> void:
	vaciar()
	for _i in TOTAL_REMOLINOS:
		var remolino := Remolino.new()
		remolino.radio = randf_range(45.0, 65.0)
		remolino.pos = _lugar_libre(remolino.radio + 40.0, mundo.alcance_juego() * 0.85)
		remolino.giro = 1.0 if randf() < 0.5 else -1.0
		remolino.rumbo = randf() * TAU
		remolino.fase = randf() * 100.0
		_crear_remolino(remolino)
		remolinos.append(remolino)
	for _i in TOTAL_KRAKENS:
		var kraken := Kraken.new()
		kraken.pos = lugar_kraken(kraken, mundo.alcance_juego() * 0.8)
		kraken.hogar = kraken.pos
		kraken.rumbo_a = kraken.pos
		kraken.rumbo = randf() * TAU
		kraken.mirada = kraken.rumbo
		kraken.fase = randf() * 100.0
		kraken.espera_rugido = randf_range(0.0, 6.0)
		_crear_kraken(kraken)
		krakens.append(kraken)
	for _i in TOTAL_VENTISCAS:
		var ventisca := Ventisca.new()
		ventisca.radio = randf_range(90.0, 130.0)
		ventisca.pos = _lugar_libre(ventisca.radio, mundo.alcance_juego() * 0.85)
		ventisca.rumbo = randf() * TAU
		ventisca.fase = randf() * 100.0
		_crear_ventisca(ventisca)
		ventiscas.append(ventisca)


func _lugar_libre(margen: float, alcance: float, lejos_de_barcos := 0.0) -> Vector2:
	var punto := Vector2.ZERO
	var separacion := 450.0 if mundo.modo == "libre" else 650.0
	for _intento in 60:
		punto = mundo.centro_juego() + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * alcance
		var libre := true
		for isla in mundo.islotes:
			if punto.distance_to(isla.pos) < isla.radio + margen + 40.0:
				libre = false
		for otro in remolinos + krakens + ventiscas:
			if punto.distance_to(otro.pos) < separacion:
				libre = false
		for barco in mundo.barcos:
			if barco.viva and punto.distance_to(barco.pos) < lejos_de_barcos:
				libre = false
		if libre and _tranquila(punto):
			libre = false
		if libre:
			return punto
	return punto


# Agua libre lejos de los barcos y de los demás krakens; si el mar no da para tanto,
# se queda con el sitio más alejado del kraken más cercano.
func _tranquila(punto: Vector2) -> bool:
	return mundo.modo == "libre" and mundo.libre.tranquila(punto)


func lugar_kraken(kraken: Kraken, alcance: float) -> Vector2:
	var mejor := mundo.centro_juego()
	var mejor_nota := -INF
	for _intento in 160:
		var punto := mundo.centro_juego() + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * alcance
		var en_tierra := false
		for isla in mundo.islotes:
			if punto.distance_to(isla.pos) < isla.radio + RADIO_KRAKEN + 100.0:
				en_tierra = true
				break
		if en_tierra or _tranquila(punto):
			continue
		# Cuánto cumple cada distancia (1 = suficiente); manda la que peor queda.
		var nota := 1.0
		for otro in krakens:
			if otro != kraken and otro.agonia < 0.0:
				var hueco := minf(punto.distance_to(otro.hogar), punto.distance_to(otro.pos))
				nota = minf(nota, hueco / SEPARACION_KRAKENS)
		for barco in mundo.barcos:
			if barco.viva:
				nota = minf(nota, punto.distance_to(barco.pos) / LEJOS_KRAKEN)
		if nota >= 1.0:
			return punto
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = punto
	return mejor


# Tras colocar los barcos: el kraken que haya quedado pegado a alguno se va a otro sitio.
func apartar_krakens() -> void:
	for kraken in krakens:
		for barco in mundo.barcos:
			if barco.viva and kraken.pos.distance_to(barco.pos) < LEJOS_KRAKEN:
				kraken.pos = lugar_kraken(kraken, mundo.alcance_juego() * 0.8)
				kraken.hogar = kraken.pos
				kraken.rumbo_a = kraken.pos
				break


# Modo libre: el kraken que queda atrás (vivo o vencido) vuelve a salir del agua en otro sitio.
func revivir_kraken(kraken: Kraken, punto: Vector2) -> void:
	_soltar(kraken)
	kraken.pos = punto
	kraken.hogar = punto
	kraken.rumbo_a = punto
	kraken.vida = VIDA_KRAKEN
	kraken.agonia = -1.0
	kraken.fuerza = 0.0
	kraken.ataque = -1.0
	kraken.espera = ESPERA_ATAQUE
	kraken.emboscada = false
	kraken.recien_emergido = false
	kraken.presa = null
	kraken.blanco = null


# Si aún queda algún kraken al que vencer (los vencidos no vuelven y con la zona pequeña se retiran).
func quedan_krakens() -> bool:
	if not activos:
		return false
	for kraken in krakens:
		if kraken.agonia < 0.0:
			return true
	return false


# Para no hacer aparecer barcos encima de un peligro.
func cerca(punto: Vector2, margen: float) -> bool:
	for remolino in remolinos:
		if punto.distance_to(remolino.pos) < remolino.radio + margen:
			return true
	for tornado in tornados:
		if punto.distance_to(tornado.pos) < tornado.radio + margen:
			return true
	for kraken in krakens:
		if punto.distance_to(kraken.pos) < ALCANCE_KRAKEN + margen:
			return true
	return false


# Modelos

func _crear_remolino(remolino: Remolino) -> void:
	var plano := PlaneMesh.new()
	plano.size = Vector2.ONE * remolino.radio * Principal.ESCALA * 2.0
	plano.subdivide_width = 56
	plano.subdivide_depth = 56
	remolino.materia = ShaderMaterial.new()
	remolino.materia.shader = SHADER_REMOLINO
	remolino.materia.set_shader_parameter("radio", remolino.radio * Principal.ESCALA)
	remolino.materia.set_shader_parameter("giro", remolino.giro)
	remolino.nodo = MeshInstance3D.new()
	remolino.nodo.mesh = plano
	remolino.nodo.material_override = remolino.materia
	remolino.nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	remolino.nodo.extra_cull_margin = 3.0
	add_child(remolino.nodo)


# Dos embudos (uno claro por fuera y otro más oscuro dentro) que se desvanecen hacia arriba.
func _crear_tornado(tornado: Tornado) -> void:
	tornado.nodo = Node3D.new()
	var embudo := CylinderMesh.new()
	embudo.top_radius = 1.0
	embudo.bottom_radius = 1.0
	embudo.height = 1.0
	embudo.radial_segments = 28
	embudo.rings = 28
	embudo.cap_top = false
	embudo.cap_bottom = false
	var capas := [
		[0.5, 2.1, 1.0, 0.7, Color(0.95, 0.96, 0.98), Color(0.55, 0.6, 0.66)],
		[0.28, 1.45, 1.4, 0.9, Color(0.8, 0.84, 0.88), Color(0.32, 0.37, 0.42)],
	]
	for datos in capas:
		var materia := ShaderMaterial.new()
		materia.shader = SHADER_TORNADO
		materia.set_shader_parameter("radio_base", datos[0])
		materia.set_shader_parameter("radio_alto", datos[1])
		materia.set_shader_parameter("vueltas", datos[2])
		materia.set_shader_parameter("opacidad", datos[3])
		materia.set_shader_parameter("color_claro", datos[4])
		materia.set_shader_parameter("color_oscuro", datos[5])
		materia.set_shader_parameter("giro", tornado.giro)
		materia.set_shader_parameter("alto", ALTO_TORNADO)
		var capa := MeshInstance3D.new()
		capa.mesh = embudo
		capa.material_override = materia
		capa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		capa.extra_cull_margin = 6.0
		capa.position.y = 0.5
		tornado.nodo.add_child(capa)
		tornado.capas.append(materia)
	add_child(tornado.nodo)


func _crear_ventisca(ventisca: Ventisca) -> void:
	var raya := PlaneMesh.new()
	raya.size = Vector2(1.0, 1.0)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = raya
	multi.instance_count = RACHAS
	for _i in RACHAS:
		var punto := Vector2.from_angle(randf() * TAU) * sqrt(randf())
		ventisca.rachas.append(Vector4(punto.x, punto.y, randf_range(0.3, 1.6), randf_range(0.7, 1.3)))
	ventisca.nodo = MultiMeshInstance3D.new()
	ventisca.nodo.multimesh = multi
	ventisca.nodo.material_override = material_racha
	ventisca.nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ventisca.nodo.extra_cull_margin = ventisca.radio * Principal.ESCALA * 1.2
	add_child(ventisca.nodo)


func _crear_kraken(kraken: Kraken) -> void:
	kraken.nodo = Node3D.new()
	kraken.nodo.scale = Vector3.ONE * TAM_KRAKEN
	add_child(kraken.nodo)
	kraken.piel = ShaderMaterial.new()
	kraken.piel.shader = SHADER_KRAKEN
	kraken.piel.set_shader_parameter("fase", kraken.fase)
	_crear_cuerpo_kraken(kraken)
	_crear_ojos_kraken(kraken)
	for j in TENTACULOS:
		_crear_tentaculo(kraken, j)
	_crear_aviso_golpe(kraken)


func _crear_cuerpo_kraken(kraken: Kraken) -> void:
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 40
	esfera.rings = 20
	kraken.cuerpo = MeshInstance3D.new()
	kraken.cuerpo.mesh = esfera
	kraken.cuerpo.material_override = kraken.piel
	kraken.cuerpo.position = Vector3(0.0, 0.9, 0.5)
	kraken.cuerpo.scale = Vector3(1.7, 2.3, 2.0)
	kraken.cuerpo.rotation.x = 0.45
	kraken.nodo.add_child(kraken.cuerpo)
	var cabeza := MeshInstance3D.new()
	cabeza.mesh = esfera
	cabeza.material_override = kraken.piel
	cabeza.position = Vector3(0.0, 0.2, -0.6)
	cabeza.scale = Vector3(1.5, 1.1, 1.3)
	kraken.nodo.add_child(cabeza)


# Ojos dorados con pupila de raya; parpadean escalando el nodo de cada ojo.
func _crear_ojos_kraken(kraken: Kraken) -> void:
	var bola := SphereMesh.new()
	bola.radius = 0.3
	bola.height = 0.6
	bola.radial_segments = 20
	bola.rings = 10
	var brillo := StandardMaterial3D.new()
	brillo.albedo_color = Color(1.0, 0.8, 0.25)
	brillo.emission_enabled = true
	brillo.emission = Color(1.0, 0.65, 0.1)
	brillo.emission_energy_multiplier = 0.9
	brillo.roughness = 0.15
	var pupila := BoxMesh.new()
	pupila.size = Vector3(0.08, 0.42, 0.06)
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color(0.02, 0.01, 0.01)
	negro.roughness = 0.1
	for lado in [-1.0, 1.0]:
		var ojo := Node3D.new()
		ojo.position = Vector3(0.75 * lado, 0.53, -1.6)
		ojo.rotation.y = 0.55 * -lado
		kraken.nodo.add_child(ojo)
		var globo := MeshInstance3D.new()
		globo.mesh = bola
		globo.material_override = brillo
		ojo.add_child(globo)
		var raya := MeshInstance3D.new()
		raya.mesh = pupila
		raya.material_override = negro
		raya.position = Vector3(0.0, 0.0, -0.27)
		ojo.add_child(raya)
		kraken.ojos.append(ojo)


# Los delanteros son más largos y gruesos: son los que suelen golpear.
func _crear_tentaculo(kraken: Kraken, j: int) -> void:
	var alrededor := TAU * (j + 0.5) / TENTACULOS
	var afuera := Vector2(sin(alrededor), -cos(alrededor))
	var tentaculo := MeshInstance3D.new()
	tentaculo.mesh = malla_tentaculo
	tentaculo.position = Vector3(afuera.x * RAIZ_TENTACULO, -0.25, afuera.y * RAIZ_TENTACULO)
	var angulo := atan2(afuera.x, afuera.y)
	tentaculo.rotation.y = angulo
	tentaculo.extra_cull_margin = 16.0
	var materia := ShaderMaterial.new()
	materia.shader = SHADER_TENTACULO
	var delantero := j == 0 or j == TENTACULOS - 1
	var largo := randf_range(6.4, 7.0) if delantero else randf_range(5.2, 6.2)
	var fase := randf() * TAU
	materia.set_shader_parameter("largo", largo)
	materia.set_shader_parameter("grosor", 0.5 if delantero else randf_range(0.38, 0.46))
	materia.set_shader_parameter("fase", fase)
	materia.set_shader_parameter("vaiven", randf_range(0.25, 0.4))
	tentaculo.material_override = materia
	kraken.nodo.add_child(tentaculo)
	kraken.tentaculos.append(tentaculo)
	kraken.materiales.append(materia)
	kraken.angulos.append(angulo)
	kraken.largos.append(largo)
	kraken.fases.append(fase)
	kraken.poses.append(Vector4(0.8, 2.0, 0.5, largo))
	kraken.giros.append(angulo)


# Aviso del golpe: la sombra del tentáculo bajo el agua y un aro de espuma que se cierra.
func _crear_aviso_golpe(kraken: Kraken) -> void:
	var disco := CylinderMesh.new()
	disco.top_radius = RADIO_GOLPE * Principal.ESCALA
	disco.bottom_radius = disco.top_radius
	disco.height = 0.02
	disco.radial_segments = 48
	disco.rings = 1
	kraken.aviso_materia = StandardMaterial3D.new()
	kraken.aviso_materia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	kraken.aviso_materia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	kraken.aviso_materia.albedo_color = Color(0.05, 0.02, 0.08, 0.0)
	kraken.aviso = MeshInstance3D.new()
	kraken.aviso.mesh = disco
	kraken.aviso.material_override = kraken.aviso_materia
	kraken.aviso.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	kraken.aviso.visible = false
	var aro := TorusMesh.new()
	aro.inner_radius = disco.top_radius * 0.92
	aro.outer_radius = disco.top_radius
	aro.rings = 48
	aro.ring_segments = 4
	kraken.aviso_espuma = StandardMaterial3D.new()
	kraken.aviso_espuma.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	kraken.aviso_espuma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	kraken.aviso_espuma.albedo_color = Color(1, 1, 1, 0.0)
	var borde := MeshInstance3D.new()
	borde.name = "Aro"
	borde.mesh = aro
	borde.material_override = kraken.aviso_espuma
	borde.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	kraken.aviso.add_child(borde)
	add_child(kraken.aviso)


# Lógica de la partida

func actualizar(delta: float) -> void:
	activos = mundo.zona_radio > ZONA_RETIRADA
	for remolino in remolinos:
		if remolino.fundido > 0.0:
			remolino.fundido -= delta
			remolino.fuerza = move_toward(remolino.fuerza, 0.0, delta * 0.8)
			if remolino.fundido <= 0.0:
				remolino.pos = _lugar_libre(remolino.radio + 40.0, mundo.alcance_juego() * 0.8, 400.0)
			continue
		remolino.fuerza = move_toward(remolino.fuerza, 1.0 if activos else 0.0, delta * 0.25)
		if remolino.fuerza <= 0.0:
			continue
		_derivar(remolino, VEL_REMOLINO, remolino.radio, delta, _remolino_cercano(remolino))
		_arrastrar_barcos(remolino, delta)
	_juntar_remolinos()
	for tornado in tornados:
		_actualizar_tornado(tornado, delta)
	for i in range(tornados.size() - 1, -1, -1):
		if tornados[i].vida <= 0.0 and tornados[i].fuerza <= 0.0:
			tornados[i].nodo.queue_free()
			tornados.remove_at(i)
	for kraken in krakens:
		_actualizar_kraken(kraken, delta)
	for ventisca in ventiscas:
		ventisca.fuerza = move_toward(ventisca.fuerza, 1.0 if activos else 0.0, delta * 0.25)
		if ventisca.fuerza <= 0.0:
			continue
		_derivar(ventisca, VEL_VENTISCA, ventisca.radio, delta, Vector2.INF)
		_soplar(ventisca, delta)


func _soplar(ventisca: Ventisca, delta: float) -> void:
	var viento := Vector2.from_angle(ventisca.rumbo) * ventisca.fuerza
	for barco in mundo.barcos:
		if not barco.viva:
			continue
		var dist := barco.pos.distance_to(ventisca.pos)
		if dist >= ventisca.radio:
			continue
		var k := sqrt(1.0 - dist / ventisca.radio)
		barco.pos += viento * EMPUJE_VIENTO * k * delta
		var a_favor := barco.proa().dot(viento)
		if a_favor > 0.0:
			barco.velocidad = minf(barco.vel_max * TOPE_VIENTO, barco.velocidad + a_favor * IMPULSO_VIENTO * k * delta)


# Viento que sopla en un punto (para las tablas sueltas).
func viento(punto: Vector2) -> Vector2:
	var total := Vector2.ZERO
	for ventisca in ventiscas:
		var dist: float = punto.distance_to(ventisca.pos)
		if dist < ventisca.radio:
			total += Vector2.from_angle(ventisca.rumbo) * EMPUJE_VIENTO * 0.5 * ventisca.fuerza * sqrt(1.0 - dist / ventisca.radio)
	return total


func _arrastrar_barcos(remolino: Remolino, delta: float) -> void:
	for barco in mundo.barcos:
		if not barco.viva:
			continue
		var rel := barco.pos - remolino.pos
		var dist := rel.length()
		if dist >= remolino.radio or dist < 0.001:
			continue
		var k := (1.0 - dist / remolino.radio) * remolino.fuerza
		var hacia_centro := -rel / dist
		var de_lado := Vector2(-rel.y, rel.x) / dist * remolino.giro
		barco.pos += (hacia_centro * ARRASTRE_CENTRO + de_lado * ARRASTRE_GIRO) * k * delta
		barco.rumbo = wrapf(barco.rumbo + remolino.giro * k * 1.1 * delta, -PI, PI)
		barco.recibir_danio((2.0 + DANIO_REMOLINO * k) * delta)
		if barco.es_jugador:
			mundo.golpe = maxf(mundo.golpe, 0.04 + 0.1 * k)
			mundo.avisar_combate()


func _remolino_cercano(remolino: Remolino) -> Vector2:
	if not activos or tornados.size() >= MAX_TORNADOS:
		return Vector2.INF
	var mejor := Vector2.INF
	var minima := ATRACCION_REMOLINOS
	for otro in remolinos:
		if otro == remolino or otro.fundido > 0.0 or otro.fuerza < 0.9:
			continue
		var distancia: float = remolino.pos.distance_to(otro.pos)
		if distancia < minima:
			minima = distancia
			mejor = otro.pos
	return mejor


func _juntar_remolinos() -> void:
	if not activos:
		return
	for a in remolinos:
		for b in remolinos:
			if tornados.size() >= MAX_TORNADOS:
				return
			if a == b or a.fundido > 0.0 or b.fundido > 0.0 or a.fuerza < 0.9 or b.fuerza < 0.9:
				continue
			if a.pos.distance_to(b.pos) < (a.radio + b.radio) * 0.6:
				_formar_tornado(a, b)


func _formar_tornado(a: Remolino, b: Remolino) -> void:
	a.fundido = DURACION_TORNADO + 10.0
	b.fundido = DURACION_TORNADO + 14.0
	var tornado := Tornado.new()
	tornado.pos = (a.pos + b.pos) * 0.5
	tornado.giro = a.giro
	tornado.rumbo = randf() * TAU
	tornado.fase = randf() * 100.0
	_crear_tornado(tornado)
	tornados.append(tornado)
	mundo.salpicar(tornado.pos, 24)


func _actualizar_tornado(tornado: Tornado, delta: float) -> void:
	tornado.vida -= delta
	var crece := tornado.vida > 0.0 and activos
	tornado.fuerza = move_toward(tornado.fuerza, 1.0 if crece else 0.0, delta * (0.5 if crece else 0.35))
	if tornado.fuerza <= 0.0:
		return
	_derivar(tornado, VEL_TORNADO, tornado.radio, delta, Vector2.INF)
	for barco in mundo.barcos:
		if not barco.viva:
			continue
		var rel: Vector2 = barco.pos - tornado.pos
		var dist := rel.length()
		if dist >= tornado.radio + barco.radio * 0.5 or dist < 0.001:
			continue
		var k := clampf(1.0 - dist / (tornado.radio + barco.radio * 0.5), 0.0, 1.0) * tornado.fuerza
		var hacia_centro := -rel / dist
		var de_lado := Vector2(-rel.y, rel.x) / dist * tornado.giro
		barco.pos += (hacia_centro * ARRASTRE_TORNADO + de_lado * GIRO_TORNADO) * k * delta
		barco.velocidad *= 1.0 - minf(1.0, 1.5 * k * delta)
		barco.rumbo = wrapf(barco.rumbo + tornado.giro * k * 2.6 * delta, -PI, PI)
		barco.recibir_danio((4.0 + DANIO_TORNADO * k) * delta)
		if barco.es_jugador:
			mundo.golpe = maxf(mundo.golpe, 0.12 + 0.3 * k)
			mundo.avisar_combate()


# Velocidad con la que el agua de los remolinos arrastra algo suelto, como las tablas.
func arrastre(punto: Vector2) -> Vector2:
	var total := Vector2.ZERO
	for remolino in remolinos:
		var rel: Vector2 = punto - remolino.pos
		var dist := rel.length()
		if dist >= remolino.radio or dist < 6.0:
			continue
		var k: float = (1.0 - dist / remolino.radio) * remolino.fuerza
		total += (-rel / dist * ARRASTRE_CENTRO * 0.6 + Vector2(-rel.y, rel.x) / dist * remolino.giro * ARRASTRE_GIRO) * k
	for tornado in tornados:
		var rel: Vector2 = punto - tornado.pos
		var dist := rel.length()
		if dist >= tornado.radio * 1.3 or dist < 6.0:
			continue
		var k: float = (1.0 - dist / (tornado.radio * 1.3)) * tornado.fuerza
		total += (-rel / dist * ARRASTRE_TORNADO * 0.6 + Vector2(-rel.y, rel.x) / dist * tornado.giro * GIRO_TORNADO) * k
	return total


# Rumbo lento y serpenteante que esquiva islas, otros peligros y vuelve a la zona.
func _derivar(cosa, velocidad: float, margen: float, delta: float, destino: Vector2) -> void:
	cosa.rumbo += sin(mundo.tiempo * 0.11 + cosa.fase) * 0.25 * delta
	var pos: Vector2 = cosa.pos
	var empuje := Vector2.from_angle(cosa.rumbo)
	if destino != Vector2.INF:
		empuje += (destino - pos).normalized() * 2.0
	if pos.distance_to(mundo.zona_centro) > mundo.zona_radio * 0.8:
		empuje += (mundo.zona_centro - pos).normalized() * 2.0
	for isla in mundo.islotes:
		var sep: Vector2 = pos - isla.pos
		var limite: float = isla.borde(pos) + margen + 80.0
		if sep.length() < limite:
			empuje += sep.normalized() * 3.0 * (1.2 - sep.length() / limite)
	for otro in remolinos + krakens:
		if otro == cosa or (cosa is Remolino and otro is Remolino):
			continue
		var sep: Vector2 = pos - otro.pos
		if sep.length() < 600.0 and sep != Vector2.ZERO:
			empuje += sep.normalized() * (1.0 - sep.length() / 600.0) * 2.0
	cosa.rumbo = lerp_angle(cosa.rumbo, empuje.angle(), minf(1.0, delta * 0.5))
	pos += Vector2.from_angle(cosa.rumbo) * velocidad * delta
	for isla in mundo.islotes:
		var sep: Vector2 = pos - isla.pos
		var minimo: float = isla.borde(pos) + margen
		if sep.length() < minimo and sep != Vector2.ZERO:
			pos = isla.pos + sep.normalized() * minimo
	cosa.pos = pos.limit_length(mundo.radio_mundo() * 0.9)


func _actualizar_kraken(kraken: Kraken, delta: float) -> void:
	kraken.destello = maxf(0.0, kraken.destello - delta * 3.0)
	kraken.espera_rugido = maxf(0.0, kraken.espera_rugido - delta)
	if kraken.agonia >= 0.0:
		kraken.agonia += delta
		kraken.fuerza = move_toward(kraken.fuerza, 0.0, delta / DURACION_AGONIA)
		return
	if kraken.sumergido > 0.0:
		kraken.fuerza = move_toward(kraken.fuerza, 0.0, delta * 0.5)
		kraken.sumergido -= delta
		if kraken.sumergido <= 0.0:
			var presa := kraken.presa
			kraken.presa = null
			if activos and presa != null and presa.viva:
				kraken.pos = _junto_a(presa)
				kraken.hogar = kraken.pos
				kraken.rumbo_a = kraken.pos
				kraken.emboscada = true
				kraken.recien_emergido = true
				kraken.ataque = -1.0
				kraken.espera = ESPERA_EMERGER
			elif activos:
				kraken.pos = lugar_kraken(kraken, maxf(300.0, mundo.alcance_juego() * 0.75))
				kraken.hogar = kraken.pos
				kraken.rumbo_a = kraken.pos
				kraken.ataque = -1.0
				kraken.espera = ESPERA_ATAQUE
			else:
				kraken.sumergido = 5.0
		return
	# Tras una emboscada sale del agua de golpe.
	kraken.fuerza = move_toward(kraken.fuerza, 1.0 if activos else 0.0, delta * (1.3 if kraken.emboscada else 0.4))
	if not activos:
		kraken.ataque = -1.0
		_soltar(kraken)
		if kraken.fuerza <= 0.0:
			return

	# Si la tormenta se traga su territorio, se sumerge y reaparece en otro sitio. Tras una
	# emboscada espera a atacar aunque esté junto a la tormenta: el barco está ahí.
	if kraken.ataque < 0.0 and kraken.agarre <= 0.0 and not kraken.emboscada \
			and (kraken.hogar.distance_to(mundo.zona_centro) > mundo.zona_radio or _tranquila(kraken.hogar)):
		kraken.presa = null
		kraken.sumergido = ESCONDIDO
		mundo.salpicar(kraken.pos, 14)
		return

	var blanco: Barco = null
	var mejor := VISTA_KRAKEN
	for barco in mundo.barcos:
		if barco.viva and barco.pos.distance_to(kraken.pos) < mejor:
			mejor = barco.pos.distance_to(kraken.pos)
			blanco = barco

	kraken.espera_emboscada -= delta
	if kraken.ataque < 0.0 and not kraken.emboscada and kraken.espera_emboscada <= 0.0 and kraken.fuerza > 0.95:
		var presa := _presa_debil(kraken)
		if presa != null:
			kraken.presa = presa
			kraken.sumergido = ESCONDIDO
			kraken.espera_emboscada = randf_range(ESPERA_EMBOSCADA.x, ESPERA_EMBOSCADA.y)
			mundo.salpicar(kraken.pos, 14)
			return
		kraken.espera_emboscada = randf_range(3.0, 6.0)

	if kraken.ataque < 0.0:
		var destino := Vector2.INF
		var velocidad := VEL_KRAKEN
		var cerca_de_el := blanco != null and mejor < ALERTA_KRAKEN and blanco.pos.distance_to(kraken.hogar) < ZONA_KRAKEN + ALCANCE_KRAKEN
		if cerca_de_el:
			if mejor > ALCANCE_KRAKEN * 0.55:
				destino = kraken.hogar + (blanco.pos - kraken.hogar).limit_length(ZONA_KRAKEN)
			else:
				velocidad = 0.0
		else:
			# Patrulla: nada hacia un punto de su zona y, al llegar, elige otro.
			if kraken.pos.distance_to(kraken.rumbo_a) < 60.0:
				kraken.rumbo_a = _punto_patrulla(kraken)
			destino = kraken.rumbo_a
		_derivar(kraken, velocidad, RADIO_KRAKEN + 60.0, delta, destino)
		kraken.pos = kraken.hogar + (kraken.pos - kraken.hogar).limit_length(ZONA_KRAKEN)
	var mirar_a := kraken.rumbo
	if blanco != null:
		mirar_a = (blanco.pos - kraken.pos).angle()
	elif kraken.ataque >= 0.0:
		mirar_a = (kraken.punto_golpe - kraken.pos).angle()
	kraken.mirada = lerp_angle(kraken.mirada, mirar_a, minf(1.0, delta * 0.8))

	if blanco != null and blanco.es_jugador and mejor < VISTA_KRAKEN * 0.6:
		mundo.avisar_combate()
		if kraken.espera_rugido <= 0.0:
			kraken.espera_rugido = 14.0
			_rugir(kraken)

	kraken.espera -= delta
	var listo := kraken.fuerza > (0.6 if kraken.emboscada else 0.95)
	if kraken.ataque < 0.0 and kraken.espera <= 0.0 and blanco != null and listo \
			and mejor < ALCANCE_KRAKEN + blanco.radio * 0.5:
		kraken.ataque = 0.0
		kraken.duracion_ataque = DURACION_ATAQUE * (LENTITUD_EMERGER if kraken.recien_emergido else 1.0)
		kraken.recien_emergido = false
		kraken.blanco = blanco
		kraken.golpeado = false
		kraken.agarra_al_golpe = kraken.emboscada or randf() < PROBABILIDAD_AGARRE
		kraken.emboscada = false
		kraken.punto_golpe = _al_alcance(kraken, blanco.pos)
		kraken.tentaculo = _tentaculo_hacia(kraken, kraken.punto_golpe)
	elif kraken.emboscada and kraken.fuerza >= 1.0:
		kraken.emboscada = false

	if kraken.agarre > 0.0:
		_sujetar(kraken, delta)
	elif kraken.ataque >= 0.0:
		kraken.ataque += delta / kraken.duracion_ataque
		if kraken.ataque < FIN_PUNTERIA and kraken.blanco != null and kraken.blanco.viva:
			kraken.punto_golpe = kraken.punto_golpe.lerp(_al_alcance(kraken, kraken.blanco.pos), minf(1.0, delta * 8.0))
		if not kraken.golpeado and kraken.ataque >= MOMENTO_GOLPE:
			kraken.golpeado = true
			_golpear(kraken)
		if kraken.ataque >= 1.0:
			kraken.ataque = -1.0
			kraken.espera = ESPERA_ATAQUE + randf_range(0.0, 1.5)

	if kraken.fuerza > 0.5:
		for barco in mundo.barcos:
			if not barco.viva:
				continue
			var sep := barco.pos - kraken.pos
			var minimo := RADIO_KRAKEN + barco.radio * 0.6
			if sep.length() < minimo and sep != Vector2.ZERO:
				barco.pos = kraken.pos + sep.normalized() * minimo
				barco.velocidad *= 0.9


# El tentáculo queda sobre el barco agarrado: no avanza ni gira y la madera cruje.
func _sujetar(kraken: Kraken, delta: float) -> void:
	var barco := kraken.agarrado
	kraken.agarre -= delta
	if barco == null or not barco.viva or kraken.agarre <= 0.0:
		_soltar(kraken)
		return
	barco.pos = kraken.pos_agarre
	barco.velocidad = 0.0
	barco.vel_giro = 0.0
	barco.recibir_danio(DANIO_AGARRE * delta)
	kraken.punto_golpe = _al_alcance(kraken, barco.pos)
	kraken.destello = maxf(kraken.destello, 0.25)
	if barco.es_jugador:
		mundo.golpe = maxf(mundo.golpe, 0.1)
		mundo.avisar_combate()
	if randf() < delta * 3.0:
		mundo.salpicar(barco.pos + Vector2.from_angle(randf() * TAU) * barco.radio * 0.5, 4)


func _soltar(kraken: Kraken) -> void:
	kraken.agarre = 0.0
	kraken.agarrado = null


func _agarrado(barco: Barco) -> bool:
	for kraken in krakens:
		if kraken.agarrado == barco and kraken.agarre > 0.0:
			return true
	return false


# El barco más cercano que ya va a media vida o menos y queda fuera del alcance del tentáculo.
func _presa_debil(kraken: Kraken) -> Barco:
	var presa: Barco = null
	var mejor := ALCANCE_EMBOSCADA
	for barco in mundo.barcos:
		if not barco.viva or barco.vida > barco.vida_max * VIDA_PRESA or _tranquila(barco.pos):
			continue
		var distancia := barco.pos.distance_to(kraken.pos)
		if distancia > ALCANCE_KRAKEN + 150.0 and distancia < mejor and not _otro_kraken_cerca(kraken, barco):
			mejor = distancia
			presa = barco
	return presa


# Otro kraken ya ronda o persigue a ese barco: no se juntan dos en el mismo sitio.
func _otro_kraken_cerca(kraken: Kraken, barco: Barco) -> bool:
	for otro in krakens:
		if otro == kraken or otro.agonia >= 0.0:
			continue
		if otro.presa == barco or otro.pos.distance_to(barco.pos) < SEPARACION_KRAKENS * 0.5:
			return true
	return false


# Un punto de agua libre dentro de la zona del kraken, hacia el que nada mientras patrulla.
func _punto_patrulla(kraken: Kraken) -> Vector2:
	var punto := kraken.hogar
	for _intento in 8:
		punto = kraken.hogar + Vector2.from_angle(randf() * TAU) * sqrt(randf_range(0.15, 1.0)) * ZONA_KRAKEN
		var libre := true
		for isla in mundo.islotes:
			if punto.distance_to(isla.pos) < isla.radio + RADIO_KRAKEN + 80.0:
				libre = false
		if libre:
			return punto
	return punto


# Un sitio de agua libre delante de la proa del barco, a tiro de tentáculo.
func _junto_a(barco: Barco) -> Vector2:
	var distancia := ALCANCE_KRAKEN * 0.75 + barco.radio * 0.3
	var punto := barco.pos + barco.proa() * distancia
	for intento in 12:
		var giro := randf_range(-0.7, 0.7) if intento < 6 else randf() * TAU
		punto = barco.pos + barco.proa().rotated(giro) * distancia
		var libre := true
		for isla in mundo.islotes:
			if punto.distance_to(isla.pos) < isla.radio + RADIO_KRAKEN + 20.0:
				libre = false
		for otro in mundo.barcos:
			if otro != barco and otro.viva and punto.distance_to(otro.pos) < RADIO_KRAKEN + otro.radio:
				libre = false
		if libre:
			return punto
	return punto


func _al_alcance(kraken: Kraken, punto: Vector2) -> Vector2:
	return kraken.pos + (punto - kraken.pos).limit_length(ALCANCE_KRAKEN)


func _tentaculo_hacia(kraken: Kraken, punto: Vector2) -> int:
	var rel := punto - kraken.pos
	var hacia := atan2(rel.x, rel.y)
	var mejor := 0
	var menor := INF
	for j in TENTACULOS:
		var diferencia := absf(angle_difference(kraken.angulos[j] + kraken.nodo.rotation.y, hacia))
		if diferencia < menor:
			menor = diferencia
			mejor = j
	return mejor


func _golpear(kraken: Kraken) -> void:
	var punto := kraken.punto_golpe
	for barco in mundo.barcos:
		if barco.viva and barco.pos.distance_to(punto) < RADIO_GOLPE + barco.radio * 0.6:
			barco.recibir_danio(DANIO_TENTACULO, true)
			barco.velocidad *= 0.5
			if barco.es_jugador:
				mundo.golpe = maxf(mundo.golpe, 0.35)
				mundo.avisar_combate()
			if kraken.agarra_al_golpe and kraken.agarrado == null and barco.viva:
				kraken.agarrado = barco
				kraken.agarre = DURACION_AGARRE
				kraken.pos_agarre = barco.pos
	kraken.agarra_al_golpe = false
	mundo.salpicar(punto, 22)
	for k in 3:
		mundo.salpicar(kraken.pos.lerp(punto, 0.5 + k * 0.17), 5)
	var sitio := mundo.a_3d(punto)
	var h := mundo.altura_mar(sitio.x, sitio.z)
	for i in 3:
		mundo.crear_efecto(mundo.malla_espuma, Color(1, 1, 1, 0.75 - i * 0.2), sitio + Vector3(0, h + 0.08, 0), Vector3.ZERO, 1.1 + i * 0.5, 1.0 + i * 0.6, 2.8 + i * 1.4)
	var cercania := clampf(1.0 - sitio.distance_to(mundo.foco) / 45.0, 0.0, 1.0)
	if cercania > 0.0:
		for voz in mundo.voces_canon:
			if not voz.playing:
				voz.volume_db = lerpf(-30.0, -6.0, cercania)
				voz.pitch_scale = randf_range(0.42, 0.5)
				voz.play()
				break


func _rugir(kraken: Kraken) -> void:
	var cercania := clampf(1.0 - mundo.a_3d(kraken.pos).distance_to(mundo.foco) / 60.0, 0.0, 1.0)
	if cercania <= 0.0 or voz_kraken.playing:
		return
	voz_kraken.volume_db = lerpf(-28.0, -9.0, cercania)
	voz_kraken.pitch_scale = randf_range(0.9, 1.05)
	voz_kraken.play()
	var apagado := create_tween()
	apagado.tween_interval(2.2)
	apagado.tween_property(voz_kraken, "volume_db", -60.0, 1.3)
	apagado.tween_callback(voz_kraken.stop)


# Las balas que pegan en el cuerpo del kraken; devuelve true si la bala se detiene.
func recibir_bala(punto: Vector2, dueno: Barco) -> bool:
	for kraken in krakens:
		if kraken.sumergido > 0.0 or kraken.fuerza < 0.5:
			continue
		if punto.distance_to(kraken.pos) < RADIO_KRAKEN:
			kraken.vida -= Principal.DANIO_BALA
			kraken.destello = 1.0
			mundo.salpicar(punto, 5)
			if kraken.vida <= 0.0:
				_vencer(kraken, dueno)
			return true
	return false


# Un kraken fuera del agua que alcanza el punto (para que revienten los barriles).
func toca(punto: Vector2, margen: float) -> bool:
	for kraken in krakens:
		if kraken.sumergido <= 0.0 and kraken.fuerza >= 0.5 and kraken.agonia < 0.0 \
				and punto.distance_to(kraken.pos) < RADIO_KRAKEN + margen:
			return true
	return false


# Un barril que revienta cerca también hiere al kraken que esté fuera del agua.
func explosion(punto: Vector2, radio: float, danio: float, dueno: Barco) -> void:
	for kraken in krakens:
		if kraken.sumergido > 0.0 or kraken.fuerza < 0.5 or kraken.agonia >= 0.0:
			continue
		var distancia := maxf(0.0, punto.distance_to(kraken.pos) - RADIO_KRAKEN)
		if distancia >= radio:
			continue
		kraken.vida -= danio * (1.0 - distancia / radio)
		kraken.destello = 1.0
		if kraken.vida <= 0.0:
			_vencer(kraken, dueno)


func _vencer(kraken: Kraken, dueno: Barco) -> void:
	kraken.vida = 0.0
	kraken.sumergido = INF
	kraken.ataque = -1.0
	kraken.agonia = 0.0
	kraken.destello = 1.0
	kraken.presa = null
	kraken.emboscada = false
	_soltar(kraken)
	voz_kraken.stop()
	_rugir(kraken)
	mundo.salpicar(kraken.pos, 30)
	if dueno == mundo.jugador:
		ahuyentados += 1
		mundo.recompensas.al_vencer("kraken")
	if dueno != null and dueno.viva:
		mundo.ganar_botin(dueno, MONEDAS_KRAKEN, mundo.a_3d(kraken.pos, 2.0))
	var giro := randf() * TAU
	for k in COFRES_KRAKEN:
		var a := giro + TAU * k / COFRES_KRAKEN + randf_range(-0.4, 0.4)
		mundo.soltar_cofre(kraken.pos + Vector2.from_angle(a) * (RADIO_KRAKEN + randf_range(12.0, 30.0)), randi_range(1, 3))


# Hacia dónde debería escapar un bot; Vector2.ZERO si no hay peligro cerca.
func evitar(barco: Barco) -> Vector2:
	var huida := Vector2.ZERO
	for remolino in remolinos:
		if remolino.fuerza < 0.3:
			continue
		var sep: Vector2 = barco.pos - remolino.pos
		var limite: float = remolino.radio + barco.radio + 140.0
		if sep.length() < limite and sep != Vector2.ZERO:
			huida += sep.normalized() * (1.2 - sep.length() / limite)
	for tornado in tornados:
		if tornado.fuerza < 0.2:
			continue
		var sep: Vector2 = barco.pos - tornado.pos
		var limite: float = tornado.radio + barco.radio + 200.0
		if sep.length() < limite and sep != Vector2.ZERO:
			huida += sep.normalized() * (1.5 - sep.length() / limite)
	for kraken in krakens:
		if kraken.sumergido > 0.0 or kraken.fuerza < 0.5:
			continue
		var sep: Vector2 = barco.pos - kraken.pos
		var limite := ALCANCE_KRAKEN + 120.0
		if sep.length() < limite and sep != Vector2.ZERO:
			huida += sep.normalized() * (1.2 - sep.length() / limite)
	return huida.normalized() if huida != Vector2.ZERO else Vector2.ZERO


func aviso(barco: Barco) -> String:
	if _agarrado(barco):
		return "¡El Kraken te tiene atrapado!"
	for tornado in tornados:
		if tornado.fuerza > 0.3:
			var dist: float = barco.pos.distance_to(tornado.pos)
			if dist < tornado.radio + barco.radio * 0.5:
				return "¡Atrapado en un tornado!"
			if dist < tornado.radio + 220.0:
				return "¡Cuidado: tornado!"
	for remolino in remolinos:
		if remolino.fuerza > 0.3 and barco.pos.distance_to(remolino.pos) < remolino.radio:
			return "¡Atrapado en un remolino!"
	for kraken in krakens:
		if kraken.sumergido <= 0.0 and kraken.fuerza > 0.5 and barco.pos.distance_to(kraken.pos) < ALCANCE_KRAKEN + 120.0:
			return "¡Cuidado con el Kraken!"
	for ventisca in ventiscas:
		if ventisca.fuerza > 0.3 and barco.pos.distance_to(ventisca.pos) < ventisca.radio:
			return "¡Viento a favor!" if barco.proa().dot(Vector2.from_angle(ventisca.rumbo)) > 0.3 else "Ventisca: navega con el viento"
	return ""


func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	var t := mundo.tiempo
	for ventisca in ventiscas:
		if ventisca.fuerza < 0.05 or not mundo.en_mapa(ventisca.pos):
			continue
		var punto: Vector2 = centro + ventisca.pos * escala
		var radio := maxf(5.0, ventisca.radio * escala)
		var dir := Vector2.from_angle(ventisca.rumbo)
		var color := Color(0.85, 0.95, 1.0, 0.45)
		lienzo.draw_circle(punto, radio, Color(0.85, 0.95, 1.0, 0.08))
		var paso := fmod(t * 0.8, 1.0)
		for k in 2:
			var cabeza := punto + dir * radio * lerpf(-0.6, 0.7, fmod(paso + k * 0.5, 1.0))
			lienzo.draw_polyline(PackedVector2Array([cabeza - dir.rotated(0.6) * 4.0, cabeza, cabeza - dir.rotated(-0.6) * 4.0]), color, 1.5, true)
	for remolino in remolinos:
		if remolino.fuerza < 0.05 or not mundo.en_mapa(remolino.pos):
			continue
		var punto: Vector2 = centro + remolino.pos * escala
		var radio := maxf(4.0, remolino.radio * escala)
		var color := Color(0.65, 0.92, 1.0, 0.9 * remolino.fuerza)
		var inicio: float = t * 3.0 * remolino.giro
		lienzo.draw_arc(punto, radio, inicio, inicio + 4.2, 14, color, 1.6, true)
		lienzo.draw_arc(punto, radio * 0.5, inicio + PI, inicio + PI + 3.6, 10, color, 1.4, true)
	for tornado in tornados:
		if tornado.fuerza < 0.05 or not mundo.en_mapa(tornado.pos):
			continue
		var punto: Vector2 = centro + tornado.pos * escala
		var radio := maxf(5.0, tornado.radio * escala)
		var color := Color(0.88, 0.9, 0.95, tornado.fuerza)
		var inicio: float = t * 6.0 * tornado.giro
		for k in 3:
			var r := radio * (1.0 - k * 0.3)
			lienzo.draw_arc(punto, r, inicio + k * 2.1, inicio + k * 2.1 + 3.4, 12, color, 1.8, true)


# Misma fórmula que con_remolinos() en agua.gdshader (metros del mundo 3D).
func ajustar_mar(x: float, z: float, h: float) -> float:
	var calma := 0.0
	var hundido := 0.0
	var p := Vector2(x, z)
	for remolino in remolinos:
		if remolino.fuerza <= 0.0:
			continue
		var radio: float = remolino.radio * Principal.ESCALA
		var d := p.distance_to(remolino.pos * Principal.ESCALA) / radio
		var k := clampf(1.0 - (sqrt(d * d + 0.0225) - 0.15) / 0.8662, 0.0, 1.0)
		if k > 0.0:
			calma = maxf(calma, k)
			hundido += _hondura(remolino) * pow(k, 2.4)
	return h * (1.0 - 0.6 * smoothstep(0.0, 1.0, calma)) - hundido


func _hondura(remolino: Remolino) -> float:
	return remolino.radio * Principal.ESCALA * HONDURA_REMOLINO * remolino.fuerza


# Animación (también fuera de la partida)

func animar(delta: float) -> void:
	var foco_plano := Vector2(mundo.foco.x, mundo.foco.z)
	var t := mundo.tiempo
	var en_agua: Array = []
	var rugido_cerca := 0.0
	for remolino in remolinos:
		var centro: Vector2 = remolino.pos * Principal.ESCALA
		var radio: float = remolino.radio * Principal.ESCALA
		var distancia := centro.distance_to(foco_plano)
		rugido_cerca = maxf(rugido_cerca, clampf(1.0 - (distancia - radio) / 30.0, 0.0, 1.0) * remolino.fuerza)
		remolino.nodo.visible = distancia < Principal.DISTANCIA_VISIBLE + radio and remolino.fuerza > 0.01
		if distancia < Principal.LADO_AGUA * 0.5 + radio:
			en_agua.append(remolino)
		if not remolino.nodo.visible:
			continue
		remolino.nodo.position = Vector3(centro.x, 0.0, centro.y)
		var materia: ShaderMaterial = remolino.materia
		materia.set_shader_parameter("tiempo", t)
		materia.set_shader_parameter("zona_centro", mundo.zona_centro * Principal.ESCALA)
		materia.set_shader_parameter("zona_radio", mundo.zona_radio * Principal.ESCALA)
		materia.set_shader_parameter("centro", centro)
		materia.set_shader_parameter("profundidad", _hondura(remolino))
		materia.set_shader_parameter("fuerza", remolino.fuerza)
		_salpicar_remolino(remolino, delta)

	en_agua.sort_custom(func(a: Remolino, b: Remolino) -> bool:
		return a.pos.distance_squared_to(foco_plano / Principal.ESCALA) < b.pos.distance_squared_to(foco_plano / Principal.ESCALA))
	var datos := PackedVector4Array()
	datos.resize(REMOLINOS_EN_AGUA)
	for i in mini(en_agua.size(), REMOLINOS_EN_AGUA):
		var remolino: Remolino = en_agua[i]
		datos[i] = Vector4(remolino.pos.x * Principal.ESCALA, remolino.pos.y * Principal.ESCALA, remolino.radio * Principal.ESCALA, _hondura(remolino))
	mundo.material_agua.set_shader_parameter("remolinos", datos)

	if rugido_cerca > 0.01:
		rumor.volume_db = linear_to_db(rugido_cerca * 0.16)
		if not rumor.playing:
			rumor.play()
	elif rumor.playing:
		rumor.stop()

	var aullido_cerca := 0.0
	for tornado in tornados:
		aullido_cerca = maxf(aullido_cerca, _animar_tornado(tornado, delta, t, foco_plano))
	if aullido_cerca > 0.01:
		aullido.volume_db = linear_to_db(aullido_cerca * 0.3)
		if not aullido.playing:
			aullido.play()
	elif aullido.playing:
		aullido.stop()

	for kraken in krakens:
		_animar_kraken(kraken, delta, t, foco_plano)
	for ventisca in ventiscas:
		_animar_ventisca(ventisca, t, foco_plano)


func _animar_ventisca(ventisca: Ventisca, t: float, foco_plano: Vector2) -> void:
	var centro: Vector2 = ventisca.pos * Principal.ESCALA
	var radio: float = ventisca.radio * Principal.ESCALA
	ventisca.nodo.visible = centro.distance_to(foco_plano) < Principal.DISTANCIA_VISIBLE + radio and ventisca.fuerza > 0.01
	if not ventisca.nodo.visible:
		return
	var dir2 := Vector2.from_angle(ventisca.rumbo)
	var dir := Vector3(dir2.x, 0.0, dir2.y)
	var lado := Vector3(-dir2.y, 0.0, dir2.x)
	var multi := ventisca.nodo.multimesh
	for i in RACHAS:
		var racha: Vector4 = ventisca.rachas[i]
		var avance := wrapf(racha.x + t * VEL_RACHA * racha.w / radio, -1.0, 1.0)
		var traves := racha.y + sin(t * 1.7 + avance * 4.0 + i) * 0.04
		var alfa := clampf((1.0 - (avance * avance + traves * traves)) * 2.0, 0.0, 1.0)
		var plano := centro + dir2 * avance * radio + Vector2(-dir2.y, dir2.x) * traves * radio
		var y := mundo.altura_mar(plano.x, plano.y) + 0.25 + racha.z
		var base := Basis(dir * 2.2 * racha.w, Vector3.UP, lado * 0.2)
		multi.set_instance_transform(i, Transform3D(base, Vector3(plano.x, y, plano.y)))
		multi.set_instance_color(i, Color(1, 1, 1, alfa * ventisca.fuerza))


# Devuelve lo cerca que suena (0 a 1) para el aullido del viento.
func _animar_tornado(tornado: Tornado, delta: float, t: float, foco_plano: Vector2) -> float:
	var centro: Vector2 = tornado.pos * Principal.ESCALA
	var distancia := centro.distance_to(foco_plano)
	tornado.nodo.visible = distancia < Principal.DISTANCIA_VISIBLE + 10.0 and tornado.fuerza > 0.01
	if not tornado.nodo.visible:
		return 0.0
	var h := mundo.altura_mar(centro.x, centro.y)
	tornado.nodo.position = Vector3(centro.x, h - 0.3, centro.y)
	var inclina := Vector2(sin(t * 0.4 + tornado.fase), cos(t * 0.31 + tornado.fase)) * 0.6
	for materia in tornado.capas:
		materia.set_shader_parameter("tiempo", t)
		materia.set_shader_parameter("fuerza", tornado.fuerza)
		materia.set_shader_parameter("inclina", inclina)
	_salpicar_tornado(tornado, delta)
	return clampf(1.0 - (distancia - tornado.radio * Principal.ESCALA) / 45.0, 0.0, 1.0) * tornado.fuerza


# Espuma y gotas que salen girando y suben desde la base.
func _salpicar_tornado(tornado: Tornado, delta: float) -> void:
	tornado.espera_gotas -= delta
	if tornado.espera_gotas > 0.0:
		return
	tornado.espera_gotas = 0.05
	var angulo := randf() * TAU
	var rel := Vector2.from_angle(angulo) * tornado.radio * randf_range(0.1, 0.45)
	var sitio := mundo.a_3d(tornado.pos + rel)
	var h := mundo.altura_mar(sitio.x, sitio.z)
	var tangente := Vector2(-rel.y, rel.x).normalized() * tornado.giro * 3.5
	for _i in 3:
		var vel := Vector3(tangente.x + randf_range(-0.5, 0.5), randf_range(2.5, 5.0), tangente.y + randf_range(-0.5, 0.5))
		mundo.crear_efecto(mundo.malla_gota, Color(0.9, 0.95, 1.0, 0.85), sitio + Vector3(0, h + 0.1, 0), vel, 0.9, 0.9, 0.0, 6.0)
	if randf() < 0.5:
		mundo.crear_efecto(mundo.malla_humo, Color(0.9, 0.93, 0.96, 0.5), sitio + Vector3(0, h + 0.2, 0), Vector3(tangente.x, 0.8, tangente.y) * 0.6, 1.2, 1.4, 1.5)


func _salpicar_remolino(remolino: Remolino, delta: float) -> void:
	remolino.espera_gotas -= delta
	if remolino.espera_gotas > 0.0:
		return
	remolino.espera_gotas = 0.09
	var angulo := randf() * TAU
	var rel := Vector2.from_angle(angulo) * remolino.radio * randf_range(0.12, 0.5)
	var punto: Vector2 = remolino.pos + rel
	var sitio := mundo.a_3d(punto)
	var h := mundo.altura_mar(sitio.x, sitio.z)
	var tangente := Vector2(-rel.y, rel.x).normalized() * remolino.giro * 2.2
	for _i in 2:
		var vel := Vector3(tangente.x + randf_range(-0.4, 0.4), randf_range(1.6, 3.0), tangente.y + randf_range(-0.4, 0.4))
		mundo.crear_efecto(mundo.malla_gota, Color(0.92, 0.97, 1.0, 0.85), sitio + Vector3(0, h + 0.1, 0), vel, 0.8, 0.9, 0.0, 9.0)


func _animar_kraken(kraken: Kraken, delta: float, t: float, foco_plano: Vector2) -> void:
	var centro: Vector2 = kraken.pos * Principal.ESCALA
	var cerca := centro.distance_to(foco_plano) < Principal.DISTANCIA_VISIBLE + 10.0
	kraken.nodo.visible = cerca and kraken.fuerza > 0.01
	kraken.aviso.visible = false
	if not kraken.nodo.visible:
		return

	var h := mundo.altura_mar(centro.x, centro.y)
	kraken.altura = lerpf(kraken.altura, h, minf(1.0, delta * 3.0))
	var fases := _fases_ataque(kraken.ataque)
	var muere := clampf(kraken.agonia / DURACION_AGONIA, 0.0, 1.0) if kraken.agonia >= 0.0 else 0.0
	var destello := _animar_cuerpo_kraken(kraken, delta, t, centro, fases, muere)
	_animar_tentaculos(kraken, delta, t, fases, muere, destello)
	_animar_aviso_golpe(kraken, t)
	_espumar_kraken(kraken, delta, centro)


# Fases del ataque, cada una de 0 a 1: (carga, látigo, arrastre, recoge).
func _fases_ataque(a: float) -> Vector4:
	if a < 0.0:
		return Vector4.ZERO
	return Vector4(
		smoothstep(0.0, INICIO_LATIGO, a),
		clampf((a - INICIO_LATIGO) / (MOMENTO_GOLPE - INICIO_LATIGO), 0.0, 1.0),
		clampf((a - MOMENTO_GOLPE) / (FIN_ARRASTRE - MOMENTO_GOLPE), 0.0, 1.0),
		smoothstep(FIN_ARRASTRE, 1.0, a))


# El cuerpo asoma, se alza al cargar y se lanza hacia el golpe; los ojos parpadean.
# Devuelve el destello con que brilla la piel.
func _animar_cuerpo_kraken(kraken: Kraken, delta: float, t: float, centro: Vector2, fases: Vector4, muere: float) -> float:
	var a := kraken.ataque
	var carga := fases.x
	var latigo := fases.y
	var lanzarse := sin(PI * clampf((a - INICIO_LATIGO) / 0.4, 0.0, 1.0)) if a >= 0.0 else 0.0
	kraken.embestida = lerpf(kraken.embestida, lanzarse, 1.0 - exp(-delta * 10.0))

	var asomado := ease(kraken.fuerza, -2.0)
	var mira := Vector2.from_angle(kraken.mirada)
	var adelante := Vector3(mira.x, 0.0, mira.y) * kraken.embestida * 0.5
	var alzado := carga * (1.0 - latigo) * 0.25
	kraken.nodo.position = Vector3(centro.x, kraken.altura - (1.0 - asomado) * 5.0 * TAM_KRAKEN + alzado + sin(t * 0.8 + kraken.fase) * 0.07, centro.y) + adelante
	kraken.nodo.rotation.y = atan2(-mira.x, -mira.y)
	kraken.nodo.rotation.z = sin(t * 0.5 + kraken.fase) * 0.04
	var destello := kraken.destello
	if kraken.agonia >= 0.0:
		destello = maxf(destello, absf(sin(t * 9.0)) * 0.7 * (1.0 - muere))
		kraken.nodo.rotation.z += sin(t * 7.0) * 0.12 * (1.0 - muere) + muere * 0.35
	kraken.cuerpo.rotation.x = 0.45 + carga * (1.0 - latigo) * 0.14 - kraken.embestida * 0.28 + muere * 0.5
	kraken.piel.set_shader_parameter("tiempo", t)
	kraken.piel.set_shader_parameter("destello", destello)

	kraken.parpadeo -= delta
	var cierre := 0.0
	if kraken.parpadeo < 0.0:
		cierre = sin(clampf(-kraken.parpadeo / 0.2, 0.0, 1.0) * PI)
		if kraken.parpadeo < -0.2:
			kraken.parpadeo = randf_range(2.0, 5.0)
	cierre = maxf(cierre, maxf(kraken.embestida * 0.55, muere))
	for ojo in kraken.ojos:
		ojo.scale = Vector3(1.0, maxf(0.08, 1.0 - cierre), 1.0)
	return destello


func _animar_tentaculos(kraken: Kraken, delta: float, t: float, fases: Vector4, muere: float, destello: float) -> void:
	var a := kraken.ataque
	var carga := fases.x
	var latigo := fases.y
	var recoge := fases.w
	var hacia_golpe := 0.0
	var largo_golpe := 0.0
	if a >= 0.0:
		var rel := kraken.punto_golpe - kraken.pos
		hacia_golpe = atan2(rel.x, rel.y) - kraken.nodo.rotation.y
		largo_golpe = maxf(3.0, rel.length() * Principal.ESCALA / TAM_KRAKEN - RAIZ_TENTACULO) * 1.03
	var agitado := carga * (1.0 - recoge)
	for j in TENTACULOS:
		var materia := kraken.materiales[j]
		var fase := kraken.fases[j]
		var largo_base := kraken.largos[j]
		# Reposo: brazos arqueados que meten la punta en el agua, cada uno a su ritmo;
		# de vez en cuando uno se alza y se enrosca.
		var lento := sin(t * 0.37 + fase) * 0.6 + sin(t * 0.23 + fase * 2.1) * 0.4
		var alza := smoothstep(0.55, 0.95, sin(t * 0.29 + fase * 1.7))
		var meta := Vector4(
			lerpf(0.85 + lento * 0.15, 0.2, alza) + agitado * 0.12,
			lerpf(2.0 + lento * 0.35, 1.0, alza),
			0.5 + sin(t * 0.7 + fase) * 0.45 + alza * 1.4,
			largo_base * (1.0 + alza * 0.08))
		var onda := 0.35 + agitado * 0.35
		var giro_meta := kraken.angulos[j] + sin(t * 0.31 + fase * 1.3) * 0.12
		var rapidez := 5.0
		if j == kraken.tentaculo and a >= 0.0:
			var temblor := sin(t * 15.0 + fase) * 0.05 * carga * (1.0 - latigo)
			meta = _pose_latigo(meta, fases, largo_base, largo_golpe, temblor)
			onda = lerpf(0.15, onda, recoge)
			giro_meta = lerp_angle(giro_meta, hacia_golpe, smoothstep(0.0, 0.6, carga) * (1.0 - recoge))
			rapidez = 35.0 if latigo > 0.0 and latigo < 1.0 else 9.0
		if kraken.agonia >= 0.0:
			# Se retuerce y después se enrosca mientras se hunde.
			var retuerce := 1.0 - muere
			meta = Vector4(
				0.3 + sin(t * 6.0 + fase * 2.0) * 0.55 * retuerce + muere * 0.4,
				1.2 + sin(t * 4.3 + fase) * 0.8 * retuerce,
				1.0 + muere * 2.2,
				largo_base * (1.0 - muere * 0.3))
			onda = 1.1 * retuerce
			rapidez = 8.0
		var paso := 1.0 - exp(-delta * rapidez)
		kraken.poses[j] = kraken.poses[j].lerp(meta, paso)
		kraken.giros[j] = lerp_angle(kraken.giros[j], giro_meta, paso)
		var actual := kraken.poses[j]
		kraken.tentaculos[j].rotation.y = kraken.giros[j]
		materia.set_shader_parameter("tiempo", t)
		materia.set_shader_parameter("inclinacion", actual.x)
		materia.set_shader_parameter("curva", actual.y)
		materia.set_shader_parameter("curva_punta", actual.z)
		materia.set_shader_parameter("onda", onda)
		materia.set_shader_parameter("largo", actual.w)
		materia.set_shader_parameter("destello", destello)


# Pose (inclinación, curva, curva de la punta, largo) del tentáculo que ataca:
# se arma hacia atrás, restalla, arrastra por el agua y vuelve al reposo.
func _pose_latigo(reposo: Vector4, fases: Vector4, largo_base: float, largo_golpe: float, temblor: float) -> Vector4:
	var latigo := fases.y
	var arrastre := fases.z
	var armado := Vector4(-0.25 + temblor, 0.5, -1.6, largo_base * 1.1)
	var tendido := Vector4(1.42, 0.25, 0.3, largo_golpe)
	var pose := reposo.lerp(armado, fases.x)
	if latigo > 0.0:
		# La base va primero y la punta llega tarde: así restalla como un látigo.
		var base := latigo * latigo * (3.0 - 2.0 * latigo)
		var punta := smoothstep(0.3, 1.0, latigo)
		pose = armado.lerp(tendido, base)
		pose.z = lerpf(armado.z, tendido.z, punta)
	if arrastre > 0.0:
		pose = tendido
		pose.x += sin(arrastre * PI) * 0.06
		pose.z = tendido.z + arrastre * 1.3
		pose.w = largo_golpe * (1.0 - arrastre * 0.12)
	return pose.lerp(reposo, fases.w)


# Sombra del tentáculo bajo el agua y aro de espuma que se cierra sobre el punto del golpe.
func _animar_aviso_golpe(kraken: Kraken, t: float) -> void:
	var a := kraken.ataque
	if a < 0.0 or a >= MOMENTO_GOLPE + 0.06:
		return
	var sitio := mundo.a_3d(kraken.punto_golpe)
	var avance := clampf(a / MOMENTO_GOLPE, 0.0, 1.0)
	var apaga := 1.0 - clampf((a - MOMENTO_GOLPE) / 0.06, 0.0, 1.0)
	var crece := ease(avance, 0.5)
	kraken.aviso.visible = true
	kraken.aviso.position = sitio + Vector3(0.0, mundo.altura_mar(sitio.x, sitio.z) + 0.12, 0.0)
	kraken.aviso.scale = Vector3(1.0, 1.0, 1.0) * lerpf(0.55, 1.0, crece)
	kraken.aviso_materia.albedo_color = Color(0.05, 0.02, 0.08, (0.08 + 0.3 * crece) * apaga)
	var aro: Node3D = kraken.aviso.get_node("Aro")
	var cierra := lerpf(1.6, 1.0, crece) / lerpf(0.55, 1.0, crece)
	aro.scale = Vector3(cierra, 1.0, cierra)
	kraken.aviso_espuma.albedo_color = Color(1, 1, 1, (0.2 + 0.55 * avance + sin(t * 10.0) * 0.08 * avance) * apaga)


# Espuma alrededor del cuerpo, y salpicaduras mientras sale o se hunde.
func _espumar_kraken(kraken: Kraken, delta: float, centro: Vector2) -> void:
	kraken.espera_espuma -= delta
	if kraken.espera_espuma > 0.0:
		return
	kraken.espera_espuma = 0.1
	var angulo := randf() * TAU
	var borde := centro + Vector2.from_angle(angulo) * randf_range(1.8, 2.4) * TAM_KRAKEN
	mundo.crear_efecto(mundo.malla_espuma, Color(1, 1, 1, 0.45), Vector3(borde.x, kraken.altura + 0.08, borde.y), Vector3.ZERO, 1.4, 0.4, 1.1)
	if kraken.fuerza < 0.98:
		mundo.salpicar(kraken.pos + Vector2.from_angle(angulo) * RADIO_KRAKEN * 0.9, 3)
