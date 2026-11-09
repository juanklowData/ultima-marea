class_name Supervivencia
extends Node

# El único modo de juego: tu barco, guiado por un dios, contra oleadas sin fin de piratas
# malditos. Los cañones disparan solos al enemigo más cercano; tú navegas y lanzas el poder
# divino. Los hundidos sueltan almas: al juntar las suficientes subes de nivel y eliges una
# de tres bendiciones. Cada 3 minutos llega un jefe. Si aguantas 10 minutos, ganas.
# Las monedas de cada partida desbloquean dioses nuevos (se guardan en user://).
# Distancias en unidades del mar (Principal.ESCALA las pasa a 3D).

const DURACION := 600.0
const JEFES: Array[float] = [180.0, 360.0, 540.0]
const ARCHIVO := "user://supervivencia.cfg"
# Enemigos vivos a la vez: más barcos cuestan demasiado en el móvil, así que en vez de más
# barcos, con el tiempo salen más duros.
const MAX_ENEMIGOS_INICIO := 8
const MAX_ENEMIGOS_FINAL := 15
const DISTANCIA_APARICION := Vector2(480.0, 640.0)
const ALCANCE_CANONES := 300.0
const RADIO_IMAN := 170.0
const VEL_ALMA := 520.0
const MAX_ALMAS := 160
const MONEDAS_POR_MINUTO := 6
# Dioses con los que se empieza; el resto se compra con monedas.
const GRATIS: Array[String] = ["ares", "poseidon", "bachue"]
const PRECIOS := {"quetzalcoatl": 200, "atenea": 250, "ra": 300, "anubis": 350, "thor": 400,
	"odin": 450, "loki": 500, "pele": 550, "tiamat": 650}

# Poder divino de cada dios: nombre, descripción, recarga y color.
const PODERES := {
	"quetzalcoatl": {"nombre": "Vuelo de Ehécatl", "espera": 11.0, "info": "Vuelas un 80% más rápido 4 segundos y un vendaval aparta y daña a los piratas cercanos."},
	"ares": {"nombre": "Furia de Ares", "espera": 9.0, "info": "Dos andanadas de 16 balas en todas las direcciones."},
	"atenea": {"nombre": "Égida", "espera": 15.0, "info": "No recibes daño durante 4 segundos y reparas un 20% del barco."},
	"ra": {"nombre": "Disco solar", "espera": 11.0, "info": "Un anillo de sol quema a todos los piratas a tu alrededor."},
	"anubis": {"nombre": "Juicio de Anubis", "espera": 12.0, "info": "Frena y daña a los piratas cercanos y atrae hacia ti todas las almas."},
	"bachue": {"nombre": "Aguas de Iguaque", "espera": 13.0, "info": "Repara un 35% del barco y una ola empuja y daña a los piratas cercanos."},
	"poseidon": {"nombre": "Torbellino del tridente", "espera": 12.0, "info": "Abre un torbellino sobre los piratas que los arrastra y los daña 4 segundos."},
	"tiamat": {"nombre": "Hijos de Tiamat", "espera": 11.0, "info": "Tentáculos del abismo golpean a los 4 piratas más cercanos y los dejan quietos."},
	"pele": {"nombre": "Erupción", "espera": 11.0, "info": "Seis estallidos de lava caen alrededor de tu barco."},
	"loki": {"nombre": "Ilusión de Loki", "espera": 13.0, "info": "Te vuelves invisible 4 segundos: los piratas te pierden y navegas más rápido."},
	"odin": {"nombre": "Gungnir", "espera": 9.0, "info": "Odín arroja su lanza: atraviesa a todos los piratas en línea recta."},
	"thor": {"nombre": "Ira de Mjölnir", "espera": 10.0, "info": "Cinco rayos caen sobre los piratas más cercanos."},
}

# Bendiciones que se eligen al subir de nivel (hasta "max" veces cada una).
const BENDICIONES := {
	"canones": {"nombre": "Cañones de bronce", "info": "+20% de daño de tus cañones", "max": 5, "color": Color("ff6b5b")},
	"recarga": {"nombre": "Pólvora divina", "info": "Tus cañones recargan un 15% más rápido", "max": 5, "color": Color("ffb347")},
	"balas": {"nombre": "Andanada", "info": "+1 bala en cada cañonazo", "max": 4, "color": Color("ffd54a")},
	"casco": {"nombre": "Casco bendito", "info": "+20% de vida máxima y reparas un 30%", "max": 5, "color": Color("6fd06b")},
	"velas": {"nombre": "Velas de seda", "info": "Navegas un 10% más rápido", "max": 4, "color": Color("5cc8ff")},
	"regenera": {"nombre": "Marea sanadora", "info": "Reparas un 0,6% del barco cada segundo", "max": 4, "color": Color("7dffb2")},
	"iman": {"nombre": "Imán de almas", "info": "Recoges las almas desde un 35% más lejos", "max": 4, "color": Color("b9a6ff")},
	"alcance": {"nombre": "Catalejo", "info": "Tus balas llegan un 15% más lejos", "max": 3, "color": Color("dfe6ee")},
	"poder": {"nombre": "Fervor", "info": "Tu poder divino se recarga un 15% antes", "max": 4, "color": Color("ffe08a")},
	"furia": {"nombre": "Ira de los dioses", "info": "Tu poder divino hace un 30% más de daño", "max": 4, "color": Color("ff8a5c")},
	"armadura": {"nombre": "Placas de hierro", "info": "Recibes un 8% menos de daño", "max": 4, "color": Color("9aa3ab")},
	"fuego": {"nombre": "Balas de fuego", "info": "Un 25% de tus balas incendian al pirata", "max": 3, "color": Color("ff6a1e")},
	"explosiva": {"nombre": "Balas explosivas", "info": "Un 20% de tus balas estallan y dañan alrededor", "max": 3, "color": Color("f2c230")},
	"cadena": {"nombre": "Balas encadenadas", "info": "Un 25% de tus balas rompen las velas del pirata", "max": 2, "color": Color("cfd6dc")},
}

