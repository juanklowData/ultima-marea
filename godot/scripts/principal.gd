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
const TABLAS_RESTOS := 2
const MEDIO_EJE_CASCO := 0.83
const MEDIA_MANGA_CASCO := 0.5
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
# Más allá (metros 3D desde el foco) los bots se calculan uno de cada CADA_LEJOS cuadros.
const DISTANCIA_CALCULO := 75.0
const CADA_LEJOS := 3
const RADIO_PALANCA := 60.0
const ALTO_HUD := 150.0
const ANCHO_BRUJULA := 20.0
const CAMARA_JUEGO := Vector3(0.0, 18.0, 11.5)
# Radianes por segundo que gira sola la cámara alrededor del barco en el puerto.
# En el menú la cámara va y viene por el lado del mar, sin pasar sobre la isla del puerto,
# mirando a un punto entre el barco y la isla.
const ARCO_MENU := 0.3
const RITMO_MENU := 0.12
const GIRO_BASE_MENU := PI + 0.75
const MIRA_MENU := Vector3(3.0, 0.0, 1.2)
const DISTANCIA_MENU := 12.5
const ALTURA_MENU := 5.0
const NIEBLA_MAR := 0.003
const NIEBLA_PUERTO := 0.0018
const GIRO_VITRINA := 0.12
# Segundos sin girar solo después de que el jugador mueva la cámara a mano.
const PAUSA_GIRO_MANUAL := 300.0
const LADO_AGUA := 190.0
const DIVISIONES_AGUA := 160
const ANCHO_PANEL := 540.0
const MONEDAS_VICTORIA := 15
const MONEDAS_POR_HUNDIDO := 1
# Monedas con que zarpa cada bot, para que hundirlos deje algo en el mar.
const BOTIN_INICIAL_BOTS := 3
# Segundos que flota un cofre antes de hundirse.
const VIDA_COFRE := 45.0
# Parte de los bots zarpa con un cofre a la vista: hundirlos tiene premio.
const BOTS_CON_COFRE := 0.2
# Tamaño de las tablas y cofres que flotan (solo el dibujo; se recogen igual de cerca).
const ESCALA_FLOTANTES := 0.6
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

# Segundos que tarda en cerrarse cada fase; en total, 15 minutos de partida.
const DURACION_FASES: Array[float] = [176.0, 148.0, 133.0, 120.0, 112.0, 107.0, 104.0]
const RADIO_FASES: Array[float] = [2750.0, 2100.0, 1550.0, 1050.0, 650.0, 360.0, 190.0]

const COLOR_TEXTO := Paleta.TEXTO
const COLOR_ORO := Paleta.ORO
const COLOR_PELIGRO := Paleta.PELIGRO
# Acabado de cada tipo de superficie: la madera y la piedra mates, lo pintado con algo de brillo.
const ASPEREZA := {"madera": 0.82, "roca": 0.95, "arena": 0.97, "hierba": 0.92, "general": 0.62}
const COLORES_TABLA: Array[Color] = [Color("a7774a"), Color("8e6239"), Color("b88a58")]
# Pestaña de la tienda con las piezas únicas que se pagan con gemas.
const TESOROS := "tesoros"

enum Estado { MENU, ASTILLERO, BUSCANDO, JUGANDO, FIN, AJUSTES, NIVELES, CAPITANES }


class Bala:
	var pos: Vector2
	var vel: Vector2
	var vida := 0.0
	var gracia := 0.15
	var dueno: Barco
	var nodo: MeshInstance3D
	# Munición del mar libre ("hierro", "cadena", "fuego", "explosiva"); vacía = bala normal.
	var tipo := ""
	# Isla desde la que sale (los fuertes disparan desde su islote): no choca con ella.
	var origen: Circulo
	# Armada que dispara en el modo MOBA: no daña a los suyos.
	var equipo := -1
	# Daño fijo (botes y torres del MOBA); negativo = el normal.
	var danio := -1.0


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
	# Si no está vacío es un tesoro ("cofre", "calavera") en vez de monedas sueltas.
	var tesoro := ""
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


# Estado de la partida
var estado := Estado.MENU
# "tormenta": todos contra todos con la zona que se cierra. "libre": mar abierto enorme.
var modo := "tormenta"
var personalizacion := Personalizacion.new()
var barcos: Array[Barco] = []
var jugador: Barco
var balas: Array = []
var tablas: Array = []
var cofres: Array = []
var efectos: Array = []
var islotes: Array[Circulo]:
	get:
		return islas.islotes
var hundidos := 0
var resultado := ""
var puesto := 0
var golpe := 0.0
var tiempo := 0.0
var tiempo_combate := 0.0
var avisos_botin: Array = []
var botin_perdido := 0

# Zona segura que cierra la tormenta
var zona_centro := Vector2.ZERO
var zona_radio := ZONA_INICIAL
var zona_desde := ZONA_INICIAL
var centro_desde := Vector2.ZERO
var centro_hacia := Vector2.ZERO
var fase := 0
var edad_fase := 0.0
var cierre := 0.0

# Controles táctiles
var palanca := Vector2.ZERO
var centro_palanca := Vector2.ZERO
var palanca_dedo := -1
var dedos_fuego := {}

# Cámara, en partida y en el puerto
var camara: Camera3D
var foco := Vector3.ZERO
var angulo_puerto := 0.0
var altura_vitrina := 5.0
var distancia_vitrina := 11.0
var pausa_giro := 0.0
var dedos_vitrina := {}

# Módulos del mundo
var islas: Islas
var peligros: Peligros
var tiburones: Tiburones
var barriles: Barriles
var misiones: Misiones
var tesoros: Tesoros
var comercio: Comercio
var persecucion: Persecucion
var niebla: Niebla
var recompensas: Recompensas
var emotes: Emotes
var moba: Moba
var libre: MarLibre
var fauna: Fauna
var capa_barcos: Node3D
var musica: Musica
var miniaturas: Miniaturas

# Escena 3D: mar, luz y mallas compartidas por los efectos
var entorno: Environment
var sol: DirectionalLight3D
var agua: MeshInstance3D
var material_agua: ShaderMaterial
var muro: MeshInstance3D
var material_muro: ShaderMaterial
var materiales := {}
var malla_bala: SphereMesh
var malla_humo: SphereMesh
var malla_gota: SphereMesh
var malla_espuma: CylinderMesh
var malla_astilla: BoxMesh

# Cielo de tormenta: nubes, lluvia, rayos y el destello en pantalla
var nubes: MeshInstance3D
var material_nubes: ShaderMaterial
var lluvia: CPUParticles3D
var material_lluvia: StandardMaterial3D
var fuerza_lluvia := 0.0
var botones_graficos: Array[Button] = []
var luz_rayo: OmniLight3D
var rayo: Node3D
var rayo_vida := 0.0
var relampago := 0.0
var proximo_rayo := 2.5
var truenos: Array = []
var destello: ColorRect

# Voces de los efectos de sonido
var voces_trueno: Array[AudioStreamPlayer] = []
var sonidos_trueno: Array[AudioStreamWAV] = []
var voces_canon: Array[AudioStreamPlayer] = []
var voces_hundir: Array[AudioStreamPlayer] = []
var voces_explosion: Array[AudioStreamPlayer] = []
var voz_monedas: AudioStreamPlayer
var voz_moneda: AudioStreamPlayer
var voz_equipar: AudioStreamPlayer

# Interfaz durante la partida
var velo_golpe: ColorRect
var marcadores: Control
var controles: Control
var hud: VBoxContainer
var texto_vivos: Label
var texto_tormenta: Label
var texto_botin: Label
var texto_mision: Label
var marcador_moba: HBoxContainer
var cifra_hundidos: Label
var cifra_veces_hundido: Label
var minimapa: Control
var aviso_giro: Label
var boton_partida: Button
var panel_partida: Control
var boton_salir: Button

# Menú del puerto, ajustes y niveles
var panel_menu: Control
var texto_monedas_menu: Label
var texto_gemas_menu: Label
var insignia_menu: Insignia
var texto_nivel_menu: Label
var texto_xp_menu: Label
var barra_nivel_menu: Control
var boton_ajustes: Button
var boton_idioma: BotonIdioma
var panel_ajustes: Control
var campo_nombre: LineEdit
var deslizadores_volumen: Array[HSlider] = []
var panel_niveles: Control
var lista_niveles: VBoxContainer
var desliz_niveles: ScrollContainer

# Búsqueda de partida
var panel_busqueda: Control
var titulo_busqueda: Label
var texto_busqueda: Label
var texto_jugadores: Label
var tiempo_busqueda := 0.0

# Tienda
var panel_astillero: Control
var texto_monedas_tienda: Label
var texto_gemas_tienda: Label
var botones_categoria: Array = []
var rejilla_piezas: GridContainer
var desplazable: ScrollContainer
var botones_pieza := {}
var texto_pieza: Label
var boton_accion: Button
var categoria := "tipo"
var seleccion := ""

# Pantalla final y premio
var panel_final: Control
var titulo_final: RichTextLabel
var salto_titulo := TextoSaltarin.new()
var texto_final: Label
var texto_premio: Label
var caja_final: PanelContainer
var lineas_premio: VBoxContainer
var texto_tesoro: Label
var fila_final: HBoxContainer
var capa_monedas: Control
var anim_premio: Tween
var ultimo_conteo := 0


func _ready() -> void:
	randomize()
	personalizacion.cargar()
	Idioma.instalar()
	Idioma.usar(personalizacion.idioma)
	_revisar_arranque()
	var carga := PantallaCarga.new()
	add_child(carga)
	carga.paso(tr("Detectando tu dispositivo..."), 0.1, _texto_dispositivo())
	await get_tree().process_frame
	await get_tree().process_frame
	nivel_graficos = nivel_efectivo()
	_ajustar_pantalla(nivel_graficos)
	carga.paso(tr("Ajustando los gráficos..."), 0.25)
	await get_tree().process_frame
	_crear_buses()
	musica = Musica.new()
	add_child(musica)
	miniaturas = Miniaturas.new()
	add_child(miniaturas)
	carga.paso(tr("Preparando el mar..."), 0.45)
	await get_tree().process_frame
	_crear_escena()
	carga.paso(tr("Preparando la interfaz..."), 0.7)
	await get_tree().process_frame
	_crear_interfaz()
	aplicar_graficos()
	aplicar_tamano_controles()
	get_viewport().size_changed.connect(aplicar_tamano_controles)
	get_viewport().size_changed.connect(aplicar_graficos)
	carga.paso(tr("Abriendo el puerto..."), 0.9)
	await get_tree().process_frame
	_preparar_puerto()
	_mostrar(Estado.MENU)
	listo = true
	carga.paso(tr("¡Listo!"), 1.0)
	carga.cerrar()


# Si la partida anterior se cerró de golpe (sin pasar por segundo plano ni salir), el móvil no
# aguantó: se bajan los gráficos un nivel más cada vez hasta que vaya bien.
const RUTA_ARRANQUE := "user://arranque.cfg"

var listo := false
var rebaja := 0
var se_cerro := false


func _revisar_arranque() -> void:
	var archivo := ConfigFile.new()
	archivo.load(RUTA_ARRANQUE)
	rebaja = int(archivo.get_value("arranque", "rebaja", 0))
	if archivo.get_value("arranque", "abierto", false):
		se_cerro = true
		rebaja = mini(rebaja + 1, 3)
	_marcar_abierto(true)


func _marcar_abierto(abierto: bool) -> void:
	var archivo := ConfigFile.new()
	archivo.set_value("arranque", "abierto", abierto)
	archivo.set_value("arranque", "rebaja", rebaja)
	archivo.save(RUTA_ARRANQUE)


func _notification(que: int) -> void:
	if que in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_PREDELETE]:
		_marcar_abierto(false)
	elif que in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN] and listo:
		_marcar_abierto(true)


func nivel_efectivo() -> int:
	var base := personalizacion.graficos if personalizacion.graficos >= 0 else detectar_graficos()
	return maxi(0, base - rebaja)


func _texto_dispositivo() -> String:
	var texto := tr("Gráficos: %s") % tr(NIVELES_GRAFICOS[nivel_efectivo()])
	if se_cerro:
		texto += "\n" + tr("La última vez el juego se cerró: bajamos los gráficos para que vaya fluido")
	return texto


# Niveles: 0 súper bajo, 1 bajo, 2 medio, 3 alto. Los bajos apagan sombras, brillo y
# antialias, bajan la resolución 3D y acortan la vista; súper bajo además va a 30 cuadros,
# quita la lluvia y pone un mar plano. Con "automático" (-1) se elige según el dispositivo.
const NIVELES_GRAFICOS: Array[String] = ["Súper bajo", "Bajo", "Medio", "Alto"]

var nivel_graficos := 1
var agua_sencilla: StandardMaterial3D
var botones_efectos: Array[Button] = []
# Metros hasta el punto del mar más lejano que entra en pantalla: x desde la cámara, y desde el foco.
var cobertura := Vector2(40.0, 30.0)

# Cada efecto se puede encender o apagar a mano; si no, va encendido desde ese nivel de gráficos.
const EFECTOS_VISUALES := {
	"lluvia": ["Lluvia", 1],
	"fps60": ["60 FPS", 1],
	"sombras": ["Sombras", 2],
	"colores": ["Colores vivos", 2],
	"resolucion": ["Alta resolución", 2],
	"suavizado": ["Bordes suaves", 3],
	"brillo": ["Brillo", 3],
	"lejos": ["Vista lejana", 3],
}


const CALIDADES_MAR: Array[String] = ["Plano", "Suave", "Con olas", "Detallado"]
const DIVISIONES_MAR: Array[int] = [40, 60, 100, DIVISIONES_AGUA]
var botones_mar: Array[Button] = []


func calidad_mar() -> int:
	return personalizacion.calidad_mar if personalizacion.calidad_mar >= 0 else [0, 2, 2, 3][nivel_graficos]


func efecto_visual(clave: String) -> bool:
	return personalizacion.efectos.get(clave, nivel_graficos >= EFECTOS_VISUALES[clave][1])


