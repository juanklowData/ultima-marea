class_name FiguraCapitan
extends Node3D

# Capitán articulado de pie en cubierta: piernas, torso, brazos con codo, cabeza y sombrero.
# Mira hacia -Z como los barcos. Cada capitán saluda a su manera; sin saludo se queda quieto.
# Los ángulos de los brazos se dan "hacia fuera": abrir sube el brazo por el costado,
# adelantar lo lleva al frente y doblar cierra el codo en la misma dirección que abrir.

const ALTURA_CADERA := 0.44
# Saludan un rato, descansan otro y vuelven a empezar; el paso de uno a otro se funde.
const DURA_SALUDO := 3.6
const FUNDIDO := 0.45

var saludo := ""
# Mientras dura, el dios alza los brazos invocando su poder.
var invoca := 0.0
var vitoreo := 0.0
var tiempo := randf() * 10.0
var descanso := randf_range(3.5, 6.0)
var cadera: Node3D
var torso: Node3D
var cabeza: Node3D
var sombrero: Node3D
var piernas: Array[Node3D] = []
var hombros: Array[Node3D] = []
var codos: Array[Node3D] = []
var rueda: Node3D


static func crear(datos: Dictionary) -> FiguraCapitan:
	var figura := FiguraCapitan.new()
	figura.saludo = datos.get("saludo", "")
	figura._armar(datos)
	figura.set_process(figura.saludo != "")
	return figura


# Se pone al timón (ModeloBarco._timon): agarra la rueda y la va corrigiendo a un lado y a otro.
func tomar_timon(nueva: Node3D) -> void:
	rueda = nueva
	set_process(true)
	_reposo()