var mundo: Principal
var dios := {}
var tiempo := 0.0
var activa := false
var ganado := false
var enemigos: Array[Barco] = []
var espera_aparicion := 2.0
var jefes_lanzados := 0
var nivel := 1
var almas := 0
var niveles := {}
var espera_canones := 0.0
var espera_poder := 0.0
var invulnerable := 0.0
var invisible := 0.0
var veloz := 0.0
var torbellinos: Array[Dictionary] = []
var eligiendo := false
var opciones: Array[String] = []
var hundidos_jefe := 0
var record_nuevo := false
# Almas en el agua: posiciones, valores y si ya vuelan hacia el barco.
var almas_pos: Array[Vector2] = []
var almas_valor: Array[int] = []
var almas_vuelan: Array[bool] = []
var multi_almas: MultiMeshInstance3D
# Guardado.
var desbloqueados: Array[String] = []
var mejor_tiempo := 0.0
var mejor_hundidos := 0
# Interfaz.
var hud: Control
var panel_nivel: PanelContainer
var titulo_nivel: Label
var cartas: Array[Button] = []
var dedo_poder := -1


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	_cargar()
	multi_almas = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bola := SphereMesh.new()
	bola.radius = 0.32
	bola.height = 0.64
	bola.radial_segments = 8
	bola.rings = 4
	mm.mesh = bola
	mm.instance_count = MAX_ALMAS
	mm.visible_instance_count = 0
	multi_almas.multimesh = mm
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.albedo_color = Color("8ff0ff")
	multi_almas.material_override = brillo
	multi_almas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(multi_almas)


# ---------------------------------------------------------------------------------------
# Guardado: dioses desbloqueados y récords.

func _cargar() -> void:
	var archivo := ConfigFile.new()
	archivo.load(ARCHIVO)
	desbloqueados.assign(archivo.get_value("dioses", "desbloqueados", GRATIS.duplicate()))
	for id in GRATIS:
		if not desbloqueados.has(id):
			desbloqueados.append(id)
	mejor_tiempo = archivo.get_value("records", "tiempo", 0.0)
	mejor_hundidos = archivo.get_value("records", "hundidos", 0)


func _guardar() -> void:
	var archivo := ConfigFile.new()
	archivo.set_value("dioses", "desbloqueados", desbloqueados)
	archivo.set_value("records", "tiempo", mejor_tiempo)
	archivo.set_value("records", "hundidos", mejor_hundidos)
	archivo.save(ARCHIVO)


func desbloqueado(id: String) -> bool:
	return desbloqueados.has(id)


func precio(id: String) -> int:
	return int(PRECIOS.get(id, 0))


# Botón principal del panel de dioses: zarpa con el dios elegido o lo compra si se puede.
func zarpar_o_desbloquear() -> void:
	var id := mundo.moba.elegido
	if desbloqueado(id):
		mundo._buscar_partida("supervivencia")
		return
	if mundo.personalizacion.monedas < precio(id):
		mundo.avisar_premio(mundo.jugador.position + Vector3(0, 3, 0) if mundo.jugador != null else Vector3.ZERO, tr("Te faltan %d monedas") % (precio(id) - mundo.personalizacion.monedas), Color("ff8a7a"))
		return
	mundo.personalizacion.monedas -= precio(id)
	mundo.personalizacion.guardar()
	desbloqueados.append(id)
	_guardar()
	mundo.voz_equipar.play()
	mundo.moba.elegir(id, false)


func texto_boton_zarpar(id: String) -> String:
	if desbloqueado(id):
		return tr("¡Zarpar!")
	return tr("Desbloquear · %d") % precio(id)


func nombre_poder(id: String) -> String:
	return tr(PODERES[id]["nombre"]) if PODERES.has(id) else ""


func info_poder(id: String) -> String:
	if not PODERES.has(id):
		return ""
	return tr(PODERES[id]["info"]) + "  ·  " + tr("Recarga: %d s") % int(PODERES[id]["espera"])


func texto_records() -> String:
	if mejor_tiempo <= 0.0:
		return tr("Aguanta 10 minutos contra las oleadas de piratas malditos.")
	return tr("Récord: %s · %d hundidos") % [_reloj(mejor_tiempo), mejor_hundidos]


# ---------------------------------------------------------------------------------------
# Partida.

func empezar(capitan: Dictionary) -> void:
	dios = capitan
	activa = true
	ganado = false
	tiempo = 0.0
	nivel = 1
	almas = 0
	niveles.clear()
	enemigos.clear()
	torbellinos.clear()
	espera_aparicion = 2.5
	jefes_lanzados = 0
	espera_canones = 0.5
	espera_poder = 2.0
	invulnerable = 0.0
	invisible = 0.0
	veloz = 0.0
	eligiendo = false
	record_nuevo = false
	_vaciar_almas()
	var jugador := mundo.jugador
	jugador.equipo = 0
	mundo.moba.igualar_barco(jugador, capitan)
	Moba.ritmo_heroe(jugador)
	jugador.vida_max = float(capitan["vida"]) * 1.3
	jugador.vida = jugador.vida_max
	jugador.vel_max = jugador.vel_max * float(capitan["velocidad"]) / 42.0
	hud.visible = true
	panel_nivel.visible = false


func vaciar() -> void:
	activa = false
	eligiendo = false
	enemigos.clear()
	torbellinos.clear()
	_vaciar_almas()
	if hud != null:
		hud.visible = false
		panel_nivel.visible = false


func pausado() -> bool:
	return activa and eligiendo