func aplicar_graficos() -> void:
	var nivel := nivel_efectivo()
	nivel_graficos = nivel
	cobertura = _cobertura_pantalla()
	_ajustar_pantalla(nivel)
	sol.shadow_enabled = efecto_visual("sombras")
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if nivel <= 2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sol.directional_shadow_max_distance = 60.0 if nivel <= 2 else 90.0
	entorno.glow_enabled = efecto_visual("brillo")
	entorno.adjustment_enabled = efecto_visual("colores")
	camara.far = 400.0 if efecto_visual("lejos") else [140.0, 180.0, 260.0, 400.0][nivel]
	var mar := calidad_mar()
	agua.material_override = material_agua if mar > 0 else _agua_sencilla()
	material_agua.set_shader_parameter("detalle", mar >= 2)
	var plano := agua.mesh as PlaneMesh
	plano.subdivide_width = DIVISIONES_MAR[mar]
	plano.subdivide_depth = plano.subdivide_width
	lluvia.amount = [150, 150, 300, 600][nivel] if efecto_visual("lluvia") else 1
	miniaturas.calidad(nivel)
	for pieza in get_tree().get_nodes_in_group("aparicion"):
		ajustar_distancia(pieza)
	for k in botones_graficos.size():
		var boton: Button = botones_graficos[k]
		var opcion: int = boton.get_meta("nivel")
		Ui.estilo_boton(boton, opcion == personalizacion.graficos and personalizacion.efectos.is_empty() and personalizacion.calidad_mar < 0)
		if opcion < 0:
			boton.text = tr("Automático") + " (" + tr(NIVELES_GRAFICOS[maxi(0, detectar_graficos() - rebaja)]) + ")"
	for boton in botones_mar:
		Ui.estilo_boton(boton, boton.get_meta("mar") == mar)
	for boton in botones_efectos:
		var clave: String = boton.get_meta("efecto")
		var encendido := efecto_visual(clave)
		Ui.estilo_boton(boton, encendido)
		boton.text = tr(EFECTOS_VISUALES[clave][0]) + ": " + tr("Sí" if encendido else "No")


# Con la cámara de partida, hasta dónde se ve el mar en las esquinas de arriba de la pantalla
# (las más lejanas). Nada que esté dentro de ese alcance se debe esconder.
func _cobertura_pantalla() -> Vector2:
	var tam := get_viewport().get_visible_rect().size
	var aspecto := tam.x / maxf(tam.y, 1.0)
	var medio := deg_to_rad(camara.fov) * 0.5
	var borde := atan2(CAMARA_JUEGO.y, CAMARA_JUEGO.z) - medio
	var largo := CAMARA_JUEGO.y / sin(borde)
	var lado := largo * cos(medio) * tan(medio) * aspecto
	var delante := CAMARA_JUEGO.y / tan(borde) - CAMARA_JUEGO.z
	return Vector2(Vector2(largo, lado).length(), Vector2(delante, lado).length())


# Metros desde el foco hasta donde se dibujan barcos e islas en partida.
func alcance_vista() -> float:
	if efecto_visual("lejos"):
		return DISTANCIA_VISIBLE
	return maxf([38.0, 46.0, 56.0, DISTANCIA_VISIBLE][nivel_graficos], cobertura.y + 10.0)


# Lo pequeño se dibuja solo cuando el barco se acerca y lo mediano un poco antes; lo
# grande, siempre. Metros desde la cámara por nivel de gráficos (0 = sin límite), nunca
# menos de lo que abarca la pantalla.
const APARICION_CHICO: Array[float] = [26.0, 32.0, 45.0, 0.0]
const APARICION_MEDIANO: Array[float] = [40.0, 50.0, 70.0, 0.0]


func ajustar_distancia(pieza: GeometryInstance3D) -> void:
	var tamano: float = pieza.get_meta("tamano", 99.0)
	var lejos := efecto_visual("lejos")
	if tamano < 0.7:
		pieza.visibility_range_end = 0.0 if lejos else maxf(APARICION_CHICO[nivel_graficos], cobertura.x + 4.0)
	elif tamano < 2.5:
		pieza.visibility_range_end = 0.0 if lejos else maxf(APARICION_MEDIANO[nivel_graficos], cobertura.x + 8.0)


# Las chispas, humo y salpicaduras que caerían fuera de la pantalla no se crean.
func _alcance_efectos() -> float:
	if efecto_visual("lejos"):
		return DISTANCIA_VISIBLE
	return maxf([26.0, 34.0, 50.0, DISTANCIA_VISIBLE][nivel_graficos], cobertura.y + 4.0)


func _ajustar_pantalla(nivel: int) -> void:
	var vista := get_viewport()
	vista.scaling_3d_scale = 1.0 if efecto_visual("resolucion") else [0.8, 0.9, 1.0, 1.0][nivel]
	vista.msaa_3d = Viewport.MSAA_2X if efecto_visual("suavizado") else Viewport.MSAA_DISABLED
	Engine.max_fps = 60 if efecto_visual("fps60") else 30


# Mar plano de un color, sin el shader de olas, para los móviles más justos.
func _agua_sencilla() -> StandardMaterial3D:
	if agua_sencilla == null:
		agua_sencilla = StandardMaterial3D.new()
		agua_sencilla.albedo_color = Paleta.MAR_CLARO.lerp(Paleta.MAR_HONDO, 0.35)
		agua_sencilla.roughness = 0.35
		agua_sencilla.metallic_specular = 0.6
	return agua_sencilla


# Calcula el nivel según la memoria, los núcleos y la tarjeta gráfica. En el ordenador, alto;
# en el móvil va a lo seguro: como mucho bajo, y medio solo en los equipos potentes de verdad.
static func detectar_graficos() -> int:
	if not OS.has_feature("mobile"):
		return 1 if OS.has_feature("web") else 3
	var memoria: float = OS.get_memory_info().get("physical", 0) / 1073741824.0
	var nivel := 1
	if memoria > 0.0:
		nivel = 0 if memoria < 3.0 else 1 if memoria < 4.5 else 2 if memoria < 7.0 else 3
	if OS.get_processor_count() <= 4:
		nivel = 0
	var tarjeta := RenderingServer.get_video_adapter_name().to_lower()
	for debil in ["mali-4", "mali-t", "powervr", "adreno (tm) 3", "adreno (tm) 4", "adreno (tm) 50", "adreno (tm) 51", "adreno (tm) 52"]:
		if debil in tarjeta:
			nivel = 0
	for media in ["mali-g3", "mali-g5", "adreno (tm) 53", "adreno (tm) 54", "adreno (tm) 60", "adreno (tm) 61"]:
		if media in tarjeta:
			nivel = mini(nivel, 1)
	var potente := false
	for fuerte in ["adreno (tm) 7", "adreno (tm) 8", "mali-g7", "mali-g6", "immortalis", "xclipse", "apple"]:
		if fuerte in tarjeta:
			potente = true
	return mini(nivel, 2 if potente else 1)


func _selector_graficos(cuerpo: VBoxContainer) -> void:
	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 10)
	cuerpo.add_child(cabecera)
	var titulo := Ui.etiqueta_panel("Gráficos", 22, COLOR_ORO)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)
	var automatico := Ui.boton("Automático", false)
	automatico.custom_minimum_size = Vector2(240, 44)
	automatico.add_theme_font_size_override("font_size", 17)
	_preparar_boton_graficos(automatico, -1)
	cabecera.add_child(automatico)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	cuerpo.add_child(fila)
	for k in NIVELES_GRAFICOS.size():
		var boton := Ui.boton(NIVELES_GRAFICOS[k], false)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.custom_minimum_size = Vector2(0, 44)
		boton.add_theme_font_size_override("font_size", 16)
		boton.clip_text = true
		_preparar_boton_graficos(boton, k)
		fila.add_child(boton)

	cuerpo.add_child(Ui.etiqueta_panel("Calidad del mar", 22, COLOR_ORO))
	var fila_mar := HBoxContainer.new()
	fila_mar.add_theme_constant_override("separation", 8)
	cuerpo.add_child(fila_mar)
	for k in CALIDADES_MAR.size():
		var boton := Ui.boton(CALIDADES_MAR[k], false)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.custom_minimum_size = Vector2(0, 44)
		boton.add_theme_font_size_override("font_size", 16)
		boton.clip_text = true
		boton.set_meta("mar", k)
		boton.mouse_filter = Control.MOUSE_FILTER_PASS
		boton.pressed.connect(func() -> void:
			personalizacion.calidad_mar = k
			personalizacion.guardar()
			aplicar_graficos())
		fila_mar.add_child(boton)
		botones_mar.append(boton)

	cuerpo.add_child(Ui.etiqueta_panel("Efectos visuales", 22, COLOR_ORO))
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 8)
	rejilla.add_theme_constant_override("v_separation", 8)
	cuerpo.add_child(rejilla)
	for clave: String in EFECTOS_VISUALES:
		var boton := Ui.boton(EFECTOS_VISUALES[clave][0], false)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.custom_minimum_size = Vector2(0, 44)
		boton.add_theme_font_size_override("font_size", 16)
		boton.clip_text = true
		boton.set_meta("efecto", clave)
		boton.mouse_filter = Control.MOUSE_FILTER_PASS
		boton.pressed.connect(func() -> void:
			personalizacion.efectos[clave] = not efecto_visual(clave)
			personalizacion.guardar()
			aplicar_graficos())
		rejilla.add_child(boton)
		botones_efectos.append(boton)


func _preparar_boton_graficos(boton: Button, nivel: int) -> void:
	boton.set_meta("nivel", nivel)
	boton.mouse_filter = Control.MOUSE_FILTER_PASS
	boton.pressed.connect(func() -> void:
		personalizacion.graficos = nivel
		personalizacion.efectos.clear()
		personalizacion.calidad_mar = -1
		personalizacion.guardar()
		rebaja = 0
		se_cerro = false
		_marcar_abierto(true)
		aplicar_graficos())
	botones_graficos.append(boton)


func _process(delta: float) -> void:
	if not listo or cargando:
		return
	delta = minf(delta, 0.05)
	tiempo += delta
	if estado == Estado.JUGANDO:
		_actualizar(delta)
	else:
		golpe = maxf(0.0, golpe - delta)
	if estado == Estado.BUSCANDO:
		_avanzar_busqueda(delta)
	if en_puerto() and jugador != null:
		_amarrar()

	var vista := alcance_vista()
	for barco in barcos:
		var cerca := a_3d(barco.pos).distance_to(Vector3(foco.x, 0.0, foco.z)) < vista
		if cerca or barco == jugador:
			barco.colocar(delta)
		barco.visible = (cerca or barco == jugador) and barco.hundimiento < 1.0 \
				and not (modo == "moba" and jugador != null and barco.equipo != jugador.equipo and moba.escondido(barco))
	_actualizar_tablas(delta)
	_actualizar_cofres(delta)
	_actualizar_efectos(delta)
	_mover_camara(delta)
	peligros.animar(delta)
	tiburones.animar(delta)
	barriles.animar(delta)
	misiones.animar(delta)
	if modo == "libre":
		libre.animar(delta)
		comercio.animar(delta)
	elif modo == "moba":
		comercio.animar_llamas(delta)
	fauna.animar(delta)
	emotes.actualizar(delta)
	# En puerto la cámara mira al horizonte y las islas se ven más lejos.
	var en_partida := estado == Estado.JUGANDO or estado == Estado.FIN
	islas.recortar(delta, foco, vista + 8.0 if en_partida else 170.0)
	_actualizar_tormenta(delta)
	_actualizar_agua()

	velo_golpe.color = Color(0.7, 0.12, 0.12, golpe)
	minimapa.queue_redraw()
	controles.queue_redraw()
	marcadores.queue_redraw()


func _actualizar(delta: float) -> void:
	if modo == "libre":
		libre.actualizar(delta)
	elif modo == "moba":
		moba.actualizar(delta)
	else:
		_mover_zona(delta)
	for i in barcos.size():
		var barco := barcos[i]
		if barco.mando != Barco.Mando.BOT:
			barco.actualizar(delta)
			continue
		var paso := paso_lejano(barco, i, delta)
		if paso > 0.0:
			barco.actualizar(paso)
	if modo != "moba":
		peligros.actualizar(delta)
		tiburones.actualizar(delta)
		barriles.actualizar(delta)
		misiones.actualizar(delta)
	_separar_barcos()
	_recoger_tablas()
	_recoger_cofres()
	_mover_balas(delta)
	golpe = maxf(0.0, golpe - delta)
	tiempo_combate = maxf(0.0, tiempo_combate - delta)
	var rival: Barco = rival_de(jugador) if jugador.viva else null
	if rival != null and rival.pos.distance_to(jugador.pos) < DISTANCIA_COMBATE:
		avisar_combate()
	musica.batalla = tiempo_combate > 0.0
	if modo != "libre":
		_revisar_fin(delta)
	_pintar_hud()


# Lo que está lejos del foco se calcula uno de cada CADA_LEJOS cuadros con el tiempo
# acumulado en "pendiente". Devuelve el tiempo a calcular ahora, o 0 si toca esperar.
func paso_lejano(cosa, indice: int, delta: float) -> float:
	cosa.pendiente += delta
	if (Engine.get_process_frames() + indice) % CADA_LEJOS != 0 \
			and a_3d(cosa.pos).distance_to(Vector3(foco.x, 0.0, foco.z)) > DISTANCIA_CALCULO:
		return 0.0
	var paso: float = cosa.pendiente
	cosa.pendiente = 0.0
	return paso


func a_3d(punto: Vector2, altura := 0.0) -> Vector3:
	return Vector3(punto.x * ESCALA, altura, punto.y * ESCALA)


func radio_mundo() -> float:
	if modo == "moba":
		return Moba.RADIO_MAPA
	return MarLibre.RADIO + 400.0 if modo == "libre" else RADIO_MUNDO


# Dónde y hasta dónde se reparten peligros, tablas y cofres: toda la zona en el modo
# tormenta, alrededor del barco en el mar libre.
func centro_juego() -> Vector2:
	return jugador.pos if modo == "libre" and jugador != null else zona_centro


func alcance_juego() -> float:
	return MarLibre.ACTIVO if modo == "libre" else zona_radio


# En el mar libre el minimapa es un radar alrededor del barco: lo de fuera no se dibuja.
func en_mapa(punto: Vector2) -> bool:
	return modo != "libre" or jugador == null or punto.distance_to(jugador.pos) < MarLibre.RADAR * 0.94


func destino_bot(barco: Barco) -> Vector2:
	return libre.destino_bot(barco) if modo == "libre" else zona_centro


func rival_de(barco: Barco) -> Barco:
	if modo == "moba":
		return moba.rival_de(barco)
	return libre.rival_de(barco) if modo == "libre" else rival_mas_cercano(barco)


# Escena 3D

