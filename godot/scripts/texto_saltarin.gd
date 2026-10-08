class_name TextoSaltarin
extends RichTextEffect
# [salto]texto[/salto]: las letras caen una a una rebotando y luego, cada poco,
# dan un brinco en ola de izquierda a derecha.

const CAIDA := 0.55
const ALTURA_CAIDA := 90.0
const RETRASO_LETRA := 0.07
const CICLO_BRINCO := 2.2
const DURACION_BRINCO := 0.4
const ALTURA_BRINCO := 16.0

var bbcode := "salto"
var inicio := 0


func reiniciar() -> void:
	inicio = Time.get_ticks_msec()


func _process_custom_fx(letra: CharFXTransform) -> bool:
	var t := (Time.get_ticks_msec() - inicio) / 1000.0 - letra.relative_index * RETRASO_LETRA
	if t < CAIDA:
		var u := clampf(t / CAIDA, 0.0, 1.0)
		letra.offset.y = -(1.0 - _rebote(u)) * ALTURA_CAIDA
		letra.color.a *= clampf(u * 3.0, 0.0, 1.0)
		return true
	var fase := fposmod(t - CAIDA, CICLO_BRINCO)
	if fase < DURACION_BRINCO:
		letra.offset.y = -sin(PI * fase / DURACION_BRINCO) * ALTURA_BRINCO
	return true


# Curva de caída con dos botes al llegar al suelo (0 arriba, 1 en su sitio).
func _rebote(u: float) -> float:
	if u < 0.6:
		return pow(u / 0.6, 2.0)
	if u < 0.85:
		var v := (u - 0.725) / 0.125
		return 1.0 - 0.18 * (1.0 - v * v)
	var w := (u - 0.925) / 0.075
	return 1.0 - 0.05 * (1.0 - w * w)