func actualizar(delta: float) -> void:
	if not activa or eligiendo:
		return
	var jugador := mundo.jugador
	if jugador == null:
		return
	tiempo += delta
	if jugador.viva and tiempo >= DURACION and not ganado:
		ganado = true
	invulnerable = maxf(0.0, invulnerable - delta)
	invisible = maxf(0.0, invisible - delta)
	veloz = maxf(0.0, veloz - delta)
	jugador.factor_defensa = 0.0 if invulnerable > 0.0 else pow(0.92, nivel_de("armadura"))
	jugador.factor_danio = 1.0 + 0.2 * nivel_de("canones")
	jugador.factor_recarga = pow(0.85, nivel_de("recarga"))
	var regen := 0.006 * nivel_de("regenera")
	if regen > 0.0 and jugador.viva:
		jugador.vida = minf(jugador.vida_max, jugador.vida + jugador.vida_max * regen * delta)
	if veloz > 0.0 or invisible > 0.0:
		jugador.velocidad = maxf(jugador.velocidad, jugador.vel_max * (1.8 if veloz > 0.0 else 1.3) * clampf(mundo.direccion_jugador().length(), 0.3, 1.0))
	_aparecer(delta)
	_limpiar_hundidos()
	if jugador.viva:
		espera_poder = maxf(0.0, espera_poder - delta)
	_mover_torbellinos(delta)
	_mover_almas(delta)


func nivel_de(clave: String) -> int:
	return int(niveles.get(clave, 0))


func _dificultad() -> float:
	return clampf(tiempo / DURACION, 0.0, 1.0)


# Saca piratas alrededor del jugador, fuera de la vista, cada vez más seguido y más duros.
func _aparecer(delta: float) -> void:
	espera_aparicion -= delta
	if jugadores_jefe_pendiente():
		jefes_lanzados += 1
		_crear_enemigo("galeon", true)
		mundo.avisar_premio(mundo.jugador.position + Vector3(0, 4, 0), tr("¡Llega un jefe pirata!"), Color("ff6a3d"))
		mundo.musica.batalla = true
	if espera_aparicion > 0.0:
		return
	var d := _dificultad()
	espera_aparicion = lerpf(2.2, 0.8, d)
	var maximo := int(lerpf(MAX_ENEMIGOS_INICIO, MAX_ENEMIGOS_FINAL, d))
	var grupo := 1 + int(d * 2.5 + randf() * 0.8)
	for _i in grupo:
		if enemigos.size() >= maximo:
			return
		var tirada := randf()
		var tipo := "balandro"
		if tirada < 0.15 + d * 0.35:
			tipo = "galeon"
		elif tirada < 0.55 + d * 0.15:
			tipo = "bergantin"
		_crear_enemigo(tipo, false)


func jugadores_jefe_pendiente() -> bool:
	return jefes_lanzados < JEFES.size() and tiempo >= JEFES[jefes_lanzados]


func _crear_enemigo(tipo: String, jefe: bool) -> void:
	var jugador := mundo.jugador
	var pos := Vector2.ZERO
	for _intento in 12:
		var angulo := randf() * TAU
		pos = jugador.pos + Vector2.from_angle(angulo) * randf_range(DISTANCIA_APARICION.x, DISTANCIA_APARICION.y)
		if pos.length() > mundo.zona_radio - 80.0:
			pos = pos.limit_length(mundo.zona_radio - 80.0)
		var libre := true
		for isla in mundo.islas.cerca(pos, 60.0):
			if isla.dentro(pos):
				libre = false
				break
		if libre:
			break
	var aspecto := Personalizacion.al_azar()
	aspecto.elegidos["tipo"] = tipo
	aspecto.elegidos["velas"] = "pirata"
	aspecto.elegidos["bandera"] = "jolly_roger"
	aspecto.elegidos["casco"] = "fantasma" if not jefe else "ebano"
	# Proa y popa sencillas: menos piezas por barco, que en el móvil se nota con muchos piratas.
	aspecto.elegidos["proa"] = "sencilla"
	aspecto.elegidos["popa"] = "camarote"
	var barco := mundo._crear_barco(aspecto, false, pos)
	barco.es_bot = true
	barco.es_pirata = true
	barco.agresivo = true
	barco.equipo = 1
	barco.nombre = tr("Jefe pirata") if jefe else tr("Pirata maldito")
	barco.rumbo = barco._angulo_hacia(jugador.pos)
	var d := _dificultad()
	var dureza := (1.0 + d * 2.2) * (6.0 if jefe else 1.0)
	barco.vida_max *= dureza * 0.45
	barco.vida = barco.vida_max
	barco.factor_danio = (0.55 + d * 0.6) * (1.6 if jefe else 1.0)
	barco.factor_recarga = lerpf(1.5, 1.0, d)
	if jefe:
		barco.legendario = true
		barco.modelo.scale *= 1.5
		barco.radio *= 1.5
		barco.vel_max *= 0.85
		barco.set_meta("jefe", true)
	barco.set_meta("almas", {"balandro": 2, "bergantin": 3, "galeon": 5}[tipo] * (10 if jefe else 1))
	# Resplandor espectral de pirata maldito (verde; violeta los jefes).
	mundo.moba._poner_aura(barco, Color("3c0d52") if jefe else Color("0b3d2a"))
	enemigos.append(barco)


# Los hundidos se retiran cuando ya se fueron al fondo, para no acumular barcos.
func _limpiar_hundidos() -> void:
	for i in range(enemigos.size() - 1, -1, -1):
		var barco := enemigos[i]
		if not is_instance_valid(barco):
			enemigos.remove_at(i)
			continue
		if not barco.viva and barco.hundimiento >= 1.0:
			enemigos.remove_at(i)
			mundo.barcos.erase(barco)
			mundo._retirar(barco)
		elif barco.viva and barco.pos.distance_to(mundo.jugador.pos) > 1800.0:
			# Se perdió muy lejos: se recoloca cerca para que no se quede fuera de juego.
			barco.pos = mundo.jugador.pos + Vector2.from_angle(randf() * TAU) * DISTANCIA_APARICION.y