func _crear_escena() -> void:
	_crear_luz_y_camara()
	_crear_mar()
	islas = Islas.new()
	add_child(islas)
	peligros = Peligros.new()
	add_child(peligros)
	tiburones = Tiburones.new()
	add_child(tiburones)
	barriles = Barriles.new()
	add_child(barriles)
	misiones = Misiones.new()
	add_child(misiones)
	tesoros = Tesoros.new()
	add_child(tesoros)
	comercio = Comercio.new()
	persecucion = Persecucion.new()
	add_child(persecucion)
	niebla = Niebla.new()
	add_child(niebla)
	recompensas = Recompensas.new()
	add_child(recompensas)
	emotes = Emotes.new()
	add_child(emotes)
	moba = Moba.new()
	add_child(moba)
	add_child(comercio)
	libre = MarLibre.new()
	add_child(libre)
	fauna = Fauna.new()
	add_child(fauna)
	capa_barcos = Node3D.new()
	add_child(capa_barcos)
	_crear_mallas_efectos()
	_crear_cielo_tormenta()
	_crear_sonidos()
	peligros.preparar(self)
	tiburones.preparar(self)
	barriles.preparar(self)
	misiones.preparar(self)
	tesoros.preparar(self)
	comercio.preparar(self)
	persecucion.preparar(self)
	niebla.preparar(self)
	recompensas.preparar(self)
	emotes.preparar(self)
	moba.preparar(self)
	libre.preparar(self)
	fauna.preparar(self)


func _crear_luz_y_camara() -> void:
	entorno = Environment.new()
	var cielo := ProceduralSkyMaterial.new()
	cielo.sky_top_color = Paleta.CIELO_ALTO
	cielo.sky_horizon_color = Paleta.CIELO_HORIZONTE
	cielo.sky_curve = 0.12
	cielo.ground_horizon_color = Paleta.CIELO_HORIZONTE
	cielo.ground_bottom_color = Paleta.MAR_CLARO
	cielo.sun_angle_max = 20.0
	entorno.background_mode = Environment.BG_SKY
	entorno.sky = Sky.new()
	entorno.sky.sky_material = cielo
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Paleta.AMBIENTE
	entorno.ambient_light_energy = Paleta.AMBIENTE_ENERGIA
	entorno.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	entorno.tonemap_white = 4.0
	entorno.tonemap_exposure = 1.0
	entorno.glow_enabled = true
	entorno.glow_intensity = 0.3
	entorno.glow_hdr_threshold = 1.1
	entorno.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	entorno.adjustment_enabled = true
	entorno.adjustment_saturation = Paleta.SATURACION
	entorno.adjustment_contrast = Paleta.CONTRASTE
	entorno.fog_enabled = true
	entorno.fog_light_color = Paleta.NIEBLA
	entorno.fog_density = NIEBLA_MAR
	var ambiente := WorldEnvironment.new()
	ambiente.environment = entorno
	add_child(ambiente)

	sol = DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sol.light_energy = Paleta.SOL_ENERGIA
	sol.light_color = Paleta.SOL
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 90.0
	add_child(sol)

	camara = Camera3D.new()
	camara.fov = 42.0
	camara.keep_aspect = Camera3D.KEEP_HEIGHT
	camara.far = 400.0
	add_child(camara)
	camara.current = true


# El agua sigue a la cámara; el muro es la cortina de la tormenta en el borde de la zona.
func _crear_mar() -> void:
	var plano := PlaneMesh.new()
	plano.size = Vector2(LADO_AGUA, LADO_AGUA)
	plano.subdivide_width = DIVISIONES_AGUA
	plano.subdivide_depth = DIVISIONES_AGUA
	material_agua = ShaderMaterial.new()
	material_agua.shader = load("res://shaders/agua.gdshader")
	# Es transparente sobre los bajíos: se dibuja antes que la espuma y los efectos.
	material_agua.render_priority = -10
	material_agua.set_shader_parameter("color_hondo", Paleta.MAR_HONDO)
	material_agua.set_shader_parameter("color_claro", Paleta.MAR_CLARO)
	material_agua.set_shader_parameter("color_cielo", Paleta.MAR_REFLEJO)
	material_agua.set_shader_parameter("color_tormenta", Paleta.MAR_TORMENTA)
	material_agua.set_shader_parameter("color_bajio", Paleta.MAR_BAJIO)
	material_agua.set_shader_parameter("color_espuma", Paleta.ESPUMA)
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


# Mallas compartidas por todos los efectos (balas, humo, gotas, espuma y astillas).
func _crear_mallas_efectos() -> void:
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


# Nubes, lluvia y rayos; empiezan apagados y los enciende la tormenta.
func _crear_cielo_tormenta() -> void:
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
	material_lluvia = material_gota
	# Partículas por CPU: las de GPU cuelgan algunos móviles con el renderizador de compatibilidad.
	lluvia = CPUParticles3D.new()
	lluvia.mesh = gota
	lluvia.amount = 600
	lluvia.lifetime = 0.75
	lluvia.local_coords = false
	lluvia.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	lluvia.emission_box_extents = Vector3(30.0, 0.5, 22.0)
	lluvia.direction = Vector3(0.18, -1.0, 0.06)
	lluvia.spread = 3.0
	lluvia.initial_velocity_min = 24.0
	lluvia.initial_velocity_max = 30.0
	lluvia.gravity = Vector3(0.0, -12.0, 0.0)
	lluvia.particle_flag_align_y = true
	lluvia.emitting = false
	lluvia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lluvia)

	luz_rayo = OmniLight3D.new()
	luz_rayo.light_color = Color(0.75, 0.82, 1.0)
	luz_rayo.omni_range = 40.0
	luz_rayo.light_energy = 0.0
	add_child(luz_rayo)
	rayo = Node3D.new()
	add_child(rayo)


# Sonido

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
		sonidos_trueno.append(Sonidos.trueno())
	for _i in 2:
		voces_trueno.append(_nueva_voz(null))
	var canon := Sonidos.canon()
	for _i in 6:
		voces_canon.append(_nueva_voz(canon))
	var hundir := Sonidos.hundir()
	for _i in 3:
		voces_hundir.append(_nueva_voz(hundir))
	var explosion := Sonidos.explosion()
	for _i in 3:
		voces_explosion.append(_nueva_voz(explosion))
	voz_monedas = _nueva_voz(Sonidos.monedas(), -16.0)
	voz_moneda = _nueva_voz(Sonidos.monedas([0.0]), -22.0)
	voz_moneda.max_polyphony = 4
	voz_equipar = _nueva_voz(Sonidos.equipar(), -13.0)
	var ambiente := AmbientePuerto.new()
	add_child(ambiente)
	ambiente.preparar(self)


func _nueva_voz(sonido: AudioStream, volumen := 0.0) -> AudioStreamPlayer:
	var voz := AudioStreamPlayer.new()
	voz.stream = sonido
	voz.bus = "Efectos"
	voz.volume_db = volumen
	add_child(voz)
	return voz


func sonar_explosion(punto: Vector3) -> void:
	_sonar_en_vista(voces_explosion, punto, -3.0, -24.0, 40.0)


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


# Materiales y piezas 3D

# textura: uno de los tipos de Texturas (hierba, roca, arena, madera, general).
func material(color: Color, textura := "general") -> StandardMaterial3D:
	var clave := "%s|%s" % [color.to_html(), textura]
	if not materiales.has(clave):
		var nuevo := StandardMaterial3D.new()
		nuevo.albedo_color = Paleta.armonizar(color)
		nuevo.roughness = ASPEREZA.get(textura, 0.75)
		Texturas.aplicar(nuevo, textura)
		materiales[clave] = nuevo
	return materiales[clave]


func _malla(padre: Node3D, forma: Mesh, color: Color, pos: Vector3, textura := "general") -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = forma
	pieza.material_override = material(color, textura)
	pieza.position = pos
	padre.add_child(pieza)
	return pieza


func _crear_tabla() -> Node3D:
	var nodo := Node3D.new()
	var tabla := BoxMesh.new()
	tabla.size = Vector3(1.0, 0.08, 0.22)
	for i in 3:
		var pieza := _malla(nodo, tabla, COLORES_TABLA[i], Vector3(randf_range(-0.06, 0.06), 0.0, (i - 1) * 0.25), "madera")
		pieza.rotation.y = randf_range(-0.08, 0.08)
	var travesano := BoxMesh.new()
	travesano.size = Vector3(0.12, 0.06, 0.8)
	for lado in [-1.0, 1.0]:
		_malla(nodo, travesano, Color("5e4028"), Vector3(lado * 0.32, 0.07, 0.0), "madera")

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
	nodo.scale = Vector3.ONE * ESCALA_FLOTANTES
	return nodo


# Mar y tormenta

func _actualizar_agua() -> void:
	var paso := LADO_AGUA / float((agua.mesh as PlaneMesh).subdivide_width + 1)
	agua.position = Vector3(snappedf(foco.x, paso), 0.0, snappedf(foco.z, paso))
	nubes.position = Vector3(agua.position.x, 7.5, agua.position.z)
	for materia in [material_agua, material_nubes]:
		materia.set_shader_parameter("zona_centro", zona_centro * ESCALA)
		materia.set_shader_parameter("zona_radio", zona_radio * ESCALA)
		materia.set_shader_parameter("relampago", relampago)
	material_agua.set_shader_parameter("tiempo", tiempo)
	islas.actualizar_orillas(tiempo, zona_centro, zona_radio)
	material_muro.set_shader_parameter("relampago", relampago)
	muro.visible = not en_puerto()
	muro.position = a_3d(zona_centro, 4.0)
	muro.scale = Vector3(zona_radio * ESCALA, 1.0, zona_radio * ESCALA)
	entorno.fog_density = (NIEBLA_PUERTO if en_puerto() else NIEBLA_MAR) + niebla.espesor * Niebla.ESPESOR_MAXIMO
	entorno.fog_light_color = Paleta.NIEBLA.lerp(Niebla.COLOR_NIEBLA, niebla.espesor)


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
	fuerza_lluvia = lerpf(fuerza_lluvia, intensidad, minf(1.0, delta * 2.0))
	lluvia.emitting = fuerza_lluvia > 0.05 and lluvia.amount > 1
	material_lluvia.albedo_color.a = 0.45 * fuerza_lluvia
	var en_tormenta := fuerza_tormenta(jugador.pos) if activa and jugador != null else 0.0
	sol.light_energy = lerpf(sol.light_energy, lerpf(Paleta.SOL_ENERGIA, Paleta.SOL_TORMENTA, en_tormenta), minf(1.0, delta * 2.0))
	entorno.ambient_light_energy = lerpf(entorno.ambient_light_energy, lerpf(Paleta.AMBIENTE_ENERGIA, Paleta.AMBIENTE_TORMENTA, en_tormenta), minf(1.0, delta * 2.0))

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


# Cámara

func _mover_camara(delta: float) -> void:
	if jugador == null:
		return
	var objetivo := jugador.position
	if en_puerto():
		var vitrina := estado in [Estado.ASTILLERO, Estado.CAPITANES]
		if moba.figura_muelle != null:
			objetivo = objetivo.lerp(moba.figura_muelle.global_position, 0.25)
		pausa_giro -= delta
		if not vitrina:
			angulo_puerto = GIRO_BASE_MENU + sin(tiempo * RITMO_MENU) * ARCO_MENU
			objetivo += MIRA_MENU
		elif pausa_giro <= 0.0:
			angulo_puerto += delta * GIRO_VITRINA
		var lejos := distancia_vitrina if vitrina else DISTANCIA_MENU
		var alto := altura_vitrina if vitrina else ALTURA_MENU
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

func en_puerto() -> bool:
	return estado in [Estado.MENU, Estado.ASTILLERO, Estado.BUSCANDO, Estado.AJUSTES, Estado.NIVELES, Estado.CAPITANES]


# Fuera de la partida solo existe el puerto: una isla con su muelle y el barco amarrado.
func _preparar_puerto(ya_vaciado := false) -> void:
	if not ya_vaciado:
		_vaciar_mar()
	peligros.vaciar()
	tiburones.vaciar()
	barriles.vaciar()
	misiones.vaciar()
	islas.generar_puerto()
	jugador = _crear_barco(personalizacion, true, Vector2.ZERO)
	jugador.nombre = personalizacion.nombre_visible()
	_amarrar()
	islas.muelle.amarrar(jugador)
	foco = jugador.position
	camara.position = jugador.position + Vector3(0.0, 5.0, -11.0)


# Cambiar de casco en la tienda cambia la manga: el barco se recoloca junto al muelle.
func _amarrar() -> void:
	# Los barcos de los capitanes del MOBA miden todos como un bergantín.
	jugador.pos = Muelle.amarre("bergantin" if jugador.has_meta("capitan") else jugador.tipo) / ESCALA
	jugador.rumbo = -PI / 2.0


func _preparar_mar(carga: PantallaCarga) -> void:
	_vaciar_mar()
	# El mar libre conserva el puerto; los demás modos levantan su propio mapa.
	if modo != "libre":
		restos.append_array(islas.soltar_todo())
	await _desmontar(carga, "Preparando el mar...", 0.1, 0.15)
	if modo == "libre":
		await _avanzar_carga(carga, "Levantando las islas...", 0.35)
		libre.empezar()
		foco = jugador.position
		camara.position = jugador.position + Vector3(0.0, 5.0, 11.0)
		return
	if modo == "moba":
		peligros.vaciar()
		tiburones.vaciar()
		barriles.vaciar()
		misiones.vaciar()
		await _avanzar_carga(carga, "Levantando los fuertes...", 0.35)
		moba.empezar()
		foco = jugador.position
		camara.position = jugador.position + Vector3(0.0, 5.0, 11.0)
		return
	await _avanzar_carga(carga, "Levantando las islas...", 0.15)
	await islas.generar(func(parte: float) -> void: carga.paso(tr("Levantando las islas..."), lerpf(0.15, 0.6, parte)))
	peligros.reiniciar()
	await _avanzar_carga(carga, "Llamando a los piratas...", 0.6)

	var alcance := ZONA_INICIAL * 0.9
	jugador = _crear_barco(personalizacion, true, _punto_libre(300.0, alcance))
	jugador.nombre = personalizacion.nombre_visible()
	var nombres := _nombres_bots(TOTAL_BARCOS - 1)
	for i in range(1, TOTAL_BARCOS):
		var bot := _crear_barco(Personalizacion.al_azar(), false, _punto_libre(300.0, alcance))
		bot.nombre = nombres[i - 1]
		bot.botin = randi_range(0, BOTIN_INICIAL_BOTS)
		bot.es_bot = true
		if randf() < BOTS_CON_COFRE:
			tesoros.cargar(bot, "cofre")
		if i % 8 == 0:
			carga.paso(tr("Llamando a los piratas..."), lerpf(0.6, 0.85, float(i) / TOTAL_BARCOS))
			await get_tree().process_frame
	peligros.apartar_krakens()
	await _avanzar_carga(carga, "Soltando tiburones y barriles...", 0.88)
	for _i in TOTAL_TABLAS:
		_soltar_tabla()
	tiburones.reiniciar()
	barriles.reiniciar()
	misiones.reiniciar()

	foco = jugador.position
	camara.position = jugador.position + Vector3(0.0, 5.0, 11.0)



