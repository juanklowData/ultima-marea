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


# Barril de pólvora que revienta: chasquido seco, golpe grave que baja de tono y un retumbo
# con astillas que caen al agua.
static func explosion() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA * 2.2)
	var golpe := PackedFloat32Array()
	var retumbo := PackedFloat32Array()
	var chasquido := PackedFloat32Array()
	golpe.resize(muestras)
	retumbo.resize(muestras)
	chasquido.resize(muestras)
	var a_grave := paso_grave(220.0)
	var a_medio := paso_grave(1600.0)
	var grave_1 := 0.0
	var grave_2 := 0.0
	var medio := 0.0
	var fase := 0.0
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var blanco := randf_range(-1.0, 1.0)
		grave_1 += a_grave * (blanco - grave_1)
		grave_2 += a_grave * (grave_1 - grave_2)
		medio += a_medio * (blanco - medio)
		fase += TAU * (34.0 + 90.0 * exp(-t * 7.0)) / FRECUENCIA
		var ataque := 1.0 - exp(-t * 900.0)
		golpe[i] = sin(fase) * exp(-t * 3.2) * ataque
		retumbo[i] = grave_2 * exp(-t * 1.6) * ataque
		var astillas := 0.0
		if t > 0.15 and randf() < 0.0012 * exp(-t * 1.5):
			astillas = randf_range(0.5, 1.0)
		chasquido[i] = medio * exp(-t * 30.0) + astillas
	golpe = normalizar(golpe)
	retumbo = normalizar(retumbo)
	chasquido = normalizar(chasquido)
	for i in muestras:
		golpe[i] = golpe[i] + retumbo[i] * 0.9 + chasquido[i] * 0.35
	return a_wav(golpe)


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


# Olas suaves que llegan y se retiran, en bucle sin corte. Se parte de ruido rosa (más grave
# y suave que el blanco, como el agua de verdad); cada ola abre un poco el filtro al romper
# y deja detrás una espuma fina que se apaga despacio.
static func olas() -> AudioStreamWAV:
	var largo := FRECUENCIA * 16
	var cruce := int(FRECUENCIA * 2.0)
	var total := largo + cruce
	var cuerpo := PackedFloat32Array()
	cuerpo.resize(total)
	var resaca := PackedFloat32Array()
	resaca.resize(total)
	var inicio := 0.0
	while inicio < 18.0:
		var desde := int(inicio * FRECUENCIA)
		var sube := randf_range(0.8, 1.4)
		var baja := randf_range(1.6, 2.6)
		var fuerza := randf_range(0.5, 1.0)
		for i in range(desde, mini(total, desde + int((sube + baja + 1.5) * FRECUENCIA))):
			var t := float(i - desde) / FRECUENCIA
			cuerpo[i] += smoothstep(0.0, sube, t) * (1.0 - smoothstep(sube, sube + baja, t)) * fuerza
			resaca[i] += smoothstep(sube * 0.8, sube + 0.4, t) * (1.0 - smoothstep(sube + 0.4, sube + baja + 1.5, t)) * fuerza
		inicio += randf_range(3.0, 5.0)
	var a_bajo := paso_grave(80.0)
	var a_cerrado := paso_grave(350.0)
	var a_abierto := paso_grave(1300.0)
	var a_espuma := paso_grave(2500.0)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	var bajo := 0.0
	var agua_1 := 0.0
	var agua_2 := 0.0
	var espuma_1 := 0.0
	var crudo := PackedFloat32Array()
	crudo.resize(total)
	for i in total:
		var blanco := randf_range(-1.0, 1.0)
		b0 = 0.99765 * b0 + blanco * 0.099046
		b1 = 0.963 * b1 + blanco * 0.2965164
		b2 = 0.57 * b2 + blanco * 1.0526913
		var rosa := (b0 + b1 + b2 + blanco * 0.1848) * 0.2
		bajo += a_bajo * (rosa - bajo)
		rosa -= bajo
		var ola := minf(cuerpo[i], 1.0)
		var corte := lerpf(a_cerrado, a_abierto, ola * ola)
		agua_1 += corte * (rosa - agua_1)
		agua_2 += corte * (agua_1 - agua_2)
		espuma_1 += a_espuma * (blanco - espuma_1)
		var fina := (blanco - espuma_1) * 0.06 * minf(resaca[i], 1.0)
		crudo[i] = agua_2 * (0.25 + ola * 0.9) + fina
	var valores := PackedFloat32Array()
	valores.resize(largo)
	for i in largo:
		valores[i] = crudo[i]
	for i in cruce:
		var mezcla := float(i) / cruce
		valores[i] = crudo[i] * mezcla + crudo[largo + i] * (1.0 - mezcla)
	return a_wav(valores, true)