func al_hundirse(barco: Barco, verdugo: Barco) -> void:
	if not activa or barco == mundo.jugador:
		return
	var cuantas: int = barco.get_meta("almas", 1)
	if barco.has_meta("jefe"):
		hundidos_jefe += 1
		mundo.avisar_premio(barco.position + Vector3(0, 4, 0), tr("¡Jefe hundido!"), Color("ffe08a"))
		mundo.ganar_botin(mundo.jugador, 20, barco.position + Vector3(0, 3, 0))
	var _sin_uso := verdugo
	for k in mini(cuantas, 8):
		var valor := ceili(cuantas / float(mini(cuantas, 8)))
		_soltar_alma(barco.pos + Vector2.from_angle(TAU * k / maxf(1.0, mini(cuantas, 8))) * randf_range(10.0, 40.0), valor)


# A quién apunta cada barco: los piratas siempre al jugador (salvo si es invisible).
func rival_de(barco: Barco) -> Barco:
	var jugador := mundo.jugador
	if barco == jugador:
		return _enemigo_cercano(ALCANCE_CANONES * 3.0)
	if jugador == null or not jugador.viva or invisible > 0.0:
		return null
	return jugador


func _enemigo_cercano(alcance: float) -> Barco:
	var jugador := mundo.jugador
	var mejor: Barco
	var mejor_d := alcance
	for barco in enemigos:
		if not barco.viva:
			continue
		var d := barco.pos.distance_to(jugador.pos)
		if d < mejor_d:
			mejor_d = d
			mejor = barco
	return mejor


# El jugador apunta y dispara sus cañones con el botón (como en la Tormenta); las
# bendiciones se suman en Principal.disparar con estas tres funciones.

# Balas de más por la bendición "Andanada": salidas extra a los lados de las normales.
func balas_extra(barco: Barco, direccion: Vector2, salidas: Array[Vector2]) -> void:
	var extra := nivel_de("balas")
	if extra <= 0 or salidas.is_empty():
		return
	var lado := direccion.orthogonal() * barco.radio * 0.35
	var base := salidas[salidas.size() / 2]
	for k in extra:
		var paso := (k / 2 + 1) * (1.0 if k % 2 == 0 else -1.0)
		salidas.append(base + lado * paso)


func tipo_bala() -> String:
	return _tipo_bala()


func vida_bala() -> float:
	return Principal.VIDA_BALA * (1.0 + 0.15 * nivel_de("alcance"))


func _tipo_bala() -> String:
	var tirada := randf()
	var fuego := 0.25 * nivel_de("fuego")
	var explosiva := 0.2 * nivel_de("explosiva")
	var cadena := 0.25 * nivel_de("cadena")
	if tirada < explosiva:
		return "explosiva"
	if tirada < explosiva + fuego:
		return "fuego"
	if tirada < explosiva + fuego + cadena:
		return "cadena"
	return ""


# ---------------------------------------------------------------------------------------
# Poder divino.

func espera_total() -> float:
	return float(PODERES.get(dios.get("id", ""), {"espera": 10.0})["espera"]) * pow(0.85, nivel_de("poder"))


func usar_poder() -> void:
	var jugador := mundo.jugador
	if not activa or eligiendo or jugador == null or not jugador.viva or espera_poder > 0.0:
		return
	espera_poder = espera_total()
	var id: String = dios.get("id", "")
	var color := Color(dios["figura"].get("aura", "ffe08a"))
	var fuerza := 1.0 + 0.3 * nivel_de("furia")
	var figura := jugador.modelo.get_node_or_null("Dios") as FiguraCapitan
	if figura != null:
		figura.invocar()
	mundo.voz_equipar.play()
	match id:
		"quetzalcoatl":
			veloz = 4.0
			_pulso(jugador.pos, 230.0, 14.0 * fuerza, 180.0, color)
		"ares":
			_andanada(16, fuerza)
			get_tree().create_timer(0.35).timeout.connect(_andanada.bind(16, fuerza))
		"atenea":
			invulnerable = 4.0
			jugador.vida = minf(jugador.vida_max, jugador.vida + jugador.vida_max * 0.2)
			_anillo(jugador.pos, 120.0, color, 4.0)
		"ra":
			_pulso(jugador.pos, 270.0, 16.0 * fuerza, 0.0, color, 4.0)
		"anubis":
			for barco in _enemigos_en(jugador.pos, 320.0):
				barco.frenado = maxf(barco.frenado, 4.0)
				barco.recibir_danio(18.0 * fuerza, true, jugador)
			for i in almas_vuelan.size():
				almas_vuelan[i] = true
			_anillo(jugador.pos, 320.0, color, 0.6)
		"bachue":
			jugador.vida = minf(jugador.vida_max, jugador.vida + jugador.vida_max * 0.35)
			mundo._brillo_reparacion(jugador.position + Vector3(0, 0.6, 0))
			_pulso(jugador.pos, 240.0, 16.0 * fuerza, 220.0, color)
		"poseidon":
			var blanco := _enemigo_cercano(450.0)
			var centro := blanco.pos if blanco != null else jugador.pos + jugador.proa() * 220.0
			torbellinos.append({"pos": centro, "queda": 4.0, "radio": 170.0, "danio": 12.0 * fuerza, "color": color, "tic": 0.0})
			_anillo(centro, 170.0, color, 4.0)
		"tiamat":
			var lista := _enemigos_en(jugador.pos, 480.0)
			lista.sort_custom(func(a: Barco, b: Barco) -> bool: return a.pos.distance_squared_to(jugador.pos) < b.pos.distance_squared_to(jugador.pos))
			for k in mini(4, lista.size()):
				var barco: Barco = lista[k]
				barco.recibir_danio(38.0 * fuerza, true, jugador)
				barco.velocidad = 0.0
				barco.frenado = maxf(barco.frenado, 2.0)
				_columna(barco.pos, Color("3fe0d0"), 4.0)
		"pele":
			for k in 6:
				var punto := jugador.pos + Vector2.from_angle(TAU * k / 6.0 + randf() * 0.5) * randf_range(120.0, 300.0)
				get_tree().create_timer(0.12 * k).timeout.connect(_estallido.bind(punto, 95.0, 30.0 * fuerza))
		"loki":
			invisible = 4.0
			_anillo(jugador.pos, 100.0, color, 0.6)
		"odin":
			var blanco := _enemigo_cercano(700.0)
			var dir := (blanco.pos - jugador.pos).normalized() if blanco != null else jugador.proa()
			for barco in enemigos:
				if not barco.viva:
					continue
				var rel := barco.pos - jugador.pos
				var a_lo_largo := rel.dot(dir)
				if a_lo_largo > 0.0 and a_lo_largo < 760.0 and absf(rel.cross(dir)) < barco.radio + 26.0:
					barco.recibir_danio(55.0 * fuerza, true, jugador)
			for k in 14:
				var punto := jugador.pos + dir * (40.0 + k * 52.0)
				mundo.crear_efecto(mundo.malla_humo, Color(color, 0.95), mundo.a_3d(punto, 1.4), Vector3.ZERO, 0.45, 0.7, 1.4)
		"thor":
			var lista := _enemigos_en(jugador.pos, 480.0)
			lista.sort_custom(func(a: Barco, b: Barco) -> bool: return a.pos.distance_squared_to(jugador.pos) < b.pos.distance_squared_to(jugador.pos))
			for k in mini(5, lista.size()):
				var barco: Barco = lista[k]
				get_tree().create_timer(0.08 * k).timeout.connect(_golpe_rayo.bind(barco, 34.0 * fuerza))