func _armar(datos: Dictionary) -> void:
	var abrigo := Color(datos["abrigo"])
	var piel := Color(datos["piel"])
	var botas := Color("2a1f18")
	var calzon := Color("e6dcc4")
	var dorado := Color("d9b46a")
	cadera = Node3D.new()
	cadera.position.y = ALTURA_CADERA
	add_child(cadera)
	for lado: float in [-1.0, 1.0]:
		var pierna := Node3D.new()
		pierna.position.x = lado * 0.055
		cadera.add_child(pierna)
		ModeloBarco._pieza(pierna, ModeloBarco._cilindro(0.042, 0.036, 0.26), calzon, Vector3(0, -0.13, 0))
		ModeloBarco._pieza(pierna, ModeloBarco._cilindro(0.047, 0.05, 0.17), botas, Vector3(0, -0.34, 0))
		ModeloBarco._pieza(pierna, ModeloBarco._caja(Vector3(0.08, 0.045, 0.14)), botas, Vector3(0, -0.42, -0.03))
		piernas.append(pierna)

	torso = Node3D.new()
	cadera.add_child(torso)
	ModeloBarco._pieza(torso, ModeloBarco._cilindro(0.11, 0.155, 0.2), abrigo, Vector3(0, -0.06, 0))
	ModeloBarco._pieza(torso, ModeloBarco._cilindro(0.135, 0.11, 0.26), abrigo, Vector3(0, 0.15, 0))
	if datos.has("tocado"):
		_tunica(abrigo, dorado, Color(datos.get("aura", "d9b46a")))
	else:
		ModeloBarco._pieza(torso, ModeloBarco._caja(Vector3(0.08, 0.2, 0.02)), Color("f2ead8"), Vector3(0, 0.17, -0.118))
		ModeloBarco._pieza(torso, ModeloBarco._cilindro(0.117, 0.117, 0.045), Color("3a2a1c"), Vector3(0, 0.03, 0))
		ModeloBarco._pieza(torso, ModeloBarco._caja(Vector3(0.05, 0.04, 0.02)), dorado, Vector3(0, 0.03, -0.12))
		for lado: float in [-1.0, 1.0]:
			for alto: float in [0.11, 0.19]:
				ModeloBarco._pieza(torso, ModeloBarco._esfera(0.012), dorado, Vector3(lado * 0.055, alto, -0.12))
			ModeloBarco._pieza(torso, ModeloBarco._caja(Vector3(0.08, 0.025, 0.09)), dorado, Vector3(lado * 0.12, 0.285, 0))
	ModeloBarco._pieza(torso, ModeloBarco._cilindro(0.04, 0.045, 0.06), piel, Vector3(0, 0.3, 0))

	for lado: float in [-1.0, 1.0]:
		var hombro := Node3D.new()
		hombro.position = Vector3(lado * 0.15, 0.26, 0)
		torso.add_child(hombro)
		ModeloBarco._pieza(hombro, ModeloBarco._esfera(0.045), abrigo, Vector3.ZERO)
		ModeloBarco._pieza(hombro, ModeloBarco._cilindro(0.036, 0.04, 0.15), abrigo, Vector3(0, -0.075, 0))
		var codo := Node3D.new()
		codo.position.y = -0.15
		hombro.add_child(codo)
		ModeloBarco._pieza(codo, ModeloBarco._cilindro(0.03, 0.035, 0.13), abrigo, Vector3(0, -0.065, 0))
		ModeloBarco._pieza(codo, ModeloBarco._cilindro(0.042, 0.042, 0.03), Color("f2ead8"), Vector3(0, -0.12, 0))
		ModeloBarco._pieza(codo, ModeloBarco._esfera(0.036), piel, Vector3(0, -0.16, 0))
		hombros.append(hombro)
		codos.append(codo)
	if datos.has("objeto"):
		_objeto(str(datos["objeto"]), dorado)
	elif saludo == "espada":
		ModeloBarco._pieza(codos[1], ModeloBarco._caja(Vector3(0.09, 0.016, 0.035)), dorado, Vector3(0, -0.18, 0))
		ModeloBarco._pieza(codos[1], ModeloBarco._caja(Vector3(0.018, 0.34, 0.04)), Color("d4d8dc"), Vector3(0, -0.36, 0))
	elif saludo == "catalejo":
		ModeloBarco._pieza(codos[1], ModeloBarco._cilindro(0.022, 0.03, 0.2), Color("b8892f"), Vector3(0, -0.2, -0.02)).rotation.x = PI / 2.0
	elif saludo == "arpon":
		ModeloBarco._pieza(codos[1], ModeloBarco._cilindro(0.012, 0.012, 0.62), Color("6b4a2a"), Vector3(0, -0.17, 0))
		ModeloBarco._pieza(codos[1], ModeloBarco._cilindro(0.03, 0.0, 0.09), Color("c9ced6"), Vector3(0, -0.52, 0))

	cabeza = Node3D.new()
	cabeza.position.y = 0.32
	torso.add_child(cabeza)
	ModeloBarco._pieza(cabeza, ModeloBarco._esfera(0.088), piel, Vector3(0, 0.09, 0))
	ModeloBarco._pieza(cabeza, ModeloBarco._esfera(0.018), piel.darkened(0.12), Vector3(0, 0.08, -0.088))
	ModeloBarco._pieza(cabeza, ModeloBarco._esfera(0.013), Color("141414"), Vector3(-0.032, 0.105, -0.076))
	if datos["parche"]:
		ModeloBarco._pieza(cabeza, ModeloBarco._caja(Vector3(0.045, 0.04, 0.02)), Color("101010"), Vector3(0.032, 0.105, -0.08))
		ModeloBarco._pieza(cabeza, ModeloBarco._cilindro(0.09, 0.09, 0.01), Color("101010"), Vector3(0, 0.12, 0)).rotation.z = 0.35
	else:
		ModeloBarco._pieza(cabeza, ModeloBarco._esfera(0.013), Color("141414"), Vector3(0.032, 0.105, -0.076))
	if datos["pelo"] != "":
		var pelo := Color(datos["pelo"])
		ModeloBarco._pieza(cabeza, ModeloBarco._esfera(0.092), pelo, Vector3(0, 0.1, 0.022))
		if datos.get("melena", false):
			ModeloBarco._pieza(cabeza, ModeloBarco._cilindro(0.07, 0.05, 0.18), pelo, Vector3(0, 0.0, 0.05))
	if datos["barba"] != "":
		var barba := ModeloBarco._pieza(cabeza, ModeloBarco._esfera(0.07), Color(datos["barba"]), Vector3(0, 0.035, -0.05))
		barba.scale = Vector3(1.0, 1.25, 0.8)

	var tela := Color(datos["sombrero"])
	sombrero = Node3D.new()
	sombrero.position.y = 0.165
	cabeza.add_child(sombrero)
	if datos.has("aura"):
		_aura(Color(datos["aura"]))
	if datos.get("tocado", "") != "":
		_tocado(str(datos["tocado"]), tela, Color(datos["pluma"]) if datos["pluma"] != "" else dorado, dorado, datos)
		_reposo()
		return
	for k in 3:
		var pico := ModeloBarco._pieza(sombrero, ModeloBarco._caja(Vector3(0.2, 0.07, 0.025)), tela, Vector3(0, 0.025, 0.085).rotated(Vector3.UP, TAU * k / 3.0))
		pico.rotation.y = TAU * k / 3.0
		pico.rotation.x = -0.35
	ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.15, 0.15, 0.02), tela, Vector3.ZERO)
	ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.075, 0.092, 0.09), tela, Vector3(0, 0.05, 0))
	ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.093, 0.093, 0.02), dorado, Vector3(0, 0.018, 0))
	if datos["pluma"] != "":
		var pluma := ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.04), Color(datos["pluma"]), Vector3(0.08, 0.1, 0.03))
		pluma.scale = Vector3(0.6, 2.4, 0.6)
		pluma.rotation.z = -0.7
	_reposo()