func _danio_bala(bala: Bala) -> float:
	if bala.danio >= 0.0:
		return bala.danio
	var base := comercio.danio(bala.tipo) if bala.tipo != "" else DANIO_BALA
	return base * (bala.dueno.factor_danio if is_instance_valid(bala.dueno) else 1.0)


func _vaciar_mar() -> void:
	libre.vaciar()
	comercio.vaciar()
	persecucion.vaciar()
	emotes.vaciar()
	moba.vaciar()
	niebla.vaciar()
	tesoros.vaciar()
	for barco in barcos:
		_retirar(barco)
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
	fauna.limpiar()

	zona_centro = Vector2.ZERO
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


func _crear_barco(aspecto: Personalizacion, es_jugador: bool, pos: Vector2) -> Barco:
	var barco := Barco.new()
	barco.pos = pos
	barco.rumbo = randf_range(-PI, PI)
	capa_barcos.add_child(barco)
	barco.preparar(aspecto, es_jugador, self)
	if not es_jugador:
		islas.preparar_aparicion(barco, "MeshInstance3D")
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
		var alcance := maxf(120.0, alcance_juego() * 0.75)
		var punto := centro_juego() + Vector2.from_angle(randf() * TAU) * randf() * alcance
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
	if modo == "libre":
		return MarLibre.TABLAS
	if modo == "moba":
		return 0
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


# Cada casco es una cápsula alargada como el modelo (proa y popa a 1.33 radios del centro,
# media manga de medio radio). Al tocarse se apartan y el que empuja contra el otro frena,
# así resbalan uno junto al otro en vez de quedarse pegados.
func _separar_barcos() -> void:
	for i in barcos.size():
		var a: Barco = barcos[i]
		if not a.viva:
			continue
		for j in range(i + 1, barcos.size()):
			var b: Barco = barcos[j]
			if not b.viva or a.pos.distance_to(b.pos) > (a.radio + b.radio) * 1.4:
				continue
			var eje_a := a.proa() * a.radio * MEDIO_EJE_CASCO
			var eje_b := b.proa() * b.radio * MEDIO_EJE_CASCO
			var puntos := _mas_cercanos(a.pos - eje_a, a.pos + eje_a, b.pos - eje_b, b.pos + eje_b)
			var separacion: Vector2 = puntos[1] - puntos[0]
			var dist := separacion.length()
			var minimo := (a.radio + b.radio) * MEDIA_MANGA_CASCO
			if dist >= minimo:
				continue
			var normal := separacion / dist if dist > 0.001 else (b.pos - a.pos).normalized()
			var peso_a := b.radio / (a.radio + b.radio)
			var empuje := normal * (minimo - dist + 1.0)
			a.pos -= empuje * peso_a
			b.pos += empuje * (1.0 - peso_a)
			var acercamiento := a.proa().dot(normal) * a.velocidad - b.proa().dot(normal) * b.velocidad
			var fuerza := acercamiento / maxf(a.vel_max, b.vel_max)
			a.chocar_barco(fuerza, b)
			b.chocar_barco(fuerza, a)
			var choque_a := a.proa().dot(normal)
			if choque_a > 0.0 and a.velocidad > 0.0:
				a.velocidad *= 1.0 - 0.25 * choque_a
			var choque_b := -b.proa().dot(normal)
			if choque_b > 0.0 and b.velocidad > 0.0:
				b.velocidad *= 1.0 - 0.25 * choque_b


# Puntos más cercanos entre los segmentos p1-q1 y p2-q2.
func _mas_cercanos(p1: Vector2, q1: Vector2, p2: Vector2, q2: Vector2) -> Array[Vector2]:
	var d1 := q1 - p1
	var d2 := q2 - p2
	var r := p1 - p2
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var c := d1.dot(r)
	var b := d1.dot(d2)
	var den := a * e - b * b
	var s := clampf((b * f - c * e) / den, 0.0, 1.0) if den > 0.0001 else 0.0
	var t := (b * s + f) / e
	if t < 0.0:
		t = 0.0
		s = clampf(-c / a, 0.0, 1.0)
	elif t > 1.0:
		t = 1.0
		s = clampf((b - c) / a, 0.0, 1.0)
	return [p1 + d1 * s, p2 + d2 * t]


# "proa" dispara un cañón hacia delante; "babor" y "estribor", andanadas de tres por cada costado.
func disparar(barco: Barco, arma: String) -> void:
	if not barco.viva or barco.recargas[arma] > 0.0:
		return
	# En el mar libre las balas del jugador se acaban: se recogen en cajas o se compran.
	var cuantas := 1 if arma == "proa" else 3
	var tipo := ""
	if modo == "libre" and barco == jugador:
		cuantas = comercio.gastar_balas(cuantas)
		if cuantas == 0:
			return
		tipo = comercio.tipo_bala
	barco.recargas[arma] = RECARGAS[arma] * barco.factor_recarga
	if barco.es_jugador:
		avisar_combate()
	var proa := barco.proa()
	var salidas: Array[Vector2] = []
	var direccion := proa
	if arma == "proa":
		salidas.append(barco.pos + proa * barco.radio * 1.15)
	else:
		direccion = proa.orthogonal() * (1.0 if arma == "babor" else -1.0)
		for k: int in [0, -1, 1]:
			salidas.append(barco.pos + direccion * barco.radio * 0.6 + proa * k * barco.radio * 0.4)
	salidas = salidas.slice(0, cuantas)
	for k in salidas.size():
		var bala := Bala.new()
		bala.pos = salidas[k]
		bala.vel = direccion.rotated(randf_range(-0.03, 0.03)) * VEL_BALA + proa * barco.velocidad * 0.6
		bala.vida = VIDA_BALA
		bala.dueno = barco
		bala.tipo = tipo
		bala.equipo = barco.equipo
		bala.nodo = MeshInstance3D.new()
		bala.nodo.mesh = malla_bala
		bala.nodo.material_override = comercio.material_bala(tipo) if tipo != "" else material(Color("1d2024"))
		bala.nodo.position = a_3d(bala.pos, 1.0)
		add_child(bala.nodo)
		balas.append(bala)
		for _i in 2 if salidas.size() > 1 else 4:
			var deriva := Vector3(randf_range(-0.5, 0.5), randf_range(0.3, 0.8), randf_range(-0.5, 0.5))
			crear_efecto(malla_humo, Color(0.93, 0.92, 0.9, 0.75), a_3d(salidas[k], 1.0), deriva, randf_range(0.9, 1.3), 0.6, 1.7, 0.0, true)
	var salida := salidas[salidas.size() / 2]
	if barco.es_jugador:
		_sonar_en_vista(voces_canon, barco.position, -9.0, -9.0, 1.0)
	else:
		_sonar_en_vista(voces_canon, a_3d(salida, 1.0), -12.0, -26.0, 30.0)


# Disparo de un fuerte del mar libre (dueno es quien se lleva el mérito, o null).
func disparar_desde(desde: Vector2, direccion: Vector2, dueno: Barco, origen: Circulo = null, equipo := -1, danio := -1.0) -> Bala:
	var bala := Bala.new()
	bala.origen = origen
	bala.equipo = equipo
	bala.danio = danio
	bala.pos = desde
	bala.vel = direccion.rotated(randf_range(-0.03, 0.03)) * VEL_BALA
	bala.vida = VIDA_BALA
	bala.dueno = dueno
	bala.gracia = VIDA_BALA
	bala.nodo = MeshInstance3D.new()
	bala.nodo.mesh = malla_bala
	bala.nodo.material_override = material(Color("1d2024"))
	bala.nodo.position = a_3d(bala.pos, 1.0)
	add_child(bala.nodo)
	balas.append(bala)
	if origen != null:
		bala.nodo.scale = Vector3.ONE * 1.8
		crear_efecto(malla_humo, Color(1.0, 0.75, 0.3, 0.95), a_3d(desde, 1.4), Vector3.ZERO, 0.18, 0.9, 3.0)
	for _i in 4:
		var deriva := Vector3(randf_range(-0.5, 0.5), randf_range(0.3, 0.8), randf_range(-0.5, 0.5))
		crear_efecto(malla_humo, Color(0.93, 0.92, 0.9, 0.75), a_3d(desde, 1.4), deriva, randf_range(0.9, 1.3), 0.6, 1.7, 0.0, true)
	_sonar_en_vista(voces_canon, a_3d(desde, 1.0), -12.0, -26.0, 30.0)
	return bala


func _mover_balas(delta: float) -> void:
	for i in range(balas.size() - 1, -1, -1):
		var bala: Bala = balas[i]
		bala.pos += bala.vel * delta
		bala.vida -= delta
		bala.gracia -= delta
		var avance := 1.0 - bala.vida / VIDA_BALA
		bala.nodo.position = a_3d(bala.pos, 1.0 + sin(avance * PI) * 1.1)
		if bala.tipo != "":
			comercio.estela(bala.tipo, bala.nodo.position)
		elif bala.origen != null:
			crear_efecto(malla_humo, Color(0.95, 0.93, 0.88, 0.7), bala.nodo.position, Vector3(0, 0.2, 0), 0.5, 0.35, 0.8)

		var termina := false
		var golpeado: Barco = null
		for isla in islas.cerca(bala.pos):
			if isla != bala.origen and isla.dentro(bala.pos):
				termina = true
				if modo == "libre" and is_instance_valid(bala.dueno):
					libre.golpear_isla(isla, bala.dueno, _danio_bala(bala) * (1.5 if bala.tipo == "explosiva" else 1.0))
				elif modo == "moba":
					moba.golpear_isla(isla, bala)
				astillas(a_3d(bala.pos, 0.6))
				break
		if not termina and modo == "moba" and moba.recibir_bala(bala):
			termina = true
		if not termina and peligros.recibir_bala(bala.pos, bala.dueno):
			termina = true
		if not termina and tiburones.recibir_bala(bala.pos, bala.dueno):
			termina = true
		if not termina and barriles.recibir_bala(bala.pos, bala.dueno):
			termina = true
		if not termina:
			for barco in barcos:
				if not barco.viva:
					continue
				if barco == bala.dueno and bala.gracia > 0.0:
					continue
				if bala.equipo >= 0 and barco.equipo == bala.equipo:
					continue
				if barco.pos.distance_to(bala.pos) < barco.radio * 0.85:
					barco.recibir_danio(_danio_bala(bala), true, bala.dueno)
					golpeado = barco
					termina = true
					if barco.es_jugador:
						golpe = 0.22
						avisar_combate()
					break
		if not termina and bala.vida <= 0.0:
			termina = true
			salpicar(bala.pos, 7)
		if termina:
			if modo == "moba":
				moba.impacto(bala, golpeado)
			elif bala.tipo != "":
				comercio.impacto(bala.tipo, bala.pos, golpeado, bala.dueno)
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


func avisar_premio(punto: Vector3, texto: String, color: Color) -> void:
	var aviso := AvisoBotin.new()
	aviso.punto = punto
	aviso.texto = texto
	aviso.color = color
	avisos_botin.append(aviso)
	voz_moneda.pitch_scale = 1.4
	voz_moneda.play()


func _pintar_botin() -> void:
	texto_botin.text = tr("Botín a bordo: %d") % jugador.botin
	if modo == "libre":
		texto_botin.text += "   " + tr("Bodega: %d/%d") % [comercio.bodega.size(), comercio.capacidad()]


func soltar_cofre(punto: Vector2, monedas: int) -> void:
	var cofre := Cofre.new()
	cofre.pos = punto
	cofre.vel = Vector2.from_angle(randf() * TAU) * 25.0
	cofre.monedas = monedas
	cofre.fase = randf() * TAU
	cofre.nodo = _crear_cofre(monedas)
	add_child(cofre.nodo)
	cofres.append(cofre)


func soltar_tesoro(punto: Vector2, tipo: String) -> void:
	var cofre := Cofre.new()
	cofre.pos = punto
	cofre.vel = Vector2.from_angle(randf() * TAU) * 20.0
	cofre.tesoro = tipo
	cofre.fase = randf() * TAU
	cofre.nodo = tesoros.modelo(tipo)
	cofre.nodo.scale = Vector3.ONE * 1.4
	var aro := TorusMesh.new()
	aro.inner_radius = 0.5
	aro.outer_radius = 0.6
	aro.rings = 32
	aro.ring_segments = 4
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	brillo.albedo_color = Color(Tesoros.COLOR_MALDICION if tipo == "calavera" else COLOR_ORO, 0.85)
	var anillo := MeshInstance3D.new()
	anillo.mesh = aro
	anillo.material_override = brillo
	anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anillo.name = "Aro"
	cofre.nodo.add_child(anillo)
	add_child(cofre.nodo)
	cofres.append(cofre)


func _crear_cofre(monedas: int) -> Node3D:
	var nodo := Node3D.new()
	var escala := 1.0 + minf(monedas, 10) * 0.06
	var caja := BoxMesh.new()
	caja.size = Vector3(0.7, 0.42, 0.48) * escala
	_malla(nodo, caja, Color("6b4126"), Vector3(0, 0.21 * escala, 0), "madera")
	var tapa := CylinderMesh.new()
	tapa.top_radius = 0.24 * escala
	tapa.bottom_radius = 0.24 * escala
	tapa.height = 0.7 * escala
	tapa.radial_segments = 10
	var pieza_tapa := _malla(nodo, tapa, Color("7d4c2c"), Vector3(0, 0.42 * escala, 0), "madera")
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
	nodo.scale = Vector3.ONE * ESCALA_FLOTANTES
	return nodo