func _enemigos_en(centro: Vector2, radio: float) -> Array[Barco]:
	var lista: Array[Barco] = []
	for barco in enemigos:
		if barco.viva and barco.pos.distance_to(centro) <= radio + barco.radio * 0.5:
			lista.append(barco)
	return lista


func _pulso(centro: Vector2, radio: float, danio: float, empuje: float, color: Color, quema := 0.0) -> void:
	var jugador := mundo.jugador
	for barco in _enemigos_en(centro, radio):
		barco.recibir_danio(danio, true, jugador)
		if empuje > 0.0:
			var hacia := (barco.pos - centro).normalized()
			barco.pos += hacia * empuje * 0.6
			barco.velocidad *= 0.3
		if quema > 0.0:
			barco.quemadura = maxf(barco.quemadura, quema)
			barco.quemador = jugador
	mundo.tiburones.explosion(centro, radio, danio, jugador)
	_anillo(centro, radio, color, 0.6)


func _andanada(cuantas: int, fuerza: float) -> void:
	var jugador := mundo.jugador
	if not jugador.viva:
		return
	for k in cuantas:
		var dir := Vector2.from_angle(TAU * k / cuantas)
		mundo.disparar_desde(jugador.pos + dir * jugador.radio * 0.9, dir, jugador, null, 0, Principal.DANIO_BALA * 1.2 * fuerza * jugador.factor_danio)


func _estallido(punto: Vector2, radio: float, danio: float) -> void:
	if not activa:
		return
	var jugador := mundo.jugador
	for barco in _enemigos_en(punto, radio):
		barco.recibir_danio(danio, true, jugador)
		barco.quemadura = maxf(barco.quemadura, 2.0)
		barco.quemador = jugador
	var centro := mundo.a_3d(punto, 0.6)
	mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.85, 0.4, 0.95), centro, Vector3.ZERO, 0.25, 1.4, 4.5)
	mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.35, 0.08, 0.9), centro, Vector3(0, 1.2, 0), 0.5, 1.1, 3.0)
	mundo.salpicar(punto, 10)
	mundo.sonar_explosion(centro)


func _golpe_rayo(barco: Barco, danio: float) -> void:
	if not activa or not is_instance_valid(barco) or not barco.viva:
		return
	barco.recibir_danio(danio, true, mundo.jugador)
	_columna(barco.pos, Color("ffe24a"), 22.0)
	mundo.sonar_explosion(barco.position)


# Haz vertical brillante que cae del cielo (rayo) o sale del agua (tentáculo).
func _columna(punto: Vector2, color: Color, alto: float) -> void:
	var haz := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.45, alto, 0.45)
	haz.mesh = caja
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.lightened(0.3), 0.95)
	haz.material_override = material
	haz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	haz.position = mundo.a_3d(punto, alto / 2.0)
	mundo.add_child(haz)
	var desvanecer := haz.create_tween()
	desvanecer.tween_property(material, "albedo_color:a", 0.0, 0.35)
	desvanecer.parallel().tween_property(haz, "scale:x", 3.0, 0.35)
	desvanecer.tween_callback(haz.queue_free)
	for _i in 6:
		mundo.crear_efecto(mundo.malla_humo, Color(color, 0.9), mundo.a_3d(punto, 0.8), Vector3(randf_range(-1, 1), randf_range(1, 2), randf_range(-1, 1)), 0.5, 0.5, 1.5)


