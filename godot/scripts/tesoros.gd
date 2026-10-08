class_name Tesoros
extends Node

# Tesoros que se llevan a la vista en la cubierta y se venden en los puertos (y en la base
# propia del mar libre): cofres que salen de los mapas y calaveras que cargan los piratas.
# Si el barco se hunde quedan flotando para el primero que llegue, bot o persona.

const TIPOS := {
	"cofre": {"valor": 20, "nombre": "Cofre del tesoro"},
	"calavera": {"valor": 12, "nombre": "Calavera maldita"},
}
const MAXIMO_VISIBLE := 6
const VIDA_FLOTANDO := 90.0
const COLOR_MADERA := Color("6b4126")
const COLOR_TAPA := Color("7d4c2c")
const COLOR_HUESO := Color("efe6d2")
const COLOR_MALDICION := Color("7dffcf")

var mundo: Principal
# Monedas que el jugador ha sacado vendiendo tesoros en esta partida.
var vendidos := 0
var material_maldicion: StandardMaterial3D


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	material_maldicion = StandardMaterial3D.new()
	material_maldicion.albedo_color = COLOR_MALDICION
	material_maldicion.emission_enabled = true
	material_maldicion.emission = COLOR_MALDICION
	material_maldicion.emission_energy_multiplier = 2.0


func vaciar() -> void:
	vendidos = 0


func cargar(barco: Barco, tipo: String) -> void:
	barco.tesoros.append(tipo)
	vestir_cubierta(barco)


func valor(barco: Barco) -> int:
	var total := 0
	for tipo in barco.tesoros:
		total += TIPOS[tipo]["valor"]
	return total


func quitar(barco: Barco) -> void:
	barco.tesoros.clear()
	vestir_cubierta(barco)


# Al hundirse, cada tesoro queda flotando cerca de los restos.
func soltar_todos(barco: Barco) -> void:
	for tipo in barco.tesoros:
		mundo.soltar_tesoro(barco.pos + Vector2.from_angle(randf() * TAU) * randf_range(10.0, 30.0), tipo)
	quitar(barco)


# El jugador vende todo lo que lleva en cubierta: las monedas van directas al tesoro guardado.
func vender_jugador() -> void:
	var jugador := mundo.jugador
	if jugador == null or jugador.tesoros.is_empty():
		return
	var cuantos := jugador.tesoros.size()
	var total := valor(jugador)
	quitar(jugador)
	vendidos += total
	mundo.personalizacion.monedas += total
	mundo.personalizacion.guardar()
	mundo.avisar_premio(jugador.position + Vector3(0, 2.5, 0), "+%d" % total, Principal.COLOR_ORO)
	mundo.voz_monedas.play()
	var texto := tr("Vendiste un tesoro: +%d monedas") % total if cuantos == 1 else tr("Vendiste %d tesoros: +%d monedas") % [cuantos, total]
	mundo.misiones.anunciar(texto, Principal.COLOR_ORO)


# Los tesoros se apilan a la vista en la cubierta, detrás del palo mayor.
func vestir_cubierta(barco: Barco) -> void:
	var viejo := barco.get_node_or_null("Tesoros")
	if viejo != null:
		viejo.name = "TesorosViejos"
		viejo.queue_free()
	if barco.tesoros.is_empty():
		return
	var medidas: Dictionary = ModeloBarco.MEDIDAS[barco.tipo]
	var cubierta := Node3D.new()
	cubierta.name = "Tesoros"
	cubierta.position = Vector3(0, medidas["alto"], medidas["largo"] * 0.24)
	barco.add_child(cubierta)
	var sitios := [Vector3(-0.24, 0, 0), Vector3(0.24, 0, 0.04), Vector3(-0.22, 0, 0.42),
		Vector3(0.24, 0, 0.44), Vector3(0, 0.3, 0.06), Vector3(0, 0.3, 0.44)]
	for i in mini(barco.tesoros.size(), MAXIMO_VISIBLE):
		var pieza := modelo(barco.tesoros[i])
		pieza.position = sitios[i]
		pieza.rotation.y = randf_range(-0.35, 0.35)
		cubierta.add_child(pieza)


func modelo(tipo: String) -> Node3D:
	return _calavera() if tipo == "calavera" else _cofre()


# Cofre de madera con tapa curva, flejes y cerradura dorados y monedas asomando.
func _cofre() -> Node3D:
	var nodo := Node3D.new()
	var caja := BoxMesh.new()
	_pieza(nodo, caja, mundo.material(COLOR_MADERA, "madera"), Vector3(0, 0.12, 0), Vector3(0.44, 0.24, 0.3))
	var tapa := CylinderMesh.new()
	tapa.top_radius = 0.15
	tapa.bottom_radius = 0.15
	tapa.height = 0.44
	tapa.radial_segments = 12
	tapa.rings = 1
	var pieza_tapa := _pieza(nodo, tapa, mundo.material(COLOR_TAPA, "madera"), Vector3(0, 0.24, 0), Vector3(1.0, 1.0, 1.0))
	pieza_tapa.rotation.z = PI / 2.0
	pieza_tapa.scale = Vector3(0.62, 1.0, 1.0)
	var oro := mundo.material(Principal.COLOR_ORO)
	for x in [-0.15, 0.15]:
		_pieza(nodo, caja, oro, Vector3(x, 0.2, 0), Vector3(0.04, 0.42, 0.32))
	_pieza(nodo, caja, oro, Vector3(0, 0.2, 0.155), Vector3(0.07, 0.09, 0.02))
	var moneda := CylinderMesh.new()
	moneda.top_radius = 0.05
	moneda.bottom_radius = 0.05
	moneda.height = 0.015
	moneda.radial_segments = 8
	var brillo := StandardMaterial3D.new()
	brillo.albedo_color = Color("ffd36b")
	brillo.emission_enabled = true
	brillo.emission = Color("ffb83a")
	brillo.emission_energy_multiplier = 0.6
	for k in 3:
		var pieza := _pieza(nodo, moneda, brillo, Vector3(-0.1 + k * 0.1, 0.25, 0.12), Vector3.ONE)
		pieza.rotation = Vector3(randf_range(0.6, 1.2), 0, randf_range(-0.4, 0.4))
	return nodo


# Calavera de hueso con ojos que brillan en verde.
func _calavera() -> Node3D:
	var nodo := Node3D.new()
	var hueso := mundo.material(COLOR_HUESO)
	var bola := SphereMesh.new()
	bola.radius = 0.5
	bola.height = 1.0
	bola.radial_segments = 12
	bola.rings = 6
	_pieza(nodo, bola, hueso, Vector3(0, 0.2, 0), Vector3(0.3, 0.27, 0.32))
	var caja := BoxMesh.new()
	_pieza(nodo, caja, hueso, Vector3(0, 0.08, 0.06), Vector3(0.17, 0.09, 0.15))
	var oscuro := mundo.material(Color("2a2420"))
	for k in 3:
		_pieza(nodo, caja, oscuro, Vector3(-0.05 + k * 0.05, 0.09, 0.135), Vector3(0.02, 0.05, 0.01))
	for x in [-0.065, 0.065]:
		_pieza(nodo, bola, material_maldicion, Vector3(x, 0.22, 0.135), Vector3(0.07, 0.07, 0.05))
	return nodo


func _pieza(padre: Node3D, malla: Mesh, materia: Material, pos: Vector3, escala: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = materia
	pieza.position = pos
	pieza.scale = escala
	padre.add_child(pieza)
	return pieza
