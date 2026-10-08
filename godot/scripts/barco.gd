class_name Barco
extends Node3D

const TIPOS := {
	"balandro": {"vida": 80.0, "velocidad": 48.0, "giro": 1.0, "radio": 26.0, "altura": 4.6},
	"bergantin": {"vida": 105.0, "velocidad": 40.0, "giro": 0.85, "radio": 32.0, "altura": 5.4},
	"galeon": {"vida": 145.0, "velocidad": 32.0, "giro": 0.7, "radio": 40.0, "altura": 6.4},
}

enum Mando { BOT, LOCAL, REMOTO }

var mundo: Principal
var tipo := "bergantin"
var es_jugador := false
var nombre := ""
var id := 0
var peer := 0
var mando := Mando.BOT
var entrada_direccion := Vector2.ZERO
var entrada_fuego: Array[String] = []
var red_pos := Vector2.ZERO
var red_rumbo := 0.0
var ultimo_atacante: Barco
var hora_ataque := 0
var pos := Vector2.ZERO
var rumbo := 0.0
var vel_giro := 0.0
var velocidad := 0.0
var acelerador := 0.0
var vida := 100.0
var vida_max := 100.0
var vel_max := 100.0
var giro_max := 1.35
var radio := 32.0
var altura := 5.4
# Segundos que le faltan a cada arma: "proa", "babor" (izquierda) y "estribor" (derecha).
var recargas := {"proa": 0.0, "babor": 0.0, "estribor": 0.0}
var espera_roca := 0.0
var espera_choque := 0.0
var viva := true
var hundimiento := 0.0
var deriva := 0.0
# Tiempo aún sin calcular de un bot lejano, que se pone al día cada pocos cuadros.
var pendiente := 0.0
var temporizador_estela := 0.0
var fase_oleaje := 0.0
var cabeceo_ola := 0.0
var escora_ola := 0.0
var fase_proa := 0.0
# Monedas que lleva en la bodega durante la partida; al hundirse cae la mitad en un cofre.
var botin := 0
# Tesoros a la vista en la cubierta ("cofre", "calavera"); se venden en los puertos.
var tesoros: Array[String] = []
# Solo a los bots se les muestra el botín encima: el de las personas queda en secreto.
var es_bot := false
# Modo libre: los piratas atacan a todos y dan recompensa; los agresivos atacan a quien pase.
var es_pirata := false
var agresivo := false
var recompensa := 0
var destino_libre := Vector2.INF
# Segundos que le quedan con las velas rotas (bala encadenada) y ardiendo (bala de fuego).
var frenado := 0.0
var quemadura := 0.0
var quemador: Barco
# Mar libre: cazadores que persiguen al jugador buscado y barcos legendarios (jefes).
var cazador := false
var legendario := false
var fantasma := false
# Mar libre: nombre del encargo del tablón de recompensas que lleva este pirata.
var objetivo := ""
# Armada en el modo MOBA (0 azul, 1 roja); -1 fuera de ese modo.
var equipo := -1
var factor_defensa := 1.0
# Mejoras (mar libre) o refuerzos de jefe: multiplican el daño de sus balas y la recarga.
var factor_danio := 1.0
var factor_recarga := 1.0
# MOBA: acelera, frena y responde al timón más rápido.
var agil := false
var modelo: Node3D
var desgaste: Desgaste
var aro: MeshInstance3D