# Anillo de luz sobre el agua que se abre y se apaga.
func _anillo(centro: Vector2, radio: float, color: Color, dura: float) -> void:
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.9
	toro.outer_radius = 1.0
	toro.rings = 40
	toro.ring_segments = 4
	aro.mesh = toro
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(color, 0.9)
	aro.material_override = material
	aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var r := radio * Principal.ESCALA
	aro.scale = Vector3(r * 0.3, 0.6, r * 0.3)
	aro.position = mundo.a_3d(centro, 0.25)
	mundo.add_child(aro)
	var animar := aro.create_tween()
	animar.tween_property(aro, "scale", Vector3(r, 0.6, r), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animar.tween_interval(maxf(0.0, dura - 0.6))
	animar.tween_property(material, "albedo_color:a", 0.0, 0.3)
	animar.tween_callback(aro.queue_free)
	for k in 12:
		var hacia := Vector2.from_angle(TAU * k / 12.0)
		mundo.crear_efecto(mundo.malla_humo, Color(color, 0.85), mundo.a_3d(centro + hacia * radio * 0.35, 0.5), Vector3(hacia.x, 0.2, hacia.y) * radio * Principal.ESCALA * 1.5, 0.4, 0.6, 2.0)


func _mover_torbellinos(delta: float) -> void:
	var jugador := mundo.jugador
	for t in torbellinos:
		t["queda"] = float(t["queda"]) - delta
		t["tic"] = float(t["tic"]) - delta
		var centro: Vector2 = t["pos"]
		for barco in _enemigos_en(centro, float(t["radio"])):
			barco.pos = barco.pos.move_toward(centro, 90.0 * delta)
			barco.velocidad *= 0.9
			if float(t["tic"]) <= 0.0:
				barco.recibir_danio(float(t["danio"]) * 0.5, false, jugador)
		if float(t["tic"]) <= 0.0:
			t["tic"] = 0.5
			mundo.salpicar(centro + Vector2.from_angle(randf() * TAU) * float(t["radio"]) * 0.6, 4)
	torbellinos = torbellinos.filter(func(t: Dictionary) -> bool: return float(t["queda"]) > 0.0)


# ---------------------------------------------------------------------------------------
# Almas y niveles.

func _vaciar_almas() -> void:
	almas_pos.clear()
	almas_valor.clear()
	almas_vuelan.clear()
	if multi_almas != null:
		multi_almas.multimesh.visible_instance_count = 0


func _soltar_alma(pos: Vector2, valor: int) -> void:
	if almas_pos.size() >= MAX_ALMAS:
		# Si hay demasiadas, la nueva se suma a la más vieja.
		almas_valor[0] += valor
		return
	almas_pos.append(pos)
	almas_valor.append(valor)
	almas_vuelan.append(false)


func almas_para(n: int) -> int:
	return 3 + n * 2 + int(n * n * 0.08)


func _mover_almas(delta: float) -> void:
	var jugador := mundo.jugador
	var iman := RADIO_IMAN * (1.0 + 0.35 * nivel_de("iman"))
	var mm := multi_almas.multimesh
	var i := 0
	var visibles := 0
	while i < almas_pos.size():
		var pos := almas_pos[i]
		var d := pos.distance_to(jugador.pos)
		if jugador.viva and d < iman:
			almas_vuelan[i] = true
		if almas_vuelan[i] and jugador.viva:
			pos = pos.move_toward(jugador.pos, VEL_ALMA * delta * (1.0 + 2.0 * clampf(1.0 - d / iman, 0.0, 1.0)))
			almas_pos[i] = pos
			if pos.distance_to(jugador.pos) < jugador.radio * 0.6:
				_sumar_almas(almas_valor[i])
				almas_pos.remove_at(i)
				almas_valor.remove_at(i)
				almas_vuelan.remove_at(i)
				continue
		var altura := 0.7 + sin(tiempo * 4.0 + pos.x * 0.05) * 0.18
		var tam := 1.0 + minf(almas_valor[i], 6) * 0.15
		mm.set_instance_transform(visibles, Transform3D(Basis().scaled(Vector3.ONE * tam), mundo.a_3d(pos, altura)))
		visibles += 1
		i += 1
	mm.visible_instance_count = visibles


func _sumar_almas(valor: int) -> void:
	almas += valor
	mundo.voz_moneda.pitch_scale = randf_range(1.3, 1.6)
	mundo.voz_moneda.play()
	if almas >= almas_para(nivel):
		almas -= almas_para(nivel)
		nivel += 1
		_abrir_bendiciones()


func _abrir_bendiciones() -> void:
	var posibles: Array[String] = []
	for clave: String in BENDICIONES:
		if nivel_de(clave) < int(BENDICIONES[clave]["max"]):
			posibles.append(clave)
	if posibles.is_empty():
		mundo.jugador.vida = minf(mundo.jugador.vida_max, mundo.jugador.vida + mundo.jugador.vida_max * 0.2)
		return
	posibles.shuffle()
	opciones = posibles.slice(0, 3)
	eligiendo = true
	titulo_nivel.text = tr("¡Nivel %d! Elige una bendición") % nivel
	for k in cartas.size():
		cartas[k].visible = k < opciones.size()
		cartas[k].queue_redraw()
	panel_nivel.visible = true
	mundo.voz_equipar.play()


func elegir_bendicion(k: int) -> void:
	if not eligiendo or k >= opciones.size():
		return
	var clave := opciones[k]
	niveles[clave] = nivel_de(clave) + 1
	var jugador := mundo.jugador
	match clave:
		"casco":
			jugador.vida_max *= 1.2
			jugador.vida = minf(jugador.vida_max, jugador.vida + jugador.vida_max * 0.3)
		"velas":
			jugador.vel_max *= 1.1
	eligiendo = false
	panel_nivel.visible = false
	mundo.avisar_premio(jugador.position + Vector3(0, 3, 0), tr(BENDICIONES[clave]["nombre"]), BENDICIONES[clave]["color"])


# ---------------------------------------------------------------------------------------
# Final de partida.

func terminar() -> void:
	if not activa:
		return
	var jugador := mundo.jugador
	jugador.botin += int(tiempo / 60.0) * MONEDAS_POR_MINUTO
	if tiempo > mejor_tiempo or mundo.hundidos > mejor_hundidos:
		record_nuevo = tiempo > mejor_tiempo
		mejor_tiempo = maxf(mejor_tiempo, tiempo)
		mejor_hundidos = maxi(mejor_hundidos, mundo.hundidos)
		_guardar()
	activa = false
	hud.visible = false
	panel_nivel.visible = false


func texto_final() -> String:
	var lineas: Array[String] = []
	lineas.append(tr("Aguantaste %s · nivel %d · %d piratas hundidos") % [_reloj(tiempo), nivel, mundo.hundidos])
	if hundidos_jefe > 0:
		lineas.append(tr("Jefes hundidos: %d") % hundidos_jefe)
	if record_nuevo:
		lineas.append(tr("¡Nuevo récord!"))
	return "\n".join(lineas)


func puesto() -> int:
	return 1 if ganado else clampi(12 - int(tiempo / 60.0), 2, 12)


func _reloj(segundos: float) -> String:
	return "%d:%02d" % [int(segundos) / 60, int(segundos) % 60]


func texto_estado() -> String:
	return tr("Hundidos: %d") % mundo.hundidos


func texto_aviso() -> String:
	if ganado:
		return tr("¡Aguantaste 10 minutos!")
	var siguiente := ""
	if jefes_lanzados < JEFES.size():
		siguiente = "  ·  " + tr("Jefe en %s") % _reloj(JEFES[jefes_lanzados] - tiempo)
	return _reloj(maxf(0.0, DURACION - tiempo)) + siguiente


# ---------------------------------------------------------------------------------------
# Interfaz: barra de almas, botón del poder divino y cartas de bendición.

func crear_interfaz(capa: CanvasLayer) -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_dibujar_hud)
	hud.visible = false
	capa.add_child(hud)
	panel_nivel = PanelContainer.new()
	panel_nivel.add_theme_stylebox_override("panel", Ui.estilo_panel())
	panel_nivel.set_anchors_preset(Control.PRESET_CENTER)
	panel_nivel.anchor_left = 0.5
	panel_nivel.anchor_right = 0.5
	panel_nivel.anchor_top = 0.5
	panel_nivel.anchor_bottom = 0.5
	panel_nivel.offset_left = -500
	panel_nivel.offset_right = 500
	panel_nivel.offset_top = -210
	panel_nivel.offset_bottom = 210
	panel_nivel.visible = false
	capa.add_child(panel_nivel)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 16)
	panel_nivel.add_child(cuerpo)
	titulo_nivel = Ui.etiqueta_panel("", 32, Principal.COLOR_ORO)
	titulo_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cuerpo.add_child(titulo_nivel)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(fila)
	for k in 3:
		var carta := Button.new()
		carta.focus_mode = Control.FOCUS_NONE
		carta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		carta.size_flags_vertical = Control.SIZE_EXPAND_FILL
		Ui.estilo_boton(carta, false)
		carta.draw.connect(_dibujar_carta.bind(carta, k))
		carta.pressed.connect(elegir_bendicion.bind(k))
		fila.add_child(carta)
		cartas.append(carta)


