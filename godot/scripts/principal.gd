class_name Principal
extends Node3D

const ESCALA := 0.05
const RADIO_MUNDO := 3900.0
const DANIO_BALA := 11.0
# Segundos de recarga de cada arma; iguales para el jugador y los bots.
const RECARGAS := {"proa": 1.8, "babor": 4.5, "estribor": 4.5}
# Botones de disparo: posición desde la esquina inferior derecha, radio y texto.
const BOTONES_FUEGO := {
	"proa": [Vector2(-150.0, -212.0), 40.0, "Frente"],
	"babor": [Vector2(-207.0, -112.0), 44.0, "Izq."],
	"estribor": [Vector2(-93.0, -112.0), 44.0, "Der."],
}
const VEL_BALA := 240.0
const VIDA_BALA := 1.15
const TOTAL_BARCOS := 50
const TOTAL_TABLAS := 34
const REPARACION := 26.0
const TABLAS_RESTOS := 3
# La música de batalla entra con un rival a esta distancia, al disparar o al recibir
# un cañonazo, y se mantiene unos segundos después del último motivo.
const DISTANCIA_COMBATE := 420.0
const DURACION_COMBATE := 7.0
const REPARACION_RESTOS := 14.0
# Segundos que flotan las tablas de un naufragio antes de hundirse.
const VIDA_RESTOS := 25.0
const ZONA_INICIAL := 3500.0
# Más allá de esta distancia a la cámara (metros 3D) los barcos y efectos no se dibujan.
const DISTANCIA_VISIBLE := 60.0
const RADIO_PALANCA := 60.0
const ALTO_HUD := 150.0
const CAMARA_JUEGO := Vector3(0.0, 18.0, 11.5)
# Radianes por segundo que gira sola la cámara alrededor del barco en el puerto.
const GIRO_MENU := 0.035
const GIRO_VITRINA := 0.12
# Segundos sin girar solo después de que el jugador mueva la cámara a mano.
const PAUSA_GIRO_MANUAL := 300.0
const LADO_AGUA := 190.0
const DIVISIONES_AGUA := 160
const ANCHO_PANEL := 540.0
const FRECUENCIA_AUDIO := 22050
const MONEDAS_VICTORIA := 15
const MONEDAS_POR_HUNDIDO := 1
# Monedas con que zarpa cada bot, para que hundirlos deje algo en el mar.
const BOTIN_INICIAL_BOTS := 3
# Segundos que flota un cofre antes de hundirse.
const VIDA_COFRE := 45.0
const ESPERA_BUSQUEDA := 4.0
const ESPERA_BOTS := 1.4
const NOMBRES_PIRATAS: Array[String] = [
	"La Sirena Roja", "El Tiburón", "Viento Salvaje", "La Gaviota", "Calavera Dorada",
	"El Kraken", "Marea Brava", "La Tempestad", "Barba de Hierro", "El Albatros",
	"La Furia", "Coral Negro", "El Corsario", "Bruma Gris", "La Venganza", "Ancla Rota",
	"Lobo de Mar", "La Medusa", "Trueno Azul", "El Bucanero",
]
const NOMBRES_SUELTOS: Array[String] = [
	"Garfio", "Barbarroja", "Ojo de Vidrio", "Pata de Palo", "Diente de Oro", "Morgan", "Calicó",
	"Mala Racha", "Tormentosa", "Viejo Ron", "Cuervo", "Escorpión", "Sable", "Perla Negra",
	"Medianoche", "Huracán", "Corsaria", "Bribón", "Pólvora", "Doblón",
]
const TITULOS_PIRATAS: Array[String] = ["Capitán", "Capitana", "Almirante", "Contramaestre", "Corsario"]

const DURACION_FASES: Array[float] = [68.0, 57.0, 51.0, 46.0, 43.0, 41.0, 40.0]
const RADIO_FASES: Array[float] = [2750.0, 2100.0, 1550.0, 1050.0, 650.0, 360.0, 190.0]

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

const COLOR_TEXTO := Color("f6efe2")
const COLOR_ORO := Color("e2b15a")
const COLOR_PELIGRO := Color("ff8a7a")
const COLOR_ARENA := Color("e9d6a8")
const COLOR_HIERBA := Color("4f9a55")
const COLOR_HIERBA_OSCURA := Color("2f7a48")
const COLOR_ROCA := Color("8b8f8c")
const COLOR_TRONCO := Color("8a6a45")
const COLOR_HOJA := Color("3f9a4f")
const COLORES_TABLA: Array[Color] = [Color("a7774a"), Color("8e6239"), Color("b88a58")]

enum Estado { MENU, ASTILLERO, BUSCANDO, JUGANDO, FIN, AJUSTES, NIVELES }


class Bala:
	var pos: Vector2
	var vel: Vector2
	var vida := 0.0
	var gracia := 0.15
	var dueno: Barco
	var nodo: MeshInstance3D


class Tabla:
	var pos: Vector2
	var vel := Vector2.ZERO
	var fase := 0.0
	var cura := REPARACION
	var de_restos := false
	var edad := 0.0
	var nodo: Node3D


class Cofre:
	var pos: Vector2
	var vel := Vector2.ZERO
	var monedas := 1
	var edad := 0.0
	var fase := 0.0
	var nodo: Node3D


class AvisoBotin:
	var punto: Vector3
	var texto := ""
	var color := Color.WHITE
	var vida := 1.6


class Efecto:
	var nodo: MeshInstance3D
	var material: StandardMaterial3D
	var color: Color
	var vel: Vector3
	var vida := 1.0
	var vida_max := 1.0
	var escala := 1.0
	var crece := 0.0
	var gravedad := 0.0


var estado := Estado.MENU
var personalizacion := Personalizacion.new()
var barcos: Array[Barco] = []
var jugador: Barco
var balas: Array = []
var tablas: Array = []
var cofres: Array = []
var avisos_botin: Array = []
var botin_perdido := 0
var texto_botin: Label
var efectos: Array = []
var islotes: Array = []

var zona_centro := Vector2.ZERO
var zona_radio := ZONA_INICIAL
var zona_desde := ZONA_INICIAL
var centro_desde := Vector2.ZERO
var centro_hacia := Vector2.ZERO
var fase := 0
var edad_fase := 0.0
var cierre := 0.0
var resultado := ""
var puesto := 0
var golpe := 0.0
var tiempo := 0.0

var palanca := Vector2.ZERO
var centro_palanca := Vector2.ZERO
var palanca_dedo := -1
var dedos_fuego := {}

var camara: Camera3D
var foco := Vector3.ZERO
var agua: MeshInstance3D
var material_agua: ShaderMaterial
var muro: MeshInstance3D
var islas_nodo: Node3D
var peligros: Peligros
var fauna: Fauna
var capa_barcos: Node3D
var materiales := {}
var materiales_orilla: Array[ShaderMaterial] = []
var malla_bala: SphereMesh
var malla_humo: SphereMesh
var malla_gota: SphereMesh
var malla_espuma: CylinderMesh
var malla_astilla: BoxMesh
var malla_musgo: SphereMesh
var malla_mata: SphereMesh

var sol: DirectionalLight3D
var entorno: Environment
var material_muro: ShaderMaterial
var nubes: MeshInstance3D
var material_nubes: ShaderMaterial
var lluvia: GPUParticles3D
var luz_rayo: OmniLight3D
var rayo: Node3D
var rayo_vida := 0.0
var relampago := 0.0
var proximo_rayo := 2.5
var truenos: Array = []
var voces_trueno: Array[AudioStreamPlayer] = []
var sonidos_trueno: Array[AudioStreamWAV] = []
var voces_canon: Array[AudioStreamPlayer] = []
var voz_monedas: AudioStreamPlayer
var voces_hundir: Array[AudioStreamPlayer] = []
var voz_equipar: AudioStreamPlayer
var destello: ColorRect

var velo_golpe: ColorRect
var marcadores: Control
var controles: Control
var hud: VBoxContainer
var texto_vivos: Label
var texto_tormenta: Label
var minimapa: Control
var panel_menu: Control
var panel_astillero: Control
var panel_final: Control
var titulo_final: Label
var texto_final: Label
var texto_premio: Label
var caja_final: PanelContainer
var lineas_premio: VBoxContainer
var texto_tesoro: Label
var fila_final: HBoxContainer
var capa_monedas: Control
var anim_premio: Tween
var ultimo_conteo := 0
var voz_moneda: AudioStreamPlayer
var texto_monedas_menu: Label
var insignia_menu: Insignia
var texto_nivel_menu: Label
var texto_xp_menu: Label
var barra_nivel_menu: Control
var panel_niveles: Control
var lista_niveles: VBoxContainer
var desliz_niveles: ScrollContainer
var texto_monedas_tienda: Label
var botones_categoria: Array = []
var rejilla_piezas: GridContainer
var desplazable: ScrollContainer
var botones_pieza := {}
var texto_pieza: Label
var boton_accion: Button
var categoria := "tipo"
var seleccion := ""
var hundidos := 0
var campo_nombre: LineEdit
var musica: Musica
var miniaturas: Miniaturas
var panel_ajustes: Control
var boton_ajustes: Button
var boton_idioma: BotonIdioma
var boton_partida: Button
var panel_partida: Control
var boton_salir: Button
var deslizadores_volumen: Array[HSlider] = []
var aviso_giro: Label
var tiempo_combate := 0.0
var angulo_puerto := 0.0
var altura_vitrina := 5.0
var distancia_vitrina := 11.0
var pausa_giro := 0.0
var dedos_vitrina := {}
var panel_busqueda: Control
var texto_busqueda: Label
var texto_jugadores: Label
var tiempo_busqueda := 0.0


func _ready() -> void:
	randomize()
	personalizacion.cargar()
	Idioma.instalar()
	Idioma.usar(personalizacion.idioma)
	_crear_buses()
	musica = Musica.new()
	add_child(musica)
	miniaturas = Miniaturas.new()
	add_child(miniaturas)
	_crear_escena()
	_crear_interfaz()
	_preparar_mar()
	_mostrar(Estado.MENU)


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	tiempo += delta
	if estado == Estado.JUGANDO:
		_actualizar(delta)
	else:
		golpe = maxf(0.0, golpe - delta)
	if estado == Estado.BUSCANDO:
		_avanzar_busqueda(delta)

	for barco in barcos:
		var cerca := a_3d(barco.pos).distance_to(Vector3(foco.x, 0.0, foco.z)) < DISTANCIA_VISIBLE
		if cerca or barco == jugador:
			barco.colocar(delta)
		barco.visible = (cerca or barco == jugador) and barco.hundimiento < 1.0
	_actualizar_tablas(delta)
	_actualizar_cofres(delta)
	_actualizar_efectos(delta)
	_mover_camara(delta)
	peligros.animar(delta)
	fauna.animar(delta)
	_recortar_islas(delta)
	_actualizar_tormenta(delta)
	_actualizar_agua()

	velo_golpe.color = Color(0.7, 0.12, 0.12, golpe)
	minimapa.queue_redraw()
	controles.queue_redraw()
	marcadores.queue_redraw()


func _actualizar(delta: float) -> void:
	_mover_zona(delta)
	for barco in barcos:
		barco.actualizar(delta)
	peligros.actualizar(delta)
	_separar_barcos()
	_recoger_tablas()
	_recoger_cofres()
	_mover_balas(delta)
	golpe = maxf(0.0, golpe - delta)
	tiempo_combate = maxf(0.0, tiempo_combate - delta)
	var rival: Barco = rival_mas_cercano(jugador) if jugador.viva else null
	if rival != null and rival.pos.distance_to(jugador.pos) < DISTANCIA_COMBATE:
		avisar_combate()
	musica.batalla = tiempo_combate > 0.0
	_revisar_fin(delta)
	_pintar_hud()


func a_3d(punto: Vector2, altura := 0.0) -> Vector3:
	return Vector3(punto.x * ESCALA, altura, punto.y * ESCALA)


# Escena 3D

func _crear_escena() -> void:
	entorno = Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color("8fc9cc")
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color("cfe9ee")
	entorno.ambient_light_energy = 0.35
	entorno.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	entorno.fog_enabled = true
	entorno.fog_light_color = Color("8fc3c6")
	entorno.fog_density = 0.003
	var ambiente := WorldEnvironment.new()
	ambiente.environment = entorno
	add_child(ambiente)

	sol = DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sol.light_energy = 0.8
	sol.light_color = Color("fff1d6")
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 90.0
	add_child(sol)

	camara = Camera3D.new()
	camara.fov = 42.0
	camara.keep_aspect = Camera3D.KEEP_HEIGHT
	camara.far = 400.0
	add_child(camara)
	camara.current = true

	var plano := PlaneMesh.new()
	plano.size = Vector2(LADO_AGUA, LADO_AGUA)
	plano.subdivide_width = DIVISIONES_AGUA
	plano.subdivide_depth = DIVISIONES_AGUA
	material_agua = ShaderMaterial.new()
	material_agua.shader = load("res://shaders/agua.gdshader")
	agua = MeshInstance3D.new()
	agua.mesh = plano
	agua.material_override = material_agua
	agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(agua)

	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 1.0
	cilindro.bottom_radius = 1.0
	cilindro.height = 12.0
	cilindro.radial_segments = 128
	cilindro.rings = 1
	cilindro.cap_top = false
	cilindro.cap_bottom = false
	material_muro = ShaderMaterial.new()
	material_muro.shader = load("res://shaders/tormenta.gdshader")
	muro = MeshInstance3D.new()
	muro.mesh = cilindro
	muro.material_override = material_muro
	muro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(muro)

	islas_nodo = Node3D.new()
	add_child(islas_nodo)
	peligros = Peligros.new()
	add_child(peligros)
	fauna = Fauna.new()
	add_child(fauna)
	capa_barcos = Node3D.new()
	add_child(capa_barcos)

	malla_bala = SphereMesh.new()
	malla_bala.radius = 0.15
	malla_bala.height = 0.3
	malla_bala.radial_segments = 12
	malla_bala.rings = 6
	malla_humo = SphereMesh.new()
	malla_humo.radius = 0.35
	malla_humo.height = 0.7
	malla_humo.radial_segments = 10
	malla_humo.rings = 5
	malla_gota = SphereMesh.new()
	malla_gota.radius = 0.08
	malla_gota.height = 0.16
	malla_gota.radial_segments = 6
	malla_gota.rings = 3
	malla_espuma = CylinderMesh.new()
	malla_espuma.top_radius = 0.35
	malla_espuma.bottom_radius = 0.35
	malla_espuma.height = 0.02
	malla_espuma.radial_segments = 14
	malla_espuma.rings = 1
	malla_astilla = BoxMesh.new()
	malla_astilla.size = Vector3(0.2, 0.06, 0.08)

	var techo := PlaneMesh.new()
	techo.size = Vector2(240.0, 240.0)
	material_nubes = ShaderMaterial.new()
	material_nubes.shader = load("res://shaders/nubes.gdshader")
	nubes = MeshInstance3D.new()
	nubes.mesh = techo
	nubes.material_override = material_nubes
	nubes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nubes)

	var gota := BoxMesh.new()
	gota.size = Vector3(0.025, 0.9, 0.025)
	var material_gota := StandardMaterial3D.new()
	material_gota.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_gota.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_gota.albedo_color = Color(0.8, 0.86, 1.0, 0.45)
	gota.material = material_gota
	var caida := ParticleProcessMaterial.new()
	caida.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	caida.emission_box_extents = Vector3(30.0, 0.5, 22.0)
	caida.direction = Vector3(0.18, -1.0, 0.06)
	caida.spread = 3.0
	caida.initial_velocity_min = 24.0
	caida.initial_velocity_max = 30.0
	caida.gravity = Vector3(0.0, -12.0, 0.0)
	caida.particle_flag_align_y = true
	lluvia = GPUParticles3D.new()
	lluvia.draw_pass_1 = gota
	lluvia.process_material = caida
	lluvia.amount = 900
	lluvia.lifetime = 0.75
	lluvia.preprocess = 0.75
	lluvia.local_coords = false
	lluvia.visibility_aabb = AABB(Vector3(-40, -20, -30), Vector3(80, 25, 60))
	lluvia.amount_ratio = 0.0
	add_child(lluvia)

	luz_rayo = OmniLight3D.new()
	luz_rayo.light_color = Color(0.75, 0.82, 1.0)
	luz_rayo.omni_range = 40.0
	luz_rayo.light_energy = 0.0
	add_child(luz_rayo)
	rayo = Node3D.new()
	add_child(rayo)

	_crear_sonidos()
	peligros.preparar(self)
	fauna.preparar(self)