func _process(delta: float) -> void:
	tiempo += delta
	if not is_visible_in_tree():
		return
	_reposo()
	if invoca > 0.0:
		invoca -= delta
		var fuerza := sin(clampf(invoca / 0.9, 0.0, 1.0) * PI)
		for k in 2:
			_brazo(k, lerpf(0.1, 2.75, fuerza), 0.25 * fuerza, 0.15)
		torso.rotation.x = -0.25 * fuerza
		cabeza.rotation.x = -0.35 * fuerza
		cadera.position.y = ALTURA_CADERA + 0.04 * fuerza
		return
	if saludo == "marinero":
		vitoreo = maxf(0.0, vitoreo - delta)
		_faena()
		return
	var ciclo := fmod(tiempo, DURA_SALUDO + descanso)
	if ciclo >= DURA_SALUDO:
		return
	var quieto := _postura()
	_saludar(ciclo)
	var peso := smoothstep(0.0, FUNDIDO, ciclo) * (1.0 - smoothstep(DURA_SALUDO - FUNDIDO, DURA_SALUDO, ciclo))
	var nodos := _articulaciones()
	for k in nodos.size():
		nodos[k].rotation = (quieto[k] as Vector3).lerp(nodos[k].rotation, peso)
	cadera.position.y = lerpf(quieto[-1], cadera.position.y, peso)


func _articulaciones() -> Array[Node3D]:
	return [torso, cabeza, piernas[0], piernas[1], hombros[0], hombros[1], codos[0], codos[1]]


# Rotaciones de todas las articulaciones y, al final, la altura de la cadera.
func _postura() -> Array:
	var datos: Array = []
	for nodo in _articulaciones():
		datos.append(nodo.rotation)
	datos.append(cadera.position.y)
	return datos


