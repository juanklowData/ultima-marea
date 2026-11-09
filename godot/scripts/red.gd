class_name Red
extends Node

# 1 contra 1 entre dos móviles de la misma wifi. Quien crea la partida es el anfitrión
# (armada azul) y manda sobre vidas, hundimientos, oleadas y monstruos; quien se une
# (armada roja) corrige lo suyo con lo que le cuenta el anfitrión. Cada uno pilota su
# barco y avisa al otro de dónde está y de qué dispara, lanza o compra.

const PUERTO := 47810
const PUERTO_AVISO := 47811
const FIRMA := "ULTIMA_MAREA_1V1"
const CADA_AVISO := 1.0
const CADA_POSICION := 0.05
const CADA_ESTADO := 0.1
const CADUCA_PARTIDA := 3500

var mundo: Principal
var anfitrion := false
var uniendose := false
var en_partida := false
var rival_perdido := false
var rival_listo := false
var rival_nombre := ""
var rival_capitan := ""
var semilla := 0
# Anuncio de la partida creada a toda la wifi y escucha de los anuncios de otros.
var aviso: PacketPeerUDP
var oyente: PacketPeerUDP
var encontradas := {}
var espera_aviso := 0.0
var espera_posicion := 0.0
var espera_estado := 0.0
var mensaje := ""

var panel: PanelContainer
var texto_capitan: Label
var boton_crear: Button
var bloque_unirse: VBoxContainer
var lista_partidas: VBoxContainer
var texto_vacio: Label
var campo_ip: LineEdit
var texto_estado: Label


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	multiplayer.peer_connected.connect(_al_llegar_rival)
	multiplayer.peer_disconnected.connect(_al_perder_rival)
	multiplayer.connected_to_server.connect(_al_unirse)
	multiplayer.connection_failed.connect(_al_fallar)
	multiplayer.server_disconnected.connect(_al_perder_rival.bind(1))


# Armada del jugador de este móvil: la azul para el anfitrión, la roja para el invitado.
func lado() -> int:
	return 0 if anfitrion else 1


# El invitado no decide hundimientos ni oleadas: los espera del anfitrión.
func es_invitado() -> bool:
	return en_partida and not anfitrion


func _hablando() -> bool:
	return en_partida and not rival_perdido and mundo.estado == Principal.Estado.JUGANDO


# Panel

func crear_interfaz(capa: CanvasLayer) -> void:
	var partes := Ui.panel_lateral_desplazable(capa)
	panel = partes[0]
	panel.visible = false
	var cuerpo: VBoxContainer = partes[1]
	var pie: VBoxContainer = partes[2]
	cuerpo.add_theme_constant_override("separation", 12)
	cuerpo.add_child(Ui.etiqueta_panel(tr("Jugar por wifi"), 34, Principal.COLOR_ORO))
	cuerpo.add_child(Ui.etiqueta_panel(tr("1 contra 1 con un amigo. Los dos móviles deben estar conectados a la misma red wifi."), 17, Color("c9d1d3")))
	texto_capitan = Ui.etiqueta_panel("", 20, Principal.COLOR_TEXTO)
	cuerpo.add_child(texto_capitan)
	boton_crear = Ui.boton(tr("Crear partida"), true)
	boton_crear.pressed.connect(crear_partida)
	cuerpo.add_child(boton_crear)

	bloque_unirse = VBoxContainer.new()
	bloque_unirse.add_theme_constant_override("separation", 10)
	cuerpo.add_child(bloque_unirse)
	bloque_unirse.add_child(Ui.etiqueta_panel(tr("Partidas en tu wifi"), 22, Principal.COLOR_ORO))
	lista_partidas = VBoxContainer.new()
	lista_partidas.add_theme_constant_override("separation", 8)
	bloque_unirse.add_child(lista_partidas)
	texto_vacio = Ui.etiqueta_panel(tr("Buscando partidas cerca..."), 17, Color("c9d1d3"))
	bloque_unirse.add_child(texto_vacio)
	bloque_unirse.add_child(Ui.etiqueta_panel(tr("¿No aparece? Escribe la dirección que ve tu amigo:"), 16, Color("c9d1d3")))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	bloque_unirse.add_child(fila)
	campo_ip = LineEdit.new()
	campo_ip.placeholder_text = "192.168.1.5"
	campo_ip.max_length = 15
	campo_ip.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	campo_ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campo_ip.custom_minimum_size = Vector2(0, 64)
	campo_ip.add_theme_font_size_override("font_size", 26)
	campo_ip.add_theme_color_override("font_color", Principal.COLOR_TEXTO)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0, 0, 0, 0.3)
	fondo.border_color = Color(1, 1, 1, 0.3)
	fondo.set_border_width_all(2)
	fondo.set_corner_radius_all(14)
	fondo.set_content_margin_all(12)
	var foco := fondo.duplicate() as StyleBoxFlat
	foco.border_color = Principal.COLOR_ORO
	campo_ip.add_theme_stylebox_override("normal", fondo)
	campo_ip.add_theme_stylebox_override("focus", foco)
	campo_ip.text_submitted.connect(func(_texto: String) -> void: campo_ip.release_focus())
	fila.add_child(campo_ip)
	var unirse := Ui.boton(tr("Unirse"), false)
	unirse.custom_minimum_size = Vector2(150, 64)
	unirse.add_theme_font_size_override("font_size", 24)
	unirse.pressed.connect(func() -> void: unirse_a(campo_ip.text.strip_edges()))
	fila.add_child(unirse)

	texto_estado = Ui.etiqueta_panel("", 22, Principal.COLOR_TEXTO)
	cuerpo.add_child(texto_estado)
	var volver := Ui.boton(tr("Volver"), false)
	Ui.estilo_volver(volver)
	volver.custom_minimum_size = Vector2(0, 64)
	volver.pressed.connect(_volver)
	pie.add_child(volver)


