class_name Muelle
extends Node3D

# Muelle del puerto en coordenadas del mundo: va a lo largo de X desde la isla (+X) hasta
# mar abierto. El barco del jugador amarra por su costado -Z, con la proa hacia -X.

# Es pequeño a propósito: solo llega hasta media eslora para que el barco se vea entero.
const LADO := 2.2
const ANCHO := 0.7
const PUNTA := 0.7
const TIERRA := 4.2
const ENTRA_EN_TIERRA := 0.7
const ALTO := 0.5
const HUECO_BARCO := 0.75
const COLORES_TABLON: Array[Color] = [Color("9c7048"), Color("8a6040"), Color("a87b52"), Color("94683f")]
const COLOR_VIGA := Color("5e3a22")
const COLOR_PILOTE := Paleta.MADERA_OSCURA
const COLOR_CUERDA := Paleta.CUERDA
const COLOR_HIERRO := Paleta.HIERRO
const COLOR_LUZ := Paleta.FAROL

var mundo: Principal
var barco: Barco
# Cada amarra: [tramo hasta el seno, tramo hasta el barco, noray en el mundo, punto en el barco].
var amarras: Array = []
var cilindro: CylinderMesh


# Distancia del centro del barco a la línea media del muelle, según su manga.
static func amarre(tipo: String) -> Vector2:
	var manga: float = ModeloBarco.MEDIDAS[tipo]["ancho"] * 0.5
	return Vector2(0.0, LADO - ANCHO * 0.5 - HUECO_BARCO - manga)


func construir(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	cilindro = CylinderMesh.new()
	cilindro.top_radius = 0.5
	cilindro.bottom_radius = 0.5
	cilindro.height = 1.0
	cilindro.radial_segments = 8
	cilindro.rings = 1
	var fin := TIERRA + ENTRA_EN_TIERRA

	var tablon := BoxMesh.new()
	tablon.size = Vector3(0.2, 0.05, ANCHO)
	var x := PUNTA + 0.11
	while x < fin:
		var pieza := mundo._malla(self, tablon, COLORES_TABLON[randi() % COLORES_TABLON.size()], Vector3(x, ALTO - 0.025, LADO + randf_range(-0.025, 0.025)), "madera")
		pieza.rotation.y = randf_range(-0.02, 0.02)
		x += 0.23

	var viga := BoxMesh.new()
	viga.size = Vector3(fin - PUNTA, 0.1, 0.1)
	for lado in [-1.0, 1.0]:
		mundo._malla(self, viga, COLOR_VIGA, Vector3((fin + PUNTA) * 0.5, ALTO - 0.1, LADO + lado * (ANCHO * 0.5 - 0.08)), "madera")
	var travesano := BoxMesh.new()
	travesano.size = Vector3(0.09, 0.09, ANCHO + 0.12)
	x = PUNTA + 0.08
	while x <= TIERRA:
		mundo._malla(self, travesano, COLOR_VIGA, Vector3(x, ALTO - 0.2, LADO), "madera")
		for lado in [-1.0, 1.0]:
			var alto_pilote := 0.16 if x == PUNTA + 0.08 else 0.04
			var pilote := mundo._malla(self, cilindro, COLOR_PILOTE, Vector3(x, (ALTO + alto_pilote - 1.4) * 0.5, LADO + lado * (ANCHO * 0.5 + 0.04)), "madera")
			pilote.scale = Vector3(0.14, ALTO + alto_pilote + 1.4, 0.14)
		x += 1.15

	var borde := LADO - ANCHO * 0.5 + 0.12
	# Una sola amarra: x del noray en el muelle; z, a qué parte del largo del barco va (proa a -Z).
	for donde in [Vector3(PUNTA + 0.25, 0.0, 0.1)]:
		var noray := Vector3(donde.x, ALTO, borde)
		var base := mundo._malla(self, cilindro, COLOR_HIERRO, noray + Vector3(0, 0.07, 0))
		base.scale = Vector3(0.1, 0.14, 0.1)
		var cabeza := mundo._malla(self, cilindro, COLOR_HIERRO, noray + Vector3(0, 0.15, 0))
		cabeza.scale = Vector3(0.17, 0.035, 0.17)
		var tramos: Array[MeshInstance3D] = []
		for _t in 2:
			var tramo := mundo._malla(self, cilindro, COLOR_CUERDA, Vector3.ZERO)
			tramo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			tramos.append(tramo)
		amarras.append([tramos[0], tramos[1], noray + Vector3(0, 0.1, 0), donde.z])

	_farol(Vector3(PUNTA + 0.12, ALTO, LADO + ANCHO * 0.5 - 0.1))


func amarrar(nuevo_barco: Barco) -> void:
	barco = nuevo_barco
	for amarra in amarras:
		amarra[0].visible = true
		amarra[1].visible = true


# El barco zarpa del puerto (ensayo del MOBA): se recogen las amarras.
func soltar() -> void:
	barco = null
	for amarra in amarras:
		amarra[0].visible = false
		amarra[1].visible = false


func _process(_delta: float) -> void:
	if barco == null or not is_instance_valid(barco):
		return
	var medidas: Dictionary = ModeloBarco.MEDIDAS[barco.tipo]
	# La amarra muere sobre la borda, no dentro del casco.
	var media: float = medidas["ancho"] * 0.47
	var borda: float = medidas["alto"] + 0.35
	for amarra in amarras:
		var noray: Vector3 = to_global(amarra[2])
		var en_barco := barco.to_global(Vector3(-media, borda, medidas["largo"] * amarra[3]))
		var seno := (noray + en_barco) * 0.5 - Vector3(0, 0.25, 0)
		_tender(amarra[0], noray, seno)
		_tender(amarra[1], seno, en_barco)


# Estira un cilindro de cuerda entre dos puntos del mundo.
func _tender(tramo: MeshInstance3D, desde: Vector3, hasta: Vector3) -> void:
	var eje := hasta - desde
	var largo := eje.length()
	if largo < 0.01:
		return
	var arriba := eje / largo
	var lado := arriba.cross(Vector3.FORWARD if absf(arriba.z) < 0.9 else Vector3.RIGHT).normalized()
	var frente := lado.cross(arriba)
	tramo.global_transform = Transform3D(Basis(lado * 0.04, arriba * largo, frente * 0.04), (desde + hasta) * 0.5)


func _farol(donde: Vector3) -> void:
	var poste := BoxMesh.new()
	poste.size = Vector3(0.07, 1.0, 0.07)
	mundo._malla(self, poste, COLOR_PILOTE, donde + Vector3(0, 0.5, 0), "madera")
	var brazo := BoxMesh.new()
	brazo.size = Vector3(0.24, 0.04, 0.04)
	mundo._malla(self, brazo, COLOR_PILOTE, donde + Vector3(-0.1, 0.95, 0), "madera")
	var jaula := BoxMesh.new()
	jaula.size = Vector3(0.13, 0.17, 0.13)
	mundo._malla(self, jaula, COLOR_HIERRO, donde + Vector3(-0.2, 0.83, 0))
	var luz := MeshInstance3D.new()
	var vidrio := BoxMesh.new()
	vidrio.size = Vector3(0.15, 0.12, 0.15)
	luz.mesh = vidrio
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.albedo_color = COLOR_LUZ
	luz.material_override = brillo
	luz.position = donde + Vector3(-0.2, 0.83, 0)
	add_child(luz)