func _actualizar_cofres(delta: float) -> void:
	for i in range(cofres.size() - 1, -1, -1):
		var cofre: Cofre = cofres[i]
		var vida := VIDA_COFRE if cofre.tesoro == "" else Tesoros.VIDA_FLOTANDO
		if estado == Estado.JUGANDO:
			cofre.edad += delta
			if cofre.edad >= vida:
				cofre.nodo.queue_free()
				cofres.remove_at(i)
				continue
		cofre.pos += (peligros.arrastre(cofre.pos) + peligros.viento(cofre.pos) * 0.5 + cofre.vel) * delta
		cofre.vel *= maxf(0.0, 1.0 - delta * 1.5)
		var sitio := a_3d(cofre.pos)
		var hundido := clampf((cofre.edad - vida + 3.0) / 3.0, 0.0, 1.0)
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
				if cofre.tesoro != "":
					tesoros.cargar(barco, cofre.tesoro)
					if barco == jugador:
						avisar_premio(cofre.nodo.position + Vector3(0, 1.5, 0), tr(Tesoros.TIPOS[cofre.tesoro]["nombre"]), COLOR_ORO)
				else:
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
	else:
		verdugo = null
	emotes.al_hundirse(barco, verdugo)
	if modo == "libre":
		libre.al_hundirse(barco, verdugo)
	elif modo == "moba":
		moba.al_hundirse(barco, verdugo)
	tesoros.soltar_todos(barco)
	if modo == "libre":
		comercio.al_hundirse(barco)
	# En el mar libre se pierde todo lo que va a bordo: queda flotando en un cofre. En el
	# MOBA los barcos reaparecen y no sueltan nada.
	var cae := barco.botin if modo == "libre" else (0 if modo == "moba" else ceili(barco.botin / 2.0))
	if cae > 0:
		barco.botin -= cae
		if barco == jugador:
			botin_perdido = cae
		soltar_cofre(barco.pos, cae)
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
		crear_efecto(malla_humo, Color(0.35, 0.33, 0.32, 0.7), barco.position + Vector3(0, 1.2, 0), deriva, randf_range(1.5, 2.2), 0.8, 2.2, 0.0, true)


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
			if modo == "moba":
				if resultado == "victoria":
					titulo_final.text = "[salto]%s[/salto]" % tr("Victoria")
					texto_final.text = tr("Tu armada derribó el nexo enemigo.")
				else:
					titulo_final.text = tr("Derrota")
					texto_final.text = tr("La armada rival derribó tu nexo.")
			elif resultado == "victoria":
				titulo_final.text = "[salto]%s[/salto]" % tr("Victoria")
				texto_final.text = tr("Tu barco quedó solo en el mar.")
			else:
				titulo_final.text = tr("Hundido")
				texto_final.text = tr("La marea se quedó con tu barco. Terminaste en el puesto %d de %d.") % [puesto, TOTAL_BARCOS]
			_repartir_premio()
			_mostrar(Estado.FIN)
		return

	if modo == "moba":
		if moba.ganador >= 0:
			resultado = "victoria" if moba.ganador == 0 else "hundido"
			puesto = 1 if moba.ganador == 0 else 25
			cierre = 2.5
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
	var a_bordo := tesoros.valor(jugador) if jugador.viva else 0
	tesoros.quitar(jugador)
	var por_victoria := MONEDAS_VICTORIA if resultado == "victoria" else 0
	var ganada := personalizacion.experiencia_por(puesto, hundidos, resultado == "retirada")
	var antes := personalizacion.monedas
	personalizacion.monedas += botin + a_bordo + por_victoria
	var rango := personalizacion.sumar_experiencia(ganada)
	var desglose: Array = [[tr("Botín a bordo"), botin]]
	if a_bordo > 0:
		desglose.append([tr("Tesoros a bordo"), a_bordo])
	if tesoros.vendidos > 0:
		desglose.append([tr("Tesoros vendidos: +%d") % tesoros.vendidos, 0, COLOR_ORO])
	if botin_perdido > 0:
		desglose.append([tr("Botín perdido: -%d") % botin_perdido, 0, COLOR_PELIGRO])
	if por_victoria > 0:
		desglose.append([tr("Victoria"), por_victoria])
	if misiones.completadas > 0:
		desglose.append([tr("Misiones cumplidas: %d") % misiones.completadas, 0, COLOR_ORO])
	if misiones.gemas > 0:
		desglose.append([tr("Gemas encontradas: %d") % misiones.gemas, 0, Misiones.COLOR_GEMA])
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
	titulo_final.add_theme_color_override("default_color", COLOR_ORO if resultado == "victoria" else COLOR_TEXTO)
	salto_titulo.reiniciar()
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
		var linea := Ui.etiqueta_panel(parte[0] if informativa else "%s   +%d" % [parte[0], cantidad], 24, parte[2] if informativa else COLOR_ORO)
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


# Efectos

func crear_efecto(forma: Mesh, color: Color, pos: Vector3, vel: Vector3, vida: float, escala: float, crece: float, gravedad := 0.0, sombreado := false) -> void:
	if pos.distance_to(foco) > _alcance_efectos():
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
	crear_efecto(malla_espuma, Color(1, 1, 1, 0.45 * fuerza), a_3d(pos, 0.17), Vector3.ZERO, 1.2, 0.7, 1.6)


func ola_proa(pos: Vector2, rumbo: float, fuerza: float) -> void:
	var adelante := Vector2.UP.rotated(rumbo)
	var lado := Vector2(-adelante.y, adelante.x)
	for s in [-1.0, 1.0]:
		var empuje: Vector2 = lado * s * 1.5 * fuerza
		crear_efecto(malla_espuma, Color(1, 1, 1, 0.5 * fuerza), a_3d(pos + lado * s * 6.0, 0.18), Vector3(empuje.x, 0.0, empuje.y), 0.9, 0.35, 1.3)


# La proa cae sobre el agua: abanico de gotas hacia delante y a los lados.
func rociar_proa(pos: Vector2, rumbo: float, fuerza: float) -> void:
	var centro := a_3d(pos, 0.25)
	var adelante := Vector2.UP.rotated(rumbo)
	var lado := Vector2(-adelante.y, adelante.x)
	for _i in int(5 + 8 * fuerza):
		var plano := adelante * randf_range(0.4, 1.4) + lado * randf_range(-1.8, 1.8)
		var vel := Vector3(plano.x, randf_range(2.2, 3.6) * (0.6 + 0.6 * fuerza), plano.y)
		crear_efecto(malla_gota, Color(0.95, 0.98, 1.0, 0.85), centro, vel, 0.8, 0.75, 0.0, 12.0)
	crear_efecto(malla_espuma, Color(1, 1, 1, 0.6), a_3d(pos, 0.17), Vector3.ZERO, 0.8, 0.6, 2.2)


func salpicar(pos: Vector2, cantidad: int) -> void:
	var centro := a_3d(pos, 0.2)
	for _i in cantidad:
		var vel := Vector3(randf_range(-1.5, 1.5), randf_range(3.0, 5.5), randf_range(-1.5, 1.5))
		crear_efecto(malla_gota, Color(0.95, 0.98, 1.0, 0.9), centro, vel, 1.0, 1.0, 0.0, 12.0)
	crear_efecto(malla_espuma, Color(1, 1, 1, 0.7), a_3d(pos, 0.17), Vector3.ZERO, 0.9, 0.8, 2.6)


func astillas(centro: Vector3) -> void:
	for _i in 8:
		var vel := Vector3(randf_range(-2.0, 2.0), randf_range(2.0, 4.5), randf_range(-2.0, 2.0))
		crear_efecto(malla_astilla, Color("7a5230"), centro, vel, 1.2, 1.0, 0.0, 10.0, true)
	crear_efecto(malla_humo, Color(0.9, 0.88, 0.85, 0.6), centro, Vector3(0, 0.6, 0), 0.8, 0.5, 1.2, 0.0, true)


func _brillo_reparacion(centro: Vector3) -> void:
	for _i in 10:
		var vel := Vector3(randf_range(-0.8, 0.8), randf_range(1.5, 3.0), randf_range(-0.8, 0.8))
		crear_efecto(malla_gota, Color(1.0, 0.86, 0.4, 0.95), centro, vel, 0.9, 1.4, 0.0, 1.5)


# Controles

func direccion_jugador() -> Vector2:
	if panel_partida.visible or comercio.panel.visible:
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
	if panel_partida.visible or comercio.panel.visible:
		return armas
	for arma in BOTONES_FUEGO:
		if _arma_pulsada(arma):
			armas.append(arma)
	return armas


func _arma_pulsada(arma: String) -> bool:
	var tecla: Key = {"proa": KEY_SPACE, "babor": KEY_Q, "estribor": KEY_E}[arma]
	return arma in dedos_fuego.values() or Input.is_key_pressed(tecla)


# En la tienda y al elegir capitán: un dedo gira la cámara alrededor del barco, dos dedos o la rueda acercan.
func _unhandled_input(event: InputEvent) -> void:
	if not listo or estado not in [Estado.ASTILLERO, Estado.CAPITANES]:
		return
	var panel := panel_astillero if estado == Estado.ASTILLERO else moba.panel_capitanes
	var toque := event as InputEventScreenTouch
	if toque:
		if not toque.pressed:
			dedos_vitrina.erase(toque.index)
		elif not panel.get_global_rect().has_point(toque.position):
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
	if not listo or cargando:
		return
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
		if comercio.panel.visible:
			comercio.cerrar()
		elif moba.panel_tienda.visible:
			moba.cerrar_tienda()
		elif panel_partida.visible:
			_cerrar_opciones_partida()
		else:
			_abrir_opciones_partida()
		return
	if panel_partida.visible or comercio.panel.visible or moba.panel_tienda.visible:
		return
	if modo == "libre" and comercio.tecla(event):
		get_viewport().set_input_as_handled()
		return
	if modo == "moba" and (moba.tecla(event) or moba.toque_habilidad(event)):
		get_viewport().set_input_as_handled()
		return

	var toque := event as InputEventScreenTouch
	if toque:
		if toque.pressed:
			if toque.position.y < ALTO_HUD * maxf(1.0, escala_controles):
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
		var alcance := RADIO_PALANCA * escala_controles
		palanca = (arrastre.position - centro_palanca).limit_length(alcance) / alcance


func _posicion_palanca_reposo() -> Vector2:
	return Vector2(125.0 * escala_controles, controles.size.y - 120.0 * escala_controles)


func _posicion_fuego(arma: String) -> Vector2:
	return controles.size + BOTONES_FUEGO[arma][0] * escala_controles


# Tamaño de los controles táctiles de la partida. En el móvil se agrandan hasta que el aro
# de la palanca mida unos 10 mm en la pantalla real; encima va el ajuste del jugador.
var escala_controles := 1.0


func _escala_automatica() -> float:
	if not OS.has_feature("mobile"):
		return 1.0
	var dpi := float(DisplayServer.screen_get_dpi())
	var alto_vista := get_viewport().get_visible_rect().size.y
	if dpi <= 0.0 or alto_vista <= 0.0:
		return 1.3
	var pixeles_por_punto := float(DisplayServer.window_get_size().y) / alto_vista
	var milimetros := (RADIO_PALANCA + 12.0) * pixeles_por_punto / dpi * 25.4
	return clampf(10.0 / milimetros, 1.0, 1.5)


func aplicar_tamano_controles() -> void:
	escala_controles = clampf(_escala_automatica() * personalizacion.tam_botones, 0.7, 2.0)
	for control: Control in get_tree().get_nodes_in_group("control_tactil"):
		Ui.escalar_desde_ancla(control, escala_controles)
	if controles != null:
		controles.queue_redraw()


# El botón más cercano al dedo, con algo de margen alrededor de cada círculo.
func _boton_fuego_en(punto: Vector2) -> String:
	var elegido := ""
	var mejor := INF
	for arma in BOTONES_FUEGO:
		var distancia := punto.distance_to(_posicion_fuego(arma))
		if distancia < BOTONES_FUEGO[arma][1] * escala_controles * 1.35 and distancia < mejor:
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

	texto_vivos = Ui.etiqueta("A flote: 12", 18)
	hud.add_child(texto_vivos)
	texto_tormenta = Ui.etiqueta("Tormenta: 2:56", 18)
	hud.add_child(texto_tormenta)
	texto_botin = Ui.etiqueta("Botín a bordo: 0", 18)
	texto_botin.add_theme_color_override("font_color", COLOR_ORO)
	hud.add_child(texto_botin)
	texto_mision = Ui.etiqueta("", 18)
	texto_mision.add_theme_color_override("font_color", Color("ffe7a8"))
	hud.add_child(texto_mision)
	marcador_moba = HBoxContainer.new()
	marcador_moba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marcador_moba.add_theme_constant_override("separation", 6)
	hud.add_child(marcador_moba)
	cifra_hundidos = _cifra_con_icono("res://interfaz/hundidos.svg", COLOR_ORO)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(14, 0)
	marcador_moba.add_child(hueco)
	cifra_veces_hundido = _cifra_con_icono("res://interfaz/veces_hundido.svg", COLOR_TEXTO)

	minimapa = Control.new()
	minimapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.anclar(minimapa, Vector2(1, 0), Vector2(-212, 16), Vector2(196, 196))
	minimapa.draw.connect(_dibujar_minimapa)
	capa.add_child(minimapa)

	_crear_menu(capa)
	_crear_ajustes(capa)
	_crear_niveles(capa)
	_crear_astillero(capa)
	_crear_busqueda(capa)
	_crear_final(capa)
	_crear_opciones_partida(capa)
	libre.crear_interfaz(capa)
	comercio.crear_interfaz(capa)
	misiones.crear_interfaz(capa)
	emotes.crear_interfaz(capa)
	moba.crear_interfaz(capa)


func _cifra_con_icono(ruta: String, color: Color) -> Label:
	var icono := TextureRect.new()
	icono.texture = load(ruta)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.custom_minimum_size = Vector2(38, 38)
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marcador_moba.add_child(icono)
	var cifra := Ui.etiqueta("0", 26)
	cifra.add_theme_color_override("font_color", color)
	cifra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marcador_moba.add_child(cifra)
	return cifra


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


# Menú del puerto