# t cuenta desde que empieza el saludo, así las poses con ciclo propio arrancan desde el principio.
func _saludar(t: float) -> void:
	match saludo:
		"ola":
			# Capitana Brisa: saluda con la mano en alto, dando saltitos, con la otra mano en la cadera.
			_brazo(1, 2.7 + sin(t * 8.0) * 0.28, 0.1, sin(t * 8.0 + 0.7) * 0.5)
			_brazo(0, 0.65, 0.0, -1.9)
			cadera.position.y += absf(sin(t * 4.0)) * 0.035
			torso.rotation.z = sin(t * 8.0) * 0.05
			cabeza.rotation.z = sin(t * 4.0) * 0.1
			for k in 2:
				piernas[k].rotation.x = absf(sin(t * 4.0)) * 0.25 * (1.0 if k == 0 else -1.0)
		"espada":
			# Barbanegra: alza el sable amenazando y se ríe con el puño cerrado.
			_brazo(1, 2.35 + sin(t * 6.0) * 0.35, 0.45, 0.25 + sin(t * 6.0 + 1.0) * 0.25)
			_brazo(0, 0.55, 0.7, -1.3 + sin(t * 12.0) * 0.15)
			torso.rotation.y = sin(t * 1.5) * 0.3
			torso.rotation.x = 0.06
			cabeza.rotation.x = 0.2 + sin(t * 14.0) * 0.06
			piernas[0].rotation.z = -0.14
			piernas[1].rotation.z = 0.14
		"militar":
			# Almirante Hierro: saludo militar firme, se cuadra y vuelve a descansar.
			var ciclo := t - 0.3
			var s := smoothstep(0.0, 0.35, ciclo) * (1.0 - smoothstep(2.4, 2.8, ciclo))
			_brazo(1, lerpf(0.1, 1.45, s), lerpf(0.0, 0.5, s), lerpf(0.0, 2.6, s))
			_brazo(0, 0.06, 0.0, 0.0)
			torso.rotation.x = 0.06 * s
			cabeza.rotation.x = 0.12 * s
			cabeza.rotation.y = 0.0
			cadera.position.y += sin(ciclo / 0.35 * PI) * 0.015 if ciclo > 0.0 and ciclo < 0.35 else 0.0
		"reverencia":
			# Lady Escarlata: agita la mano y luego hace una gran reverencia con la pierna atrás.
			var ciclo := t
			var s := smoothstep(1.4, 1.9, ciclo) * (1.0 - smoothstep(2.9, 3.4, ciclo))
			_brazo(1, lerpf(2.75 + sin(t * 7.0) * 0.2, 1.0, s), lerpf(0.0, 1.25, s), lerpf(0.25 + sin(t * 7.0) * 0.3, 0.3, s))
			_brazo(0, lerpf(0.6, 1.0, s), lerpf(0.0, -0.7, s), lerpf(-1.9, 0.0, s))
			torso.rotation.x = -0.6 * s
			cabeza.rotation.x = -0.25 * s
			piernas[1].rotation.x = -0.45 * s
			piernas[0].rotation.x = 0.12 * s
			cadera.position.y -= 0.04 * s
		"punos":
			# Capitán Cadenas: levanta los dos puños por turnos, como un campeón.
			for k in 2:
				var golpe := sin(t * 5.0 + PI * k)
				_brazo(k, 2.45 + golpe * 0.35, 0.2, 0.9 + golpe * 0.5)
			cadera.position.y += absf(sin(t * 5.0)) * 0.02
			torso.rotation.y = sin(t * 5.0) * 0.15
			cabeza.rotation.x = 0.15
			piernas[0].rotation.z = -0.12
			piernas[1].rotation.z = 0.12
		"abuela":
			# Abuela Coral: saluda con las dos manitas al frente y se balancea con calma.
			for k in 2:
				_brazo(k, 0.3, 1.05 + sin(t * 1.6) * 0.1, 0.0)
				codos[k].rotation.x = 0.9
				codos[k].rotation.z = sin(t * 6.0 + PI * k) * 0.5
			torso.rotation.z = sin(t * 1.6) * 0.1
			torso.rotation.x = -0.12
			cabeza.rotation.z = sin(t * 1.6 + 1.0) * 0.15
			cadera.position.y += absf(sin(t * 1.6)) * 0.012
		"conjuro":
			# Madame Marea: alza los brazos y mueve las manos en círculos, como llamando al mar.
			for k in 2:
				var vuelta := t * 3.0 + PI * k
				_brazo(k, 1.9 + sin(vuelta) * 0.25, 0.5 + cos(vuelta) * 0.25, 0.5)
			torso.rotation.y = sin(t * 1.5) * 0.2
			cabeza.rotation.x = -0.25
			cadera.position.y += sin(t * 3.0) * 0.012
		"catalejo":
			# Capitán Nautilo: se lleva el catalejo al ojo y barre el horizonte.
			_brazo(1, 0.35, 1.25, 1.6)
			_brazo(0, 0.25, 0.9, 1.2)
			cabeza.rotation.y = sin(t * 0.9) * 0.45
			torso.rotation.y = sin(t * 0.9) * 0.3
			cabeza.rotation.x = -0.05
		"baile":
			# Mecha Ruiz: baila con los brazos en jarra moviendo la cadera.
			for k in 2:
				_brazo(k, 0.75, 0.0, 1.9)
			torso.rotation.z = sin(t * 9.0) * 0.12
			cadera.position.y += absf(sin(t * 9.0)) * 0.025
			cabeza.rotation.z = -sin(t * 9.0) * 0.15
			for k in 2:
				piernas[k].rotation.x = sin(t * 9.0 + PI * k) * 0.3
		"sigilo":
			# Dama Niebla: se lleva un dedo a los labios y se agacha, como pidiendo silencio.
			var s := smoothstep(0.0, 0.5, t)
			_brazo(1, lerpf(0.1, 0.35, s), lerpf(0.0, 0.7, s), lerpf(0.0, 2.5, s))
			_brazo(0, 0.3, -0.3, 0.4)
			torso.rotation.x = 0.18 * s
			cadera.position.y -= 0.035 * s
			cabeza.rotation.y = sin(t * 2.0) * 0.4
		"arpon":
			# Olaf: alza el arpón y lo blande hacia delante dos veces.
			var tiro := maxf(0.0, sin(t * 3.4))
			_brazo(1, 2.6 - tiro * 0.9, 0.3 + tiro * 0.9, 0.3)
			_brazo(0, 0.4, 0.6, -0.6)
			torso.rotation.x = tiro * 0.18
			torso.rotation.y = -0.2 + tiro * 0.3
			piernas[0].rotation.x = -0.25
			piernas[1].rotation.x = 0.2
		"trueno":
			# Señor Trueno: levanta el puño al cielo y lo baja de golpe, como llamando al rayo.
			var golpe := fmod(t, 1.2)
			var s := smoothstep(0.0, 0.6, golpe) * (1.0 - smoothstep(0.9, 1.05, golpe))
			_brazo(1, lerpf(0.4, 2.95, s), 0.15, lerpf(1.2, 0.0, s))
			_brazo(0, 0.6, 0.2, -1.6)
			cabeza.rotation.x = -0.35 * s
			cadera.position.y += 0.02 * s