func _crear_buses() -> void:
	for nombre in ["Musica", "Efectos"]:
		if AudioServer.get_bus_index(nombre) == -1:
			AudioServer.add_bus()
			var indice := AudioServer.bus_count - 1
			AudioServer.set_bus_name(indice, nombre)
			AudioServer.set_bus_send(indice, "Master")
	_aplicar_volumen()


func _aplicar_volumen() -> void:
	for par in [["Musica", personalizacion.volumen_musica], ["Efectos", personalizacion.volumen_efectos]]:
		var indice := AudioServer.get_bus_index(par[0])
		AudioServer.set_bus_mute(indice, par[1] <= 0.001)
		AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(par[1], 0.001)))


func _crear_sonidos() -> void:
	for _i in 2:
		sonidos_trueno.append(_sonido_trueno())
	for _i in 2:
		var voz := AudioStreamPlayer.new()
		voz.bus = "Efectos"
		add_child(voz)
		voces_trueno.append(voz)
	var canon := _sonido_canon()
	for _i in 6:
		var voz := AudioStreamPlayer.new()
		voz.stream = canon
		voz.bus = "Efectos"
		add_child(voz)
		voces_canon.append(voz)
	var hundir := _sonido_hundir()
	for _i in 3:
		var voz := AudioStreamPlayer.new()
		voz.stream = hundir
		voz.bus = "Efectos"
		add_child(voz)
		voces_hundir.append(voz)
	voz_monedas = AudioStreamPlayer.new()
	voz_monedas.stream = _sonido_monedas()
	voz_monedas.bus = "Efectos"
	voz_monedas.volume_db = -16.0
	add_child(voz_monedas)
	voz_moneda = AudioStreamPlayer.new()
	voz_moneda.stream = _sonido_monedas([0.0])
	voz_moneda.bus = "Efectos"
	voz_moneda.volume_db = -22.0
	voz_moneda.max_polyphony = 4
	add_child(voz_moneda)
	voz_equipar = AudioStreamPlayer.new()
	voz_equipar.stream = _sonido_equipar()
	voz_equipar.bus = "Efectos"
	voz_equipar.volume_db = -13.0
	add_child(voz_equipar)


func _paso_grave(frecuencia_corte: float) -> float:
	return 1.0 - exp(-TAU * frecuencia_corte / FRECUENCIA_AUDIO)


func _normalizar(valores: PackedFloat32Array, pico_deseado := 1.0) -> PackedFloat32Array:
	var pico := 0.0001
	for valor in valores:
		pico = maxf(pico, absf(valor))
	for i in valores.size():
		valores[i] = valores[i] / pico * pico_deseado
	return valores


func _a_wav(valores: PackedFloat32Array, bucle := false) -> AudioStreamWAV:
	valores = _normalizar(valores, 0.8)
	var datos := PackedByteArray()
	datos.resize(valores.size() * 2)
	for i in valores.size():
		datos.encode_s16(i * 2, int(valores[i] * 32767.0))
	var sonido := AudioStreamWAV.new()
	sonido.format = AudioStreamWAV.FORMAT_16_BITS
	sonido.mix_rate = FRECUENCIA_AUDIO
	sonido.stereo = false
	sonido.data = datos
	if bucle:
		sonido.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sonido.loop_end = valores.size()
	return sonido


func _sonido_trueno() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA_AUDIO * 4.0)
	var retumbo := PackedFloat32Array()
	var chasquido := PackedFloat32Array()
	retumbo.resize(muestras)
	chasquido.resize(muestras)
	var a_grave := _paso_grave(110.0)
	var a_medio := _paso_grave(700.0)
	var grave_1 := 0.0
	var grave_2 := 0.0
	var medio := 0.0
	var golpes := [0.0, randf_range(0.5, 0.9), randf_range(1.3, 1.9), randf_range(2.1, 2.7)]
	for i in muestras:
		var t := float(i) / FRECUENCIA_AUDIO
		var blanco := randf_range(-1.0, 1.0)
		grave_1 += a_grave * (blanco - grave_1)
		grave_2 += a_grave * (grave_1 - grave_2)
		medio += a_medio * (blanco - medio)
		var envolvente := 0.0
		for k in golpes.size():
			var desde: float = t - golpes[k]
			if desde > 0.0:
				envolvente += (1.0 - exp(-desde * 8.0)) * exp(-desde * 1.5) * (1.0 if k == 0 else 0.55)
		retumbo[i] = grave_2 * envolvente * (1.0 - t / 4.0)
		chasquido[i] = medio * exp(-t * 14.0)
	retumbo = _normalizar(retumbo)
	chasquido = _normalizar(chasquido)
	for i in muestras:
		retumbo[i] = retumbo[i] + chasquido[i] * 0.18
	return _a_wav(retumbo)


func _sonido_canon() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA_AUDIO * 1.3)
	var tono := PackedFloat32Array()
	var estruendo := PackedFloat32Array()
	var chasquido := PackedFloat32Array()
	tono.resize(muestras)
	estruendo.resize(muestras)
	chasquido.resize(muestras)
	var a_grave := _paso_grave(450.0)
	var a_agudo := _paso_grave(2200.0)
	var grave := 0.0
	var agudo := 0.0
	var fase_tono := 0.0
	for i in muestras:
		var t := float(i) / FRECUENCIA_AUDIO
		var blanco := randf_range(-1.0, 1.0)
		grave += a_grave * (blanco - grave)
		agudo += a_agudo * (blanco - agudo)
		fase_tono += TAU * (42.0 + 70.0 * exp(-t * 9.0)) / FRECUENCIA_AUDIO
		var ataque := 1.0 - exp(-t * 600.0)
		tono[i] = sin(fase_tono) * exp(-t * 5.0) * ataque
		estruendo[i] = grave * exp(-t * 6.0) * ataque
		chasquido[i] = agudo * exp(-t * 40.0)
	tono = _normalizar(tono)
	estruendo = _normalizar(estruendo)
	chasquido = _normalizar(chasquido)
	for i in muestras:
		tono[i] = tono[i] + estruendo[i] * 0.75 + chasquido[i] * 0.3
	return _a_wav(tono)


func _sonido_monedas(choques: Array = [0.0, 0.07, 0.15, 0.21, 0.3, 0.36, 0.47]) -> AudioStreamWAV:
	var muestras := int(FRECUENCIA_AUDIO * (choques.back() + 0.43))
	var valores := PackedFloat32Array()
	valores.resize(muestras)
	# Parciales inarmónicos de un disco metálico pequeño.
	# Todos por debajo de la mitad de FRECUENCIA_AUDIO para que no suenen ásperos.
	var parciales := [1.0, 2.32, 3.86]
	for k in choques.size():
		var inicio := int(choques[k] * FRECUENCIA_AUDIO)
		var base := randf_range(1400.0, 1900.0)
		var fuerza := 1.0 - k * 0.09
		for i in range(inicio, muestras):
			var t := float(i - inicio) / FRECUENCIA_AUDIO
			var sonido := 0.0
			for p in parciales.size():
				sonido += sin(TAU * base * parciales[p] * t) * exp(-t * (16.0 + p * 18.0)) / (1.0 + p * 1.5)
			sonido += randf_range(-1.0, 1.0) * exp(-t * 400.0) * 0.12
			valores[i] += sonido * fuerza * (1.0 - exp(-t * 1500.0))
	return _a_wav(valores)


# Crujido de la madera al partirse, agua entrando y burbujas que suben.
func _sonido_hundir() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA_AUDIO * 3.2)
	var valores := PackedFloat32Array()
	valores.resize(muestras)
	var a_grave := _paso_grave(260.0)
	var grave_1 := 0.0
	var grave_2 := 0.0
	var ola_1 := 0.0
	var ola_2 := 0.0
	var fase_queja := 0.0
	for i in muestras:
		var t := float(i) / FRECUENCIA_AUDIO
		var blanco := randf_range(-1.0, 1.0)
		# Golpe de agua: ruido filtrado cuyo corte baja de 1200 a 250 Hz.
		var a_ola := _paso_grave(lerpf(1200.0, 250.0, minf(1.0, t / 1.2)))
		ola_1 += a_ola * (blanco - ola_1)
		ola_2 += a_ola * (ola_1 - ola_2)
		var golpe := (1.0 - exp(-t * 40.0)) * exp(-t * 2.2)
		# Agua entrando: rumor grave que crece y se apaga.
		grave_1 += a_grave * (blanco - grave_1)
		grave_2 += a_grave * (grave_1 - grave_2)
		var entrada := smoothstep(0.2, 0.9, t) * exp(-maxf(0.0, t - 1.0) * 1.4)
		# Quejido de la madera: tono grave que se dobla hacia abajo.
		fase_queja += TAU * (lerpf(105.0, 62.0, minf(1.0, t / 1.6)) + 2.0 * sin(t * 9.0)) / FRECUENCIA_AUDIO
		var queja := (sin(fase_queja) + 0.3 * sin(fase_queja * 2.0)) * smoothstep(0.05, 0.35, t) * exp(-maxf(0.0, t - 0.4) * 2.0)
		valores[i] = ola_2 * golpe * 1.6 + grave_2 * entrada * 3.0 + queja * 0.22
	for _b in 14:
		var inicio := randf_range(0.7, 2.7)
		var tono := randf_range(140.0, 380.0)
		var desde := int(inicio * FRECUENCIA_AUDIO)
		var fase_burbuja := 0.0
		for i in range(desde, mini(muestras, desde + int(FRECUENCIA_AUDIO * 0.14))):
			var t := float(i - desde) / FRECUENCIA_AUDIO
			fase_burbuja += TAU * tono * (1.0 + t * 5.0) / FRECUENCIA_AUDIO
			valores[i] += sin(fase_burbuja) * (1.0 - exp(-t * 300.0)) * exp(-t * 28.0) * 0.18 * (1.0 - inicio / 3.4)
	return _a_wav(valores)


func _sonido_equipar() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA_AUDIO * 0.85)
	var valores := PackedFloat32Array()
	valores.resize(muestras)
	# Arpegio mayor ascendente (do-mi-sol-do) con timbre de campanilla.
	var notas := [[523.25, 0.0], [659.25, 0.07], [783.99, 0.14], [1046.5, 0.21]]
	for nota in notas:
		var frecuencia: float = nota[0]
		var inicio := int(float(nota[1]) * FRECUENCIA_AUDIO)
		var es_ultima: bool = nota == notas.back()
		var caida := 4.5 if es_ultima else 9.0
		for i in range(inicio, muestras):
			var t := float(i - inicio) / FRECUENCIA_AUDIO
			var vibrato := 1.0 + 0.004 * sin(TAU * 6.0 * t) if es_ultima else 1.0
			var fase := TAU * frecuencia * vibrato * t
			var sonido := sin(fase) + 0.35 * sin(fase * 2.0) * exp(-t * 6.0) + 0.15 * sin(fase * 3.0) * exp(-t * 12.0)
			valores[i] += sonido * exp(-t * caida) * (1.0 - exp(-t * 900.0)) * (1.2 if es_ultima else 0.8)
	return _a_wav(valores)


func _sonar_en_vista(voces: Array[AudioStreamPlayer], punto: Vector3, volumen_cerca: float, volumen_lejos: float, alcance: float) -> void:
	if not camara.is_position_in_frustum(punto):
		return
	var cercania := clampf(1.0 - punto.distance_to(foco) / alcance, 0.0, 1.0)
	for voz in voces:
		if not voz.playing:
			voz.volume_db = lerpf(volumen_lejos, volumen_cerca, cercania)
			voz.pitch_scale = randf_range(0.88, 1.08)
			voz.play()
			return


func material(color: Color) -> StandardMaterial3D:
	if not materiales.has(color):
		var nuevo := StandardMaterial3D.new()
		nuevo.albedo_color = color
		nuevo.roughness = 0.85
		materiales[color] = nuevo
	return materiales[color]