func abrir() -> void:
	cerrar()
	mundo._mostrar(Principal.Estado.RED)
	texto_capitan.text = tr("Tu dios: %s") % tr(mundo.moba.capitan_elegido()["nombre"])
	_escuchar()
	_pintar()
	_pintar_lista()


func _volver() -> void:
	campo_ip.release_focus()
	cerrar()
	mundo.moba.abrir_seleccion()


func _pintar() -> void:
	var esperando := multiplayer.multiplayer_peer is ENetMultiplayerPeer
	boton_crear.visible = not esperando
	bloque_unirse.visible = not esperando
	if anfitrion and esperando:
		texto_estado.text = tr("Esperando a tu rival...\nTu dirección: %s") % _mi_ip()
	elif uniendose:
		texto_estado.text = tr("Conectando...")
	else:
		texto_estado.text = mensaje


func _pintar_lista() -> void:
	for hijo in lista_partidas.get_children():
		hijo.queue_free()
	for ip in encontradas:
		var partida: Dictionary = encontradas[ip]
		var capitan := mundo.moba.capitan_por_id(partida["capitan"])
		var boton := Ui.boton("%s  ·  %s" % [partida["nombre"], tr(capitan["nombre"])], false)
		boton.custom_minimum_size = Vector2(0, 60)
		boton.add_theme_font_size_override("font_size", 22)
		boton.pressed.connect(unirse_a.bind(ip))
		lista_partidas.add_child(boton)
	texto_vacio.visible = encontradas.is_empty()


func _mi_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "?"


# Conexión

func crear_partida() -> void:
	cerrar()
	var par := ENetMultiplayerPeer.new()
	if par.create_server(PUERTO, 1) != OK:
		mensaje = tr("No se pudo crear la partida. Revisa la wifi.")
		_escuchar()
		_pintar()
		return
	multiplayer.multiplayer_peer = par
	anfitrion = true
	aviso = PacketPeerUDP.new()
	aviso.set_broadcast_enabled(true)
	aviso.set_dest_address("255.255.255.255", PUERTO_AVISO)
	espera_aviso = 0.0
	_pintar()


func unirse_a(ip: String) -> void:
	campo_ip.release_focus()
	if not ip.is_valid_ip_address():
		mensaje = tr("Escribe una dirección válida, por ejemplo 192.168.1.5")
		_pintar()
		return
	cerrar()
	var par := ENetMultiplayerPeer.new()
	if par.create_client(ip, PUERTO) != OK:
		mensaje = tr("No se pudo conectar con esa partida.")
		_escuchar()
		_pintar()
		return
	multiplayer.multiplayer_peer = par
	uniendose = true
	_pintar()


func cerrar() -> void:
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	anfitrion = false
	uniendose = false
	en_partida = false
	rival_perdido = false
	rival_listo = false
	aviso = null
	_callar()
	mensaje = ""


func _escuchar() -> void:
	_callar()
	oyente = PacketPeerUDP.new()
	if oyente.bind(PUERTO_AVISO) != OK:
		oyente = null


func _callar() -> void:
	if oyente != null:
		oyente.close()
	oyente = null
	encontradas.clear()


func _al_llegar_rival(_id: int) -> void:
	if anfitrion:
		aviso = null


func _al_unirse() -> void:
	_saludo.rpc_id(1, mundo.personalizacion.nombre_visible(), mundo.moba.elegido)


func _al_fallar() -> void:
	cerrar()
	mensaje = tr("No se pudo conectar con esa partida.")
	_escuchar()
	_pintar()


func _al_perder_rival(_id: int) -> void:
	if en_partida:
		rival_perdido = true
		return
	cerrar()
	if mundo.estado == Principal.Estado.RED:
		mensaje = tr("Se perdió la conexión con tu rival.")
		_escuchar()
		_pintar()