func preparar(aspecto: Personalizacion, jugador: bool, nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	es_jugador = jugador
	mando = Mando.LOCAL if jugador else Mando.BOT
	fase_oleaje = randf() * TAU
	deriva = randf() * TAU
	for arma in recargas:
		recargas[arma] = 0.2
	vestir(aspecto)


func vestir(aspecto: Personalizacion) -> void:
	tipo = aspecto.tipo
	var datos: Dictionary = TIPOS[tipo]
	vida_max = datos["vida"]
	vida = vida_max
	frenado = 0.0
	quemadura = 0.0
	quemador = null
	factor_danio = 1.0
	factor_recarga = 1.0
	factor_defensa = 1.0
	agil = false
	vel_max = datos["velocidad"]
	giro_max = datos["giro"]
	radio = datos["radio"]
	altura = datos["altura"]
	if modelo != null:
		modelo.queue_free()
	modelo = ModeloBarco.crear(aspecto)
	add_child(modelo)
	if desgaste != null:
		desgaste.queue_free()
	desgaste = Desgaste.new()
	add_child(desgaste)
	desgaste.preparar(mundo, tipo)
	if es_jugador:
		_crear_aro()


func _crear_aro() -> void:
	if aro != null:
		aro.queue_free()
	var toro := TorusMesh.new()
	toro.inner_radius = radio * Principal.ESCALA * 1.3
	toro.outer_radius = toro.inner_radius + 0.16
	toro.rings = 48
	toro.ring_segments = 6
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.45, 1.0, 0.7, 0.6)
	aro = MeshInstance3D.new()
	aro.mesh = toro
	aro.material_override = material
	aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	aro.top_level = true
	add_child(aro)


func proa() -> Vector2:
	return Vector2.UP.rotated(rumbo)


func actualizar(delta: float) -> void:
	if not viva:
		return
	for arma in recargas:
		recargas[arma] = maxf(0.0, recargas[arma] - delta)
	deriva += delta * 0.6

	match mando:
		Mando.LOCAL:
			# En el MOBA, con el piloto automático navega como un bot hasta que se toca la palanca.
			var direccion := mundo.direccion_jugador()
			if mundo.modo == "moba" and mundo.moba.auto and direccion != Vector2.ZERO:
				mundo.moba.cambiar_auto()
			if mundo.modo == "moba" and mundo.moba.auto:
				mundo.moba.pilotar(self, delta)
			else:
				_pilotar(direccion, mundo.armas_jugador(), delta)
		Mando.REMOTO:
			_pilotar(entrada_direccion, entrada_fuego, delta)
		_:
			_pilotar_rival(delta)

	velocidad += (acelerador * vel_max - velocidad) * minf(1.0, delta * (1.4 if agil else 0.5))
	if frenado > 0.0:
		frenado -= delta
		velocidad = minf(velocidad, vel_max * Comercio.FRENO)
	if quemadura > 0.0:
		quemadura -= delta
		recibir_danio(Comercio.DANIO_FUEGO * delta, false, quemador)
		if not viva:
			return
	rumbo = wrapf(rumbo + vel_giro * delta, -PI, PI)
	pos += proa() * velocidad * delta

	var limite := mundo.radio_mundo()
	if pos.length() > limite:
		pos = pos.limit_length(limite)

	espera_roca = maxf(0.0, espera_roca - delta)
	espera_choque = maxf(0.0, espera_choque - delta)
	for isla in mundo.islas.cerca(pos, radio * 0.7):
		var separacion: Vector2 = pos - isla.pos
		# El borde nunca pasa del radio: las islas lejanas se descartan sin calcularlo.
		var alcance: float = isla.radio + radio * 0.7
		if separacion.length_squared() >= alcance * alcance:
			continue
		var minimo: float = isla.borde(pos) + radio * 0.7
		if separacion.length() < minimo and separacion != Vector2.ZERO:
			pos = isla.pos + separacion.normalized() * minimo
			if isla.radio <= Islas.RADIO_ROCAS:
				_chocar_roca(-proa().dot(separacion.normalized()) * velocidad / vel_max)
			velocidad *= 0.96

	var dist_zona := pos.distance_to(mundo.zona_centro)
	if dist_zona > mundo.zona_radio:
		var profundidad := (dist_zona - mundo.zona_radio) / 180.0
		recibir_danio((10.0 + profundidad * 20.0) * delta)
		if es_jugador:
			mundo.golpe = maxf(mundo.golpe, 0.06)

	_dejar_estela(delta)


func seguir_red(delta: float) -> void:
	if pos.distance_to(red_pos) > 120.0:
		pos = red_pos
	pos = pos.lerp(red_pos, minf(1.0, delta * 10.0))
	rumbo = lerp_angle(rumbo, red_rumbo, minf(1.0, delta * 10.0))
	if viva:
		_dejar_estela(delta)