# Agua que corre por el casco mientras se navega, en bucle sin corte. Tres capas sobre ruido
# rosa: un rumor grave que sube y baja con el cabeceo, el «shhh» de la proa al cortar cada ola
# (el filtro se abre y se cierra) y la espuma fina que queda burbujeando detrás.
static func agua_casco() -> AudioStreamWAV:
	var largo := FRECUENCIA * 8
	var cruce := int(FRECUENCIA * 1.0)
	var total := largo + cruce
	var corte_ola := PackedFloat32Array()
	corte_ola.resize(total)
	var inicio := randf_range(0.0, 0.4)
	while inicio < float(total) / FRECUENCIA:
		var sube := randf_range(0.25, 0.4)
		var baja := randf_range(0.7, 1.1)
		var fuerza := randf_range(0.55, 1.0)
		var desde := int(inicio * FRECUENCIA)
		for i in range(desde, mini(total, desde + int((sube + baja) * FRECUENCIA))):
			var t := float(i - desde) / FRECUENCIA
			corte_ola[i] += smoothstep(0.0, sube, t) * (1.0 - smoothstep(sube, sube + baja, t)) * fuerza
		inicio += randf_range(1.1, 1.7)
	var a_bajo := paso_grave(60.0)
	var a_rumor := paso_grave(420.0)
	var a_espuma := paso_grave(3200.0)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	var bajo := 0.0
	var rumor_1 := 0.0
	var rumor_2 := 0.0
	var proa_1 := 0.0
	var proa_2 := 0.0
	var espuma := 0.0
	var resto := 0.0
	var crudo := PackedFloat32Array()
	crudo.resize(total)
	for i in total:
		var t := float(i) / FRECUENCIA
		var blanco := randf_range(-1.0, 1.0)
		b0 = 0.99765 * b0 + blanco * 0.099046
		b1 = 0.963 * b1 + blanco * 0.2965164
		b2 = 0.57 * b2 + blanco * 1.0526913
		var rosa := (b0 + b1 + b2 + blanco * 0.1848) * 0.2
		bajo += a_bajo * (rosa - bajo)
		rosa -= bajo
		rumor_1 += a_rumor * (rosa - rumor_1)
		rumor_2 += a_rumor * (rumor_1 - rumor_2)
		var cabeceo := 0.8 + 0.2 * sin(TAU * t / 4.0) * sin(TAU * t / 2.0 + 0.7)
		var ola := minf(corte_ola[i], 1.0)
		var a_proa := paso_grave(lerpf(500.0, 1900.0, ola * ola))
		proa_1 += a_proa * (rosa - proa_1)
		proa_2 += a_proa * (proa_1 - proa_2)
		resto = maxf(resto * 0.99995, ola)
		espuma += a_espuma * (blanco - espuma)
		var fina := (blanco - espuma) * 0.035 * resto * (0.6 + 0.4 * randf())
		crudo[i] = rumor_2 * cabeceo * 0.9 + proa_2 * ola * 0.8 + fina
	for _b in 14:
		var desde := randi_range(0, total - int(FRECUENCIA * 0.1))
		var tono := randf_range(260.0, 620.0)
		var fase := 0.0
		for i in range(desde, desde + int(FRECUENCIA * 0.07)):
			var t := float(i - desde) / FRECUENCIA
			fase += TAU * tono * (1.0 + t * 5.0) / FRECUENCIA
			crudo[i] += sin(fase) * (1.0 - exp(-t * 400.0)) * exp(-t * 50.0) * 0.025
	var valores := PackedFloat32Array()
	valores.resize(largo)
	for i in largo:
		valores[i] = crudo[i]
	for i in cruce:
		var mezcla := float(i) / cruce
		valores[i] = crudo[i] * mezcla + crudo[largo + i] * (1.0 - mezcla)
	return a_wav(valores, true)


# Golpecito de una ola pequeña contra el casco, con unas gotas al final.
static func chapoteo() -> AudioStreamWAV:
	var muestras := int(FRECUENCIA * 0.9)
	var valores := PackedFloat32Array()
	valores.resize(muestras)
	var agua_1 := 0.0
	var agua_2 := 0.0
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var blanco := randf_range(-1.0, 1.0)
		var corte := paso_grave(lerpf(1700.0, 280.0, minf(1.0, t / 0.45)))
		agua_1 += corte * (blanco - agua_1)
		agua_2 += corte * (agua_1 - agua_2)
		valores[i] = agua_2 * (1.0 - exp(-t * 55.0)) * exp(-t * 6.5)
	for _g in 4:
		var desde := int(randf_range(0.08, 0.45) * FRECUENCIA)
		var tono := randf_range(520.0, 1100.0)
		var fase := 0.0
		for i in range(desde, mini(muestras, desde + int(FRECUENCIA * 0.06))):
			var t := float(i - desde) / FRECUENCIA
			fase += TAU * tono * (1.0 + t * 6.0) / FRECUENCIA
			valores[i] += sin(fase) * (1.0 - exp(-t * 500.0)) * exp(-t * 60.0) * 0.06
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

# Aullido de viento que gira: ruido por un filtro resonante cuya nota sube y baja, sobre un rugido grave.
static func viento_tornado() -> AudioStreamWAV:
	var frecuencia := FRECUENCIA
	var largo := frecuencia * 4
	var cruce := int(frecuencia * 0.5)
	var crudo := PackedFloat32Array()
	crudo.resize(largo + cruce)
	var a_grave := paso_grave(160.0)
	var grave_1 := 0.0
	var grave_2 := 0.0
	var bajo := 0.0
	var banda := 0.0
	for i in crudo.size():
		var t := float(i) / frecuencia
		var blanco := randf_range(-1.0, 1.0)
		grave_1 += a_grave * (blanco - grave_1)
		grave_2 += a_grave * (grave_1 - grave_2)
		var nota := 420.0 + 160.0 * sin(TAU * t / 4.0) + 70.0 * sin(TAU * t / 1.0 + 0.7)
		var f := 2.0 * sin(PI * nota / frecuencia)
		bajo += f * banda
		var alto := blanco - bajo - 0.12 * banda
		banda += f * alto
		var rafaga := 0.6 + 0.4 * sin(TAU * t / 2.0 + 1.3)
		crudo[i] = grave_2 * 2.2 + banda * 0.05 * rafaga
	var valores := PackedFloat32Array()
	valores.resize(largo)
	for i in largo:
		valores[i] = crudo[i]
	for i in cruce:
		var mezcla := float(i) / cruce
		valores[i] = crudo[i] * mezcla + crudo[largo + i] * (1.0 - mezcla)
	return a_wav(valores, true)