func _malla(padre: Node3D, forma: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = forma
	pieza.material_override = material(color)
	pieza.position = pos
	padre.add_child(pieza)
	return pieza


var espera_recorte := 0.0


# Las islas lejanas no se dibujan (con sus palmeras, animales y sombras); en puerto
# la cámara mira al horizonte y se ven más lejos.
func _recortar_islas(delta: float) -> void:
	espera_recorte -= delta
	if espera_recorte > 0.0:
		return
	espera_recorte = 0.2
	var alcance := DISTANCIA_VISIBLE + 8.0 if estado == Estado.JUGANDO or estado == Estado.FIN else 170.0
	var foco_plano := Vector2(foco.x, foco.z)
	for nodo: Node3D in islas_nodo.get_children():
		var borde: float = nodo.get_meta("radio", 0.0) * ALCANCE_ORILLA * 1.15
		nodo.visible = Vector2(nodo.position.x, nodo.position.z).distance_to(foco_plano) < alcance + borde


func _repartir_islotes(cantidad: int, radio_min: float, radio_max: float, centro := Vector2.ZERO,
		alcance := RADIO_MUNDO * 0.85, separacion := SEPARACION_ISLAS) -> void:
	var puestos := 0
	for _intento in cantidad * 30:
		if puestos >= cantidad:
			return
		var radio := randf_range(radio_min, radio_max)
		var punto := centro + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * alcance
		if punto.length() < 200.0 or punto.length() > RADIO_MUNDO * 0.88:
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
			centro = Vector2.from_angle(randf() * TAU) * sqrt(randf()) * RADIO_MUNDO * 0.78
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


func _crear_rocas(isla: Circulo) -> Node3D:
	var nodo := Node3D.new()
	nodo.position = a_3d(isla.pos)
	nodo.rotation.y = randf() * TAU
	var r := isla.radio * ESCALA
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


func _crear_isla(isla: Circulo) -> Node3D:
	var nodo := Node3D.new()
	nodo.position = a_3d(isla.pos)
	var r := isla.radio * ESCALA
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
	var alto_palmera := func() -> float: return randf_range(1.6, 2.2) if chica else randf_range(2.0, 2.8)
	for i in (randi_range(1, 2) if chica else randi_range(2, 3)):
		var angulo := randf() * TAU
		var base := Vector3(cos(angulo), 0.0, sin(angulo)) * r_centro * randf_range(sitio_palmeras[0], sitio_palmeras[1])
		palmeras.append(_palmera(nodo, base + Vector3(0, sitio_palmeras[2], 0), alto_palmera.call()))

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
			palmeras.append(_palmera(nodo, Vector3(sitio.x, 0.45 + loma.height * 0.35, sitio.y), alto_palmera.call()))

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

	nodo.add_child(_orilla(r * 1.15, isla.forma))
	nodo.set_meta("radio", r)
	fauna.poblar(nodo, r, chica, palmeras, isla)
	return nodo


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


func _crear_tabla() -> Node3D:
	var nodo := Node3D.new()
	var tabla := BoxMesh.new()
	tabla.size = Vector3(1.0, 0.08, 0.22)
	for i in 3:
		var pieza := _malla(nodo, tabla, COLORES_TABLA[i], Vector3(randf_range(-0.06, 0.06), 0.0, (i - 1) * 0.25))
		pieza.rotation.y = randf_range(-0.08, 0.08)
	var travesano := BoxMesh.new()
	travesano.size = Vector3(0.12, 0.06, 0.8)
	for lado in [-1.0, 1.0]:
		_malla(nodo, travesano, Color("5e4028"), Vector3(lado * 0.32, 0.07, 0.0))

	var aro := TorusMesh.new()
	aro.inner_radius = 0.82
	aro.outer_radius = 0.95
	aro.rings = 32
	aro.ring_segments = 4
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	brillo.albedo_color = Color(1.0, 0.85, 0.4, 0.7)
	var anillo := MeshInstance3D.new()
	anillo.mesh = aro
	anillo.material_override = brillo
	anillo.scale = Vector3(1.0, 0.2, 1.0)
	anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nodo.add_child(anillo)
	return nodo


func _actualizar_agua() -> void:
	var paso := LADO_AGUA / float(DIVISIONES_AGUA + 1)
	agua.position = Vector3(snappedf(foco.x, paso), 0.0, snappedf(foco.z, paso))
	nubes.position = Vector3(agua.position.x, 7.5, agua.position.z)
	for materia in [material_agua, material_nubes]:
		materia.set_shader_parameter("zona_centro", zona_centro * ESCALA)
		materia.set_shader_parameter("zona_radio", zona_radio * ESCALA)
		materia.set_shader_parameter("relampago", relampago)
	material_agua.set_shader_parameter("tiempo", tiempo)
	for materia in materiales_orilla:
		materia.set_shader_parameter("tiempo", tiempo)
		materia.set_shader_parameter("zona_centro", zona_centro * ESCALA)
		materia.set_shader_parameter("zona_radio", zona_radio * ESCALA)
	material_muro.set_shader_parameter("relampago", relampago)
	muro.position = a_3d(zona_centro, 4.0)
	muro.scale = Vector3(zona_radio * ESCALA, 1.0, zona_radio * ESCALA)


# Misma fórmula que altura_mar() en agua.gdshader, en metros del mundo 3D.
func altura_mar(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var radio := zona_radio * ESCALA
	var fuera := smoothstep(radio, radio + 8.0, p.distance_to(zona_centro * ESCALA))
	var h := _ola(p, Vector2(1.0, 0.3), 14.0, 0.12) + _ola(p, Vector2(-0.4, 1.0), 9.0, 0.08) + _ola(p, Vector2(0.7, -0.7), 6.0, 0.05) \
		+ _ola(p, Vector2(-0.8, -0.35), 4.3, 0.04)
	return peligros.ajustar_mar(x, z, h * (1.0 + fuera * 2.0) + _ola(p, Vector2(0.2, 1.0), 21.0, 0.35) * fuera)


func _ola(p: Vector2, direccion: Vector2, largo: float, amplitud: float) -> float:
	var k := TAU / largo
	var s := sin(direccion.normalized().dot(p) * k - sqrt(9.8 * k) * tiempo)
	return amplitud * (2.0 * pow(0.5 + 0.5 * s, 1.8) - 0.6)


func fuerza_tormenta(punto: Vector2) -> float:
	return clampf((punto.distance_to(zona_centro) - zona_radio) / 160.0, 0.0, 1.0)


func _actualizar_tormenta(delta: float) -> void:
	var activa := estado == Estado.JUGANDO or estado == Estado.FIN
	relampago = maxf(0.0, relampago - delta * 3.0)
	luz_rayo.light_energy = relampago * 5.0
	destello.color = Color(0.85, 0.9, 1.0, relampago * 0.15)

	rayo_vida -= delta
	if rayo_vida <= 0.0:
		for hijo in rayo.get_children():
			hijo.queue_free()
	else:
		rayo.visible = fmod(rayo_vida, 0.08) > 0.03

	var foco_plano := Vector2(foco.x, foco.z) / ESCALA
	var al_borde := zona_radio - foco_plano.distance_to(zona_centro)
	var intensidad := clampf(1.0 - al_borde / 500.0, 0.0, 1.0) if activa else 0.0
	lluvia.position = foco + Vector3(0.0, 14.0, 0.0)
	lluvia.amount_ratio = lerpf(lluvia.amount_ratio, intensidad, minf(1.0, delta * 2.0))
	var en_tormenta := fuerza_tormenta(jugador.pos) if activa and jugador != null else 0.0
	sol.light_energy = lerpf(sol.light_energy, lerpf(0.8, 0.3, en_tormenta), minf(1.0, delta * 2.0))
	entorno.ambient_light_energy = lerpf(entorno.ambient_light_energy, lerpf(0.35, 0.18, en_tormenta), minf(1.0, delta * 2.0))

	for i in range(truenos.size() - 1, -1, -1):
		truenos[i]["espera"] -= delta
		if truenos[i]["espera"] <= 0.0:
			_tronar(truenos[i]["volumen"])
			truenos.remove_at(i)

	if not activa:
		return
	proximo_rayo -= delta
	if proximo_rayo <= 0.0:
		proximo_rayo = randf_range(1.2, 3.2)
		_caer_rayo(foco_plano)


func _caer_rayo(foco_plano: Vector2) -> void:
	var punto := foco_plano + Vector2.from_angle(randf() * TAU) * randf_range(120.0, 700.0)
	var expuestos: Array[Barco] = []
	for barco in barcos:
		if barco.viva and fuerza_tormenta(barco.pos) > 0.0 and barco.pos.distance_to(foco_plano) < 900.0:
			expuestos.append(barco)
	if not expuestos.is_empty() and randf() < 0.45:
		var victima: Barco = expuestos.pick_random()
		punto = victima.pos + Vector2.from_angle(randf() * TAU) * randf_range(10.0, 90.0)

	var desde_centro := punto - zona_centro
	var minimo := zona_radio + 50.0
	if desde_centro.length() < minimo:
		var direccion := desde_centro.normalized() if desde_centro.length() > 1.0 else Vector2.RIGHT
		punto = zona_centro + direccion * (minimo + randf_range(0.0, 300.0))

	var distancia := punto.distance_to(foco_plano) * ESCALA
	var cerca := clampf(1.0 - distancia / 60.0, 0.0, 1.0)
	var a_la_vista := camara.is_position_in_frustum(a_3d(punto)) or camara.is_position_in_frustum(a_3d(punto, 8.0))
	if a_la_vista:
		relampago = maxf(relampago, 0.3 + 0.7 * cerca)
		luz_rayo.position = a_3d(punto, 9.0)
		_dibujar_rayo(a_3d(punto))
		salpicar(punto, 12)
		truenos.append({"espera": 0.1 + distancia / 45.0, "volumen": lerpf(-28.0, -11.0, cerca)})
	for barco in barcos:
		if barco.viva and barco.pos.distance_to(punto) < barco.radio + 40.0:
			barco.recibir_danio(18.0, true)
			if barco.es_jugador:
				golpe = 0.35


func _dibujar_rayo(suelo: Vector3) -> void:
	for hijo in rayo.get_children():
		hijo.queue_free()
	var material_rayo := StandardMaterial3D.new()
	material_rayo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_rayo.albedo_color = Color(0.95, 0.97, 1.0)
	var material_halo := StandardMaterial3D.new()
	material_halo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_halo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material_halo.albedo_color = Color(0.4, 0.5, 1.0, 0.35)
	var tramo := BoxMesh.new()
	tramo.size = Vector3(0.4, 1.0, 0.4)
	var puntos: Array[Vector3] = []
	var actual := suelo + Vector3(randf_range(-3.0, 3.0), 18.0, randf_range(-3.0, 3.0))
	puntos.append(actual)
	for i in 9:
		var t := float(i + 1) / 9.0
		var siguiente := actual.lerp(suelo, 1.0 / (9 - i)) + Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-1.2, 1.2)) * (1.0 - t)
		puntos.append(siguiente)
		actual = siguiente
	puntos[puntos.size() - 1] = suelo
	for i in puntos.size() - 1:
		_tramo_rayo(puntos[i], puntos[i + 1], tramo, material_rayo, 1.0)
		_tramo_rayo(puntos[i], puntos[i + 1], tramo, material_halo, 2.2)
		if i in [2, 5]:
			var rama := puntos[i] + Vector3(randf_range(-3.0, 3.0), -randf_range(2.0, 4.0), randf_range(-3.0, 3.0))
			_tramo_rayo(puntos[i], rama, tramo, material_rayo, 0.6)
			_tramo_rayo(puntos[i], rama, tramo, material_halo, 1.5)
	rayo.visible = true
	rayo_vida = 0.35


func _tramo_rayo(a: Vector3, b: Vector3, forma: BoxMesh, materia: StandardMaterial3D, grosor: float) -> void:
	var eje := b - a
	var largo := eje.length()
	if largo < 0.01:
		return
	var y := eje / largo
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y).normalized()
	var pieza := MeshInstance3D.new()
	pieza.mesh = forma
	pieza.material_override = materia
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pieza.transform = Transform3D(Basis(x * grosor, y * largo, z * grosor), (a + b) / 2.0)
	rayo.add_child(pieza)


func _tronar(volumen: float) -> void:
	for voz in voces_trueno:
		if not voz.playing:
			voz.stream = sonidos_trueno.pick_random()
			voz.volume_db = volumen
			voz.pitch_scale = randf_range(0.85, 1.05)
			voz.play()
			return


func _mover_camara(delta: float) -> void:
	if jugador == null:
		return
	var objetivo := jugador.position
	var en_puerto := estado in [Estado.MENU, Estado.ASTILLERO, Estado.BUSCANDO, Estado.AJUSTES, Estado.NIVELES]
	if en_puerto:
		var vitrina := estado == Estado.ASTILLERO
		pausa_giro -= delta
		if not vitrina or pausa_giro <= 0.0:
			angulo_puerto += delta * (GIRO_VITRINA if vitrina else GIRO_MENU)
		var lejos := distancia_vitrina if vitrina else 11.0
		var alto := altura_vitrina if vitrina else 5.0
		var deseada := objetivo + Vector3(sin(angulo_puerto) * lejos, alto, cos(angulo_puerto) * lejos)
		camara.position = camara.position.lerp(deseada, minf(1.0, delta * (7.0 if vitrina else 2.0)))
		foco = foco.lerp(objetivo + Vector3(0, 1.2, 0), minf(1.0, delta * 2.0))
		camara.h_offset = lerpf(camara.h_offset, 3.6, minf(1.0, delta * 2.0))
	else:
		var avance := jugador.proa() * jugador.velocidad * ESCALA * 0.7
		foco = foco.lerp(objetivo + Vector3(avance.x, 0.0, avance.y), minf(1.0, delta * 2.2))
		camara.position = camara.position.lerp(foco + CAMARA_JUEGO, minf(1.0, delta * 2.6))
		camara.h_offset = lerpf(camara.h_offset, 0.0, minf(1.0, delta * 2.0))
	camara.look_at(foco, Vector3.UP)


# Partida

func _preparar_mar() -> void:
	for barco in barcos:
		barco.queue_free()
	barcos.clear()
	for bala in balas:
		bala.nodo.queue_free()
	balas.clear()
	for tabla in tablas:
		tabla.nodo.queue_free()
	tablas.clear()
	for cofre in cofres:
		cofre.nodo.queue_free()
	cofres.clear()
	avisos_botin.clear()
	botin_perdido = 0
	for efecto in efectos:
		efecto.nodo.queue_free()
	efectos.clear()
	for hijo in islas_nodo.get_children():
		hijo.queue_free()
	islotes.clear()
	materiales_orilla.clear()
	fauna.limpiar()

	# Cerca del centro, donde acaba la tormenta, siempre hay islas para cubrirse.
	_repartir_islotes(ISLAS_CENTRO, 55.0, 85.0, Vector2.ZERO, 650.0)
	_repartir_islotes(ISLAS_GRANDES, 58.0, 96.0)
	_repartir_archipielagos()
	_repartir_islotes(ISLOTES_CHICOS, 40.0, 54.0)
	_repartir_islotes(GRUPOS_ROCAS, 22.0, 34.0, Vector2.ZERO, RADIO_MUNDO * 0.85, 80.0)
	for isla in islotes:
		if isla.radio <= RADIO_ROCAS:
			islas_nodo.add_child(_crear_rocas(isla))
		else:
			isla.radio *= 1.15
			isla.dar_forma()
			islas_nodo.add_child(_crear_isla(isla))

	zona_centro = Vector2.ZERO
	zona_radio = ZONA_INICIAL
	peligros.reiniciar()
	zona_radio = ZONA_INICIAL
	zona_desde = ZONA_INICIAL
	centro_desde = Vector2.ZERO
	centro_hacia = Vector2.ZERO
	fase = 0
	edad_fase = 0.0
	cierre = 0.0
	resultado = ""
	puesto = 0
	golpe = 0.0
	hundidos = 0
	truenos.clear()
	proximo_rayo = 2.5
	rayo_vida = 0.0

	var alcance := ZONA_INICIAL * 0.9
	jugador = _crear_barco(personalizacion, true, _punto_libre(300.0, alcance))
	jugador.nombre = personalizacion.nombre_visible()
	var nombres := _nombres_bots(TOTAL_BARCOS - 1)
	for i in range(1, TOTAL_BARCOS):
		var bot := _crear_barco(Personalizacion.al_azar(), false, _punto_libre(300.0, alcance))
		bot.nombre = nombres[i - 1]
		bot.botin = randi_range(0, BOTIN_INICIAL_BOTS)
		bot.es_bot = true
	for _i in TOTAL_TABLAS:
		_soltar_tabla()

	foco = jugador.position
	camara.position = jugador.position + Vector3(0.0, 5.0, 11.0)


func _crear_barco(aspecto: Personalizacion, es_jugador: bool, pos: Vector2) -> Barco:
	var barco := Barco.new()
	barco.pos = pos
	barco.rumbo = randf_range(-PI, PI)
	capa_barcos.add_child(barco)
	barco.preparar(aspecto, es_jugador, self)
	barco.colocar(0.0)
	barcos.append(barco)
	return barco


func _nombres_bots(cantidad: int) -> Array[String]:
	var nombres: Array[String] = NOMBRES_PIRATAS.duplicate()
	var sueltos := NOMBRES_SUELTOS.duplicate()
	sueltos.shuffle()
	var vuelta := 0
	while nombres.size() < cantidad:
		var suelto: String = sueltos[vuelta % sueltos.size()]
		var titulo := TITULOS_PIRATAS[(vuelta + vuelta / sueltos.size()) % TITULOS_PIRATAS.size()]
		nombres.append("%s %s" % [titulo, suelto])
		vuelta += 1
	nombres.shuffle()
	return nombres


func _punto_libre(radio_min: float, radio_max: float) -> Vector2:
	for _intento in 50:
		var distancia := sqrt(randf_range(radio_min * radio_min, radio_max * radio_max))
		var punto := Vector2.from_angle(randf() * TAU) * distancia
		var libre := true
		for isla in islotes:
			if punto.distance_to(isla.pos) < isla.radio + 60.0:
				libre = false
		for barco in barcos:
			if punto.distance_to(barco.pos) < 380.0:
				libre = false
		if peligros.cerca(punto, 250.0):
			libre = false
		if libre:
			return punto
	return Vector2.from_angle(randf() * TAU) * radio_min


func _soltar_tabla() -> void:
	for _intento in 20:
		var alcance := maxf(120.0, zona_radio * 0.75)
		var punto := zona_centro + Vector2.from_angle(randf() * TAU) * randf() * alcance
		var libre := true
		for isla in islotes:
			if punto.distance_to(isla.pos) < isla.radio + 30.0:
				libre = false
		for barco in barcos:
			if barco.viva and punto.distance_to(barco.pos) < 70.0:
				libre = false
		if libre:
			_poner_tabla(punto)
			return


func _poner_tabla(punto: Vector2) -> Tabla:
	var tabla := Tabla.new()
	tabla.pos = punto
	tabla.fase = randf() * TAU
	tabla.nodo = _crear_tabla()
	tabla.nodo.position = a_3d(punto, 0.1)
	add_child(tabla.nodo)
	tablas.append(tabla)
	return tabla


# Los restos de un barco hundido: tablas que se separan del naufragio y reparan menos.
func _soltar_restos(centro: Vector2) -> void:
	for k in TABLAS_RESTOS:
		var direccion := Vector2.from_angle(TAU * k / TABLAS_RESTOS + randf_range(-0.4, 0.4))
		var tabla := _poner_tabla(centro + direccion * 12.0)
		tabla.vel = direccion * randf_range(30.0, 45.0)
		tabla.cura = REPARACION_RESTOS
		tabla.de_restos = true


func _actualizar_tablas(delta: float) -> void:
	for i in range(tablas.size() - 1, -1, -1):
		var tabla: Tabla = tablas[i]
		if tabla.de_restos and estado == Estado.JUGANDO:
			tabla.edad += delta
			if tabla.edad >= VIDA_RESTOS:
				tabla.nodo.queue_free()
				tablas.remove_at(i)
				continue
		tabla.pos += peligros.arrastre(tabla.pos) * delta
		if tabla.vel != Vector2.ZERO:
			var siguiente: Vector2 = tabla.pos + tabla.vel * delta
			for isla in islotes:
				if isla.dentro(siguiente, 8.0):
					tabla.vel = Vector2.ZERO
			if tabla.vel != Vector2.ZERO:
				tabla.pos = siguiente
				tabla.vel *= maxf(0.0, 1.0 - delta * 1.2)
				if tabla.vel.length() < 2.0:
					tabla.vel = Vector2.ZERO
		var sitio := a_3d(tabla.pos)
		var hundida := clampf((tabla.edad - VIDA_RESTOS + 2.0) / 2.0, 0.0, 1.0)
		tabla.nodo.position = a_3d(tabla.pos, 0.1 + altura_mar(sitio.x, sitio.z) - hundida * 0.6)
		tabla.nodo.rotation.y += delta * 0.5