@rpc("any_peer", "call_remote", "reliable")
func _saludo(nombre: String, capitan: String) -> void:
	if not anfitrion or en_partida:
		return
	rival_nombre = nombre
	rival_capitan = capitan
	semilla = randi()
	_empezar.rpc_id(multiplayer.get_remote_sender_id(), semilla, mundo.personalizacion.nombre_visible(), mundo.moba.elegido)
	_arrancar()


@rpc("authority", "call_remote", "reliable")
func _empezar(nueva_semilla: int, nombre: String, capitan: String) -> void:
	semilla = nueva_semilla
	rival_nombre = nombre
	rival_capitan = capitan
	_arrancar()


func _arrancar() -> void:
	en_partida = true
	uniendose = false
	rival_perdido = false
	rival_listo = false
	aviso = null
	_callar()
	campo_ip.release_focus()
	if anfitrion:
		multiplayer.multiplayer_peer.refuse_new_connections = true
	mundo.modo = "moba"
	mundo._zarpar()


# Cada móvil carga el mar a su ritmo; la partida empieza cuando los dos han terminado.
func esperar_rival(carga: PantallaCarga) -> void:
	carga.paso(tr("Esperando a tu rival..."), 0.95)
	_listo.rpc()
	while not rival_listo and not rival_perdido:
		await get_tree().process_frame


@rpc("any_peer", "call_remote", "reliable")
func _listo() -> void:
	rival_listo = true


func _process(delta: float) -> void:
	if aviso != null:
		espera_aviso -= delta
		if espera_aviso <= 0.0:
			espera_aviso = CADA_AVISO
			aviso.put_packet(("%s|%s|%s" % [FIRMA, mundo.moba.elegido, mundo.personalizacion.nombre_visible()]).to_utf8_buffer())
	if oyente != null:
		_oir()
	if not en_partida or mundo.estado != Principal.Estado.JUGANDO or mundo.cargando or mundo.jugador == null:
		return
	if rival_perdido:
		if mundo.moba.ganador < 0:
			mundo.moba.rival_se_fue()
		return
	espera_posicion -= delta
	if espera_posicion <= 0.0:
		espera_posicion = CADA_POSICION
		var barco := mundo.jugador
		if barco.viva:
			_posicion.rpc(barco.pos, barco.rumbo, barco.velocidad)
	if anfitrion:
		espera_estado -= delta
		if espera_estado <= 0.0:
			espera_estado = CADA_ESTADO
			_estado.rpc(mundo.moba.foto())


func _oir() -> void:
	var cambio := false
	while oyente.get_available_packet_count() > 0:
		var texto := oyente.get_packet().get_string_from_utf8()
		var ip := oyente.get_packet_ip()
		var partes := texto.split("|", true, 2)
		if partes.size() < 3 or partes[0] != FIRMA:
			continue
		if not encontradas.has(ip):
			cambio = true
		encontradas[ip] = {"capitan": partes[1], "nombre": partes[2], "visto": Time.get_ticks_msec()}
	for ip in encontradas.keys():
		if Time.get_ticks_msec() - encontradas[ip]["visto"] > CADUCA_PARTIDA:
			encontradas.erase(ip)
			cambio = true
	if cambio:
		_pintar_lista()


# Partida

func avisar_habilidad(ranura: int, hacia: Vector2, largo: float) -> void:
	if _hablando():
		_habilidad.rpc(ranura, hacia, largo, mundo.jugador.pos, mundo.jugador.rumbo)


func avisar_disparo(arma: String, hacia: Vector2) -> void:
	if _hablando():
		_disparo.rpc(arma, hacia, mundo.jugador.pos, mundo.jugador.rumbo)


func avisar_compra(clave: String) -> void:
	if _hablando():
		_compra.rpc(clave)


func avisar_oleada(numero: int, extras: Array) -> void:
	if _hablando() and anfitrion:
		_oleada.rpc(numero, extras)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _posicion(pos: Vector2, rumbo: float, velocidad: float) -> void:
	var heroe := mundo.moba.heroe_rival()
	if heroe == null:
		return
	heroe.barco.red_pos = pos
	heroe.barco.red_rumbo = rumbo
	heroe.barco.velocidad = velocidad


@rpc("any_peer", "call_remote", "reliable")
func _habilidad(ranura: int, hacia: Vector2, largo: float, pos: Vector2, rumbo: float) -> void:
	mundo.moba.habilidad_rival(ranura, hacia, largo, pos, rumbo)


@rpc("any_peer", "call_remote", "reliable")
func _disparo(arma: String, hacia: Vector2, pos: Vector2, rumbo: float) -> void:
	mundo.moba.disparo_rival(arma, hacia, pos, rumbo)


@rpc("any_peer", "call_remote", "reliable")
func _compra(clave: String) -> void:
	mundo.moba.compra_rival(clave)


@rpc("authority", "call_remote", "reliable")
func _oleada(numero: int, extras: Array) -> void:
	mundo.moba.oleada_rival(numero, extras)


@rpc("authority", "call_remote", "reliable")
func _estado(foto: Dictionary) -> void:
	mundo.moba.aplicar_foto(foto)