func _crear_menu(capa: CanvasLayer) -> void:
	var partes := Ui.panel_lateral(capa)
	panel_menu = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_child(_crear_logo())
	var lema := Ui.etiqueta_panel("El mar no perdona.\n¿Serás el último a flote?", 30, COLOR_TEXTO)
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
	tesoro.add_child(Ui.icono_moneda(34))
	texto_monedas_menu = Ui.etiqueta_panel("", 28, COLOR_ORO)
	texto_monedas_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tesoro.add_child(texto_monedas_menu)
	tesoro.add_child(Ui.icono_gema(32))
	texto_gemas_menu = Ui.etiqueta_panel("", 28, Misiones.COLOR_GEMA)
	texto_gemas_menu.autowrap_mode = TextServer.AUTOWRAP_OFF
	tesoro.add_child(texto_gemas_menu)
	cuerpo.add_child(tesoro)
	var tienda := Ui.boton("Tienda", false)
	tienda.pressed.connect(_mostrar.bind(Estado.ASTILLERO))
	cuerpo.add_child(tienda)
	var modos := HBoxContainer.new()
	modos.add_theme_constant_override("separation", 10)
	cuerpo.add_child(modos)
	for nombre in ["tormenta", "libre", "moba"]:
		var boton_modo := Ui.boton({"tormenta": "Tormenta", "libre": "Libre", "moba": "MOBA 5v5"}[nombre], true)
		boton_modo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton_modo.add_theme_font_size_override("font_size", 24)
		if nombre == "moba":
			boton_modo.pressed.connect(func() -> void: moba.abrir_seleccion())
		else:
			boton_modo.pressed.connect(_buscar_partida.bind(nombre))
		modos.add_child(boton_modo)

	boton_ajustes = _boton_engranaje()
	Ui.anclar(boton_ajustes, Vector2(0, 0), Vector2(28, 28), Vector2(80, 80))
	boton_ajustes.pressed.connect(_mostrar.bind(Estado.AJUSTES))
	capa.add_child(boton_ajustes)

	boton_idioma = BotonIdioma.new()
	boton_idioma.idioma = personalizacion.idioma
	boton_idioma.tooltip_text = "Idioma"
	Ui.anclar(boton_idioma, Vector2(0, 0), Vector2(124, 36), Vector2(92, 64))
	boton_idioma.pressed.connect(_cambiar_idioma)
	capa.add_child(boton_idioma)


func _cambiar_idioma() -> void:
	var lista := Idioma.IDIOMAS
	personalizacion.idioma = lista[(lista.find(personalizacion.idioma) + 1) % lista.size()]
	personalizacion.guardar()
	Idioma.usar(personalizacion.idioma)
	boton_idioma.idioma = personalizacion.idioma
	boton_idioma.queue_redraw()
	aplicar_graficos()
	voz_equipar.play()
	_mostrar(estado)


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
	Ui.anclar(boton_partida, Vector2(1, 0), Vector2(-212 - 14 - 72, 28), Vector2(72, 72))
	boton_partida.pressed.connect(_abrir_opciones_partida)
	capa.add_child(boton_partida)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)
	panel_partida = centro
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.estilo_panel())
	panel.custom_minimum_size = Vector2(520, 0)
	centro.add_child(panel)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 14)
	panel.add_child(cuerpo)
	cuerpo.add_child(Ui.etiqueta_panel("Opciones", 40, COLOR_TEXTO))
	var opciones := _lista_desplazable(cuerpo)
	opciones.get_parent().get_parent().custom_minimum_size = Vector2(0, 380)
	_deslizador_volumen(opciones, "Música", personalizacion.volumen_musica, func(valor: float) -> void:
		personalizacion.volumen_musica = valor)
	_deslizador_volumen(opciones, "Efectos", personalizacion.volumen_efectos, func(valor: float) -> void:
		personalizacion.volumen_efectos = valor)
	_deslizador_botones(opciones)
	_selector_graficos(opciones)
	var seguir := Ui.boton("Seguir jugando", true)
	seguir.pressed.connect(_cerrar_opciones_partida)
	cuerpo.add_child(seguir)
	boton_salir = Ui.boton("Salir de la partida", false)
	boton_salir.pressed.connect(_salir_de_partida)
	cuerpo.add_child(boton_salir)


func _abrir_opciones_partida() -> void:
	if estado != Estado.JUGANDO or cierre > 0.0:
		return
	panel_partida.visible = true
	boton_salir.text = "Volver al puerto" if modo == "libre" else "Salir de la partida"
	controles.visible = false
	palanca_dedo = -1
	dedos_fuego.clear()
	palanca = Vector2.ZERO


func _cerrar_opciones_partida() -> void:
	panel_partida.visible = false
	controles.visible = estado == Estado.JUGANDO
	personalizacion.guardar()


func _salir_de_partida() -> void:
	if modo == "moba" and moba.ensayo:
		moba.terminar_ensayo()
		return
	# El mar libre sigue ahí: se guardan el barco, el botín a bordo y la base.
	if modo == "libre":
		libre.salir()
		_al_puerto()
		return
	if boton_salir.text == "Salir de la partida":
		boton_salir.text = "Pierdes todo el botín. Toca otra vez"
		return
	personalizacion.guardar()
	resultado = "retirada"
	if modo == "moba":
		puesto = 25
		titulo_final.text = tr("Retirada")
		texto_final.text = tr("Abandonaste a tu armada antes de que cayera un nexo.")
		_repartir_premio()
		_mostrar(Estado.FIN)
		return
	puesto = _contar_vivos()
	if jugador.viva:
		botin_perdido = jugador.botin + tesoros.valor(jugador)
		jugador.botin = 0
		tesoros.quitar(jugador)
		_pintar_botin()
	titulo_final.text = tr("Retirada")
	texto_final.text = tr("Abandonaste la partida en el puesto %d de %d.") % [puesto, TOTAL_BARCOS]
	_repartir_premio()
	_mostrar(Estado.FIN)


func _crear_ajustes(capa: CanvasLayer) -> void:
	var partes := Ui.panel_lateral(capa)
	panel_ajustes = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	var titulo := Ui.etiqueta_panel("Configuración", 40, COLOR_TEXTO)
	cuerpo.add_child(titulo)
	var lista_cuerpo := cuerpo
	cuerpo = _lista_desplazable(lista_cuerpo)
	cuerpo.get_parent().get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL

	cuerpo.add_child(Ui.etiqueta_panel("Nombre del barco", 22, COLOR_ORO))
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
	_deslizador_botones(cuerpo)
	_selector_graficos(cuerpo)

	var listo := Ui.boton("Listo", true)
	listo.pressed.connect(_cerrar_ajustes)
	lista_cuerpo.add_child(listo)


# Columna con desplazamiento vertical (se arrastra con el dedo) dentro de otra columna.
func _lista_desplazable(cuerpo: VBoxContainer) -> VBoxContainer:
	var desplazar := ScrollContainer.new()
	desplazar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desplazar.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	desplazar.follow_focus = true
	desplazar.scroll_deadzone = 12
	cuerpo.add_child(desplazar)
	var riel := StyleBoxFlat.new()
	riel.bg_color = Color(0, 0, 0, 0.35)
	riel.set_corner_radius_all(9)
	riel.content_margin_left = 9
	riel.content_margin_right = 9
	var tirador := StyleBoxFlat.new()
	tirador.bg_color = COLOR_ORO
	tirador.set_corner_radius_all(9)
	tirador.content_margin_top = 30
	var tirador_activo := tirador.duplicate() as StyleBoxFlat
	tirador_activo.bg_color = COLOR_ORO.lightened(0.25)
	var barra := desplazar.get_v_scroll_bar()
	barra.add_theme_stylebox_override("scroll", riel)
	barra.add_theme_stylebox_override("scroll_focus", riel)
	barra.add_theme_stylebox_override("grabber", tirador)
	barra.add_theme_stylebox_override("grabber_highlight", tirador_activo)
	barra.add_theme_stylebox_override("grabber_pressed", tirador_activo)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_right", 16)
	desplazar.add_child(margen)
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 14)
	margen.add_child(lista)
	return lista


# Del 70 % al 150 % del tamaño automático de los botones de la partida.
func _deslizador_botones(cuerpo: VBoxContainer) -> void:
	var deslizador := _deslizador_volumen(cuerpo, "Tamaño de botones", personalizacion.tam_botones, func(valor: float) -> void:
		personalizacion.tam_botones = valor
		aplicar_tamano_controles())
	deslizador.max_value = 150.0
	deslizador.min_value = 70.0
	deslizador.value = personalizacion.tam_botones * 100.0


func _deslizador_volumen(cuerpo: VBoxContainer, titulo: String, valor: float, guardar: Callable) -> HSlider:
	var fila := HBoxContainer.new()
	var nombre := Ui.etiqueta_panel(titulo, 22, COLOR_ORO)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var porcentaje := Ui.etiqueta_panel("%d%%" % roundi(valor * 100.0), 22, COLOR_TEXTO)
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
	var tirador := Ui.textura_circulo(40, COLOR_TEXTO)
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
	texto_nivel_menu = Ui.etiqueta_panel("", 24, COLOR_ORO)
	textos.add_child(texto_nivel_menu)
	barra_nivel_menu = Ui.barra_progreso()
	textos.add_child(barra_nivel_menu)
	texto_xp_menu = Ui.etiqueta_panel("", 17, COLOR_TEXTO)
	textos.add_child(texto_xp_menu)
	var flecha := Ui.etiqueta_panel("›", 44, Color(COLOR_TEXTO, 0.7))
	flecha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(flecha)
	return boton


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
	var partes := Ui.panel_lateral(capa)
	panel_niveles = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_child(Ui.etiqueta_panel("Niveles", 40, COLOR_TEXTO))
	cuerpo.add_child(Ui.etiqueta_panel(
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
	var listo := Ui.boton("Listo", true)
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
		textos.add_child(Ui.etiqueta_panel(tr("Nivel %d · %s") % [nivel + 1, tr(datos[0])], 24, COLOR_ORO if nivel == actual else COLOR_TEXTO))
		var detalle := tr("Desde %d XP") % datos[1]
		if datos[2] > 0:
			detalle += "  ·  " + tr("Premio: +%d monedas") % datos[2]
		textos.add_child(Ui.etiqueta_panel(detalle, 16, Color(COLOR_TEXTO, 0.75)))
		if nivel < actual:
			textos.add_child(Ui.etiqueta_panel(tr("Superado"), 16, Color("7dffb2")))
		elif nivel == actual:
			var barra := Ui.barra_progreso()
			barra.set_meta("avance", _avance_nivel(nivel))
			textos.add_child(barra)
			textos.add_child(Ui.etiqueta_panel(tr("Estás aquí") + " · " + _texto_progreso(nivel), 16, COLOR_TEXTO))
			if personalizacion.proteccion > 0 and nivel > 0:
				textos.add_child(Ui.etiqueta_panel(tr("Protegido de bajar: %d partidas") % personalizacion.proteccion, 16, Color("7dffb2")))
			fila_actual = caja
		else:
			escudo.modulate = Color(0.45, 0.45, 0.5)
			caja.modulate.a = 0.75
			textos.add_child(Ui.etiqueta_panel(tr("Te faltan %d XP") % (int(datos[1]) - personalizacion.experiencia), 16, Color(COLOR_TEXTO, 0.6)))
	if fila_actual != null:
		get_tree().create_timer(0.05).timeout.connect(func() -> void: desliz_niveles.ensure_control_visible(fila_actual))


func _cambiar_nombre(texto: String) -> void:
	personalizacion.cambiar_nombre(texto)
	if jugador != null:
		jugador.nombre = personalizacion.nombre_visible()


# Búsqueda de partida

func _crear_busqueda(capa: CanvasLayer) -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)
	panel_busqueda = centro
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.estilo_panel())
	panel.custom_minimum_size = Vector2(520, 0)
	centro.add_child(panel)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 16)
	panel.add_child(cuerpo)
	titulo_busqueda = Ui.etiqueta_panel("TODOS CONTRA TODOS", 20, COLOR_ORO)
	cuerpo.add_child(titulo_busqueda)
	texto_busqueda = Ui.etiqueta_panel("Buscando partida", 40, COLOR_TEXTO)
	cuerpo.add_child(texto_busqueda)
	texto_jugadores = Ui.etiqueta_panel("", 24, COLOR_TEXTO)
	cuerpo.add_child(texto_jugadores)
	var cancelar := Ui.boton("Cancelar", false)
	cancelar.pressed.connect(_mostrar.bind(Estado.MENU))
	cuerpo.add_child(cancelar)


func _buscar_partida(nuevo_modo := "tormenta") -> void:
	modo = nuevo_modo
	titulo_busqueda.text = "MAR LIBRE" if modo == "libre" else ("5 CONTRA 5" if modo == "moba" else "TODOS CONTRA TODOS")
	campo_nombre.release_focus()
	tiempo_busqueda = 0.0
	_mostrar(Estado.BUSCANDO)
	_avanzar_busqueda(0.0)


func _avanzar_busqueda(delta: float) -> void:
	tiempo_busqueda += delta
	var puntos := ".".repeat(1 + int(tiempo_busqueda * 2.0) % 3)
	if modo == "libre":
		if tiempo_busqueda < 1.2:
			texto_busqueda.text = tr("Entrando al mar libre") + puntos
			texto_jugadores.text = tr("Un mar enorme y abierto, para hasta 1000 capitanes")
		elif tiempo_busqueda < 2.6:
			texto_busqueda.text = tr("Zarpando") + puntos
			texto_jugadores.text = tr("Aún no hay servidor en línea: compartes el mar con bots y piratas.")
		else:
			_zarpar()
		return
	if modo == "moba":
		if tiempo_busqueda < 1.4:
			texto_busqueda.text = tr("Formando las armadas") + puntos
			texto_jugadores.text = tr("Tu armada azul contra la armada roja: cinco barcos por bando")
		elif tiempo_busqueda < 3.0:
			texto_busqueda.text = tr("Completando con bots") + puntos
			texto_jugadores.text = tr("Derriba los fuertes de cada carril y luego el nexo enemigo para ganar.")
		else:
			_zarpar()
		return
	if tiempo_busqueda < ESPERA_BUSQUEDA:
		texto_busqueda.text = tr("Buscando partida") + puntos
		texto_jugadores.text = tr("Capitanes en el puerto: 1/%d\nEsperando %ds") % [TOTAL_BARCOS, int(tiempo_busqueda)]
	elif tiempo_busqueda < ESPERA_BUSQUEDA + ESPERA_BOTS:
		texto_busqueda.text = tr("Completando con bots") + puntos
		texto_jugadores.text = tr("No hay más capitanes conectados.\nSe unen %d bots a la marea.") % (TOTAL_BARCOS - 1)
	else:
		_zarpar()


# Tienda