func _recoger_tablas() -> void:
	for i in range(tablas.size() - 1, -1, -1):
		var tabla: Tabla = tablas[i]
		for barco in barcos:
			if barco.viva and barco.pos.distance_to(tabla.pos) < barco.radio + 18.0:
				barco.vida = minf(barco.vida_max, barco.vida + tabla.cura)
				_brillo_reparacion(a_3d(tabla.pos, 0.4))
				tabla.nodo.queue_free()
				tablas.remove_at(i)
				break
	if tablas.filter(func(t: Tabla) -> bool: return not t.de_restos).size() < _tablas_deseadas():
		_soltar_tabla()


# Las tablas sueltas se reparten según el tamaño de la zona: cuando se achica hay pocas.
func _tablas_deseadas() -> int:
	var area := pow(zona_radio / ZONA_INICIAL, 2.0)
	return clampi(roundi(TOTAL_TABLAS * area), 2, TOTAL_TABLAS)


func _mover_zona(delta: float) -> void:
	edad_fase += delta
	var duracion: float = DURACION_FASES[fase]
	var avance := minf(1.0, edad_fase / duracion)
	zona_radio = lerpf(zona_desde, RADIO_FASES[fase], avance)
	# El centro se desliza a la vez que se encoge el radio, nunca de golpe.
	zona_centro = centro_desde.lerp(centro_hacia, avance)
	if edad_fase >= duracion and fase < DURACION_FASES.size() - 1:
		fase += 1
		edad_fase = 0.0
		zona_desde = zona_radio
		centro_desde = zona_centro
		var corrimiento := Vector2.from_angle(randf() * TAU) * RADIO_FASES[fase] * 0.18
		centro_hacia = (zona_centro + corrimiento).limit_length(RADIO_MUNDO * 0.25)


func _separar_barcos() -> void:
	for i in barcos.size():
		var a: Barco = barcos[i]
		if not a.viva:
			continue
		for j in range(i + 1, barcos.size()):
			var b: Barco = barcos[j]
			if not b.viva:
				continue
			var separacion := b.pos - a.pos
			var dist := separacion.length()
			var minimo := (a.radio + b.radio) * 0.85
			if dist < minimo and dist > 0.001:
				var empuje := separacion / dist * (minimo - dist) / 2.0
				a.pos -= empuje
				b.pos += empuje


# "proa" dispara un cañón hacia delante; "babor" y "estribor", andanadas de tres por cada costado.
func disparar(barco: Barco, arma: String) -> void:
	if not barco.viva or barco.recargas[arma] > 0.0:
		return
	barco.recargas[arma] = RECARGAS[arma]
	if barco.es_jugador:
		avisar_combate()
	var proa := barco.proa()
	var salidas: Array[Vector2] = []
	var direccion := proa
	if arma == "proa":
		salidas.append(barco.pos + proa * barco.radio * 1.15)
	else:
		direccion = proa.orthogonal() * (1.0 if arma == "babor" else -1.0)
		for k in range(-1, 2):
			salidas.append(barco.pos + direccion * barco.radio * 0.6 + proa * k * barco.radio * 0.4)
	for k in salidas.size():
		var bala := Bala.new()
		bala.pos = salidas[k]
		bala.vel = direccion.rotated(randf_range(-0.03, 0.03)) * VEL_BALA + proa * barco.velocidad * 0.6
		bala.vida = VIDA_BALA
		bala.dueno = barco
		bala.nodo = MeshInstance3D.new()
		bala.nodo.mesh = malla_bala
		bala.nodo.material_override = material(Color("1d2024"))
		bala.nodo.position = a_3d(bala.pos, 1.0)
		add_child(bala.nodo)
		balas.append(bala)
		for _i in 2 if salidas.size() > 1 else 4:
			var deriva := Vector3(randf_range(-0.5, 0.5), randf_range(0.3, 0.8), randf_range(-0.5, 0.5))
			_efecto(malla_humo, Color(0.93, 0.92, 0.9, 0.75), a_3d(salidas[k], 1.0), deriva, randf_range(0.9, 1.3), 0.6, 1.7, 0.0, true)
	var salida := salidas[salidas.size() / 2]
	if barco.es_jugador:
		_sonar_en_vista(voces_canon, barco.position, -9.0, -9.0, 1.0)
	else:
		_sonar_en_vista(voces_canon, a_3d(salida, 1.0), -12.0, -26.0, 30.0)


func _mover_balas(delta: float) -> void:
	for i in range(balas.size() - 1, -1, -1):
		var bala: Bala = balas[i]
		bala.pos += bala.vel * delta
		bala.vida -= delta
		bala.gracia -= delta
		var avance := 1.0 - bala.vida / VIDA_BALA
		bala.nodo.position = a_3d(bala.pos, 1.0 + sin(avance * PI) * 1.1)

		var termina := false
		for isla in islotes:
			if isla.dentro(bala.pos):
				termina = true
				astillas(a_3d(bala.pos, 0.6))
				break
		if not termina and peligros.recibir_bala(bala.pos, bala.dueno):
			termina = true
		if not termina:
			for barco in barcos:
				if not barco.viva:
					continue
				if barco == bala.dueno and bala.gracia > 0.0:
					continue
				if barco.pos.distance_to(bala.pos) < barco.radio * 0.85:
					barco.recibir_danio(DANIO_BALA, true, bala.dueno)
					termina = true
					if barco.es_jugador:
						golpe = 0.22
						avisar_combate()
					break
		if not termina and bala.vida <= 0.0:
			termina = true
			salpicar(bala.pos, 7)
		if termina:
			bala.nodo.queue_free()
			balas.remove_at(i)


func avisar_combate() -> void:
	tiempo_combate = DURACION_COMBATE


func rival_mas_cercano(barco: Barco) -> Barco:
	var mejor: Barco = null
	var mejor_dist := INF
	for otro in barcos:
		if otro == barco or not otro.viva:
			continue
		var dist := barco.pos.distance_to(otro.pos)
		if dist < mejor_dist:
			mejor = otro
			mejor_dist = dist
	return mejor


# Botín

