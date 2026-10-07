class_name Sonidos
extends RefCounted

# Efectos de sonido sintetizados al arrancar: ruido filtrado y tonos, sin archivos de audio.

const FRECUENCIA := 22050


static func paso_grave(frecuencia_corte: float) -> float:
	return 1.0 - exp(-TAU * frecuencia_corte / FRECUENCIA)


static func normalizar(valores: PackedFloat32Array, pico_deseado := 1.0) -> PackedFloat32Array:
	var pico := 0.0001
	for valor in valores:
		pico = maxf(pico, absf(valor))
	for i in valores.size():
		valores[i] = valores[i] / pico * pico_deseado
	return valores


static func a_wav(valores: PackedFloat32Array, bucle := false) -> AudioStreamWAV:
	valores = normalizar(valores, 0.8)
	var datos := PackedByteArray()
	datos.resize(valores.size() * 2)
	for i in valores.size():
		datos.encode_s16(i * 2, int(valores[i] * 32767.0))
	var sonido := AudioStreamWAV.new()
	sonido.format = AudioStreamWAV.FORMAT_16_BITS
	sonido.mix_rate = FRECUENCIA
	sonido.stereo = false
	sonido.data = datos
	if bucle:
		sonido.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sonido.loop_end = valores.size()
	return sonido


static func trueno() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA * 4.0)
	var retumbo := PackedFloat32Array()
	var chasquido := PackedFloat32Array()
	retumbo.resize(muestras)
	chasquido.resize(muestras)
	var a_grave := paso_grave(110.0)
	var a_medio := paso_grave(700.0)
	var grave_1 := 0.0
	var grave_2 := 0.0
	var medio := 0.0
	var golpes := [0.0, randf_range(0.5, 0.9), randf_range(1.3, 1.9), randf_range(2.1, 2.7)]
	for i in muestras:
		var t := float(i) / FRECUENCIA
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
	retumbo = normalizar(retumbo)
	chasquido = normalizar(chasquido)
	for i in muestras:
		retumbo[i] = retumbo[i] + chasquido[i] * 0.18
	return a_wav(retumbo)


static func canon() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA * 1.3)
	var tono := PackedFloat32Array()
	var estruendo := PackedFloat32Array()
	var chasquido := PackedFloat32Array()
	tono.resize(muestras)
	estruendo.resize(muestras)
	chasquido.resize(muestras)
	var a_grave := paso_grave(450.0)
	var a_agudo := paso_grave(2200.0)
	var grave := 0.0
	var agudo := 0.0
	var fase_tono := 0.0
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var blanco := randf_range(-1.0, 1.0)
		grave += a_grave * (blanco - grave)
		agudo += a_agudo * (blanco - agudo)
		fase_tono += TAU * (42.0 + 70.0 * exp(-t * 9.0)) / FRECUENCIA
		var ataque := 1.0 - exp(-t * 600.0)
		tono[i] = sin(fase_tono) * exp(-t * 5.0) * ataque
		estruendo[i] = grave * exp(-t * 6.0) * ataque
		chasquido[i] = agudo * exp(-t * 40.0)
	tono = normalizar(tono)
	estruendo = normalizar(estruendo)
	chasquido = normalizar(chasquido)
	for i in muestras:
		tono[i] = tono[i] + estruendo[i] * 0.75 + chasquido[i] * 0.3
	return a_wav(tono)


static func monedas(choques: Array = [0.0, 0.07, 0.15, 0.21, 0.3, 0.36, 0.47]) -> AudioStreamWAV:
	var muestras := int(FRECUENCIA * (choques.back() + 0.43))
	var valores := PackedFloat32Array()
	valores.resize(muestras)
	# Parciales inarmónicos de un disco metálico pequeño.
	# Todos por debajo de la mitad de FRECUENCIA para que no suenen ásperos.
	var parciales := [1.0, 2.32, 3.86]
	for k in choques.size():
		var inicio := int(choques[k] * FRECUENCIA)
		var base := randf_range(1400.0, 1900.0)
		var fuerza := 1.0 - k * 0.09
		for i in range(inicio, muestras):
			var t := float(i - inicio) / FRECUENCIA
			var sonido := 0.0
			for p in parciales.size():
				sonido += sin(TAU * base * parciales[p] * t) * exp(-t * (16.0 + p * 18.0)) / (1.0 + p * 1.5)
			sonido += randf_range(-1.0, 1.0) * exp(-t * 400.0) * 0.12
			valores[i] += sonido * fuerza * (1.0 - exp(-t * 1500.0))
	return a_wav(valores)