func _crear_astillero(capa: CanvasLayer) -> void:
	aviso_giro = Ui.etiqueta_panel("Arrastra para girar el barco", 22, Color(COLOR_TEXTO, 0.75))
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
	var partes := Ui.panel_lateral(capa)
	panel_astillero = partes[0]
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_theme_constant_override("separation", 10)

	var cabecera := HBoxContainer.new()
	var titulo := Ui.etiqueta_panel("Tienda", 40, COLOR_TEXTO)
	titulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)
	cabecera.add_theme_constant_override("separation", 10)
	cabecera.add_child(Ui.icono_moneda(28))
	texto_monedas_tienda = Ui.etiqueta_panel("", 26, COLOR_ORO)
	texto_monedas_tienda.autowrap_mode = TextServer.AUTOWRAP_OFF
	cabecera.add_child(texto_monedas_tienda)
	cabecera.add_child(Ui.icono_gema(26))
	texto_gemas_tienda = Ui.etiqueta_panel("", 26, Misiones.COLOR_GEMA)
	texto_gemas_tienda.autowrap_mode = TextServer.AUTOWRAP_OFF
	cabecera.add_child(texto_gemas_tienda)
	cuerpo.add_child(cabecera)

	var pestanas := GridContainer.new()
	pestanas.columns = 5
	pestanas.add_theme_constant_override("h_separation", 8)
	pestanas.add_theme_constant_override("v_separation", 8)
	for cat in Catalogo.CATEGORIAS + [TESOROS]:
		var boton := Ui.boton(Catalogo.TITULOS.get(cat, "Tesoros"), false)
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

	texto_pieza = Ui.etiqueta_panel("", 15, Color(COLOR_TEXTO, 0.85))
	cuerpo.add_child(texto_pieza)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	cuerpo.add_child(fila)
	var volver := Ui.boton("Menú principal", false)
	Ui.estilo_volver(volver)
	volver.custom_minimum_size = Vector2(0, 54)
	volver.add_theme_font_size_override("font_size", 22)
	volver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volver.pressed.connect(_cerrar_tienda)
	fila.add_child(volver)
	boton_accion = Ui.boton("Comprar", true)
	boton_accion.custom_minimum_size = Vector2(0, 54)
	boton_accion.add_theme_font_size_override("font_size", 22)
	boton_accion.add_theme_constant_override("icon_max_width", 24)
	boton_accion.add_theme_constant_override("h_separation", 10)
	boton_accion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton_accion.size_flags_stretch_ratio = 1.6
	boton_accion.pressed.connect(_usar_pieza)
	fila.add_child(boton_accion)


func _abrir_categoria(nueva: String) -> void:
	categoria = nueva
	if categoria == TESOROS:
		seleccion = Catalogo.unicas()[0]["id"]
	else:
		seleccion = personalizacion.elegidos[categoria]
	jugador.vestir(personalizacion)
	_llenar_rejilla()
	if categoria == TESOROS:
		_elegir_pieza(seleccion)
	else:
		_refrescar_astillero()


func _piezas_tienda() -> Array:
	return Catalogo.unicas() if categoria == TESOROS else Catalogo.lista(categoria)


# En la pestaña de tesoros cada pieza pertenece a su propia categoría.
func _categoria_de(pieza: Dictionary) -> String:
	return pieza.get("categoria", categoria) if categoria == TESOROS else categoria


func _pieza_tienda(id: String) -> Dictionary:
	if categoria == TESOROS:
		for pieza in Catalogo.unicas():
			if pieza["id"] == id:
				return pieza
	return Catalogo.buscar(categoria, id)


func _llenar_rejilla() -> void:
	for hijo in rejilla_piezas.get_children():
		hijo.queue_free()
	botones_pieza.clear()
	miniaturas.cancelar()
	for pieza in _piezas_tienda():
		var boton := _boton_pieza(pieza)
		rejilla_piezas.add_child(boton)
		botones_pieza[pieza["id"]] = boton
	desplazable.scroll_vertical = 0


func _elegir_pieza(id: String) -> void:
	seleccion = id
	var prueba := personalizacion.copia()
	prueba.elegidos[_categoria_de(_pieza_tienda(id))] = id
	jugador.vestir(prueba)
	_refrescar_astillero()


func _usar_pieza() -> void:
	var cat := _categoria_de(_pieza_tienda(seleccion))
	if personalizacion.tiene(cat, seleccion):
		personalizacion.elegidos[cat] = seleccion
		personalizacion.guardar()
		voz_equipar.play()
	elif personalizacion.comprar(cat, seleccion):
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
	texto_gemas_tienda.text = str(personalizacion.gemas)
	var pestanas: Array = Catalogo.CATEGORIAS + [TESOROS]
	for i in botones_categoria.size():
		Ui.estilo_boton(botones_categoria[i], pestanas[i] == categoria)

	var propias := 0
	for pieza in _piezas_tienda():
		if personalizacion.tiene(_categoria_de(pieza), pieza["id"]):
			propias += 1
		_pintar_boton_pieza(botones_pieza[pieza["id"]], pieza)

	var elegida := _pieza_tienda(seleccion)
	var cat := _categoria_de(elegida)
	var propia := personalizacion.tiene(cat, seleccion)
	var en_gemas: int = elegida.get("gemas", 0)
	var info := tr(elegida.get("info", ""))
	texto_pieza.text = "%s%s" % [tr(elegida["nombre"]), "  ·  " + info if info != "" else ""] + tr("\nTienes %d de %d") % [propias, _piezas_tienda().size()]
	boton_accion.icon = null if propia else (Ui.textura_gema() if en_gemas > 0 else Ui.textura_moneda())
	if personalizacion.elegidos[cat] == seleccion:
		boton_accion.text = "Equipado"
		boton_accion.disabled = true
		Ui.estilo_boton(boton_accion, false)
	elif propia:
		boton_accion.text = "Equipar"
		boton_accion.disabled = false
		Ui.estilo_boton(boton_accion, true)
	elif en_gemas > 0:
		var alcanza := personalizacion.gemas >= en_gemas
		boton_accion.text = tr("Comprar · %d gemas") % en_gemas if alcanza else tr("Te faltan %d gemas") % (en_gemas - personalizacion.gemas)
		boton_accion.disabled = not alcanza
		Ui.estilo_boton(boton_accion, alcanza)
	elif personalizacion.monedas >= elegida["precio"]:
		boton_accion.text = tr("Comprar · %d monedas") % elegida["precio"]
		boton_accion.disabled = false
		Ui.estilo_boton(boton_accion, true)
	else:
		boton_accion.text = tr("Te faltan %d monedas") % (elegida["precio"] - personalizacion.monedas)
		boton_accion.disabled = true
		Ui.estilo_boton(boton_accion, false)


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
	var cat := _categoria_de(pieza)
	if cat in Catalogo.CON_DIBUJO:
		boton.icon = Dibujos.textura(pieza, 96, 64)
	else:
		boton.icon = _hueco_miniatura()
		miniaturas.pedir(cat, pieza, personalizacion, boton)
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
	var cat := _categoria_de(pieza)
	var propia := personalizacion.tiene(cat, id)
	var equipada: bool = personalizacion.elegidos[cat] == id
	var en_gemas: int = pieza.get("gemas", 0)
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
		precio.add_child(Ui.icono_gema(16) if en_gemas > 0 else Ui.icono_moneda(16))
		var cifra := Ui.etiqueta("", 14)
		cifra.name = "Cifra"
		cifra.add_theme_color_override("font_color", Misiones.COLOR_GEMA if en_gemas > 0 else COLOR_ORO)
		cifra.add_theme_constant_override("outline_size", 4)
		precio.add_child(cifra)
		boton.add_child(precio)
	precio.visible = not propia
	(precio.get_node("Cifra") as Label).text = str(en_gemas if en_gemas > 0 else pieza["precio"])

	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(12)
	estilo.set_content_margin_all(5)
	estilo.bg_color = Color(0.25, 0.13, 0.36, 0.95) if en_gemas > 0 else Color(0.11, 0.27, 0.33, 0.95)
	if not propia:
		estilo.bg_color = estilo.bg_color.darkened(0.35)
	var borde_normal := Color(Misiones.COLOR_GEMA, 0.6) if en_gemas > 0 else Color(1, 1, 1, 0.25)
	estilo.border_color = Color.WHITE if id == seleccion else (COLOR_ORO if equipada else borde_normal)
	estilo.set_border_width_all(4 if id == seleccion else (3 if equipada else 1))
	for nombre in ["normal", "hover", "pressed"]:
		boton.add_theme_stylebox_override(nombre, estilo)
	var claro := estilo.bg_color.get_luminance() > 0.55 and estilo.bg_color.a > 0.5
	var texto := Color("2a1c10") if claro else COLOR_TEXTO
	for nombre in ["font_color", "font_hover_color", "font_pressed_color"]:
		boton.add_theme_color_override(nombre, texto)
	boton.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	boton.add_theme_constant_override("outline_size", 0 if claro else 4)


# Pantalla final

func _crear_final(capa: CanvasLayer) -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)
	panel_final = centro
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.estilo_panel())
	panel.custom_minimum_size = Vector2(560, 0)
	panel.gui_input.connect(_tocar_final)
	centro.add_child(panel)
	caja_final = panel
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 14)
	panel.add_child(cuerpo)
	cuerpo.add_child(Ui.etiqueta_panel("MAREA CERRADA", 20, COLOR_ORO))
	titulo_final = RichTextLabel.new()
	titulo_final.bbcode_enabled = true
	titulo_final.fit_content = true
	titulo_final.scroll_active = false
	titulo_final.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo_final.clip_contents = false
	titulo_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# El texto ya llega traducido y con las etiquetas del efecto.
	titulo_final.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	titulo_final.add_theme_font_size_override("normal_font_size", 60)
	titulo_final.add_theme_color_override("default_color", COLOR_TEXTO)
	titulo_final.install_effect(salto_titulo)
	cuerpo.add_child(titulo_final)
	texto_final = Ui.etiqueta_panel("Tu barco quedó solo en el mar.", 26, COLOR_TEXTO)
	cuerpo.add_child(texto_final)
	texto_premio = Ui.etiqueta_panel("+0 monedas", 44, COLOR_ORO)
	texto_premio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cuerpo.add_child(texto_premio)
	lineas_premio = VBoxContainer.new()
	lineas_premio.add_theme_constant_override("separation", 4)
	cuerpo.add_child(lineas_premio)
	texto_tesoro = Ui.etiqueta_panel("", 22, COLOR_TEXTO)
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
	var puerto := Ui.boton("Al puerto", false)
	puerto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	puerto.pressed.connect(_al_puerto)
	fila.add_child(puerto)
	var otra := Ui.boton("Otra partida", true)
	otra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	otra.pressed.connect(func() -> void:
		if modo == "moba":
			_al_puerto(true)
		else:
			_buscar_partida(modo))
	fila.add_child(otra)


# Cambio de pantalla y HUD

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
	texto_gemas_menu.text = str(personalizacion.gemas)
	_pintar_nivel_menu()
	panel_niveles.visible = estado == Estado.NIVELES
	moba.panel_capitanes.visible = estado == Estado.CAPITANES
	if estado != Estado.CAPITANES:
		moba.quitar_del_muelle()
	if estado in [Estado.MENU, Estado.ASTILLERO, Estado.AJUSTES, Estado.NIVELES]:
		moba.restaurar_puerto()
	if estado == Estado.NIVELES:
		_llenar_niveles()
	campo_nombre.text = personalizacion.nombre
	panel_busqueda.visible = estado == Estado.BUSCANDO
	panel_ajustes.visible = estado == Estado.AJUSTES
	boton_ajustes.visible = estado == Estado.MENU
	boton_idioma.visible = estado == Estado.MENU
	boton_partida.visible = estado == Estado.JUGANDO
	panel_partida.visible = false
	libre.boton_base.visible = false
	comercio.ocultar()
	moba.ocultar()
	misiones.cerrar_mapa()
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


# Mientras se arma o desarma el mar, el juego no avanza ni atiende toques: la pantalla de
# carga lo tapa y su barra muestra cada paso.
var cargando := false


func _abrir_carga(titulo: String) -> PantallaCarga:
	cargando = true
	palanca_dedo = -1
	dedos_fuego.clear()
	palanca = Vector2.ZERO
	var carga := PantallaCarga.new()
	add_child(carga)
	carga.titular(tr(titulo))
	return carga


# Deja dibujar la pantalla de carga antes de seguir con el trabajo pesado.
func _avanzar_carga(carga: PantallaCarga, texto: String, parte: float) -> void:
	carga.paso(tr(texto), parte)
	await get_tree().process_frame
	await get_tree().process_frame


# Barcos e islas que se quitan durante una carga. Borrados todos juntos al final de un cuadro
# dejarían el móvil congelado unos segundos; _desmontar los borra por tandas.
var restos: Array[Node] = []


func _retirar(nodo: Node3D) -> void:
	if cargando:
		nodo.visible = false
		restos.append(nodo)
	else:
		nodo.queue_free()


func _desmontar(carga: PantallaCarga, texto: String, desde: float, hasta: float) -> void:
	var total := maxi(1, restos.size())
	while not restos.is_empty():
		var inicio := Time.get_ticks_msec()
		while not restos.is_empty() and Time.get_ticks_msec() - inicio < 60:
			var nodo: Node = restos.pop_back()
			if is_instance_valid(nodo):
				if nodo.get_parent() != null:
					nodo.get_parent().remove_child(nodo)
				nodo.queue_free()
		carga.paso(tr(texto), lerpf(desde, hasta, 1.0 - float(restos.size()) / total))
		await get_tree().process_frame


func _cerrar_carga(carga: PantallaCarga) -> void:
	await _avanzar_carga(carga, "¡Listo!", 1.0)
	cargando = false
	carga.cerrar(0.15, 0.3)


func _zarpar() -> void:
	if cargando:
		return
	var carga := _abrir_carga("Zarpando...")
	await _avanzar_carga(carga, "Preparando el mar...", 0.1)
	await _preparar_mar(carga)
	aplicar_tamano_controles()
	_mostrar(Estado.JUGANDO)
	_pintar_hud()
	await _cerrar_carga(carga)


# Con elegir_capitan se vuelve a la elección de capitán del 5 contra 5 en vez de al menú.
func _al_puerto(elegir_capitan := false) -> void:
	if cargando:
		return
	var carga := _abrir_carga("Volviendo al puerto...")
	await _avanzar_carga(carga, "Recogiendo las velas...", 0.1)
	_vaciar_mar()
	restos.append_array(islas.soltar_todo())
	await _desmontar(carga, "Recogiendo las velas...", 0.1, 0.75)
	_preparar_puerto(true)
	await _avanzar_carga(carga, "Amarrando el barco...", 0.8)
	if elegir_capitan:
		moba.abrir_seleccion()
	else:
		_mostrar(Estado.MENU)
	await _cerrar_carga(carga)