func ganar_botin(barco: Barco, cantidad: int, punto: Vector3) -> void:
	barco.botin += cantidad
	if barco != jugador:
		return
	var aviso := AvisoBotin.new()
	aviso.punto = punto
	aviso.texto = "+%d" % cantidad
	aviso.color = COLOR_ORO
	avisos_botin.append(aviso)
	voz_moneda.pitch_scale = 1.0
	voz_moneda.play()
	_pintar_botin()
	texto_botin.pivot_offset = texto_botin.size / 2.0
	texto_botin.scale = Vector2.ONE * 1.35
	create_tween().tween_property(texto_botin, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pintar_botin() -> void:
	texto_botin.text = tr("Botín a bordo: %d") % jugador.botin


func _soltar_cofre(punto: Vector2, monedas: int) -> void:
	var cofre := Cofre.new()
	cofre.pos = punto
	cofre.vel = Vector2.from_angle(randf() * TAU) * 25.0
	cofre.monedas = monedas
	cofre.fase = randf() * TAU
	cofre.nodo = _crear_cofre(monedas)
	add_child(cofre.nodo)
	cofres.append(cofre)


func _crear_cofre(monedas: int) -> Node3D:
	var nodo := Node3D.new()
	var escala := 1.0 + minf(monedas, 10) * 0.06
	var caja := BoxMesh.new()
	caja.size = Vector3(0.7, 0.42, 0.48) * escala
	_malla(nodo, caja, Color("6b4126"), Vector3(0, 0.21 * escala, 0))
	var tapa := CylinderMesh.new()
	tapa.top_radius = 0.24 * escala
	tapa.bottom_radius = 0.24 * escala
	tapa.height = 0.7 * escala
	tapa.radial_segments = 10
	var pieza_tapa := _malla(nodo, tapa, Color("7d4c2c"), Vector3(0, 0.42 * escala, 0))
	pieza_tapa.rotation.z = PI / 2.0
	pieza_tapa.scale = Vector3(1.0, 1.0, 0.55)
	var fleje := BoxMesh.new()
	fleje.size = Vector3(0.06, 0.5, 0.5) * escala
	for lado in [-1.0, 1.0]:
		_malla(nodo, fleje, COLOR_ORO, Vector3(lado * 0.24 * escala, 0.3 * escala, 0))
	var oro := StandardMaterial3D.new()
	oro.albedo_color = Color("ffd36b")
	oro.emission_enabled = true
	oro.emission = Color("ffb83a")
	oro.emission_energy_multiplier = 0.8
	var moneda := CylinderMesh.new()
	moneda.top_radius = 0.09
	moneda.bottom_radius = 0.09
	moneda.height = 0.03
	moneda.radial_segments = 10
	for k in mini(monedas + 2, 9):
		var pieza := MeshInstance3D.new()
		pieza.mesh = moneda
		pieza.material_override = oro
		pieza.position = Vector3(randf_range(-0.22, 0.22), 0.55 * escala + k * 0.02, randf_range(-0.1, 0.1)) 
		pieza.rotation = Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
		nodo.add_child(pieza)
	var aro := TorusMesh.new()
	aro.inner_radius = 0.9
	aro.outer_radius = 1.05
	aro.rings = 32
	aro.ring_segments = 4
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	brillo.albedo_color = Color(1.0, 0.75, 0.2, 0.85)
	var anillo := MeshInstance3D.new()
	anillo.mesh = aro
	anillo.material_override = brillo
	anillo.scale = Vector3(1.0, 0.2, 1.0)
	anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anillo.name = "Aro"
	nodo.add_child(anillo)
	return nodo


func _actualizar_cofres(delta: float) -> void:
	for i in range(cofres.size() - 1, -1, -1):
		var cofre: Cofre = cofres[i]
		if estado == Estado.JUGANDO:
			cofre.edad += delta
			if cofre.edad >= VIDA_COFRE:
				cofre.nodo.queue_free()
				cofres.remove_at(i)
				continue
		cofre.pos += (peligros.arrastre(cofre.pos) + peligros.viento(cofre.pos) * 0.5 + cofre.vel) * delta
		cofre.vel *= maxf(0.0, 1.0 - delta * 1.5)
		var sitio := a_3d(cofre.pos)
		var hundido := clampf((cofre.edad - VIDA_COFRE + 3.0) / 3.0, 0.0, 1.0)
		cofre.nodo.position = a_3d(cofre.pos, altura_mar(sitio.x, sitio.z) - 0.1 - hundido * 0.9)
		cofre.nodo.rotation = Vector3(sin(tiempo * 1.6 + cofre.fase) * 0.12, cofre.nodo.rotation.y + delta * 0.4, cos(tiempo * 1.3 + cofre.fase) * 0.1)
		var aro: Node3D = cofre.nodo.get_node("Aro")
		aro.scale = Vector3(1.0, 0.2, 1.0) * (1.0 + 0.12 * sin(tiempo * 4.0 + cofre.fase))
	for i in range(avisos_botin.size() - 1, -1, -1):
		var aviso: AvisoBotin = avisos_botin[i]
		aviso.vida -= delta
		aviso.punto.y += delta * 1.2
		if aviso.vida <= 0.0:
			avisos_botin.remove_at(i)


func _recoger_cofres() -> void:
	for i in range(cofres.size() - 1, -1, -1):
		var cofre: Cofre = cofres[i]
		for barco in barcos:
			if barco.viva and barco.pos.distance_to(cofre.pos) < barco.radio + 22.0:
				ganar_botin(barco, cofre.monedas, cofre.nodo.position + Vector3(0, 1.5, 0))
				_brillo_reparacion(cofre.nodo.position + Vector3(0, 0.5, 0))
				cofre.nodo.queue_free()
				cofres.remove_at(i)
				break


func cofre_cercano(barco: Barco, alcance: float):
	var mejor = null
	var mejor_dist := alcance
	for cofre in cofres:
		var dist: float = barco.pos.distance_to(cofre.pos)
		if dist < mejor_dist:
			mejor = cofre.pos
			mejor_dist = dist
	return mejor


func tabla_cercana(barco: Barco):
	var mejor = null
	var mejor_dist := 760.0
	for tabla in tablas:
		var dist := barco.pos.distance_to(tabla.pos)
		if dist < mejor_dist:
			mejor = tabla.pos
			mejor_dist = dist
	return mejor


func al_hundirse(barco: Barco) -> void:
	var verdugo := barco.ultimo_atacante
	if verdugo != null and verdugo != barco and verdugo.viva and Time.get_ticks_msec() - barco.hora_ataque < 10000:
		if verdugo == jugador:
			hundidos += 1
		ganar_botin(verdugo, MONEDAS_POR_HUNDIDO, barco.position + Vector3(0, 2.0, 0))
	var cae := ceili(barco.botin / 2.0)
	if cae > 0:
		barco.botin -= cae
		if barco == jugador:
			botin_perdido = cae
		_soltar_cofre(barco.pos, cae)
	if barco.es_jugador:
		voces_hundir[0].volume_db = -15.0
		voces_hundir[0].pitch_scale = 1.0
		voces_hundir[0].play()
	else:
		_sonar_en_vista(voces_hundir, barco.position, -19.0, -34.0, 50.0)
	salpicar(barco.pos, 18)
	_soltar_restos(barco.pos)
	for _i in 6:
		var deriva := Vector3(randf_range(-0.6, 0.6), randf_range(0.4, 1.0), randf_range(-0.6, 0.6))
		_efecto(malla_humo, Color(0.35, 0.33, 0.32, 0.7), barco.position + Vector3(0, 1.2, 0), deriva, randf_range(1.5, 2.2), 0.8, 2.2, 0.0, true)


func _contar_vivos() -> int:
	var vivos := 0
	for barco in barcos:
		if barco.viva:
			vivos += 1
	return vivos


func _revisar_fin(delta: float) -> void:
	if cierre > 0.0:
		cierre -= delta
		if cierre <= 0.0:
			if resultado == "victoria":
				titulo_final.text = "Victoria"
				texto_final.text = "Tu barco quedó solo en el mar."
			else:
				titulo_final.text = "Hundido"
				texto_final.text = tr("La marea se quedó con tu barco. Terminaste en el puesto %d de %d.") % [puesto, TOTAL_BARCOS]
			_repartir_premio()
			_mostrar(Estado.FIN)
		return

	var vivos := _contar_vivos()
	if not jugador.viva:
		resultado = "hundido"
		puesto = vivos + 1
		cierre = 1.6
	elif vivos == 1:
		resultado = "victoria"
		puesto = 1
		cierre = 1.0


func _repartir_premio() -> void:
	var botin := jugador.botin
	var por_victoria := MONEDAS_VICTORIA if resultado == "victoria" else 0
	var ganada := personalizacion.experiencia_por(puesto, hundidos, resultado == "retirada")
	var antes := personalizacion.monedas
	personalizacion.monedas += botin + por_victoria
	var rango := personalizacion.sumar_experiencia(ganada)
	var desglose: Array = [[tr("Botín a bordo"), botin]]
	if botin_perdido > 0:
		desglose.append([tr("Botín perdido: -%d") % botin_perdido, 0, COLOR_PELIGRO])
	if por_victoria > 0:
		desglose.append([tr("Victoria"), por_victoria])
	if rango["subio"]:
		var subida := tr("¡Subiste a %s!") % tr(personalizacion.nombre_nivel())
		desglose.append([subida, rango["monedas"]] if rango["monedas"] > 0 else [subida, 0, COLOR_ORO])
	var cambio: int = rango["cambio"]
	if cambio > 0:
		desglose.append([tr("Experiencia +%d") % cambio, 0, Color("7dffb2")])
	elif cambio < 0:
		desglose.append([tr("Experiencia -%d") % -cambio, 0, COLOR_PELIGRO])
	else:
		desglose.append([tr("Experiencia sin cambios"), 0, Color(COLOR_TEXTO, 0.8)])
	if rango["bajo"]:
		desglose.append([tr("Bajaste a %s") % tr(personalizacion.nombre_nivel()), 0, COLOR_PELIGRO])
	elif rango["protegido"]:
		desglose.append([tr("Tu rango te protegió de bajar de nivel"), 0, COLOR_ORO])
	_animar_premio.call_deferred(desglose, antes)


# Cada línea del premio entra una a una y su cantidad se suma al contador con monedas saltando.
func _animar_premio(desglose: Array, antes: int) -> void:
	if anim_premio:
		anim_premio.kill()
	for hijo in lineas_premio.get_children():
		hijo.queue_free()
	ultimo_conteo = 0
	texto_premio.text = tr("+%d monedas") % 0
	texto_tesoro.text = tr("Tu tesoro para la tienda: %d monedas") % antes
	fila_final.modulate.a = 0.0
	caja_final.modulate.a = 0.0
	titulo_final.add_theme_color_override("font_color", COLOR_ORO if resultado == "victoria" else COLOR_TEXTO)
	await get_tree().process_frame
	caja_final.pivot_offset = caja_final.size / 2.0
	texto_premio.pivot_offset = texto_premio.size / 2.0
	titulo_final.pivot_offset = Vector2(0.0, titulo_final.size.y / 2.0)
	caja_final.scale = Vector2.ONE * 0.6
	titulo_final.scale = Vector2.ONE * 1.4
	anim_premio = create_tween()
	anim_premio.tween_property(caja_final, "modulate:a", 1.0, 0.2)
	anim_premio.parallel().tween_property(caja_final, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_premio.parallel().tween_property(titulo_final, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.15)
	var acumulado := 0
	for parte in desglose:
		var cantidad: int = parte[1]
		var informativa: bool = parte.size() > 2
		var linea := _etiqueta_panel(parte[0] if informativa else "%s   +%d" % [parte[0], cantidad], 24, parte[2] if informativa else COLOR_ORO)
		linea.modulate.a = 0.0
		lineas_premio.add_child(linea)
		anim_premio.tween_interval(0.15)
		anim_premio.tween_property(linea, "modulate:a", 1.0, 0.2)
		anim_premio.parallel().tween_property(linea, "position:x", 0.0, 0.25).from(-40.0)
		if cantidad > 0:
			anim_premio.tween_callback(_lluvia_monedas.bind(mini(cantidad, 14)))
			anim_premio.tween_method(_contar_premio.bind(antes), float(acumulado), float(acumulado + cantidad), clampf(0.2 + cantidad * 0.05, 0.3, 1.1))
		acumulado += cantidad
	anim_premio.tween_callback(_rematar_premio)
	anim_premio.tween_property(texto_premio, "scale", Vector2.ONE * 1.25, 0.12)
	anim_premio.tween_property(texto_premio, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim_premio.tween_property(fila_final, "modulate:a", 1.0, 0.3)


func _contar_premio(valor: float, antes: int) -> void:
	var monedas := roundi(valor)
	if monedas == ultimo_conteo:
		return
	ultimo_conteo = monedas
	texto_premio.text = tr("+%d monedas") % monedas
	texto_tesoro.text = tr("Tu tesoro para la tienda: %d + %d = %d monedas") % [antes, monedas, antes + monedas]
	texto_premio.scale = Vector2.ONE * 1.12
	create_tween().tween_property(texto_premio, "scale", Vector2.ONE, 0.12)
	voz_moneda.pitch_scale = randf_range(0.92, 1.12)
	voz_moneda.play()


func _rematar_premio() -> void:
	if ultimo_conteo > 0:
		voz_monedas.play()
		_lluvia_monedas(10)


func _lluvia_monedas(cuantas: int) -> void:
	var origen := texto_premio.get_global_rect().get_center()
	for i in cuantas:
		var moneda := MonedaVoladora.new()
		moneda.position = origen + Vector2(randf_range(-60.0, 60.0), randf_range(-10.0, 10.0))
		moneda.velocidad = Vector2(randf_range(-260.0, 260.0), randf_range(-620.0, -320.0))
		capa_monedas.add_child(moneda)


# Tocar el panel durante la animación la termina de golpe.
func _tocar_final(evento: InputEvent) -> void:
	var pulsado := (evento is InputEventScreenTouch or evento is InputEventMouseButton) and evento.is_pressed()
	if pulsado and anim_premio and anim_premio.is_running():
		anim_premio.custom_step(60.0)


class MonedaVoladora extends Control:
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


# Efectos

func _efecto(forma: Mesh, color: Color, pos: Vector3, vel: Vector3, vida: float, escala: float, crece: float, gravedad := 0.0, sombreado := false) -> void:
	if pos.distance_to(foco) > DISTANCIA_VISIBLE:
		return
	var efecto := Efecto.new()
	efecto.material = StandardMaterial3D.new()
	efecto.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if not sombreado:
		efecto.material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	efecto.material.albedo_color = color
	efecto.nodo = MeshInstance3D.new()
	efecto.nodo.mesh = forma
	efecto.nodo.material_override = efecto.material
	efecto.nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	efecto.nodo.position = pos
	efecto.nodo.scale = Vector3.ONE * escala
	efecto.nodo.rotation = Vector3(randf() * TAU, randf() * TAU, 0.0) if forma == malla_astilla else Vector3.ZERO
	add_child(efecto.nodo)
	efecto.color = color
	efecto.vel = vel
	efecto.vida = vida
	efecto.vida_max = vida
	efecto.escala = escala
	efecto.crece = crece
	efecto.gravedad = gravedad
	efectos.append(efecto)


func _actualizar_efectos(delta: float) -> void:
	for i in range(efectos.size() - 1, -1, -1):
		var efecto: Efecto = efectos[i]
		efecto.vida -= delta
		efecto.vel.y -= efecto.gravedad * delta
		efecto.nodo.position += efecto.vel * delta
		if efecto.gravedad > 0.0 and efecto.nodo.position.y < 0.0:
			efecto.vida = 0.0
		var resto := clampf(efecto.vida / efecto.vida_max, 0.0, 1.0)
		efecto.nodo.scale = Vector3.ONE * (efecto.escala + efecto.crece * (1.0 - resto))
		var color := efecto.color
		color.a *= resto
		efecto.material.albedo_color = color
		if efecto.vida <= 0.0:
			efecto.nodo.queue_free()
			efectos.remove_at(i)


func dejar_estela(pos: Vector2, fuerza: float) -> void:
	_efecto(malla_espuma, Color(1, 1, 1, 0.45 * fuerza), a_3d(pos, 0.17), Vector3.ZERO, 1.2, 0.7, 1.6)


func ola_proa(pos: Vector2, rumbo: float, fuerza: float) -> void:
	var adelante := Vector2.UP.rotated(rumbo)
	var lado := Vector2(-adelante.y, adelante.x)
	for s in [-1.0, 1.0]:
		var empuje: Vector2 = lado * s * 1.5 * fuerza
		_efecto(malla_espuma, Color(1, 1, 1, 0.5 * fuerza), a_3d(pos + lado * s * 6.0, 0.18), Vector3(empuje.x, 0.0, empuje.y), 0.9, 0.35, 1.3)


# La proa cae sobre el agua: abanico de gotas hacia delante y a los lados.
func rociar_proa(pos: Vector2, rumbo: float, fuerza: float) -> void:
	var centro := a_3d(pos, 0.25)
	var adelante := Vector2.UP.rotated(rumbo)
	var lado := Vector2(-adelante.y, adelante.x)
	for _i in int(5 + 8 * fuerza):
		var plano := adelante * randf_range(0.4, 1.4) + lado * randf_range(-1.8, 1.8)
		var vel := Vector3(plano.x, randf_range(2.2, 3.6) * (0.6 + 0.6 * fuerza), plano.y)
		_efecto(malla_gota, Color(0.95, 0.98, 1.0, 0.85), centro, vel, 0.8, 0.75, 0.0, 12.0)
	_efecto(malla_espuma, Color(1, 1, 1, 0.6), a_3d(pos, 0.17), Vector3.ZERO, 0.8, 0.6, 2.2)


func salpicar(pos: Vector2, cantidad: int) -> void:
	var centro := a_3d(pos, 0.2)
	for _i in cantidad:
		var vel := Vector3(randf_range(-1.5, 1.5), randf_range(3.0, 5.5), randf_range(-1.5, 1.5))
		_efecto(malla_gota, Color(0.95, 0.98, 1.0, 0.9), centro, vel, 1.0, 1.0, 0.0, 12.0)
	_efecto(malla_espuma, Color(1, 1, 1, 0.7), a_3d(pos, 0.17), Vector3.ZERO, 0.9, 0.8, 2.6)


func astillas(centro: Vector3) -> void:
	for _i in 8:
		var vel := Vector3(randf_range(-2.0, 2.0), randf_range(2.0, 4.5), randf_range(-2.0, 2.0))
		_efecto(malla_astilla, Color("7a5230"), centro, vel, 1.2, 1.0, 0.0, 10.0, true)
	_efecto(malla_humo, Color(0.9, 0.88, 0.85, 0.6), centro, Vector3(0, 0.6, 0), 0.8, 0.5, 1.2, 0.0, true)


func _brillo_reparacion(centro: Vector3) -> void:
	for _i in 10:
		var vel := Vector3(randf_range(-0.8, 0.8), randf_range(1.5, 3.0), randf_range(-0.8, 0.8))
		_efecto(malla_gota, Color(1.0, 0.86, 0.4, 0.95), centro, vel, 0.9, 1.4, 0.0, 1.5)


# Controles

func direccion_jugador() -> Vector2:
	if panel_partida.visible:
		return Vector2.ZERO
	var teclas := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		teclas.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		teclas.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		teclas.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		teclas.y += 1.0
	if teclas != Vector2.ZERO:
		return teclas.normalized()
	return palanca


# Teclado: Espacio dispara al frente, Q a la izquierda y E a la derecha.
func armas_jugador() -> Array[String]:
	var armas: Array[String] = []
	if panel_partida.visible:
		return armas
	for arma in BOTONES_FUEGO:
		if _arma_pulsada(arma):
			armas.append(arma)
	return armas


func _arma_pulsada(arma: String) -> bool:
	var tecla: Key = {"proa": KEY_SPACE, "babor": KEY_Q, "estribor": KEY_E}[arma]
	return arma in dedos_fuego.values() or Input.is_key_pressed(tecla)


# En la tienda: un dedo gira la cámara alrededor del barco, dos dedos o la rueda acercan.
func _unhandled_input(event: InputEvent) -> void:
	if estado != Estado.ASTILLERO:
		return
	var toque := event as InputEventScreenTouch
	if toque:
		if not toque.pressed:
			dedos_vitrina.erase(toque.index)
		elif not panel_astillero.get_global_rect().has_point(toque.position):
			dedos_vitrina[toque.index] = toque.position
		return
	var arrastre := event as InputEventScreenDrag
	if arrastre and dedos_vitrina.has(arrastre.index):
		pausa_giro = PAUSA_GIRO_MANUAL
		if dedos_vitrina.size() == 1:
			angulo_puerto -= arrastre.relative.x * 0.008
			altura_vitrina = clampf(altura_vitrina - arrastre.relative.y * 0.02, 1.5, 9.0)
		else:
			var otro: Vector2 = dedos_vitrina[dedos_vitrina.keys().filter(func(i: int) -> bool: return i != arrastre.index)[0]]
			var antes := otro.distance_to(dedos_vitrina[arrastre.index])
			distancia_vitrina = clampf(distancia_vitrina - (otro.distance_to(arrastre.position) - antes) * 0.03, 6.0, 16.0)
		dedos_vitrina[arrastre.index] = arrastre.position
		return
	var rueda := event as InputEventMouseButton
	if rueda and rueda.pressed and rueda.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		distancia_vitrina = clampf(distancia_vitrina + (-0.8 if rueda.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8), 6.0, 16.0)
		pausa_giro = PAUSA_GIRO_MANUAL


func _input(event: InputEvent) -> void:
	if estado != Estado.JUGANDO:
		var tecla := event as InputEventKey
		if tecla and tecla.pressed and not tecla.echo and tecla.keycode in [KEY_SPACE, KEY_ENTER]:
			if estado == Estado.MENU or estado == Estado.FIN:
				get_viewport().set_input_as_handled()
				_buscar_partida()
		return

	var escape := event as InputEventKey
	if escape and escape.pressed and not escape.echo and escape.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if panel_partida.visible:
			_cerrar_opciones_partida()
		else:
			_abrir_opciones_partida()
		return
	if panel_partida.visible:
		return

	var toque := event as InputEventScreenTouch
	if toque:
		if toque.pressed:
			if toque.position.y < ALTO_HUD:
				return
			if toque.position.x < controles.size.x / 2.0:
				if palanca_dedo == -1:
					palanca_dedo = toque.index
					centro_palanca = toque.position
					palanca = Vector2.ZERO
			else:
				var arma := _boton_fuego_en(toque.position)
				if arma != "":
					dedos_fuego[toque.index] = arma
		else:
			if toque.index == palanca_dedo:
				palanca_dedo = -1
				palanca = Vector2.ZERO
			dedos_fuego.erase(toque.index)
		return

	var arrastre := event as InputEventScreenDrag
	if arrastre and arrastre.index == palanca_dedo:
		palanca = (arrastre.position - centro_palanca).limit_length(RADIO_PALANCA) / RADIO_PALANCA


func _posicion_palanca_reposo() -> Vector2:
	return Vector2(125.0, controles.size.y - 120.0)


func _posicion_fuego(arma: String) -> Vector2:
	return controles.size + BOTONES_FUEGO[arma][0]


# El botón más cercano al dedo, con algo de margen alrededor de cada círculo.
func _boton_fuego_en(punto: Vector2) -> String:
	var elegido := ""
	var mejor := INF
	for arma in BOTONES_FUEGO:
		var distancia := punto.distance_to(_posicion_fuego(arma))
		if distancia < BOTONES_FUEGO[arma][1] * 1.35 and distancia < mejor:
			mejor = distancia
			elegido = arma
	return elegido


# Interfaz

func _crear_interfaz() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)

	velo_golpe = ColorRect.new()
	velo_golpe.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo_golpe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(velo_golpe)

	destello = ColorRect.new()
	destello.set_anchors_preset(Control.PRESET_FULL_RECT)
	destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destello.color = Color(1, 1, 1, 0)
	capa.add_child(destello)

	marcadores = Control.new()
	marcadores.set_anchors_preset(Control.PRESET_FULL_RECT)
	marcadores.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marcadores.draw.connect(_dibujar_marcadores)
	capa.add_child(marcadores)

	controles = Control.new()
	controles.set_anchors_preset(Control.PRESET_FULL_RECT)
	controles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controles.draw.connect(_dibujar_controles)
	capa.add_child(controles)

	hud = VBoxContainer.new()
	hud.position = Vector2(20, 16)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_constant_override("separation", 0)
	capa.add_child(hud)

	texto_vivos = _etiqueta("A flote: 12", 18)
	hud.add_child(texto_vivos)
	texto_tormenta = _etiqueta("Tormenta: 24s", 18)
	hud.add_child(texto_tormenta)
	texto_botin = _etiqueta("Botín a bordo: 0", 18)
	texto_botin.add_theme_color_override("font_color", COLOR_ORO)
	hud.add_child(texto_botin)

	minimapa = Control.new()
	minimapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anclar(minimapa, Vector2(1, 0), Vector2(-188, 20), Vector2(168, 168))
	minimapa.draw.connect(_dibujar_minimapa)
	capa.add_child(minimapa)

	_crear_menu(capa)
	_crear_ajustes(capa)
	_crear_niveles(capa)
	_crear_astillero(capa)
	_crear_busqueda(capa)
	_crear_final(capa)
	_crear_opciones_partida(capa)


func _crear_logo() -> Control:
	var logo := HBoxContainer.new()
	logo.add_theme_constant_override("separation", 14)
	logo.alignment = BoxContainer.ALIGNMENT_CENTER
	var emblema := TextureRect.new()
	emblema.texture = load("res://interfaz/emblema.svg")
	emblema.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblema.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblema.custom_minimum_size = Vector2(124, 124)
	logo.add_child(emblema)

	var gruesa := FontVariation.new()
	gruesa.base_font = ThemeDB.fallback_font
	gruesa.variation_embolden = 1.1
	gruesa.spacing_glyph = 3
	var letras := VBoxContainer.new()
	letras.alignment = BoxContainer.ALIGNMENT_CENTER
	letras.add_theme_constant_override("separation", -18)
	logo.add_child(letras)
	for linea in [["ÚLTIMA", 44, COLOR_TEXTO], ["MAREA", 66, COLOR_ORO]]:
		var texto := Label.new()
		texto.text = linea[0]
		texto.add_theme_font_override("font", gruesa)
		texto.add_theme_font_size_override("font_size", linea[1])
		texto.add_theme_color_override("font_color", linea[2])
		texto.add_theme_color_override("font_outline_color", Color("08161c"))
		texto.add_theme_constant_override("outline_size", 12)
		texto.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		texto.add_theme_constant_override("shadow_offset_x", 3)
		texto.add_theme_constant_override("shadow_offset_y", 4)
		letras.add_child(texto)
	return logo


func _crear_menu(capa: CanvasLayer) -> void:
	var partes := _panel_lateral(capa)
	panel_menu = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_child(_crear_logo())
	var lema := _etiqueta_panel("El mar no perdona.\n¿Serás el último a flote?", 30, COLOR_TEXTO)
	lema.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lema.add_theme_color_override("font_outline_color", Color(0.02, 0.08, 0.12))
	lema.add_theme_constant_override("outline_size", 8)
	cuerpo.add_child(lema)

	var espacio := Control.new()
	espacio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(espacio)
	cuerpo.add_child(_crear_boton_nivel())
	var tesoro := HBoxContainer.new()
	tesoro.add_theme_constant_override("separation", 10)
	tesoro.add_child(_icono_moneda(34))
	texto_monedas_menu = _etiqueta_panel("", 28, COLOR_ORO)
	texto_monedas_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tesoro.add_child(texto_monedas_menu)
	cuerpo.add_child(tesoro)
	var tienda := _boton("Tienda", false)
	tienda.pressed.connect(_mostrar.bind(Estado.ASTILLERO))
	cuerpo.add_child(tienda)
	var buscar := _boton("Buscar partida", true)
	buscar.pressed.connect(_buscar_partida)
	cuerpo.add_child(buscar)

	boton_ajustes = _boton_engranaje()
	_anclar(boton_ajustes, Vector2(0, 0), Vector2(28, 28), Vector2(80, 80))
	boton_ajustes.pressed.connect(_mostrar.bind(Estado.AJUSTES))
	capa.add_child(boton_ajustes)

	boton_idioma = BotonIdioma.new()
	boton_idioma.idioma = personalizacion.idioma
	boton_idioma.tooltip_text = "Idioma"
	_anclar(boton_idioma, Vector2(0, 0), Vector2(124, 36), Vector2(92, 64))
	boton_idioma.pressed.connect(_cambiar_idioma)
	capa.add_child(boton_idioma)


func _cambiar_idioma() -> void:
	var lista := Idioma.IDIOMAS
	personalizacion.idioma = lista[(lista.find(personalizacion.idioma) + 1) % lista.size()]
	personalizacion.guardar()
	Idioma.usar(personalizacion.idioma)
	boton_idioma.idioma = personalizacion.idioma
	boton_idioma.queue_redraw()
	voz_equipar.play()
	_mostrar(estado)


# Muestra la bandera del idioma actual; al tocarla pasa al siguiente.
class BotonIdioma extends Button:
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


func _boton_engranaje() -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.icon = load("res://interfaz/engranaje.svg")
	boton.expand_icon = true
	boton.tooltip_text = "Configuración"
	var redondo := StyleBoxFlat.new()
	redondo.bg_color = Color(0.05, 0.16, 0.2, 0.9)
	redondo.border_color = Color(0.95, 0.88, 0.73, 0.4)
	redondo.set_border_width_all(2)
	redondo.set_corner_radius_all(40)
	redondo.set_content_margin_all(14)
	var redondo_activo := redondo.duplicate() as StyleBoxFlat
	redondo_activo.border_color = COLOR_ORO
	boton.add_theme_stylebox_override("normal", redondo)
	boton.add_theme_stylebox_override("hover", redondo_activo)
	boton.add_theme_stylebox_override("pressed", redondo_activo)
	return boton


# Engranaje durante la partida: volumen y salir. La partida no se detiene.
func _crear_opciones_partida(capa: CanvasLayer) -> void:
	boton_partida = _boton_engranaje()
	_anclar(boton_partida, Vector2(1, 0), Vector2(-188 - 18 - 72, 28), Vector2(72, 72))
	boton_partida.pressed.connect(_abrir_opciones_partida)
	capa.add_child(boton_partida)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)
	panel_partida = centro
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	panel.custom_minimum_size = Vector2(520, 0)
	centro.add_child(panel)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 14)
	panel.add_child(cuerpo)
	cuerpo.add_child(_etiqueta_panel("Opciones", 40, COLOR_TEXTO))
	_deslizador_volumen(cuerpo, "Música", personalizacion.volumen_musica, func(valor: float) -> void:
		personalizacion.volumen_musica = valor)
	_deslizador_volumen(cuerpo, "Efectos", personalizacion.volumen_efectos, func(valor: float) -> void:
		personalizacion.volumen_efectos = valor)
	var seguir := _boton("Seguir jugando", true)
	seguir.pressed.connect(_cerrar_opciones_partida)
	cuerpo.add_child(seguir)
	boton_salir = _boton("Salir de la partida", false)
	boton_salir.pressed.connect(_salir_de_partida)
	cuerpo.add_child(boton_salir)


