class_name AmbientePuerto
extends Node

# Sonido del mar: olas en el puerto y, al navegar, olas más lejanas, el agua que corre por
# el casco según la velocidad y algún golpecito de ola suelto. Todo entra y sale poco a poco.

const VOLUMEN := -18.0
const VOLUMEN_MAR := -25.0
const ENTRADA := 1.5
const CASCO_LENTO := -36.0
const CASCO_RAPIDO := -23.0
const CHAPOTEO := Vector2(-31.0, -24.0)
const ESPERA_CHAPOTEO := Vector2(2.5, 7.0)

var mundo: Principal
var olas: AudioStreamPlayer
var casco: AudioStreamPlayer
var chapoteos: Array[AudioStreamPlayer] = []
var presencia := 0.0
var en_mar := 0.0
var marcha := 0.0
var espera_chapoteo := 3.0


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	olas = _nueva_voz(Sonidos.olas())
	casco = _nueva_voz(Sonidos.agua_casco())
	for _i in 3:
		chapoteos.append(_nueva_voz(Sonidos.chapoteo()))


func _nueva_voz(sonido: AudioStream) -> AudioStreamPlayer:
	var voz := AudioStreamPlayer.new()
	voz.stream = sonido
	voz.bus = "Efectos"
	add_child(voz)
	return voz


func _process(delta: float) -> void:
	var jugador: Barco = mundo.jugador if is_instance_valid(mundo.jugador) else null
	var navegando := jugador != null and not mundo.en_puerto()
	presencia = move_toward(presencia, 1.0 if jugador != null else 0.0, delta / ENTRADA)
	en_mar = move_toward(en_mar, 1.0 if navegando else 0.0, delta / ENTRADA)
	_sonar(olas, presencia, lerpf(VOLUMEN, VOLUMEN_MAR, en_mar))
	var rapidez := 0.0
	if navegando and jugador.viva:
		rapidez = clampf(absf(jugador.velocidad) / jugador.vel_max, 0.0, 1.0)
	marcha = move_toward(marcha, rapidez, delta * 0.8)
	_sonar(casco, en_mar * smoothstep(0.03, 0.35, marcha), lerpf(CASCO_LENTO, CASCO_RAPIDO, marcha))
	casco.pitch_scale = lerpf(0.94, 1.05, marcha)
	if not navegando or not jugador.viva:
		return
	espera_chapoteo -= delta
	if espera_chapoteo > 0.0:
		return
	espera_chapoteo = randf_range(ESPERA_CHAPOTEO.x, ESPERA_CHAPOTEO.y) - marcha * 1.5
	for voz in chapoteos:
		if not voz.playing:
			voz.volume_db = randf_range(CHAPOTEO.x, CHAPOTEO.y) + marcha * 3.0 + linear_to_db(maxf(en_mar, 0.001))
			voz.pitch_scale = randf_range(0.85, 1.2)
			voz.play()
			break


func _sonar(voz: AudioStreamPlayer, nivel: float, volumen: float) -> void:
	if nivel <= 0.0:
		if voz.playing:
			voz.stop()
		return
	if not voz.playing:
		voz.play(randf() * voz.stream.get_length())
	voz.volume_db = volumen + linear_to_db(maxf(nivel, 0.001))
