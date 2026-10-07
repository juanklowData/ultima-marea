class_name Musica
extends Node

# Música grabada (ver CREDITOS.md). En la partida suenan a la vez la pista
# tranquila y la de batalla, y se cruzan según "batalla".

const PISTAS := {
	"calma": "res://musica/calma.ogg",
	"batalla": "res://musica/batalla.wav",
	"victoria": "res://musica/victoria.mp3",
	"derrota": "res://musica/derrota.mp3",
}
# Pistas que suenan una sola vez y luego vuelven a la música del menú.
const UNA_VEZ: Array[String] = ["victoria", "derrota"]
const SILENCIO := -50.0
# Segundos que tarda en entrar y en salir cada pista.
const ENTRADA := 1.5
const SALIDA := 3.0

var batalla := false
var grupo := ""
var reproductores := {}
var objetivos := {}


func _ready() -> void:
	for nombre in PISTAS:
		var pista: AudioStream = load(PISTAS[nombre])
		if pista is AudioStreamOggVorbis or pista is AudioStreamMP3:
			pista.loop = not nombre in UNA_VEZ
		var reproductor := AudioStreamPlayer.new()
		reproductor.stream = pista
		reproductor.bus = "Musica"
		reproductor.volume_db = SILENCIO
		add_child(reproductor)
		reproductores[nombre] = reproductor
		objetivos[nombre] = SILENCIO
	for nombre in UNA_VEZ:
		reproductores[nombre].finished.connect(func() -> void:
			if grupo == nombre:
				tocar("menu"))


func tocar(nuevo: String) -> void:
	if nuevo == grupo:
		return
	grupo = nuevo
	match nuevo:
		"juego":
			batalla = false
			_reiniciar("batalla")
		"victoria", "derrota":
			_reiniciar(nuevo)


func _reiniciar(nombre: String) -> void:
	var reproductor: AudioStreamPlayer = reproductores[nombre]
	reproductor.volume_db = SILENCIO
	reproductor.play()


func _process(delta: float) -> void:
	for nombre in objetivos:
		objetivos[nombre] = SILENCIO
	match grupo:
		"juego":
			objetivos["batalla" if batalla else "calma"] = 0.0
		"victoria", "derrota":
			objetivos[grupo] = 0.0
		"":
			return
		_:
			objetivos["calma"] = 0.0
	for nombre in reproductores:
		var reproductor: AudioStreamPlayer = reproductores[nombre]
		var objetivo: float = objetivos[nombre]
		var actual := reproductor.volume_db
		var paso := (absf(SILENCIO) / (ENTRADA if objetivo > actual else SALIDA)) * delta
		reproductor.volume_db = move_toward(actual, objetivo, paso)
		if objetivo > SILENCIO and not reproductor.playing:
			reproductor.play()
		elif reproductor.volume_db <= SILENCIO and reproductor.playing and not (nombre == "batalla" and grupo == "juego"):
			reproductor.stop()