func _abrir_opciones_partida() -> void:
	if estado != Estado.JUGANDO or cierre > 0.0:
		return
	panel_partida.visible = true
	boton_salir.text = "Salir de la partida"
	controles.visible = false
	palanca_dedo = -1
	dedos_fuego.clear()
	palanca = Vector2.ZERO


func _cerrar_opciones_partida() -> void:
	panel_partida.visible = false
	controles.visible = estado == Estado.JUGANDO
	personalizacion.guardar()


func _salir_de_partida() -> void:
	if boton_salir.text == "Salir de la partida":
		boton_salir.text = "¿Seguro? Toca otra vez"
		return
	personalizacion.guardar()
	resultado = "retirada"
	puesto = _contar_vivos()
	if jugador.viva:
		botin_perdido = ceili(jugador.botin / 2.0)
		jugador.botin -= botin_perdido
	titulo_final.text = "Retirada"
	texto_final.text = tr("Abandonaste la partida en el puesto %d de %d.") % [puesto, TOTAL_BARCOS]
	_repartir_premio()
	_mostrar(Estado.FIN)


func _crear_ajustes(capa: CanvasLayer) -> void:
	var partes := _panel_lateral(capa)
	panel_ajustes = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	var titulo := _etiqueta_panel("Configuración", 40, COLOR_TEXTO)
	cuerpo.add_child(titulo)

	cuerpo.add_child(_etiqueta_panel("Nombre del barco", 22, COLOR_ORO))
	campo_nombre = LineEdit.new()
	campo_nombre.max_length = Personalizacion.LARGO_NOMBRE
	campo_nombre.placeholder_text = Personalizacion.NOMBRE_INICIAL
	campo_nombre.custom_minimum_size = Vector2(0, 58)
	campo_nombre.add_theme_font_size_override("font_size", 28)
	campo_nombre.add_theme_color_override("font_color", COLOR_TEXTO)
	var fondo_nombre := StyleBoxFlat.new()
	fondo_nombre.bg_color = Color(0, 0, 0, 0.3)
	fondo_nombre.border_color = Color(1, 1, 1, 0.3)
	fondo_nombre.set_border_width_all(2)
	fondo_nombre.set_corner_radius_all(14)
	fondo_nombre.set_content_margin_all(12)
	var foco_nombre := fondo_nombre.duplicate() as StyleBoxFlat
	foco_nombre.border_color = COLOR_ORO
	campo_nombre.add_theme_stylebox_override("normal", fondo_nombre)
	campo_nombre.add_theme_stylebox_override("focus", foco_nombre)
	campo_nombre.text_changed.connect(_cambiar_nombre)
	campo_nombre.text_submitted.connect(func(_texto: String) -> void: campo_nombre.release_focus())
	cuerpo.add_child(campo_nombre)

	_deslizador_volumen(cuerpo, "Música", personalizacion.volumen_musica, func(valor: float) -> void:
		personalizacion.volumen_musica = valor)
	var efectos := _deslizador_volumen(cuerpo, "Efectos", personalizacion.volumen_efectos, func(valor: float) -> void:
		personalizacion.volumen_efectos = valor)
	efectos.drag_ended.connect(func(_cambio: bool) -> void:
		_sonar_en_vista(voces_canon, camara.global_position + camara.global_basis.z * -5.0, -9.0, -9.0, 1.0))

	var espacio := Control.new()
	espacio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(espacio)
	var listo := _boton("Listo", true)
	listo.pressed.connect(_cerrar_ajustes)
	cuerpo.add_child(listo)


func _deslizador_volumen(cuerpo: VBoxContainer, titulo: String, valor: float, guardar: Callable) -> HSlider:
	var fila := HBoxContainer.new()
	var nombre := _etiqueta_panel(titulo, 22, COLOR_ORO)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var porcentaje := _etiqueta_panel("%d%%" % roundi(valor * 100.0), 22, COLOR_TEXTO)
	porcentaje.autowrap_mode = TextServer.AUTOWRAP_OFF
	fila.add_child(porcentaje)
	cuerpo.add_child(fila)

	var deslizador := HSlider.new()
	deslizador.min_value = 0.0
	deslizador.max_value = 100.0
	deslizador.step = 1.0
	deslizador.value = valor * 100.0
	deslizador.focus_mode = Control.FOCUS_NONE
	deslizador.custom_minimum_size = Vector2(0, 52)
	var riel := StyleBoxFlat.new()
	riel.bg_color = Color(0, 0, 0, 0.35)
	riel.set_corner_radius_all(8)
	riel.content_margin_top = 7
	riel.content_margin_bottom = 7
	var lleno := riel.duplicate() as StyleBoxFlat
	lleno.bg_color = COLOR_ORO
	deslizador.add_theme_stylebox_override("slider", riel)
	deslizador.add_theme_stylebox_override("grabber_area", lleno)
	deslizador.add_theme_stylebox_override("grabber_area_highlight", lleno)
	var tirador := _textura_circulo(40, COLOR_TEXTO)
	deslizador.add_theme_icon_override("grabber", tirador)
	deslizador.add_theme_icon_override("grabber_highlight", tirador)
	deslizador.value_changed.connect(func(nuevo: float) -> void:
		porcentaje.text = "%d%%" % roundi(nuevo)
		guardar.call(nuevo / 100.0)
		_aplicar_volumen()
		for otro in deslizadores_volumen:
			if otro != deslizador and otro.get_meta("titulo") == titulo and otro.value != nuevo:
				otro.value = nuevo)
	deslizador.set_meta("titulo", titulo)
	deslizadores_volumen.append(deslizador)
	cuerpo.add_child(deslizador)
	return deslizador


func _textura_circulo(lado: int, color: Color) -> ImageTexture:
	var imagen := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var centro := Vector2(lado, lado) / 2.0
	for y in lado:
		for x in lado:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(centro)
			var borde := clampf(lado / 2.0 - d, 0.0, 1.0)
			var tono := color if d < lado / 2.0 - 4.0 else Color("08161c")
			imagen.set_pixel(x, y, Color(tono, borde))
	return ImageTexture.create_from_image(imagen)


func _cerrar_ajustes() -> void:
	campo_nombre.release_focus()
	personalizacion.guardar()
	_mostrar(Estado.MENU)


# Niveles: botón del menú con la insignia y panel con la escalera completa.

func _crear_boton_nivel() -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.custom_minimum_size = Vector2(0, 104)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.25)
	estilo.border_color = Color(1, 1, 1, 0.2)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(18)
	var activo := estilo.duplicate() as StyleBoxFlat
	activo.border_color = COLOR_ORO
	boton.add_theme_stylebox_override("normal", estilo)
	boton.add_theme_stylebox_override("hover", activo)
	boton.add_theme_stylebox_override("pressed", activo)
	boton.pressed.connect(_mostrar.bind(Estado.NIVELES))

	var fila := HBoxContainer.new()
	fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 12.0
	fila.offset_right = -22.0
	fila.add_theme_constant_override("separation", 14)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(fila)
	insignia_menu = Insignia.new()
	insignia_menu.custom_minimum_size = Vector2(80, 80)
	insignia_menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(insignia_menu)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_theme_constant_override("separation", 4)
	fila.add_child(textos)
	texto_nivel_menu = _etiqueta_panel("", 24, COLOR_ORO)
	textos.add_child(texto_nivel_menu)
	barra_nivel_menu = _barra_progreso()
	textos.add_child(barra_nivel_menu)
	texto_xp_menu = _etiqueta_panel("", 17, COLOR_TEXTO)
	textos.add_child(texto_xp_menu)
	var flecha := _etiqueta_panel("›", 44, Color(COLOR_TEXTO, 0.7))
	flecha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(flecha)
	return boton


func _barra_progreso() -> Control:
	var barra := Control.new()
	barra.custom_minimum_size = Vector2(0, 12)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.set_meta("avance", 0.0)
	barra.draw.connect(_dibujar_barra.bind(barra))
	return barra


func _dibujar_barra(barra: Control) -> void:
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0, 0, 0, 0.4)
	fondo.set_corner_radius_all(6)
	barra.draw_style_box(fondo, Rect2(Vector2.ZERO, barra.size))
	var avance: float = barra.get_meta("avance", 0.0)
	if avance <= 0.0:
		return
	var lleno := fondo.duplicate() as StyleBoxFlat
	lleno.bg_color = COLOR_ORO
	barra.draw_style_box(lleno, Rect2(Vector2.ZERO, Vector2(maxf(barra.size.x * avance, 12.0), barra.size.y)))


func _avance_nivel(nivel: int) -> float:
	if nivel >= Personalizacion.NIVELES.size() - 1:
		return 1.0
	var desde: int = Personalizacion.NIVELES[nivel][1]
	var hasta: int = Personalizacion.NIVELES[nivel + 1][1]
	return clampf(float(personalizacion.experiencia - desde) / float(hasta - desde), 0.0, 1.0)


func _texto_progreso(nivel: int) -> String:
	if nivel >= Personalizacion.NIVELES.size() - 1:
		return tr("%d XP · ¡Nivel máximo!") % personalizacion.experiencia
	var siguiente: Array = Personalizacion.NIVELES[nivel + 1]
	return tr("%d XP · faltan %d para %s") % [personalizacion.experiencia, int(siguiente[1]) - personalizacion.experiencia, tr(siguiente[0])]


func _pintar_nivel_menu() -> void:
	var nivel := personalizacion.nivel()
	insignia_menu.nivel = nivel
	texto_nivel_menu.text = tr("Nivel %d · %s") % [nivel + 1, tr(personalizacion.nombre_nivel())]
	barra_nivel_menu.set_meta("avance", _avance_nivel(nivel))
	barra_nivel_menu.queue_redraw()
	texto_xp_menu.text = _texto_progreso(nivel)


func _crear_niveles(capa: CanvasLayer) -> void:
	var partes := _panel_lateral(capa)
	panel_niveles = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_child(_etiqueta_panel("Niveles", 40, COLOR_TEXTO))
	cuerpo.add_child(_etiqueta_panel(
		"Ganas experiencia (XP) según tu puesto (ganar da +30) y +3 por cada barco que hundes. Si quedas del puesto 31 en adelante pierdes 8 XP, y retirarte resta 12: puedes bajar de nivel. Al subir tienes 3 partidas de protección. El premio de monedas se cobra solo la primera vez.",
		17, Color(COLOR_TEXTO, 0.85)))
	desliz_niveles = ScrollContainer.new()
	desliz_niveles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desliz_niveles.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cuerpo.add_child(desliz_niveles)
	lista_niveles = VBoxContainer.new()
	lista_niveles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_niveles.add_theme_constant_override("separation", 10)
	desliz_niveles.add_child(lista_niveles)
	var listo := _boton("Listo", true)
	listo.pressed.connect(_mostrar.bind(Estado.MENU))
	cuerpo.add_child(listo)