# Postura base: brazos sueltos y una respiración suave.
func _reposo() -> void:
	cadera.position.y = ALTURA_CADERA + sin(tiempo * 2.2) * 0.004
	torso.rotation = Vector3.ZERO
	cabeza.rotation = Vector3(0, sin(tiempo * 0.7) * 0.35, 0)
	for k in 2:
		piernas[k].rotation = Vector3.ZERO
		_brazo(k, 0.1, 0.0, 0.0)
	if rueda != null:
		# Con los brazos a 0.89 rad las manos caen en el aro a las 3 y a las 9; al girar la
		# rueda, la mano de ese lado sube y la otra baja.
		var giro := sin(tiempo * 0.6) * 0.3 + sin(tiempo * 1.7) * 0.08
		rueda.rotation.z = giro
		for k in 2:
			_brazo(k, 0.1, 0.89 + giro * (0.75 if k == 1 else -0.75), 0.0)
		torso.rotation.z = -giro * 0.08
		cabeza.rotation.y *= 0.4


# El dios alza los brazos un momento al usar un poder.
func invocar() -> void:
	invoca = 0.9
	set_process(true)


# Para el MOBA en tierra: camina (fase avanza con los pasos, cuanto va de 0 quieto a 1 corriendo)
# y, si golpe > 0, lanza el brazo derecho hacia delante. Se llama cada frame con _process apagado.
func andar(fase: float, cuanto: float, golpe := 0.0) -> void:
	tiempo += get_process_delta_time()
	_reposo()
	for k in 2:
		var paso := sin(fase + PI * k) * 0.75 * cuanto
		piernas[k].rotation.x = paso
		_brazo(k, 0.12, -paso * 0.8, 0.25 * cuanto)
	cadera.position.y = ALTURA_CADERA + absf(sin(fase)) * 0.03 * cuanto
	torso.rotation = Vector3(-0.08 * cuanto, sin(fase) * 0.08 * cuanto, 0)
	if golpe > 0.0:
		_brazo(1, 0.35, 1.9 * golpe, 0.15)
		torso.rotation.y -= 0.25 * golpe


# Pose de celebración (al ganar) o de caer derrotado.
func posar(alegre: bool) -> void:
	tiempo += get_process_delta_time()
	_reposo()
	if alegre:
		var salto := absf(sin(tiempo * 7.0))
		for k in 2:
			_brazo(k, 2.6 + salto * 0.25, 0.1, 0.2)
		cadera.position.y = ALTURA_CADERA + salto * 0.06
	else:
		torso.rotation.x = 0.6
		cabeza.rotation.x = 0.5
		for k in 2:
			_brazo(k, 0.2, 0.6, 0.6)


# Marinero de los botes: rema sin parar mirando a popa y, cuando su bote dispara, alza los
# brazos un momento.
func vitorear() -> void:
	vitoreo = 0.9


func _faena() -> void:
	if vitoreo > 0.0:
		var salto := absf(sin(tiempo * 12.0))
		for k in 2:
			_brazo(k, 2.5 + salto * 0.3, 0.2, 0.3 + salto * 0.4)
		cadera.position.y = ALTURA_CADERA + salto * 0.05
		cabeza.rotation = Vector3(-0.25, 0, 0)
		return
	var bogada := sin(tiempo * 3.2)
	for k in 2:
		_brazo(k, 0.3, 1.15 - bogada * 0.45, 0.5 + bogada * 0.5)
	torso.rotation.x = bogada * 0.18
	cabeza.rotation = Vector3(-bogada * 0.1, sin(tiempo * 0.5) * 0.5, 0)