func _dibujar_carta(carta: Button, k: int) -> void:
	if k >= opciones.size():
		return
	var clave := opciones[k]
	var datos: Dictionary = BENDICIONES[clave]
	var color: Color = datos["color"]
	var ancho := carta.size.x
	var fuente := ThemeDB.fallback_font
	var c := Vector2(ancho / 2.0, 70.0)
	carta.draw_circle(c, 44.0, color.darkened(0.55))
	carta.draw_circle(c, 38.0, color)
	carta.draw_arc(c, 44.0, 0, TAU, 40, Principal.COLOR_ORO, 3.0, true)
	_dibujar_icono(carta, clave, c, color.darkened(0.6))
	carta.draw_string(fuente, Vector2(8, 150), tr(datos["nombre"]), HORIZONTAL_ALIGNMENT_CENTER, ancho - 16, 24, Principal.COLOR_TEXTO)
	var lineas := _partir(tr(datos["info"]), fuente, 18, ancho - 30)
	for i in lineas.size():
		carta.draw_string(fuente, Vector2(15, 186 + i * 24), lineas[i], HORIZONTAL_ALIGNMENT_CENTER, ancho - 30, 18, Color("c9d1d3"))
	var nv := nivel_de(clave)
	for i in int(datos["max"]):
		var punto := Vector2(ancho / 2.0 + (i - (int(datos["max"]) - 1) / 2.0) * 22.0, carta.size.y - 26)
		carta.draw_circle(punto, 7.0, Principal.COLOR_ORO if i <= nv else Color(1, 1, 1, 0.18))
		if i == nv:
			carta.draw_arc(punto, 10.0, 0, TAU, 20, Color.WHITE, 2.0, true)


# Dibujo sencillo de cada bendición dentro del círculo.
func _dibujar_icono(lienzo: CanvasItem, clave: String, c: Vector2, tinta: Color) -> void:
	match clave:
		"canones", "balas", "recarga", "alcance":
			lienzo.draw_rect(Rect2(c + Vector2(-18, -6), Vector2(30, 12)), tinta)
			lienzo.draw_circle(c + Vector2(-16, 10), 7.0, tinta)
			lienzo.draw_circle(c + Vector2(22, 0), 5.0, tinta)
			if clave == "balas":
				lienzo.draw_circle(c + Vector2(22, -12), 4.0, tinta)
				lienzo.draw_circle(c + Vector2(22, 12), 4.0, tinta)
		"casco", "armadura":
			lienzo.draw_colored_polygon(PackedVector2Array([c + Vector2(-18, -18), c + Vector2(18, -18), c + Vector2(16, 4), c + Vector2(0, 22), c + Vector2(-16, 4)]), tinta)
		"velas":
			lienzo.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -22), c + Vector2(18, 12), c + Vector2(-4, 12)]), tinta)
			lienzo.draw_line(c + Vector2(-6, -24), c + Vector2(-6, 20), tinta, 3.0)
		"regenera":
			lienzo.draw_rect(Rect2(c + Vector2(-6, -18), Vector2(12, 36)), tinta)
			lienzo.draw_rect(Rect2(c + Vector2(-18, -6), Vector2(36, 12)), tinta)
		"iman":
			lienzo.draw_arc(c, 16.0, PI, TAU, 16, tinta, 9.0)
			lienzo.draw_rect(Rect2(c + Vector2(-21, 0), Vector2(10, 12)), tinta)
			lienzo.draw_rect(Rect2(c + Vector2(11, 0), Vector2(10, 12)), tinta)
		"poder", "furia":
			lienzo.draw_colored_polygon(PackedVector2Array([c + Vector2(4, -22), c + Vector2(-12, 4), c + Vector2(0, 4), c + Vector2(-4, 22), c + Vector2(12, -4), c + Vector2(0, -4)]), tinta)
		"fuego", "explosiva":
			lienzo.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -22), c + Vector2(14, 4), c + Vector2(8, 18), c + Vector2(-8, 18), c + Vector2(-14, 4)]), tinta)
		"cadena":
			lienzo.draw_arc(c + Vector2(-8, 0), 9.0, 0, TAU, 16, tinta, 4.0)
			lienzo.draw_arc(c + Vector2(8, 0), 9.0, 0, TAU, 16, tinta, 4.0)