# Del nivel más alto al más bajo, como una escalera; el actual resaltado.
func _llenar_niveles() -> void:
	for hijo in lista_niveles.get_children():
		hijo.queue_free()
	var actual := personalizacion.nivel()
	var fila_actual: Control = null
	for nivel in range(Personalizacion.NIVELES.size() - 1, -1, -1):
		var datos: Array = Personalizacion.NIVELES[nivel]
		var caja := PanelContainer.new()
		caja.mouse_filter = Control.MOUSE_FILTER_PASS
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.89, 0.69, 0.35, 0.14) if nivel == actual else Color(0, 0, 0, 0.25)
		estilo.border_color = COLOR_ORO
		estilo.set_border_width_all(3 if nivel == actual else 0)
		estilo.set_corner_radius_all(16)
		estilo.set_content_margin_all(12)
		caja.add_theme_stylebox_override("panel", estilo)
		lista_niveles.add_child(caja)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 14)
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(fila)
		var escudo := Insignia.new()
		escudo.custom_minimum_size = Vector2(64, 64)
		escudo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		escudo.nivel = nivel
		fila.add_child(escudo)
		var textos := VBoxContainer.new()
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.alignment = BoxContainer.ALIGNMENT_CENTER
		textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		textos.add_theme_constant_override("separation", 2)
		fila.add_child(textos)
		textos.add_child(_etiqueta_panel(tr("Nivel %d · %s") % [nivel + 1, tr(datos[0])], 24, COLOR_ORO if nivel == actual else COLOR_TEXTO))
		var detalle := tr("Desde %d XP") % datos[1]
		if datos[2] > 0:
			detalle += "  ·  " + tr("Premio: +%d monedas") % datos[2]
		textos.add_child(_etiqueta_panel(detalle, 16, Color(COLOR_TEXTO, 0.75)))
		if nivel < actual:
			textos.add_child(_etiqueta_panel(tr("Superado"), 16, Color("7dffb2")))
		elif nivel == actual:
			var barra := _barra_progreso()
			barra.set_meta("avance", _avance_nivel(nivel))
			textos.add_child(barra)
			textos.add_child(_etiqueta_panel(tr("Estás aquí") + " · " + _texto_progreso(nivel), 16, COLOR_TEXTO))
			if personalizacion.proteccion > 0 and nivel > 0:
				textos.add_child(_etiqueta_panel(tr("Protegido de bajar: %d partidas") % personalizacion.proteccion, 16, Color("7dffb2")))
			fila_actual = caja
		else:
			escudo.modulate = Color(0.45, 0.45, 0.5)
			caja.modulate.a = 0.75
			textos.add_child(_etiqueta_panel(tr("Te faltan %d XP") % (int(datos[1]) - personalizacion.experiencia), 16, Color(COLOR_TEXTO, 0.6)))
	if fila_actual != null:
		get_tree().create_timer(0.05).timeout.connect(func() -> void: desliz_niveles.ensure_control_visible(fila_actual))


func _cambiar_nombre(texto: String) -> void:
	personalizacion.cambiar_nombre(texto)
	if jugador != null:
		jugador.nombre = personalizacion.nombre_visible()


func _crear_busqueda(capa: CanvasLayer) -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)
	panel_busqueda = centro
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	panel.custom_minimum_size = Vector2(520, 0)
	centro.add_child(panel)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 16)
	panel.add_child(cuerpo)
	cuerpo.add_child(_etiqueta_panel("TODOS CONTRA TODOS", 20, COLOR_ORO))
	texto_busqueda = _etiqueta_panel("Buscando partida", 40, COLOR_TEXTO)
	cuerpo.add_child(texto_busqueda)
	texto_jugadores = _etiqueta_panel("", 24, COLOR_TEXTO)
	cuerpo.add_child(texto_jugadores)
	var cancelar := _boton("Cancelar", false)
	cancelar.pressed.connect(_mostrar.bind(Estado.MENU))
	cuerpo.add_child(cancelar)


func _buscar_partida() -> void:
	campo_nombre.release_focus()
	tiempo_busqueda = 0.0
	_mostrar(Estado.BUSCANDO)
	_avanzar_busqueda(0.0)


func _avanzar_busqueda(delta: float) -> void:
	tiempo_busqueda += delta
	var puntos := ".".repeat(1 + int(tiempo_busqueda * 2.0) % 3)
	if tiempo_busqueda < ESPERA_BUSQUEDA:
		texto_busqueda.text = tr("Buscando partida") + puntos
		texto_jugadores.text = tr("Capitanes en el puerto: 1/%d\nEsperando %ds") % [TOTAL_BARCOS, int(tiempo_busqueda)]
	elif tiempo_busqueda < ESPERA_BUSQUEDA + ESPERA_BOTS:
		texto_busqueda.text = tr("Completando con bots") + puntos
		texto_jugadores.text = tr("No hay más capitanes conectados.\nSe unen %d bots a la marea.") % (TOTAL_BARCOS - 1)
	else:
		_zarpar()


func _crear_astillero(capa: CanvasLayer) -> void:
	aviso_giro = _etiqueta_panel("Arrastra para girar el barco", 22, Color(COLOR_TEXTO, 0.75))
	aviso_giro.autowrap_mode = TextServer.AUTOWRAP_OFF
	aviso_giro.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	aviso_giro.add_theme_constant_override("shadow_offset_y", 2)
	aviso_giro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aviso_giro.anchor_top = 1.0
	aviso_giro.anchor_bottom = 1.0
	aviso_giro.offset_left = 36.0
	aviso_giro.offset_top = -64.0
	aviso_giro.offset_bottom = -28.0
	capa.add_child(aviso_giro)
	var partes := _panel_lateral(capa)
	panel_astillero = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_theme_constant_override("separation", 10)

	var cabecera := HBoxContainer.new()
	var titulo := _etiqueta_panel("Tienda", 40, COLOR_TEXTO)
	titulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)
	cabecera.add_theme_constant_override("separation", 10)
	cabecera.add_child(_icono_moneda(28))
	texto_monedas_tienda = _etiqueta_panel("", 26, COLOR_ORO)
	texto_monedas_tienda.autowrap_mode = TextServer.AUTOWRAP_OFF
	cabecera.add_child(texto_monedas_tienda)
	cuerpo.add_child(cabecera)

	var pestanas := GridContainer.new()
	pestanas.columns = 4
	pestanas.add_theme_constant_override("h_separation", 8)
	pestanas.add_theme_constant_override("v_separation", 8)
	for cat in Catalogo.CATEGORIAS:
		var boton := _boton(Catalogo.TITULOS[cat], false)
		boton.custom_minimum_size = Vector2(0, 38)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.add_theme_font_size_override("font_size", 16)
		boton.pressed.connect(_abrir_categoria.bind(cat))
		pestanas.add_child(boton)
		botones_categoria.append(boton)
	cuerpo.add_child(pestanas)

	desplazable = ScrollContainer.new()
	desplazable.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cuerpo.add_child(desplazable)
	rejilla_piezas = GridContainer.new()
	rejilla_piezas.columns = 4
	rejilla_piezas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla_piezas.add_theme_constant_override("h_separation", 6)
	rejilla_piezas.add_theme_constant_override("v_separation", 6)
	desplazable.add_child(rejilla_piezas)

	texto_pieza = _etiqueta_panel("", 15, Color(COLOR_TEXTO, 0.85))
	cuerpo.add_child(texto_pieza)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	cuerpo.add_child(fila)
	var listo := _boton("Listo", false)
	listo.custom_minimum_size = Vector2(0, 54)
	listo.add_theme_font_size_override("font_size", 22)
	listo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listo.pressed.connect(_cerrar_tienda)
	fila.add_child(listo)
	boton_accion = _boton("Comprar", true)
	boton_accion.custom_minimum_size = Vector2(0, 54)
	boton_accion.add_theme_font_size_override("font_size", 22)
	boton_accion.add_theme_constant_override("icon_max_width", 24)
	boton_accion.add_theme_constant_override("h_separation", 10)
	boton_accion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton_accion.size_flags_stretch_ratio = 1.6
	boton_accion.pressed.connect(_usar_pieza)
	fila.add_child(boton_accion)


func _crear_final(capa: CanvasLayer) -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)
	panel_final = centro
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	panel.custom_minimum_size = Vector2(560, 0)
	panel.gui_input.connect(_tocar_final)
	centro.add_child(panel)
	caja_final = panel
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 14)
	panel.add_child(cuerpo)
	cuerpo.add_child(_etiqueta_panel("MAREA CERRADA", 20, COLOR_ORO))
	titulo_final = _etiqueta_panel("Victoria", 60, COLOR_TEXTO)
	cuerpo.add_child(titulo_final)
	texto_final = _etiqueta_panel("Tu barco quedó solo en el mar.", 26, COLOR_TEXTO)
	cuerpo.add_child(texto_final)
	texto_premio = _etiqueta_panel("+0 monedas", 44, COLOR_ORO)
	texto_premio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cuerpo.add_child(texto_premio)
	lineas_premio = VBoxContainer.new()
	lineas_premio.add_theme_constant_override("separation", 4)
	cuerpo.add_child(lineas_premio)
	texto_tesoro = _etiqueta_panel("", 22, COLOR_TEXTO)
	texto_tesoro.modulate.a = 0.8
	cuerpo.add_child(texto_tesoro)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	cuerpo.add_child(fila)
	fila_final = fila
	capa_monedas = Control.new()
	capa_monedas.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_monedas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(capa_monedas)
	var puerto := _boton("Al puerto", false)
	puerto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	puerto.pressed.connect(_al_puerto)
	fila.add_child(puerto)
	var otra := _boton("Otra partida", true)
	otra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	otra.pressed.connect(_buscar_partida)
	fila.add_child(otra)


func _panel_lateral(capa: CanvasLayer) -> Array:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -ANCHO_PANEL - 28.0
	panel.offset_right = -28.0
	panel.offset_top = 28.0
	panel.offset_bottom = -28.0
	capa.add_child(panel)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 14)
	panel.add_child(cuerpo)
	return [panel, cuerpo]


func _estilo_panel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.05, 0.16, 0.2, 0.9)
	estilo.border_color = Color(0.95, 0.88, 0.73, 0.3)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(26)
	estilo.set_content_margin_all(30)
	return estilo


func _abrir_categoria(nueva: String) -> void:
	categoria = nueva
	seleccion = personalizacion.elegidos[categoria]
	jugador.vestir(personalizacion)
	_llenar_rejilla()
	_refrescar_astillero()


func _llenar_rejilla() -> void:
	for hijo in rejilla_piezas.get_children():
		hijo.queue_free()
	botones_pieza.clear()
	miniaturas.cancelar()
	for pieza in Catalogo.lista(categoria):
		var boton := _boton_pieza(pieza)
		rejilla_piezas.add_child(boton)
		botones_pieza[pieza["id"]] = boton
	desplazable.scroll_vertical = 0


func _elegir_pieza(id: String) -> void:
	seleccion = id
	var prueba := personalizacion.copia()
	prueba.elegidos[categoria] = id
	jugador.vestir(prueba)
	_refrescar_astillero()


func _usar_pieza() -> void:
	if personalizacion.tiene(categoria, seleccion):
		personalizacion.elegidos[categoria] = seleccion
		personalizacion.guardar()
		voz_equipar.play()
	elif personalizacion.comprar(categoria, seleccion):
		voz_monedas.play()
		get_tree().create_timer(0.35).timeout.connect(voz_equipar.play)
	else:
		return
	jugador.vestir(personalizacion)
	_brillo_reparacion(jugador.position + Vector3(0, 0.6, 0))
	_refrescar_astillero()


func _cerrar_tienda() -> void:
	jugador.vestir(personalizacion)
	_mostrar(Estado.MENU)


func _refrescar_astillero() -> void:
	texto_monedas_tienda.text = tr("%d monedas") % personalizacion.monedas
	for i in botones_categoria.size():
		_estilo_boton(botones_categoria[i], Catalogo.CATEGORIAS[i] == categoria)

	var propias := 0
	for pieza in Catalogo.lista(categoria):
		if personalizacion.tiene(categoria, pieza["id"]):
			propias += 1
		_pintar_boton_pieza(botones_pieza[pieza["id"]], pieza)

	var elegida := Catalogo.buscar(categoria, seleccion)
	var propia := personalizacion.tiene(categoria, seleccion)
	var info := tr(elegida.get("info", ""))
	texto_pieza.text = "%s%s" % [tr(elegida["nombre"]), "  ·  " + info if info != "" else ""] + tr("\nTienes %d de %d") % [propias, Catalogo.lista(categoria).size()]
	boton_accion.icon = null if propia else _textura_moneda()
	if personalizacion.elegidos[categoria] == seleccion:
		boton_accion.text = "Equipado"
		boton_accion.disabled = true
		_estilo_boton(boton_accion, false)
	elif propia:
		boton_accion.text = "Equipar"
		boton_accion.disabled = false
		_estilo_boton(boton_accion, true)
	elif personalizacion.monedas >= elegida["precio"]:
		boton_accion.text = tr("Comprar · %d monedas") % elegida["precio"]
		boton_accion.disabled = false
		_estilo_boton(boton_accion, true)
	else:
		boton_accion.text = tr("Te faltan %d monedas") % (elegida["precio"] - personalizacion.monedas)
		boton_accion.disabled = true
		_estilo_boton(boton_accion, false)


func _boton_pieza(pieza: Dictionary) -> Button:
	var boton := Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.mouse_filter = Control.MOUSE_FILTER_PASS
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boton.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	boton.custom_minimum_size = Vector2(0, 128)
	boton.add_theme_constant_override("icon_max_width", 72)
	boton.add_theme_font_size_override("font_size", 13)
	if categoria in Catalogo.CON_DIBUJO:
		boton.icon = Dibujos.textura(pieza, 96, 64)
	else:
		boton.icon = _hueco_miniatura()
		miniaturas.pedir(categoria, pieza, personalizacion, boton)
	boton.pressed.connect(_elegir_pieza.bind(pieza["id"]))
	return boton


var _hueco: ImageTexture


# Espacio vacío del tamaño de una miniatura mientras se saca la foto.
func _hueco_miniatura() -> ImageTexture:
	if _hueco == null:
		_hueco = ImageTexture.create_from_image(Image.create_empty(Miniaturas.TAM.x, Miniaturas.TAM.y, false, Image.FORMAT_RGBA8))
	return _hueco


func _pintar_boton_pieza(boton: Button, pieza: Dictionary) -> void:
	var id: String = pieza["id"]
	var propia := personalizacion.tiene(categoria, id)
	var equipada: bool = personalizacion.elegidos[categoria] == id
	var estado_pieza := tr("Equipado") if equipada else tr("Tuyo")
	# Sin comprar, el precio va aparte con su moneda; el renglón vacío le deja sitio.
	boton.text = "%s\n%s" % [tr(pieza["nombre"]), estado_pieza if propia else " "]
	var precio: HBoxContainer = boton.get_node_or_null("Precio")
	if precio == null:
		precio = HBoxContainer.new()
		precio.name = "Precio"
		precio.alignment = BoxContainer.ALIGNMENT_CENTER
		precio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		precio.add_theme_constant_override("separation", 6)
		precio.anchor_left = 0.0
		precio.anchor_right = 1.0
		precio.anchor_top = 1.0
		precio.anchor_bottom = 1.0
		precio.offset_top = -27.0
		precio.offset_bottom = -7.0
		precio.add_child(_icono_moneda(16))
		var cifra := _etiqueta("", 14)
		cifra.name = "Cifra"
		cifra.add_theme_color_override("font_color", COLOR_ORO)
		cifra.add_theme_constant_override("outline_size", 4)
		precio.add_child(cifra)
		boton.add_child(precio)
	precio.visible = not propia
	(precio.get_node("Cifra") as Label).text = str(pieza["precio"])

	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(12)
	estilo.set_content_margin_all(5)
	estilo.bg_color = Color(0.11, 0.27, 0.33, 0.95)
	if not propia:
		estilo.bg_color = estilo.bg_color.darkened(0.35)
	estilo.border_color = Color.WHITE if id == seleccion else (COLOR_ORO if equipada else Color(1, 1, 1, 0.25))
	estilo.set_border_width_all(4 if id == seleccion else (3 if equipada else 1))
	for nombre in ["normal", "hover", "pressed"]:
		boton.add_theme_stylebox_override(nombre, estilo)
	var claro := estilo.bg_color.get_luminance() > 0.55 and estilo.bg_color.a > 0.5
	var texto := Color("2a1c10") if claro else COLOR_TEXTO
	for nombre in ["font_color", "font_hover_color", "font_pressed_color"]:
		boton.add_theme_color_override(nombre, texto)
	boton.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	boton.add_theme_constant_override("outline_size", 0 if claro else 4)


