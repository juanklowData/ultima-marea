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
	if saludo == "espada":
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