func _dejar_estela(delta: float) -> void:
	temporizador_estela -= delta
	if velocidad > 10.0 and temporizador_estela <= 0.0:
		temporizador_estela = 0.13
		mundo.dejar_estela(pos - proa() * radio * 0.95, velocidad / vel_max)
		mundo.ola_proa(pos + proa() * radio * 0.9, rumbo, clampf(velocidad / vel_max, 0.0, 1.0))


func colocar(delta: float) -> void:
	var t := mundo.tiempo
	if not viva:
		hundimiento = minf(1.0, hundimiento + delta * 0.35)
		velocidad = maxf(0.0, velocidad - delta * 40.0)
		if hundimiento >= 1.0:
			visible = false
	var marcha := clampf(velocidad / vel_max, 0.0, 1.0)
	var centro := pos * Principal.ESCALA
	var largo := radio * Principal.ESCALA * 1.1
	var manga := largo * 0.45
	var adelante := proa() * largo
	var costado := proa().rotated(PI / 2.0) * manga
	var h_proa := mundo.altura_mar(centro.x + adelante.x, centro.y + adelante.y)
	var h_popa := mundo.altura_mar(centro.x - adelante.x, centro.y - adelante.y)
	var h_estribor := mundo.altura_mar(centro.x + costado.x, centro.y + costado.y)
	var h_babor := mundo.altura_mar(centro.x - costado.x, centro.y - costado.y)
	var h_centro := mundo.altura_mar(centro.x, centro.y)
	var flotacion := (h_proa + h_popa + h_estribor + h_babor + h_centro * 2.0) / 6.0
	var suave := minf(1.0, delta * 6.0) if delta > 0.0 else 1.0
	cabeceo_ola = lerpf(cabeceo_ola, atan2(h_proa - h_popa, largo * 2.0), suave)
	escora_ola = lerpf(escora_ola, atan2(h_estribor - h_babor, manga * 2.0) * 0.8, suave)
	# Vaivén de proa: con más marcha la proa sube y cae más a menudo y salpica al hundirse.
	var antes := cos(fase_proa)
	fase_proa = wrapf(fase_proa + delta * (1.5 + 2.4 * marcha), 0.0, TAU)
	var vaiven := sin(fase_proa)
	if viva and marcha > 0.35 and antes < 0.0 and cos(fase_proa) >= 0.0:
		mundo.rociar_proa(pos + proa() * radio * 1.05, rumbo, marcha)
	var cabeceo := cabeceo_ola - marcha * 0.02 + vaiven * (0.01 + 0.045 * marcha) + sin(t * 1.2 + fase_oleaje) * 0.01
	var escora := escora_ola + vel_giro * 0.18 * marcha
	position = Vector3(centro.x, flotacion + vaiven * 0.06 * marcha - hundimiento * 2.6, centro.y)
	rotation = Vector3(cabeceo + hundimiento * 0.35, -rumbo, escora + hundimiento * 0.8)
	desgaste.actualizar(delta, 1.0 - vida / vida_max, hundimiento)
	if aro != null:
		aro.visible = viva and not mundo.en_puerto()
		aro.global_position = Vector3(position.x, h_centro + 0.14, position.z)


func recibir_danio(cantidad: float, de_bala := false, atacante: Barco = null) -> void:
	if not viva:
		return
	vida -= cantidad * factor_defensa
	if atacante != null:
		ultimo_atacante = atacante
		hora_ataque = Time.get_ticks_msec()
		if atacante == mundo.jugador and mundo.modo == "libre":
			mundo.persecucion.al_golpear(self, cantidad)
	if de_bala:
		mundo.astillas(position + Vector3(0, 0.9, 0))
	if vida <= 0.0:
		vida = 0.0
		viva = false
		mundo.al_hundirse(self)


# "fuerza" va de 0 (roce de lado o parado) a 1 (de frente a toda vela).
func _chocar_roca(fuerza: float) -> void:
	if espera_roca > 0.0 or fuerza < 0.3:
		return
	espera_roca = 1.0
	velocidad *= 0.45
	recibir_danio(lerpf(2.0, 5.0, clampf((fuerza - 0.3) / 0.7, 0.0, 1.0)))
	mundo.astillas(position + Vector3(0, 0.5, 0))
	if es_jugador:
		mundo.golpe = maxf(mundo.golpe, 0.15)