func _brazo(k: int, abrir: float, adelantar: float, doblar: float) -> void:
	var lado := -1.0 if k == 0 else 1.0
	hombros[k].rotation = Vector3(adelantar, 0, lado * abrir)
	codos[k].rotation = Vector3(0, 0, lado * doblar)


# --- Dioses del MOBA ---------------------------------------------------------------
# Las piezas cuelgan del nodo "sombrero" (justo encima de la cabeza) o de las manos.
# La cara mira hacia -Z: lo que va delante tiene z negativa.

# Ropa de dios en vez de casaca: falda de túnica sobre las piernas, cinturón y pectoral de oro
# con una gema del color del aura, y una capa a la espalda.
func _tunica(tela: Color, dorado: Color, gema: Color) -> void:
	ModeloBarco._pieza(cadera, ModeloBarco._cilindro(0.15, 0.19, 0.26), tela, Vector3(0, -0.12, 0))
	ModeloBarco._pieza(cadera, ModeloBarco._cilindro(0.191, 0.191, 0.025), dorado, Vector3(0, -0.24, 0))
	ModeloBarco._pieza(torso, ModeloBarco._cilindro(0.118, 0.118, 0.04), dorado, Vector3(0, 0.03, 0))
	var pectoral := ModeloBarco._pieza(torso, ModeloBarco._cilindro(0.15, 0.15, 0.02), dorado, Vector3(0, 0.27, -0.01))
	pectoral.scale = Vector3(1.0, 1.0, 0.95)
	_brilla(ModeloBarco._pieza(torso, ModeloBarco._esfera(0.022), gema, Vector3(0, 0.2, -0.125)), gema)
	var capa := ModeloBarco._pieza(torso, ModeloBarco._caja(Vector3(0.3, 0.62, 0.02)), tela.darkened(0.35), Vector3(0, -0.02, 0.135))
	capa.rotation.x = -0.12


# Halo que brilla detrás de la cabeza.
func _aura(color: Color) -> void:
	var aro := TorusMesh.new()
	aro.inner_radius = 0.118
	aro.outer_radius = 0.13
	aro.rings = 24
	aro.ring_segments = 6
	var halo := ModeloBarco._pieza(cabeza, aro, color, Vector3(0, 0.12, 0.075))
	halo.rotation.x = PI / 2.0
	halo.material_override = ModeloBarco._material(color, true)


func _brilla(pieza: MeshInstance3D, color: Color) -> MeshInstance3D:
	pieza.material_override = ModeloBarco._material(color, true)
	return pieza


# Casco que cubre la coronilla sin tapar los ojos.
func _cupula(color: Color) -> MeshInstance3D:
	var cupula := ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.1), color, Vector3(0, -0.01, 0.02))
	cupula.scale = Vector3(1.0, 0.7, 1.0)
	return cupula


func _cuerno(color: Color, pos: Vector3, largo: float, abrir: float, atras: float) -> void:
	var cuerno := ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.0, 0.024, largo), color, pos)
	cuerno.rotation = Vector3(atras, 0, abrir)