# Crujido de la madera al partirse, agua entrando y burbujas que suben.
static func hundir() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA * 3.2)
	var valores := PackedFloat32Array()
	valores.resize(muestras)
	var a_grave := paso_grave(260.0)
	var grave_1 := 0.0
	var grave_2 := 0.0
	var ola_1 := 0.0
	var ola_2 := 0.0
	var fase_queja := 0.0
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var blanco := randf_range(-1.0, 1.0)
		# Golpe de agua: ruido filtrado cuyo corte baja de 1200 a 250 Hz.
		var a_ola := paso_grave(lerpf(1200.0, 250.0, minf(1.0, t / 1.2)))
		ola_1 += a_ola * (blanco - ola_1)
		ola_2 += a_ola * (ola_1 - ola_2)
		var golpe := (1.0 - exp(-t * 40.0)) * exp(-t * 2.2)
		# Agua entrando: rumor grave que crece y se apaga.
		grave_1 += a_grave * (blanco - grave_1)
		grave_2 += a_grave * (grave_1 - grave_2)
		var entrada := smoothstep(0.2, 0.9, t) * exp(-maxf(0.0, t - 1.0) * 1.4)
		# Quejido de la madera: tono grave que se dobla hacia abajo.
		fase_queja += TAU * (lerpf(105.0, 62.0, minf(1.0, t / 1.6)) + 2.0 * sin(t * 9.0)) / FRECUENCIA
		var queja := (sin(fase_queja) + 0.3 * sin(fase_queja * 2.0)) * smoothstep(0.05, 0.35, t) * exp(-maxf(0.0, t - 0.4) * 2.0)
		valores[i] = ola_2 * golpe * 1.6 + grave_2 * entrada * 3.0 + queja * 0.22
	for _b in 14:
		var inicio := randf_range(0.7, 2.7)
		var tono := randf_range(140.0, 380.0)
		var desde := int(inicio * FRECUENCIA)
		var fase_burbuja := 0.0
		for i in range(desde, mini(muestras, desde + int(FRECUENCIA * 0.14))):
			var t := float(i - desde) / FRECUENCIA
			fase_burbuja += TAU * tono * (1.0 + t * 5.0) / FRECUENCIA
			valores[i] += sin(fase_burbuja) * (1.0 - exp(-t * 300.0)) * exp(-t * 28.0) * 0.18 * (1.0 - inicio / 3.4)
	return a_wav(valores)


static func equipar() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA * 0.85)
	var valores := PackedFloat32Array()
	valores.resize(muestras)
	# Arpegio mayor ascendente (do-mi-sol-do) con timbre de campanilla.
	var notas := [[523.25, 0.0], [659.25, 0.07], [783.99, 0.14], [1046.5, 0.21]]
	for nota in notas:
		var frecuencia: float = nota[0]
		var inicio := int(float(nota[1]) * FRECUENCIA)
		var es_ultima: bool = nota == notas.back()
		var caida := 4.5 if es_ultima else 9.0
		for i in range(inicio, muestras):
			var t := float(i - inicio) / FRECUENCIA
			var vibrato := 1.0 + 0.004 * sin(TAU * 6.0 * t) if es_ultima else 1.0
			var fase := TAU * frecuencia * vibrato * t
			var sonido := sin(fase) + 0.35 * sin(fase * 2.0) * exp(-t * 6.0) + 0.15 * sin(fase * 3.0) * exp(-t * 12.0)
			valores[i] += sonido * exp(-t * caida) * (1.0 - exp(-t * 900.0)) * (1.2 if es_ultima else 0.8)
	return a_wav(valores)


# Rumor grave del remolino, en bucle sin corte.
static func rumor_remolino() -> AudioStreamWAV:
	var frecuencia := FRECUENCIA
	var largo := frecuencia * 3
	var cruce := int(frecuencia * 0.4)
	var crudo := PackedFloat32Array()
	crudo.resize(largo + cruce)
	# Agua grave que gira: ruido muy filtrado con un vaivén lento, sin siseo.
	var a_grave := paso_grave(220.0)
	var a_suave := paso_grave(420.0)
	var grave_1 := 0.0
	var grave_2 := 0.0
	var suave_1 := 0.0
	var suave_2 := 0.0
	for i in crudo.size():
		var t := float(i) / frecuencia
		var blanco := randf_range(-1.0, 1.0)
		grave_1 += a_grave * (blanco - grave_1)
		grave_2 += a_grave * (grave_1 - grave_2)
		suave_1 += a_suave * (blanco - suave_1)
		suave_2 += a_suave * (suave_1 - suave_2)
		var oleaje := 0.7 + 0.3 * sin(TAU * t / 1.5)
		var remolino := 0.5 + 0.5 * sin(TAU * t / 3.0 + 1.0)
		crudo[i] = grave_2 * oleaje + suave_2 * 0.35 * remolino
	var valores := PackedFloat32Array()
	valores.resize(largo)
	for i in largo:
		valores[i] = crudo[i]
	for i in cruce:
		var mezcla := float(i) / cruce
		valores[i] = crudo[i] * mezcla + crudo[largo + i] * (1.0 - mezcla)
	return a_wav(valores, true)