func _partir(texto: String, fuente: Font, tam: int, ancho: float) -> Array[String]:
	var lineas: Array[String] = []
	var actual := ""
	for palabra in texto.split(" "):
		var prueba := palabra if actual == "" else actual + " " + palabra
		if fuente.get_string_size(prueba, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho and actual != "":
			lineas.append(actual)
			actual = palabra
		else:
			actual = prueba
	if actual != "":
		lineas.append(actual)
	return lineas


func _boton_poder() -> Array:
	var tam := hud.size
	var escala := mundo.escala_controles
	var radio := 50.0 * maxf(escala, 0.8)
	# El botón de cañones queda abajo a la derecha; el poder va a su izquierda, un poco más arriba.
	var canones := tam + Moba.BOTON_CANONES * escala
	return [canones + Vector2(-(Moba.RADIO_CANONES * escala + radio + 30.0), -radio * 0.6), radio]


func _dibujar_hud() -> void:
	if not activa or mundo.jugador == null:
		return
	var tam := hud.size
	var fuente := ThemeDB.fallback_font
	# Barra de almas a lo ancho, arriba del todo, con el nivel en una insignia.
	var parte := clampf(almas / float(almas_para(nivel)), 0.0, 1.0)
	var barra := Rect2(Vector2(tam.x * 0.25, 6), Vector2(tam.x * 0.5, 14))
	hud.draw_rect(barra.grow(2), Color(0, 0, 0, 0.55))
	hud.draw_rect(Rect2(barra.position, Vector2(barra.size.x * parte, barra.size.y)), Color("8ff0ff"))
	hud.draw_circle(barra.position + Vector2(-4, 7), 20.0, Color("0b2733"))
	hud.draw_arc(barra.position + Vector2(-4, 7), 20.0, 0, TAU, 32, Color("8ff0ff"), 2.5, true)
	hud.draw_string(fuente, barra.position + Vector2(-24, 14), str(nivel), HORIZONTAL_ALIGNMENT_CENTER, 40, 20, Color.WHITE)
	# Reloj grande debajo.
	hud.draw_string_outline(fuente, Vector2(0, 58), _reloj(maxf(0.0, DURACION - tiempo)), HORIZONTAL_ALIGNMENT_CENTER, tam.x, 30, 7, Color(0, 0, 0, 0.6))
	hud.draw_string(fuente, Vector2(0, 58), _reloj(maxf(0.0, DURACION - tiempo)), HORIZONTAL_ALIGNMENT_CENTER, tam.x, 30, Color.WHITE)
	# Botón del poder divino con el retrato del dios.
	var boton := _boton_poder()
	var c: Vector2 = boton[0]
	var r: float = boton[1]
	var color := Color(dios["figura"].get("aura", "ffe08a"))
	var listo := espera_poder <= 0.0 and mundo.jugador.viva
	hud.draw_circle(c, r + 6.0, Color(0, 0, 0, 0.45))
	if listo:
		hud.draw_circle(c, r + 4.0 + sin(tiempo * 6.0) * 3.0, Color(color, 0.45))
	Moba.dibujar_retrato(hud, c, r - 4.0, dios["figura"])
	if not listo:
		hud.draw_circle(c, r, Color(0, 0, 0, 0.55))
		var avance := 1.0 - espera_poder / espera_total()
		hud.draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * avance, 48, color, 6.0, true)
		hud.draw_string_outline(fuente, c + Vector2(-r, 12), str(ceili(espera_poder)), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 34, 6, Color(0, 0, 0, 0.8))
		hud.draw_string(fuente, c + Vector2(-r, 12), str(ceili(espera_poder)), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 34, Color.WHITE)
	else:
		hud.draw_arc(c, r, 0, TAU, 48, Principal.COLOR_ORO, 4.0, true)
	var nombre := nombre_poder(dios.get("id", ""))
	hud.draw_string_outline(fuente, c + Vector2(-110, -r - 10), nombre, HORIZONTAL_ALIGNMENT_CENTER, 220, 16, 5, Color(0, 0, 0, 0.8))
	hud.draw_string(fuente, c + Vector2(-110, -r - 10), nombre, HORIZONTAL_ALIGNMENT_CENTER, 220, 16, Principal.COLOR_ORO)
	if invulnerable > 0.0 or invisible > 0.0 or veloz > 0.0:
		var queda := maxf(invulnerable, maxf(invisible, veloz))
		hud.draw_string(fuente, Vector2(0, 92), "%s %d" % [nombre, ceili(queda)], HORIZONTAL_ALIGNMENT_CENTER, tam.x, 18, color)


func animar(_delta: float) -> void:
	if hud != null and hud.visible:
		hud.queue_redraw()
	if multi_almas != null:
		multi_almas.visible = activa


# Toque en el botón del poder (o Espacio/Q en el teclado). Devuelve true si lo usó.
func toque(evento: InputEvent) -> bool:
	if not activa or eligiendo:
		return false
	if evento is InputEventKey:
		var tecla := evento as InputEventKey
		if tecla.pressed and not tecla.echo and (tecla.physical_keycode == KEY_Q or tecla.physical_keycode == KEY_E):
			usar_poder()
			return true
		return false
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		var boton := _boton_poder()
		if (evento as InputEventScreenTouch).position.distance_to(boton[0]) < float(boton[1]) + 14.0:
			usar_poder()
			return true
	return false