func _pintar_hud() -> void:
	_pintar_botin()
	texto_botin.visible = modo != "moba"
	texto_tormenta.visible = true
	marcador_moba.visible = false
	texto_mision.visible = true
	var ultima := DURACION_FASES.size() - 1
	texto_mision.text = misiones.texto_hud()
	var peligro := peligros.aviso(jugador) if jugador.viva else ""
	if peligro == "" and jugador.viva:
		peligro = tiburones.aviso(jugador)
	if peligro == "" and jugador.viva:
		peligro = barriles.aviso(jugador)
	if modo == "libre":
		texto_vivos.text = tr("Mar libre · Tesoro: %d") % personalizacion.monedas
		texto_tormenta.text = peligro if peligro != "" else libre.texto_estado()
		return
	if modo == "moba":
		texto_vivos.text = moba.texto_estado()
		texto_tormenta.text = moba.texto_aviso()
		texto_tormenta.visible = texto_tormenta.text != ""
		texto_mision.visible = false
		var marcador := moba.marcador()
		marcador_moba.visible = marcador.x >= 0
		cifra_hundidos.text = str(marcador.x)
		cifra_veces_hundido.text = str(marcador.y)
		return
	texto_vivos.text = tr("A flote: %d") % _contar_vivos()
	if peligro != "":
		texto_tormenta.text = peligro
	elif jugador.pos.distance_to(zona_centro) > zona_radio:
		texto_tormenta.text = "Estás en la tormenta"
	elif fase == ultima and edad_fase >= DURACION_FASES[ultima]:
		texto_tormenta.text = "Círculo final"
	else:
		var restante := ceili(DURACION_FASES[fase] - edad_fase)
		texto_tormenta.text = tr("Tormenta: %d:%02d") % [floori(restante / 60.0), restante % 60]


# Dibujo sobre la pantalla: marcadores, minimapa y controles

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
		var color := Color("3dde7a") if barco.es_jugador else (Moba.COLORES[barco.equipo] if barco.equipo >= 0 else Color("e23d3d"))
		var lleno := (ancho - 4.0) * barco.vida / barco.vida_max
		marcadores.draw_rect(Rect2(pantalla + Vector2(-ancho / 2.0 + 2.0, -4.0), Vector2(lleno, 8.0)), color)
		var fuente := ThemeDB.fallback_font
		var tam := 18
		var ancho_nombre := fuente.get_string_size(barco.nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var sitio := pantalla + Vector2(-ancho_nombre / 2.0, -12.0)
		var tinta := Color("c9ffd9") if barco.es_jugador else moba.tinta(barco) if barco.equipo >= 0 else (Niebla.COLOR_FANTASMA if barco.fantasma else Recompensas.COLOR_OBJETIVO if recompensas.objetivo_activo(barco) else Persecucion.COLOR_LEGENDARIO if barco.legendario else (Persecucion.COLOR_CAZADOR if barco.cazador else (COLOR_PELIGRO if barco.es_pirata else COLOR_TEXTO)))
		marcadores.draw_string_outline(fuente, sitio, barco.nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 5, Color(0, 0, 0, 0.7))
		marcadores.draw_string(fuente, sitio, barco.nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, tinta)
		if barco.es_pirata and barco.recompensa > 0:
			var cartel := tr("Recompensa: %d") % barco.recompensa
			var ancho_cartel := fuente.get_string_size(cartel, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			var arriba := pantalla + Vector2(-ancho_cartel / 2.0, -32.0)
			marcadores.draw_string_outline(fuente, arriba, cartel, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color(0, 0, 0, 0.7))
			marcadores.draw_string(fuente, arriba, cartel, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COLOR_ORO)
		if barco.botin > 0 and barco.es_bot:
			var cifra := str(barco.botin)
			var moneda := pantalla + Vector2(ancho / 2.0 + 12.0, 0.0)
			_dibujar_moneda(moneda, 8.0)
			marcadores.draw_string_outline(fuente, moneda + Vector2(11.0, 6.0), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.7))
			marcadores.draw_string(fuente, moneda + Vector2(11.0, 6.0), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_ORO)
	emotes.dibujar(marcadores, camara)
	misiones.dibujar(marcadores, camara)
	if modo == "moba":
		moba.dibujar(marcadores, camara)
	if modo == "libre":
		libre.dibujar(marcadores, camara)
		comercio.dibujar(marcadores, camara)
		persecucion.dibujar(marcadores)
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


func _dibujar_moneda(centro: Vector2, radio: float) -> void:
	marcadores.draw_circle(centro, radio, Color("8a6418"))
	marcadores.draw_circle(centro, radio * 0.82, Color("e2b13a"))
	marcadores.draw_circle(centro, radio * 0.5, Color("f0cd62"))


# Las islas del minimapa, todas en una malla (un solo dibujo) que se rehace al cambiar el mar.
# Cada círculo suelto era un dibujo aparte y con 200 islas el móvil se ahogaba.
var islas_minimapa: ArrayMesh
var clave_islas_minimapa := ""


func _islas_minimapa(escala: float) -> ArrayMesh:
	# En el radar del mar libre se rehace cada pocos metros que avanza el barco.
	var radar := modo == "libre" and jugador != null
	var sitio_radar := (jugador.pos / 25.0).round() * 25.0 if radar else Vector2.ZERO
	var clave := "%d|%f|%s|%s" % [islotes.size(), escala, islotes[0].pos if not islotes.is_empty() else Vector2.ZERO, sitio_radar]
	if clave == clave_islas_minimapa:
		return islas_minimapa
	clave_islas_minimapa = clave
	var puntos := PackedVector2Array()
	var colores := PackedColorArray()
	for isla in islotes:
		if radar and isla.pos.distance_to(sitio_radar) >= MarLibre.RADAR * 0.94:
			continue
		var tono := Islas.COLOR_ROCA if isla.radio <= Islas.RADIO_ROCAS else Islas.COLOR_ARENA
		if isla.lobulos.is_empty():
			_circulo_minimapa(puntos, colores, isla.pos, maxf(1.5 / escala, isla.radio), tono)
			continue
		for lobulo in isla.lobulos:
			var sitio: Vector2 = isla.pos + Vector2(lobulo.x, lobulo.y) * isla.radio
			_circulo_minimapa(puntos, colores, sitio, maxf(1.0 / escala, lobulo.z * isla.radio), tono)
	islas_minimapa = ArrayMesh.new()
	if not puntos.is_empty():
		var datos := []
		datos.resize(Mesh.ARRAY_MAX)
		datos[Mesh.ARRAY_VERTEX] = puntos
		datos[Mesh.ARRAY_COLOR] = colores
		islas_minimapa.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, datos)
	return islas_minimapa


func _circulo_minimapa(puntos: PackedVector2Array, colores: PackedColorArray, centro: Vector2, radio: float, color: Color) -> void:
	var lados := 16
	for k in lados:
		puntos.append(centro)
		puntos.append(centro + Vector2.from_angle(TAU * k / lados) * radio)
		puntos.append(centro + Vector2.from_angle(TAU * (k + 1) / lados) * radio)
		for _v in 3:
			colores.append(color)


func _dibujar_minimapa() -> void:
	var exterior := minimapa.size.x / 2.0
	var radio := exterior - ANCHO_BRUJULA
	var centro := minimapa.size / 2.0
	var escala := radio / RADIO_MUNDO
	_dibujar_brujula(centro, exterior, radio)
	if modo == "libre":
		# Radar alrededor del barco: el mapa se desplaza y el barco queda en el centro.
		escala = radio / MarLibre.RADAR
		minimapa.draw_circle(centro, radio, Color("1f7f86"))
		if jugador != null:
			centro -= jugador.pos * escala
			_dibujar_borde_libre(centro, escala, radio)
	elif modo == "moba":
		escala = radio / Moba.RADIO_MAPA
		minimapa.draw_circle(centro, radio, Color("1f7f86"))
	else:
		minimapa.draw_circle(centro, radio, Color("0e2f38"))
		minimapa.draw_circle(centro + zona_centro * escala, maxf(3.0, zona_radio * escala), Color("1f7f86"))
		minimapa.draw_arc(centro + zona_centro * escala, maxf(3.0, zona_radio * escala), 0.0, TAU, 64, Color(1.0, 0.96, 0.84), 2.0, true)
	minimapa.draw_set_transform(centro, 0.0, Vector2.ONE * escala)
	minimapa.draw_mesh(_islas_minimapa(escala), null)
	minimapa.draw_set_transform(Vector2.ZERO)
	peligros.dibujar_minimapa(minimapa, centro, escala)
	for tabla in tablas:
		if en_mapa(tabla.pos):
			minimapa.draw_circle(centro + tabla.pos * escala, 2.5, Color("ffd36b"))
	misiones.dibujar_minimapa(minimapa, centro, escala)
	if modo == "libre":
		libre.dibujar_minimapa(minimapa, centro, escala)
		comercio.dibujar_minimapa(minimapa, centro, escala)
		persecucion.dibujar_minimapa(minimapa, centro, escala)
		recompensas.dibujar_minimapa(minimapa, centro, escala)
	elif modo == "moba":
		moba.dibujar_minimapa(minimapa, centro, escala)
	# Los cofres tampoco: hay que encontrarlos navegando.
	# Los rivales no salen en el mapa: solo tu barco, con una flecha hacia donde mira la proa.
	if jugador != null and jugador.viva:
		var punto := centro + jugador.pos * escala
		var proa := jugador.proa()
		var lado := proa.orthogonal()
		var flecha := PackedVector2Array([punto + proa * 8.0, punto - proa * 5.0 + lado * 5.5, punto - proa * 2.5, punto - proa * 5.0 - lado * 5.5])
		minimapa.draw_colored_polygon(flecha, Color("7dffb2"))
		flecha.append(flecha[0])
		minimapa.draw_polyline(flecha, Color("0b3a2a"), 1.5, true)
	var medio := minimapa.size / 2.0
	if modo == "libre":
		niebla.dibujar_minimapa(minimapa, medio, radio)
	minimapa.draw_arc(medio, radio, 0.0, TAU, 64, COLOR_ORO, 2.5, true)
	misiones.dibujar_brujula(minimapa, medio, exterior, radio)
	if modo == "libre":
		libre.dibujar_brujula(minimapa, medio, exterior, radio)
		comercio.dibujar_brujula(minimapa, medio, exterior, radio)
		persecucion.dibujar_brujula(minimapa, medio, exterior, radio)
		recompensas.dibujar_brujula(minimapa, medio, exterior, radio)


# Tramo del borde de la tormenta que cae dentro del radar del mar libre.
func _dibujar_borde_libre(centro: Vector2, escala: float, radio: float) -> void:
	if jugador.pos.length() < MarLibre.RADIO - MarLibre.RADAR:
		return
	var medio := minimapa.size / 2.0
	var hacia := jugador.pos.angle()
	var abre := MarLibre.RADAR * 1.2 / MarLibre.RADIO
	var puntos := PackedVector2Array()
	for k in 41:
		var punto := centro + Vector2.from_angle(hacia + lerpf(-abre, abre, k / 40.0)) * MarLibre.RADIO * escala
		if punto.distance_to(medio) < radio - 1.0:
			puntos.append(punto)
	if puntos.size() > 1:
		minimapa.draw_polyline(puntos, Color(1.0, 0.96, 0.84), 2.0, true)


# Bisel de brújula alrededor del mapa: marcas cada 15° y los cuatro puntos cardinales.
# El norte es arriba, igual que el rumbo 0 de los barcos.
func _dibujar_brujula(centro: Vector2, exterior: float, interior: float) -> void:
	minimapa.draw_circle(centro + Vector2(0, 3), exterior, Color(0, 0, 0, 0.25))
	minimapa.draw_circle(centro, exterior, Color("13262c"))
	minimapa.draw_arc(centro, exterior - 1.5, 0.0, TAU, 72, COLOR_ORO, 3.0, true)
	for k in 24:
		var angulo := TAU * k / 24.0
		if k % 6 == 0:
			continue
		var dir := Vector2.from_angle(angulo)
		var largo := 7.0 if k % 3 == 0 else 4.0
		minimapa.draw_line(centro + dir * (exterior - 4.0), centro + dir * (exterior - 4.0 - largo), Color(COLOR_TEXTO, 0.7), 1.5, true)
	var fuente := ThemeDB.fallback_font
	var cardinales := [["N", -PI / 2.0], ["E", 0.0], ["S", PI / 2.0], ["O", PI]]
	for cardinal in cardinales:
		var dir := Vector2.from_angle(cardinal[1])
		var punto := centro + dir * (interior + ANCHO_BRUJULA * 0.5)
		var letra: String = tr(cardinal[0])
		var tam := 17 if cardinal[0] == "N" else 14
		var medida := fuente.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
		var base := punto + Vector2(-medida.x / 2.0, medida.y * 0.3)
		minimapa.draw_string_outline(fuente, base, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 4, Color("08161c"))
		minimapa.draw_string(fuente, base, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, COLOR_PELIGRO if cardinal[0] == "N" else COLOR_TEXTO)
	# Aguja del norte apuntando hacia fuera, sobre el borde.
	var tope := centro + Vector2(0, -exterior)
	minimapa.draw_colored_polygon(PackedVector2Array([tope + Vector2(0, -7), tope + Vector2(-6, 3), tope + Vector2(6, 3)]), COLOR_PELIGRO)


func _dibujar_controles() -> void:
	if not listo or jugador == null:
		return
	controles.draw_set_transform(centro_palanca if palanca_dedo != -1 else _posicion_palanca_reposo(), 0.0, Vector2.ONE * escala_controles)
	var base := Vector2.ZERO
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
		var carga: float = 1.0 - jugador.recargas[arma] / (RECARGAS[arma] * jugador.factor_recarga)
		var lista := carga >= 1.0
		var pulsado := _arma_pulsada(arma)
		controles.draw_set_transform(_posicion_fuego(arma) + (Vector2(0, 2) if pulsado else Vector2.ZERO), 0.0, Vector2.ONE * escala_controles)
		var centro := Vector2.ZERO
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
	controles.draw_set_transform(Vector2.ZERO)


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