func _tocado(tipo: String, tela: Color, acento: Color, dorado: Color, datos: Dictionary) -> void:
	match tipo:
		"penacho":
			# Quetzalcóatl: cinta de oro y abanico de plumas largas de quetzal.
			ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.096, 0.096, 0.035), dorado, Vector3(0, -0.035, 0))
			ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.025), Color("3fd2c8"), Vector3(0, -0.035, -0.095))
			var colores := [acento, Color("2aa8a0"), Color("d23a2a"), Color("2aa8a0"), acento]
			for k in 9:
				var a := lerpf(-1.25, 1.25, k / 8.0)
				var pluma := ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.035), colores[k % colores.size()],
					Vector3(sin(a) * 0.13, 0.05 + cos(a) * 0.13, 0.05))
				pluma.scale = Vector3(0.55, 2.8, 0.3)
				pluma.rotation.z = -a
		"casco_cresta":
			# Casco griego de bronce con cresta de crin.
			_cupula(tela)
			ModeloBarco._pieza(sombrero, ModeloBarco._caja(Vector3(0.016, 0.07, 0.012)), tela, Vector3(0, -0.06, -0.088))
			for lado: float in [-1.0, 1.0]:
				ModeloBarco._pieza(sombrero, ModeloBarco._caja(Vector3(0.012, 0.07, 0.07)), tela, Vector3(lado * 0.088, -0.07, -0.03))
			ModeloBarco._pieza(sombrero, ModeloBarco._caja(Vector3(0.012, 0.03, 0.2)), dorado, Vector3(0, 0.06, 0.02))
			var crin := ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.06), acento, Vector3(0, 0.1, 0.04))
			crin.scale = Vector3(0.35, 0.8, 2.1)
		"disco_solar":
			# Ra: tocado de rayas y el disco del sol ardiendo sobre la cabeza.
			var nemes := _cupula(dorado)
			nemes.scale = Vector3(1.05, 0.75, 1.05)
			for lado: float in [-1.0, 1.0]:
				ModeloBarco._pieza(sombrero, ModeloBarco._caja(Vector3(0.03, 0.16, 0.05)), Color("2a4fa8"), Vector3(lado * 0.09, -0.13, -0.01))
			ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.012, 0.016, 0.06), dorado, Vector3(0, 0.03, -0.06))
			var disco := _brilla(ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.1, 0.1, 0.02), tela, Vector3(0, 0.15, 0.03)), tela)
			disco.rotation.x = PI / 2.0
		"chacal":
			# Anubis: cabeza de chacal con hocico largo, orejas de punta y ojos de oro.
			var piel := Color(datos["piel"])
			var hocico := ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.022, 0.05, 0.13), piel, Vector3(0, -0.085, -0.12))
			hocico.rotation.x = PI / 2.0 + 0.15
			ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.018), Color("101010"), Vector3(0, -0.095, -0.185))
			for lado: float in [-1.0, 1.0]:
				var oreja := ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.0, 0.035, 0.15), piel, Vector3(lado * 0.045, 0.05, 0.015))
				oreja.rotation.z = -lado * 0.18
				var dentro := ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.0, 0.02, 0.1), dorado, Vector3(lado * 0.045, 0.035, 0.0))
				dentro.rotation.z = -lado * 0.18
				_brilla(ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.014), dorado, Vector3(lado * 0.034, -0.06, -0.08)), dorado)
				ModeloBarco._pieza(sombrero, ModeloBarco._caja(Vector3(0.03, 0.15, 0.05)), dorado.darkened(0.2), Vector3(lado * 0.09, -0.15, 0.0))
		"diadema":
			# Bachué: diadema de oro muisca con esmeraldas y un tunjo en la frente.
			ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.102, 0.102, 0.03), dorado, Vector3(0, -0.04, 0))
			var tunjo := ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.035, 0.035, 0.008), dorado, Vector3(0, -0.015, -0.104))
			tunjo.rotation.x = PI / 2.0
			for k in 5:
				var a := lerpf(-1.1, 1.1, k / 4.0)
				_brilla(ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.016), Color("1fd27a"), Vector3(sin(a) * 0.104, -0.04, -cos(a) * 0.104)), Color("1fd27a"))
		"corona":
			# Poseidón: corona de oro con puntas.
			ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.094, 0.094, 0.035), dorado, Vector3(0, -0.03, 0))
			for k in 7:
				var a := TAU * k / 7.0
				ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.0, 0.018, 0.07), dorado, Vector3(sin(a) * 0.088, 0.02, cos(a) * 0.088))
			_brilla(ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.018), Color("4fd6ff"), Vector3(0, -0.02, -0.097)), Color("4fd6ff"))
		"cuernos":
			# Tiamat: cuernos de dragón hacia atrás y una cresta de aleta.
			for lado: float in [-1.0, 1.0]:
				_cuerno(Color("e8dcc0"), Vector3(lado * 0.06, 0.02, 0.02), 0.17, -lado * 0.5, 0.7)
			var aleta := ModeloBarco._pieza(sombrero, ModeloBarco._caja(Vector3(0.01, 0.08, 0.16)), acento if acento != dorado else Color("3fe0d0"), Vector3(0, 0.0, 0.05))
			aleta.rotation.x = 0.3
		"llamas":
			# Pele: el pelo se le vuelve lava y fuego.
			var fuegos := [Color("ff4a1a"), Color("ff9a1a"), Color("ffd84a")]
			for k in 7:
				var a := TAU * k / 7.0
				var llama := _brilla(ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.035), fuegos[k % 3],
					Vector3(sin(a) * 0.06, 0.03 + (k % 2) * 0.02, cos(a) * 0.06 + 0.02)), fuegos[k % 3])
				llama.scale = Vector3(0.7, 2.2, 0.7)
		"cuernos_largos":
			# Loki: casco de oro con dos cuernos largos hacia arriba.
			_cupula(tela)
			for lado: float in [-1.0, 1.0]:
				_cuerno(tela, Vector3(lado * 0.07, 0.07, -0.02), 0.24, -lado * 0.32, -0.25)
		"ala_ancha":
			# Odín: sombrero de caminante de ala ancha, un poco caído hacia el ojo.
			var ala := ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.18, 0.18, 0.014), tela, Vector3(0, -0.01, 0))
			ala.rotation.x = 0.12
			var copa := ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.055, 0.09, 0.12), tela, Vector3(0, 0.05, 0.01))
			copa.rotation.x = 0.12
			ModeloBarco._pieza(sombrero, ModeloBarco._cilindro(0.091, 0.091, 0.018), Color("2a1f18"), Vector3(0, 0.0, 0.0))
		"casco_alado":
			# Thor: casco de plata con alas a los lados.
			_cupula(tela)
			for lado: float in [-1.0, 1.0]:
				for k in 3:
					var pluma := ModeloBarco._pieza(sombrero, ModeloBarco._esfera(0.03), Color("f2f2f2"), Vector3(lado * (0.1 + k * 0.012), 0.02 + k * 0.03, 0.02 + k * 0.02))
					pluma.scale = Vector3(0.35, 2.4, 0.9)
					pluma.rotation = Vector3(0.5 + k * 0.25, 0, -lado * (0.35 + k * 0.15))