# Choque contra otro barco, con la misma escala de daño que las rocas. "fuerza" va de 0
# (roce) a 1 (embestida a toda vela); quien embiste también sufre.
func chocar_barco(fuerza: float, otro: Barco) -> void:
	if espera_choque > 0.0 or fuerza < 0.25:
		return
	espera_choque = 1.0
	recibir_danio(lerpf(1.5, 4.0, clampf((fuerza - 0.25) / 0.75, 0.0, 1.0)), false, otro)
	mundo.astillas(position + Vector3(0, 0.5, 0))
	if es_jugador:
		mundo.golpe = maxf(mundo.golpe, 0.15)


func _pilotar(direccion: Vector2, armas: Array[String], delta: float) -> void:
	if direccion != Vector2.ZERO:
		_girar_hacia(atan2(direccion.x, -direccion.y), 1.0, delta)
		acelerador = minf(1.0, direccion.length())
	else:
		_girar_hacia(rumbo, 0.0, delta)
		acelerador = 0.0
	for arma in armas:
		mundo.disparar(self, arma)


func _pilotar_rival(delta: float) -> void:
	if mundo.modo == "moba":
		mundo.moba.pilotar(self, delta)
		return
	var destino := mundo.destino_bot(self)
	var blanco: Barco = null

	var cofre = mundo.cofre_cercano(self, 520.0)
	if pos.distance_to(mundo.zona_centro) > mundo.zona_radio - 130.0:
		destino = mundo.zona_centro
	elif cofre != null:
		destino = cofre
	elif vida < vida_max * 0.48:
		var tabla = mundo.tabla_cercana(self)
		if tabla != null:
			destino = tabla
		else:
			blanco = mundo.rival_de(self)
	else:
		blanco = mundo.rival_de(self)

	var rumbo_deseado := _angulo_hacia(destino)
	if blanco != null:
		var dist := pos.distance_to(blanco.pos)
		var adelanto := dist / Principal.VEL_BALA
		var previsto := blanco.pos + blanco.proa() * blanco.velocidad * adelanto * 0.85
		# Ángulo del blanco respecto a la proa: positivo a estribor, negativo a babor.
		var angulo := angle_difference(rumbo, _angulo_hacia(previsto))
		if dist < 140.0:
			rumbo_deseado = _angulo_hacia(pos - (previsto - pos))
		elif dist < 280.0:
			rumbo_deseado = _angulo_hacia(previsto) - signf(angulo) * PI / 2.0
		else:
			rumbo_deseado = _angulo_hacia(previsto)
		if dist < 320.0 and dist > 50.0:
			if absf(angulo) < 0.2:
				mundo.disparar(self, "proa")
			if absf(angulo - PI / 2.0) < 0.3:
				mundo.disparar(self, "estribor")
			if absf(angulo + PI / 2.0) < 0.3:
				mundo.disparar(self, "babor")

	var huida := mundo.peligros.evitar(self) + mundo.barriles.evitar(self)
	if huida != Vector2.ZERO:
		rumbo_deseado = _angulo_hacia(pos + huida)
	_girar_hacia(rumbo_deseado + sin(deriva) * 0.15, 1.0, delta)
	acelerador = 1.0


func _angulo_hacia(punto: Vector2) -> float:
	var d := punto - pos
	return atan2(d.x, -d.y)


func _girar_hacia(angulo: float, fuerza: float, delta: float) -> void:
	var diferencia := angle_difference(rumbo, angulo)
	var marcha := (0.7 if agil else 0.45) + (0.3 if agil else 0.55) * clampf(velocidad / vel_max, 0.0, 1.0)
	var objetivo := clampf(diferencia * (3.0 if agil else 2.0), -giro_max, giro_max) * fuerza * marcha
	vel_giro = lerpf(vel_giro, objetivo, minf(1.0, delta * (4.0 if agil else 1.8)))