func _etiqueta(texto: String, tam: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", COLOR_TEXTO)
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	etiqueta.add_theme_constant_override("outline_size", 6)
	return etiqueta


func _etiqueta_panel(texto: String, tam: int, color: Color) -> Label:
	var etiqueta := _etiqueta(texto, tam)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_constant_override("outline_size", 0)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return etiqueta


func _boton(texto: String, primario: bool) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(0, 76)
	boton.focus_mode = Control.FOCUS_NONE
	boton.add_theme_font_size_override("font_size", 30)
	_estilo_boton(boton, primario)
	return boton


func _estilo_boton(boton: Button, activo: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(18)
	normal.set_content_margin_all(10)
	if activo:
		normal.bg_color = Color("e0a15a")
	else:
		normal.bg_color = Color(1, 1, 1, 0.08)
		normal.border_color = Color(1, 1, 1, 0.3)
		normal.set_border_width_all(2)
	var presionado := normal.duplicate() as StyleBoxFlat
	presionado.bg_color = normal.bg_color.darkened(0.15)
	boton.add_theme_stylebox_override("normal", normal)
	boton.add_theme_stylebox_override("hover", normal)
	boton.add_theme_stylebox_override("pressed", presionado)
	boton.add_theme_stylebox_override("disabled", normal)
	var texto := Color("2a1c10") if activo else COLOR_TEXTO
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		boton.add_theme_color_override(nombre, texto)


func _anclar(control: Control, ancla: Vector2, desde: Vector2, tam: Vector2) -> void:
	control.anchor_left = ancla.x
	control.anchor_right = ancla.x
	control.anchor_top = ancla.y
	control.anchor_bottom = ancla.y
	control.offset_left = desde.x
	control.offset_top = desde.y
	control.offset_right = desde.x + tam.x
	control.offset_bottom = desde.y + tam.y


func _mostrar(nuevo: Estado) -> void:
	estado = nuevo
	var en_juego := estado == Estado.JUGANDO or estado == Estado.FIN
	panel_menu.visible = estado == Estado.MENU
	panel_astillero.visible = estado == Estado.ASTILLERO
	aviso_giro.visible = estado == Estado.ASTILLERO
	dedos_vitrina.clear()
	panel_final.visible = estado == Estado.FIN
	hud.visible = en_juego
	minimapa.visible = en_juego
	marcadores.visible = en_juego
	controles.visible = estado == Estado.JUGANDO
	texto_monedas_menu.text = tr("Tesoro: %d monedas") % personalizacion.monedas
	_pintar_nivel_menu()
	panel_niveles.visible = estado == Estado.NIVELES
	if estado == Estado.NIVELES:
		_llenar_niveles()
	campo_nombre.text = personalizacion.nombre
	panel_busqueda.visible = estado == Estado.BUSCANDO
	panel_ajustes.visible = estado == Estado.AJUSTES
	boton_ajustes.visible = estado == Estado.MENU
	boton_idioma.visible = estado == Estado.MENU
	boton_partida.visible = estado == Estado.JUGANDO
	panel_partida.visible = false
	if estado == Estado.ASTILLERO:
		_abrir_categoria(categoria)
	match estado:
		Estado.JUGANDO:
			tiempo_combate = 0.0
			musica.tocar("juego")
		Estado.FIN:
			musica.tocar("victoria" if resultado == "victoria" else "derrota")
		_:
			musica.tocar("menu")
	palanca_dedo = -1
	dedos_fuego.clear()
	palanca = Vector2.ZERO


func _zarpar() -> void:
	_preparar_mar()
	_mostrar(Estado.JUGANDO)
	_pintar_hud()


func _al_puerto() -> void:
	_preparar_mar()
	_mostrar(Estado.MENU)


func _pintar_hud() -> void:
	texto_vivos.text = tr("A flote: %d") % _contar_vivos()
	_pintar_botin()
	var ultima := DURACION_FASES.size() - 1
	var peligro := peligros.aviso(jugador) if jugador.viva else ""
	if peligro != "":
		texto_tormenta.text = peligro
	elif jugador.pos.distance_to(zona_centro) > zona_radio:
		texto_tormenta.text = "Estás en la tormenta"
	elif fase == ultima and edad_fase >= DURACION_FASES[ultima]:
		texto_tormenta.text = "Círculo final"
	else:
		var restante: float = DURACION_FASES[fase] - edad_fase
		texto_tormenta.text = tr("Tormenta: %ds") % ceili(restante)


func _dibujar_marcadores() -> void:
	for barco in barcos:
		if not barco.viva or not barco.visible:
			continue
		var punto := barco.position + Vector3(0.0, barco.altura, 0.0)
		if camara.is_position_behind(punto):
			continue
		var pantalla := camara.unproject_position(punto)
		var ancho := 76.0
		marcadores.draw_rect(Rect2(pantalla + Vector2(-ancho / 2.0, -6.0), Vector2(ancho, 12.0)), Color(0, 0, 0, 0.5))
		var color := Color("3dde7a") if barco.es_jugador else Color("e23d3d")
		var lleno := (ancho - 4.0) * barco.vida / barco.vida_max
		marcadores.draw_rect(Rect2(pantalla + Vector2(-ancho / 2.0 + 2.0, -4.0), Vector2(lleno, 8.0)), color)
		var fuente := ThemeDB.fallback_font
		var tam := 18
		var ancho_nombre := fuente.get_string_size(barco.nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var sitio := pantalla + Vector2(-ancho_nombre / 2.0, -12.0)
		var tinta := Color("c9ffd9") if barco.es_jugador else COLOR_TEXTO
		marcadores.draw_string_outline(fuente, sitio, barco.nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 5, Color(0, 0, 0, 0.7))
		marcadores.draw_string(fuente, sitio, barco.nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, tinta)
		if barco.botin > 0 and barco.es_bot:
			var cifra := str(barco.botin)
			var moneda := pantalla + Vector2(ancho / 2.0 + 12.0, 0.0)
			_dibujar_moneda(moneda, 8.0)
			marcadores.draw_string_outline(fuente, moneda + Vector2(11.0, 6.0), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.7))
			marcadores.draw_string(fuente, moneda + Vector2(11.0, 6.0), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_ORO)
	peligros.dibujar_vidas(marcadores, camara)
	var fuente_cofre := ThemeDB.fallback_font
	for cofre in cofres:
		var arriba: Vector3 = cofre.nodo.position + Vector3(0, 1.4, 0)
		if cofre.nodo.position.distance_to(foco) > DISTANCIA_VISIBLE or camara.is_position_behind(arriba):
			continue
		var en_pantalla := camara.unproject_position(arriba)
		var etiqueta := "+%d" % cofre.monedas
		var medida := fuente_cofre.get_string_size(etiqueta, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		_dibujar_moneda(en_pantalla + Vector2(-medida / 2.0 - 10.0, -6.0), 9.0)
		marcadores.draw_string_outline(fuente_cofre, en_pantalla + Vector2(-medida / 2.0 + 2.0, 0.0), etiqueta, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 5, Color(0, 0, 0, 0.75))
		marcadores.draw_string(fuente_cofre, en_pantalla + Vector2(-medida / 2.0 + 2.0, 0.0), etiqueta, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, COLOR_ORO)
	for aviso in avisos_botin:
		if camara.is_position_behind(aviso.punto):
			continue
		var lugar := camara.unproject_position(aviso.punto)
		var tinta_aviso := Color(aviso.color, clampf(aviso.vida / 0.5, 0.0, 1.0))
		marcadores.draw_string_outline(fuente_cofre, lugar, aviso.texto, HORIZONTAL_ALIGNMENT_CENTER, 120, 30, 6, Color(0, 0, 0, tinta_aviso.a * 0.75))
		marcadores.draw_string(fuente_cofre, lugar, aviso.texto, HORIZONTAL_ALIGNMENT_CENTER, 120, 30, tinta_aviso)


var _moneda: ImageTexture


# Moneda de oro para la interfaz: canto oscuro, cara dorada, relieve y brillo.
func _textura_moneda() -> ImageTexture:
	if _moneda != null:
		return _moneda
	var lado := 64
	var imagen := Image.create_empty(lado, lado, false, Image.FORMAT_RGBA8)
	var centro := Vector2(lado, lado) / 2.0
	var r := lado / 2.0 - 1.0
	for y in lado:
		for x in lado:
			var p := Vector2(x + 0.5, y + 0.5) - centro
			var d := p.length() / r
			if d > 1.0:
				continue
			var color := Color("8a6418")
			if d < 0.84:
				color = Color("e2b13a").lerp(Color("f6d978"), clampf(-(p.x + p.y) / (r * 1.4), 0.0, 1.0))
			if d > 0.56 and d < 0.64:
				color = Color("c08a22")
			if d < 0.56:
				color = Color("f0cd62").lerp(Color("fff1b0"), clampf(-(p.x + p.y) / r, 0.0, 1.0) * 0.6)
			color.a = clampf((1.0 - d) * r, 0.0, 1.0)
			imagen.set_pixel(x, y, color)
	_moneda = ImageTexture.create_from_image(imagen)
	return _moneda


func _icono_moneda(tam: float) -> TextureRect:
	var icono := TextureRect.new()
	icono.texture = _textura_moneda()
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.custom_minimum_size = Vector2(tam, tam)
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icono


func _dibujar_moneda(centro: Vector2, radio: float) -> void:
	marcadores.draw_circle(centro, radio, Color("8a6418"))
	marcadores.draw_circle(centro, radio * 0.82, Color("e2b13a"))
	marcadores.draw_circle(centro, radio * 0.5, Color("f0cd62"))


func _dibujar_minimapa() -> void:
	var radio := minimapa.size.x / 2.0
	var centro := minimapa.size / 2.0
	var escala := radio / RADIO_MUNDO
	minimapa.draw_circle(centro, radio, Color("0e2f38"))
	minimapa.draw_circle(centro + zona_centro * escala, maxf(3.0, zona_radio * escala), Color("1f7f86"))
	minimapa.draw_arc(centro + zona_centro * escala, maxf(3.0, zona_radio * escala), 0.0, TAU, 64, Color(1.0, 0.96, 0.84), 2.0, true)
	for isla in islotes:
		var tono := COLOR_ROCA if isla.radio <= RADIO_ROCAS else COLOR_ARENA
		if isla.lobulos.is_empty():
			minimapa.draw_circle(centro + isla.pos * escala, maxf(1.5, isla.radio * escala), tono)
			continue
		for lobulo in isla.lobulos:
			var sitio: Vector2 = isla.pos + Vector2(lobulo.x, lobulo.y) * isla.radio
			minimapa.draw_circle(centro + sitio * escala, maxf(1.0, lobulo.z * isla.radio * escala), tono)
	peligros.dibujar_minimapa(minimapa, centro, escala)
	for tabla in tablas:
		minimapa.draw_circle(centro + tabla.pos * escala, 2.5, Color("ffd36b"))
	for cofre in cofres:
		var punto_cofre: Vector2 = centro + cofre.pos * escala
		minimapa.draw_rect(Rect2(punto_cofre - Vector2(3.5, 3.0), Vector2(7, 6)), Color("ffb83a"))
		minimapa.draw_rect(Rect2(punto_cofre - Vector2(3.5, 3.0), Vector2(7, 6)), Color("5a3418"), false, 1.0)
	for barco in barcos:
		if not barco.viva:
			continue
		var punto := centro + barco.pos * escala
		if barco.es_jugador:
			minimapa.draw_circle(punto, 5.0, Color("7dffb2"))
		else:
			minimapa.draw_rect(Rect2(punto - Vector2(3, 3), Vector2(6, 6)), Color("ff9b8a"))
	minimapa.draw_arc(centro, radio, 0.0, TAU, 64, Color(1, 0.97, 0.9, 0.95), 4.0, true)


func _dibujar_controles() -> void:
	var base := centro_palanca if palanca_dedo != -1 else _posicion_palanca_reposo()
	var aro := RADIO_PALANCA + 12.0
	controles.draw_circle(base + Vector2(0, 3), aro + 2.0, Color(0, 0, 0, 0.18))
	controles.draw_circle(base, aro, Color(0.05, 0.16, 0.22, 0.42))
	controles.draw_arc(base, aro, 0.0, TAU, 64, Color(COLOR_ORO, 0.75), 2.5, true)
	controles.draw_arc(base, aro * 0.55, 0.0, TAU, 48, Color(1, 1, 1, 0.12), 1.5, true)
	for k in 4:
		var marca := Vector2.UP.rotated(k * PI / 2.0)
		controles.draw_line(base + marca * (aro - 9.0), base + marca * (aro - 4.0), Color(COLOR_ORO, 0.6), 2.0, true)
	var perilla := base + palanca * RADIO_PALANCA
	controles.draw_circle(perilla + Vector2(0, 3), 27.0, Color(0, 0, 0, 0.3))
	controles.draw_circle(perilla, 26.0, COLOR_ORO)
	controles.draw_circle(perilla, 22.0, Color("fdf3df"))
	controles.draw_circle(perilla + Vector2(0, 4), 16.0, Color("efe0c2"))
	controles.draw_circle(perilla + Vector2(-6, -7), 6.0, Color(1, 1, 1, 0.7))

	var fuente := ThemeDB.fallback_font
	for arma in BOTONES_FUEGO:
		var radio: float = BOTONES_FUEGO[arma][1]
		var texto: String = BOTONES_FUEGO[arma][2]
		var carga: float = 1.0 - jugador.recargas[arma] / RECARGAS[arma]
		var lista := carga >= 1.0
		var pulsado := _arma_pulsada(arma)
		var centro := _posicion_fuego(arma) + (Vector2(0, 2) if pulsado else Vector2.ZERO)
		if pulsado:
			radio *= 0.93
		var borde := COLOR_ORO if lista else Color("7d7368")
		controles.draw_circle(centro + Vector2(0, 4), radio + 3.0, Color(0, 0, 0, 0.3))
		controles.draw_circle(centro, radio + 3.0, borde)
		controles.draw_circle(centro, radio, Color("16384a") if lista else Color("1c2a33"))
		controles.draw_circle(centro + Vector2(0, -radio * 0.28), radio * 0.68, Color(1, 1, 1, 0.07))
		if not lista:
			_dibujar_sector(centro, radio, -PI / 2.0 + TAU * carga, -PI / 2.0 + TAU, Color(0, 0, 0, 0.45))
			controles.draw_arc(centro, radio - 2.5, -PI / 2.0, -PI / 2.0 + TAU * carga, 40, Color(COLOR_ORO, 0.9), 4.0, true)
		else:
			var brillo := 0.25 + 0.15 * sin(tiempo * 4.0)
			controles.draw_arc(centro, radio + 6.0, 0.0, TAU, 48, Color(COLOR_ORO, brillo), 2.0, true)
		var tinta := Color("fff3dc") if lista else Color(1, 1, 1, 0.45)
		_dibujar_flecha(centro + Vector2(0, -7.0), arma, radio / 36.0, tinta)
		var tam := 13
		var rotulo := tr(texto)
		var ancho_texto := fuente.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		controles.draw_string(fuente, centro + Vector2(-ancho_texto / 2.0, radio * 0.58), rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, tinta)


func _dibujar_sector(centro: Vector2, radio: float, desde: float, hasta: float, color: Color) -> void:
	var puntos := PackedVector2Array([centro])
	var pasos := maxi(2, ceili((hasta - desde) / TAU * 40.0))
	for i in pasos + 1:
		puntos.append(centro + Vector2.from_angle(lerpf(desde, hasta, float(i) / pasos)) * radio)
	if puntos.size() >= 3:
		controles.draw_colored_polygon(puntos, color)


# Bala con flecha hacia el lado del barco por el que sale el disparo.
func _dibujar_flecha(centro: Vector2, arma: String, escala: float, color: Color) -> void:
	var giro: float = {"proa": 0.0, "babor": -PI / 2.0, "estribor": PI / 2.0}[arma]
	var punta := PackedVector2Array([Vector2(0, -16), Vector2(9, -5), Vector2(-9, -5)])
	for i in punta.size():
		punta[i] = centro + punta[i].rotated(giro) * escala
	controles.draw_colored_polygon(punta, color)
	controles.draw_circle(centro + Vector2(0, 5).rotated(giro) * escala, 7.0 * escala, color)