# Lo que el dios lleva en las manos; cuelga del antebrazo (la mano queda en y = -0.16).
func _objeto(tipo: String, dorado: Color) -> void:
	var mano := codos[1]
	match tipo:
		"escudo":
			# Atenea: escudo redondo en el brazo izquierdo y lanza en el derecho.
			var escudo := ModeloBarco._pieza(codos[0], ModeloBarco._cilindro(0.13, 0.13, 0.02), dorado, Vector3(-0.045, -0.1, 0))
			escudo.rotation.z = PI / 2.0
			var centro := ModeloBarco._pieza(codos[0], ModeloBarco._cilindro(0.06, 0.06, 0.024), Color("2a4fa8"), Vector3(-0.047, -0.1, 0))
			centro.rotation.z = PI / 2.0
			ModeloBarco._pieza(mano, ModeloBarco._cilindro(0.012, 0.012, 0.66), Color("6b4a2a"), Vector3(0, -0.17, 0))
			ModeloBarco._pieza(mano, ModeloBarco._cilindro(0.028, 0.0, 0.09), dorado, Vector3(0, -0.54, 0))
		"baculo":
			ModeloBarco._pieza(mano, ModeloBarco._cilindro(0.013, 0.013, 0.66), dorado, Vector3(0, -0.17, 0))
			var aro := TorusMesh.new()
			aro.inner_radius = 0.025
			aro.outer_radius = 0.04
			ModeloBarco._pieza(mano, aro, dorado, Vector3(0, -0.53, 0)).rotation.x = PI / 2.0
			_brilla(ModeloBarco._pieza(mano, ModeloBarco._esfera(0.022), Color("4fd6ff"), Vector3(0, 0.17, 0)), Color("4fd6ff"))
		"tridente":
			ModeloBarco._pieza(mano, ModeloBarco._cilindro(0.012, 0.012, 0.7), dorado, Vector3(0, -0.2, 0))
			ModeloBarco._pieza(mano, ModeloBarco._caja(Vector3(0.13, 0.016, 0.016)), dorado, Vector3(0, -0.55, 0))
			for x: float in [-0.058, 0.0, 0.058]:
				ModeloBarco._pieza(mano, ModeloBarco._cilindro(0.013, 0.0, 0.1), dorado, Vector3(x, -0.61, 0))
		"martillo":
			# Thor: Mjölnir, mango corto y cabeza enorme.
			ModeloBarco._pieza(mano, ModeloBarco._cilindro(0.014, 0.014, 0.16), Color("5a3a22"), Vector3(0, -0.2, 0))
			ModeloBarco._pieza(mano, ModeloBarco._caja(Vector3(0.16, 0.085, 0.085)), Color("8a929a"), Vector3(0, -0.3, 0))
			_brilla(ModeloBarco._pieza(mano, ModeloBarco._caja(Vector3(0.02, 0.088, 0.088)), Color("6fe6ff"), Vector3(0, -0.3, 0)), Color("6fe6ff"))
