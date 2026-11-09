class_name ModeloBarco
extends RefCounted

# Medidas en metros. Cada mástil es Vector3(z, altura, ancho de vela); la proa mira a -Z.
const MEDIDAS := {
	"balandro": {"largo": 3.4, "ancho": 1.25, "alto": 0.5, "mastiles": [Vector3(-0.2, 3.4, 1.8)]},
	"bergantin": {"largo": 4.3, "ancho": 1.55, "alto": 0.6, "mastiles": [Vector3(-0.8, 4.0, 2.1), Vector3(0.6, 3.6, 1.9)]},
	"galeon": {"largo": 5.4, "ancho": 1.95, "alto": 0.8, "mastiles": [Vector3(-1.5, 4.3, 2.2), Vector3(-0.1, 4.9, 2.6), Vector3(1.35, 3.9, 2.0)]},
}
# Igual que las balas de cada andanada.
const CANONES_POR_LADO := 3
# Mástil más alto y vela más ancha de cada barco cuando la variante cambia el número de mástiles.
const MASTIL_TIPO := {"balandro": Vector2(3.4, 1.8), "bergantin": Vector2(4.0, 2.1), "galeon": Vector2(4.7, 2.4)}
# arrufo: cuánto suben los extremos; popa/proa: reparto de esa subida;
# llenura: exponente de la manga (menor = más panzudo); espejo: anchura de la popa; quilla: calado.
const PERFILES := {
	"clasico": {"arrufo": 0.35, "popa": 1.4, "proa": 1.0, "llenura": 0.55, "espejo": 0.16, "quilla": 0.9},
	"plano": {"arrufo": 0.12, "popa": 0.8, "proa": 1.2, "llenura": 0.45, "espejo": 0.22, "quilla": 0.7},
	"alto": {"arrufo": 0.6, "popa": 1.8, "proa": 1.5, "llenura": 0.55, "espejo": 0.2, "quilla": 1.0},
	"media_luna": {"arrufo": 1.0, "popa": 1.9, "proa": 2.2, "llenura": 0.75, "espejo": 0.07, "quilla": 0.8},
	"panzudo": {"arrufo": 0.25, "popa": 1.0, "proa": 0.8, "llenura": 0.3, "espejo": 0.34, "quilla": 1.1},
}

const COLOR_CUBIERTA := Paleta.MADERA_MIEL
const COLOR_MADERA := Paleta.MADERA_OSCURA
const COLOR_FONDO := Paleta.CASCO_FONDO
const COLOR_ADORNO := Paleta.ORO
const COLOR_HIERRO := Paleta.HIERRO
const COLOR_VENTANA := Paleta.FAROL
const SHADER_TELA := preload("res://shaders/tela.gdshader")
const SECCIONES := 24
const ANILLO := 8
# Escala de un tripulante (FiguraCapitan mide ~1 a escala 1) por metro de eslora: el timón se mide con él.
const TALLA := 0.144

static var _materiales := {}
static var _perfil: Dictionary = PERFILES["clasico"]


static func crear(aspecto: Personalizacion) -> Node3D:
	var tipo := aspecto.tipo
	var medidas: Dictionary = MEDIDAS[tipo]
	var forma: Dictionary = aspecto.pieza("tipo").get("forma", {})
	var largo: float = medidas["largo"] * forma.get("largo", 1.0)
	var ancho: float = medidas["ancho"] * forma.get("ancho", 1.0)
	var alto: float = medidas["alto"] * forma.get("alto", 1.0)
	var pintura := aspecto.pieza("casco")
	var casco: Color = pintura["color"]
	var adorno: Color = aspecto.pieza("adorno")["color"]
	var hierro: Color = aspecto.pieza("canones")["color"]
	var velas := aspecto.pieza("velas")
	var raiz := Node3D.new()
	_perfil = PERFILES[forma.get("perfil", "clasico")]

	_agregar(raiz, _casco(largo, ancho, alto, casco, adorno, pintura.get("franja", casco)))
	_agregar(raiz, _cubierta(largo, ancho, alto))
	var manga_popa := media_manga(0.0, ancho)
	_pieza(raiz, _caja(Vector3(manga_popa * 2.0 + 0.05, 0.08, 0.06)), adorno, Vector3(0, altura_cubierta(0.0, alto) - 0.03, largo / 2.0 + 0.01))
	_pieza(raiz, _caja(Vector3(manga_popa * 1.6, 0.05, 0.04)), adorno, Vector3(0, alto * 0.25, largo / 2.0 + 0.01))
	_pieza(raiz, _caja(Vector3(0.07, alto * 1.25, 0.3)), COLOR_MADERA, Vector3(0, -alto * 0.22, largo / 2.0 + 0.12))
	_popa(raiz, aspecto.pieza("popa"), tipo, largo, ancho, alto, casco, adorno)
	_proa(raiz, aspecto.pieza("proa"), largo, alto)

	var y_proa := altura_cubierta(0.9, alto) + 0.1
	if forma.get("castillo", false):
		y_proa += _castillo_proa(raiz, largo, ancho, alto, casco, adorno)
	_armar_canones(raiz, aspecto.pieza("canones").get("estilo", "clasico"), hierro, largo, ancho, alto, y_proa)

	var largo_baupres: float = largo * 0.32 * forma.get("baupres", 1.0)
	var direccion := Vector3(0, sin(0.35), -cos(0.35))
	var raiz_baupres := Vector3(0, altura_cubierta(1.0, alto), -largo / 2.0)
	var baupres := _pieza(raiz, _cilindro(0.035, 0.06, largo_baupres), COLOR_MADERA, raiz_baupres + direccion * largo_baupres * 0.4)
	baupres.rotation.x = -PI / 2.0 + 0.35
	var punta: Vector3 = raiz_baupres + direccion * largo_baupres * 0.9

	var aparejo: String = forma.get("aparejo", "cuadrado")
	var inclinacion: float = forma.get("inclinacion", 0.0)
	var textura_vela := Dibujos.textura(velas, 96, 96)
	var mastiles := _mastiles(tipo, medidas, forma, largo)
	if raiz.get_node_or_null("Timon") == null:
		_poner_timon(raiz, largo, alto, mastiles, adorno)
	var mas_alto := 0.0
	for datos in mastiles:
		mas_alto = maxf(mas_alto, datos.y)
	var tope := -INF
	var palo_bandera: Node3D
	var base_asta := 0.0
	var punta_asta := 0.0
	var palos: Array[Node3D] = []
	var cimas: Array[Vector3] = []
	for m in mastiles.size():
		var datos: Vector3 = mastiles[m]
		var hueco: float = (mastiles[m + 1].x if m + 1 < mastiles.size() else largo * 0.5) - datos.x
		var estilo := aparejo
		if aparejo == "mixto":
			estilo = "cangrejo" if m == mastiles.size() - 1 else "cuadrado"
		var palo := Node3D.new()
		palo.position = Vector3(0, altura_cubierta(_t_de_z(datos.x, largo), alto) - 0.15, datos.x)
		palo.rotation.x = inclinacion
		raiz.add_child(palo)
		palos.append(palo)
		_aparejar(palo, estilo, datos.y, datos.z, hueco, textura_vela, forma.get("cofa", false) and datos.y == mas_alto)
		# El asta de la bandera sale de la punta del palo y supera la verga de la vela latina.
		var alto_palo := datos.y * (0.8 if estilo == "latino" else 1.0)
		var asta := datos.y * (1.1 if estilo == "latino" else 1.0) + 0.45
		var cima := palo.position + palo.basis * Vector3(0, asta, 0)
		cimas.append(palo.position + palo.basis * Vector3(0, alto_palo * 0.97, 0))
		if cima.y > tope:
			tope = cima.y
			palo_bandera = palo
			base_asta = alto_palo
			punta_asta = asta

	var foques: int = forma.get("foques", 0)
	for f in foques:
		var amura: Vector3 = punta - direccion * largo_baupres * 0.3 * f
		_poner_foque(raiz, palos[0], mastiles[0].y, f, amura, largo, alto, textura_vela)

	_izar_bandera(palo_bandera, base_asta, punta_asta, adorno, aspecto.pieza("bandera"))
	_adornar(raiz, aspecto.pieza("adorno"), largo, ancho, alto, forma.get("castillo", false), punta, cimas)
	for categoria in Catalogo.CATEGORIAS:
		var tesoro := aspecto.pieza(categoria)
		if tesoro.has("aura"):
			raiz.add_child(_aura(tesoro["aura"], largo, ancho, alto))
			break
	return raiz


# Chispas de luz que suben alrededor del casco de los barcos con piezas de tesoro.
static func _aura(color: Color, largo: float, ancho: float, alto: float) -> CPUParticles3D:
	var clave := "aura|%s" % color.to_html()
	if not _materiales.has(clave):
		var degradado := Gradient.new()
		degradado.set_color(0, Color(1, 1, 1, 1))
		degradado.set_color(1, Color(1, 1, 1, 0))
		var mancha := GradientTexture2D.new()
		mancha.gradient = degradado
		mancha.fill = GradientTexture2D.FILL_RADIAL
		mancha.fill_from = Vector2(0.5, 0.5)
		mancha.fill_to = Vector2(0.5, 0.0)
		mancha.width = 32
		mancha.height = 32
		var materia := StandardMaterial3D.new()
		materia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		materia.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		materia.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		materia.vertex_color_use_as_albedo = true
		materia.albedo_texture = mancha
		materia.albedo_color = color
		materia.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_materiales[clave] = materia
	var plano := QuadMesh.new()
	plano.size = Vector2.ONE * 0.22
	plano.material = _materiales[clave]
	var rampa := Gradient.new()
	rampa.set_color(0, Color(1, 1, 1, 0))
	rampa.set_color(1, Color(1, 1, 1, 0))
	rampa.add_point(0.2, Color(1, 1, 1, 1))
	var chispas := CPUParticles3D.new()
	chispas.mesh = plano
	chispas.amount = 26
	chispas.lifetime = 1.8
	chispas.local_coords = false
	chispas.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	chispas.emission_box_extents = Vector3(ancho * 0.6, 0.1, largo * 0.5)
	chispas.position = Vector3(0, alto * 0.6, 0)
	chispas.direction = Vector3.UP
	chispas.spread = 25.0
	chispas.gravity = Vector3(0, 0.4, 0)
	chispas.initial_velocity_min = 0.3
	chispas.initial_velocity_max = 0.7
	chispas.scale_amount_min = 0.6
	chispas.scale_amount_max = 1.3
	chispas.color_ramp = rampa
	chispas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return chispas


# Un cañón de caza en la proa y una fila de cañones asomando por cada costado.
static func _armar_canones(raiz: Node3D, estilo_canon: String, hierro: Color, largo: float, ancho: float, alto: float, y_proa: float) -> void:
	_canon(raiz, estilo_canon, hierro, Vector3(0, y_proa, -largo * 0.4), Vector3(0, 0, -1), 1.5)
	_pieza(raiz, _caja(Vector3(0.2, 0.08, 0.28)), COLOR_MADERA, Vector3(0, y_proa - 0.08, -largo * 0.39))
	for k in CANONES_POR_LADO:
		var t := 0.35 + 0.35 * (k + 0.5) / CANONES_POR_LADO
		var media := media_manga(t, ancho)
		var y := altura_cubierta(t, alto) - 0.22
		var z := lerpf(largo / 2.0, -largo / 2.0, t)
		for lado: float in [-1.0, 1.0]:
			_canon(raiz, estilo_canon, hierro, Vector3(lado * (media + 0.06), y, z), Vector3(lado, 0, 0), 1.0)


# Vela triangular entre el palo de proa y el bauprés; "numero" baja cada foque un poco más.
static func _poner_foque(raiz: Node3D, proa_palo: Node3D, alto_palo: float, numero: int, amura: Vector3, largo: float, alto: float, textura_vela: Texture2D) -> void:
	var cabeza := proa_palo.position + proa_palo.basis * Vector3(0, alto_palo * (0.82 - 0.2 * numero), 0)
	var z_escota := proa_palo.position.z - 0.25
	var escota := Vector3(0, altura_cubierta(_t_de_z(z_escota, largo), alto) + 0.35, z_escota)
	var plano := Node3D.new()
	plano.rotation.y = PI / 2.0
	raiz.add_child(plano)
	_tela(plano, _vela_esquinas(Vector2(-escota.z, escota.y), Vector2(-amura.z, amura.y), Vector2(-cabeza.z, cabeza.y), Vector2(-cabeza.z, cabeza.y), 0.12), textura_vela, Vector3.ZERO)
	_entre(raiz, cabeza, amura, 0.012, COLOR_MADERA)


# Asta en la punta del palo más alto, con su bola y la bandera ondeando.
static func _izar_bandera(palo: Node3D, base_asta: float, punta_asta: float, adorno: Color, bandera: Dictionary) -> void:
	var largo_asta := punta_asta - base_asta + 0.1
	_pieza(palo, _cilindro(0.018, 0.03, largo_asta), COLOR_MADERA, Vector3(0, punta_asta - largo_asta / 2.0, 0))
	_pieza(palo, _esfera(0.045), adorno, Vector3(0, punta_asta + 0.03, 0))
	var trapo := _pieza(palo, _vela(0.7, 0.42, 0.07), Color.WHITE, Vector3(0, punta_asta - 0.25, 0.37))
	trapo.material_override = _material_tela(Dibujos.textura(bandera, 100, 60), true)
	trapo.rotation.y = PI / 2.0
	trapo.name = "Bandera"


# Decoración de la pieza "adorno"; va de la popa (t = 0) a la proa (t = 1) siguiendo la borda.
static func _adornar(raiz: Node3D, pieza: Dictionary, largo: float, ancho: float, alto: float, castillo: bool, punta: Vector3, cimas: Array[Vector3]) -> void:
	var estilo: String = pieza.get("estilo", "molduras")
	var color: Color = pieza["color"]
	var otro := color.darkened(0.5) if color.get_luminance() > 0.45 else color.lightened(0.55)
	var fin := 0.76 if castillo else 0.84
	match estilo:
		"molduras":
			for lado: float in [-1.0, 1.0]:
				var previo := Vector3.ZERO
				for i in 21:
					var t := lerpf(0.04, 0.96, i / 20.0)
					var punto := _borda(t, lado, largo, ancho, alto, 0.12, 0.015)
					if i > 0:
						_entre(raiz, previo, punto, 0.022, color)
					previo = punto
				for i in 5:
					var t := lerpf(0.22, fin, i / 4.0)
					_pieza(raiz, _esfera(0.05), color, _borda(t, lado, largo, ancho, alto, 0.12, 0.03))
		"escudos":
			for lado: float in [-1.0, 1.0]:
				for i in 7:
					var t := lerpf(0.22, fin, i / 6.0)
					var escudo := Node3D.new()
					escudo.position = _borda(t, lado, largo, ancho, alto, -0.02, 0.03)
					escudo.rotation.z = -lado * PI / 2.0
					raiz.add_child(escudo)
					_pieza(escudo, _cilindro(0.13, 0.13, 0.03), color if i % 2 == 0 else otro, Vector3.ZERO)
					_pieza(escudo, _cilindro(0.135, 0.135, 0.02), COLOR_MADERA, Vector3(0, -0.006, 0))
					_pieza(escudo, _esfera(0.04), COLOR_HIERRO.lightened(0.3), Vector3(0, 0.02, 0))
		"barandilla":
			for lado: float in [-1.0, 1.0]:
				var previo := Vector3.ZERO
				for i in 12:
					var t := lerpf(0.18, fin, i / 11.0)
					var pie := _borda(t, lado, largo, ancho, alto, 0.0, -0.04)
					_pieza(raiz, _cilindro(0.016, 0.022, 0.2), color, pie + Vector3(0, 0.1, 0))
					var cabeza := pie + Vector3(0, 0.21, 0)
					if i > 0:
						_entre(raiz, previo, cabeza, 0.018, color)
						_entre(raiz, previo - Vector3(0, 0.1, 0), cabeza - Vector3(0, 0.1, 0), 0.01, color)
					previo = cabeza
		"faroles":
			for lado: float in [-1.0, 1.0]:
				for t in [0.26, 0.52, fin]:
					var pie := _borda(t, lado, largo, ancho, alto, 0.0, -0.03)
					_pieza(raiz, _cilindro(0.015, 0.02, 0.3), COLOR_MADERA, pie + Vector3(0, 0.15, 0))
					var farol := pie + Vector3(0, 0.38, 0)
					_pieza(raiz, _caja(Vector3(0.1, 0.13, 0.1)), color, farol)
					_pieza(raiz, _caja(Vector3(0.115, 0.09, 0.07)), COLOR_VENTANA, farol).material_override = _material(COLOR_VENTANA, true)
					_pieza(raiz, _caja(Vector3(0.07, 0.09, 0.115)), COLOR_VENTANA, farol).material_override = _material(COLOR_VENTANA, true)
					_pieza(raiz, _cilindro(0.0, 0.08, 0.07), color, farol + Vector3(0, 0.1, 0))
		"remaches":
			for lado: float in [-1.0, 1.0]:
				for fila in 2:
					for i in 18:
						var t := lerpf(0.06, 0.94, (i + 0.5 * fila) / 18.0)
						if fila == 1 and t > 0.33 and t < 0.72:
							continue
						_pieza(raiz, _esfera(0.05), color, _borda(t, lado, largo, ancho, alto, 0.1 + 0.2 * fila, 0.0))
				var previo := Vector3.ZERO
				for i in 13:
					var punto := _borda(lerpf(0.04, 0.96, i / 12.0), lado, largo, ancho, alto, 0.02, 0.01)
					if i > 0:
						_entre(raiz, previo, punto, 0.04, color.darkened(0.3))
					previo = punto
		"banderines":
			var cuerdas: Array = [[punta, cimas[0]]]
			if cimas.size() > 1:
				cuerdas.append([cimas[0], cimas[cimas.size() - 1]])
			cuerdas.append([cimas[cimas.size() - 1], Vector3(0, altura_cubierta(0.0, alto) + 0.1, largo / 2.0)])
			var n := 0
			for cuerda in cuerdas:
				var a: Vector3 = cuerda[0]
				var b: Vector3 = cuerda[1]
				_entre(raiz, a, b, 0.012, Color("e8e0c8"))
				var cuantos := maxi(2, int(a.distance_to(b) / 0.36))
				for k in cuantos:
					var punto := a.lerp(b, (k + 0.5) / cuantos)
					var banderin := _pieza(raiz, _caja(Vector3(0.015, 0.18, 0.18)), color if n % 2 == 0 else otro, punto - Vector3(0, 0.12, 0))
					banderin.rotation.x = PI / 4.0
					n += 1
		"pinchos":
			for lado: float in [-1.0, 1.0]:
				for i in 11:
					var t := lerpf(0.16, fin, i / 10.0)
					var pincho := _pieza(raiz, _cilindro(0.0, 0.06, 0.32), color, _borda(t, lado, largo, ancho, alto, -0.12, 0.06))
					pincho.rotation.z = -lado * 0.6
					_pieza(raiz, _cilindro(0.065, 0.065, 0.04), otro, _borda(t, lado, largo, ancho, alto, -0.01, 0.0))
		"ojos":
			for lado: float in [-1.0, 1.0]:
				var t := 0.88
				var a := _borda(t - 0.03, lado, largo, ancho, alto, 0.2, 0.0)
				var b := _borda(t + 0.03, lado, largo, ancho, alto, 0.2, 0.0)
				var tangente := (b - a).normalized()
				var normal := Vector3(lado, 0, 0).slide(tangente).normalized()
				var ojo := Node3D.new()
				ojo.position = (a + b) / 2.0 + normal * 0.01
				ojo.basis = Basis(Quaternion(Vector3.UP, normal))
				raiz.add_child(ojo)
				var grande := 0.17 + alto * 0.12
				_pieza(ojo, _cilindro(grande, grande, 0.02), Color("f3ecdf"), Vector3.ZERO).scale = Vector3(1, 1, 1.4)
				_pieza(ojo, _cilindro(grande * 0.62, grande * 0.62, 0.02), color, Vector3(0, 0.01, 0))
				_pieza(ojo, _cilindro(grande * 0.3, grande * 0.3, 0.02), Color("141414"), Vector3(0, 0.02, 0))
				_pieza(ojo, _cilindro(grande * 1.5, grande * 1.5, 0.015), otro, Vector3(0, -0.006, 0)).scale = Vector3(0.8, 1, 1.05)


# Punto en el costado: "bajada" mide desde la borda hacia abajo y "fuera" separa del casco.
static func _borda(t: float, lado: float, largo: float, ancho: float, alto: float, bajada: float, fuera: float) -> Vector3:
	var cubierta := altura_cubierta(t, alto)
	var fondo := lerpf(-alto * _perfil["quilla"], alto * 0.25, pow(t, 3.0))
	var hundido := clampf(bajada / maxf(cubierta - fondo, 0.05), 0.0, 1.0)
	var media := media_manga(t, ancho) * cos(asin(hundido))
	return Vector3(lado * (media + fuera), cubierta - bajada, lerpf(largo / 2.0, -largo / 2.0, t))


# Vector3(z, altura, ancho de vela) de cada mástil, de proa a popa.
static func _mastiles(tipo: String, medidas: Dictionary, forma: Dictionary, largo: float) -> Array[Vector3]:
	var lista: Array[Vector3] = []
	var escala_mastil: float = forma.get("mastil", 1.0)
	var escala_vela: float = forma.get("vela", 1.0)
	var n: int = forma.get("mastiles", 0)
	if n == 0:
		for datos in medidas["mastiles"]:
			lista.append(Vector3(datos.x * forma.get("largo", 1.0), datos.y * escala_mastil, datos.z * escala_vela))
		return lista
	var tam: Vector2 = MASTIL_TIPO[tipo]
	for i in n:
		var f := 0.5 if n == 1 else float(i) / (n - 1)
		var z := largo * (lerpf(-0.26, 0.16, f) if n > 1 else -0.06)
		var centro := 1.0 - absf(f - 0.4) * 0.3
		lista.append(Vector3(z, tam.x * centro * escala_mastil, tam.y * (0.8 + 0.2 * centro) * escala_vela))
	return lista


# Las velas de cuchillo (latina, cangreja, junco) van a lo largo del barco, en un
# plano girado donde +X apunta a proa. "hueco" es el espacio libre hasta el siguiente mástil.
static func _aparejar(palo: Node3D, estilo: String, h: float, w: float, hueco: float, textura: Texture2D, cofa: bool) -> void:
	var alto_palo := h * (0.8 if estilo == "latino" else 1.0)
	_pieza(palo, _cilindro(0.045, 0.085, alto_palo), COLOR_MADERA, Vector3(0, alto_palo / 2.0, 0))
	if cofa and estilo != "cuadrado":
		_pieza(palo, _cilindro(0.16, 0.13, 0.2), COLOR_MADERA, Vector3(0, alto_palo * 0.86, 0))
	if estilo == "cuadrado":
		_tela(palo, _vela(w, h * 0.4, w * 0.2), textura, Vector3(0, h * 0.38, -0.09))
		_tela(palo, _vela(w * 0.74, h * 0.28, w * 0.15), textura, Vector3(0, h * 0.74, -0.08))
		_pieza(palo, _cilindro(0.028, 0.028, w * 1.12), COLOR_MADERA, Vector3(0, h * 0.59, -0.04)).rotation.z = PI / 2.0
		_pieza(palo, _cilindro(0.024, 0.024, w * 0.86), COLOR_MADERA, Vector3(0, h * 0.89, -0.04)).rotation.z = PI / 2.0
		_pieza(palo, _cilindro(0.17, 0.13, 0.12), COLOR_MADERA, Vector3(0, h * 0.62, 0))
		return
	var plano := Node3D.new()
	plano.rotation.y = PI / 2.0
	palo.add_child(plano)
	var largo_vela := clampf(hueco * 1.05, 0.9, w * 1.15)
	match estilo:
		"latino":
			var l := clampf(hueco * 1.4, 1.0, w * 1.4)
			var pico := Vector2(-l * 0.42, h * 1.0)
			_tela(plano, _vela_esquinas(Vector2(-l * 0.45, h * 0.3), Vector2(l * 0.5, h * 0.14), pico, pico, w * 0.12), textura, Vector3.ZERO)
			_entre(plano, Vector3(l * 0.58, h * 0.07, 0), Vector3(-l * 0.47, h * 1.05, 0), 0.03, COLOR_MADERA)
		"cangrejo":
			var abajo := h * 0.28
			_tela(plano, _vela_esquinas(Vector2(-largo_vela, abajo + 0.04), Vector2(0.05, abajo), Vector2(-largo_vela * 0.92, h * 0.92), Vector2(0.05, h * 0.72), w * 0.1), textura, Vector3.ZERO)
			_entre(plano, Vector3(0, abajo, 0), Vector3(-largo_vela * 1.05, abajo + 0.05, 0), 0.028, COLOR_MADERA)
			_entre(plano, Vector3(0, h * 0.72, 0), Vector3(-largo_vela * 0.97, h * 0.94, 0), 0.024, COLOR_MADERA)
		"junco":
			var esquinas := [Vector2(-largo_vela * 0.75, h * 0.25), Vector2(largo_vela * 0.3, h * 0.25), Vector2(-largo_vela * 0.62, h * 0.95), Vector2(largo_vela * 0.15, h * 0.86)]
			_tela(plano, _vela_esquinas(esquinas[0], esquinas[1], esquinas[2], esquinas[3], 0.03), textura, Vector3.ZERO)
			for b in 7:
				var v := b / 6.0
				var a: Vector2 = esquinas[0].lerp(esquinas[2], v)
				var c: Vector2 = esquinas[1].lerp(esquinas[3], v)
				_entre(plano, Vector3(a.x, a.y, 0.02), Vector3(c.x, c.y, 0.02), 0.014, COLOR_MADERA)


# Cubierta elevada en la proa; devuelve cuánto suben los cañones de caza.
static func _castillo_proa(raiz: Node3D, largo: float, ancho: float, alto: float, casco: Color, adorno: Color) -> float:
	var t := 0.84
	var z := lerpf(largo / 2.0, -largo / 2.0, t)
	var tam := Vector3(media_manga(0.92, ancho) * 2.0, alto * 0.45, largo * 0.16)
	var base := altura_cubierta(t, alto) - 0.12
	_pieza(raiz, _caja(tam), casco.darkened(0.12), Vector3(0, base + tam.y / 2.0, z))
	_pieza(raiz, _caja(Vector3(tam.x + 0.06, 0.05, tam.z + 0.06)), COLOR_CUBIERTA, Vector3(0, base + tam.y, z))
	for lado in [-1.0, 1.0]:
		_pieza(raiz, _caja(Vector3(0.04, 0.14, tam.z)), adorno, Vector3(lado * tam.x / 2.0, base + tam.y + 0.09, z))
	_pieza(raiz, _caja(Vector3(tam.x, 0.14, 0.04)), adorno, Vector3(0, base + tam.y + 0.09, z + tam.z / 2.0))
	return tam.y - 0.1


# Cañón armado sobre el eje +Y local (la boca); el +X local queda siempre hacia arriba.
static func _canon(padre: Node3D, estilo: String, color: Color, pos: Vector3, apunta: Vector3, escala: float) -> void:
	var canon := Node3D.new()
	canon.position = pos
	canon.basis = Basis(Vector3.UP, apunta, Vector3.UP.cross(apunta)).scaled(Vector3.ONE * escala)
	padre.add_child(canon)
	var boca := Color(0.03, 0.03, 0.03)
	match estilo:
		"culebrina":
			_pieza(canon, _cilindro(0.034, 0.05, 0.5), color, Vector3(0, 0.08, 0))
			_pieza(canon, _cilindro(0.047, 0.047, 0.04), color, Vector3(0, 0.31, 0))
			_pieza(canon, _cilindro(0.056, 0.056, 0.03), color, Vector3(0, -0.06, 0))
			_pieza(canon, _cilindro(0.022, 0.022, 0.01), boca, Vector3(0, 0.335, 0))
		"carronada":
			_pieza(canon, _cilindro(0.075, 0.085, 0.2), color, Vector3(0, -0.02, 0))
			_pieza(canon, _cilindro(0.095, 0.078, 0.06), color, Vector3(0, 0.1, 0))
			_pieza(canon, _esfera(0.08), color, Vector3(0, -0.12, 0))
			_pieza(canon, _cilindro(0.06, 0.06, 0.01), boca, Vector3(0, 0.132, 0))
		"anillado":
			_pieza(canon, _cilindro(0.05, 0.065, 0.32), color, Vector3.ZERO)
			for y: float in [-0.09, -0.01, 0.07]:
				_pieza(canon, _cilindro(0.078, 0.078, 0.028), color.lightened(0.15), Vector3(0, y, 0))
			_pieza(canon, _cilindro(0.064, 0.064, 0.04), color, Vector3(0, 0.15, 0))
			_pieza(canon, _cilindro(0.032, 0.032, 0.01), boca, Vector3(0, 0.172, 0))
		"doble":
			for lado: float in [-1.0, 1.0]:
				_pieza(canon, _cilindro(0.04, 0.052, 0.34), color, Vector3(0, 0.01, lado * 0.055))
				_pieza(canon, _cilindro(0.024, 0.024, 0.01), boca, Vector3(0, 0.182, lado * 0.055))
			_pieza(canon, _caja(Vector3(0.08, 0.05, 0.2)), color.darkened(0.2), Vector3(0, -0.08, 0))
		"bocina":
			_pieza(canon, _cilindro(0.045, 0.06, 0.26), color, Vector3(0, -0.03, 0))
			_pieza(canon, _cilindro(0.105, 0.045, 0.13), color, Vector3(0, 0.16, 0))
			_pieza(canon, _cilindro(0.08, 0.08, 0.01), boca, Vector3(0, 0.222, 0))
		"dragon":
			_pieza(canon, _cilindro(0.05, 0.065, 0.28), color, Vector3(0, -0.02, 0))
			var cabeza := _pieza(canon, _esfera(0.085), color, Vector3(0, 0.15, 0))
			cabeza.scale = Vector3(1.0, 1.35, 1.0)
			for lado: float in [-1.0, 1.0]:
				var cuerno := _pieza(canon, _cilindro(0.0, 0.022, 0.13), color.lightened(0.2), Vector3(0, 0.12, lado * 0.08))
				cuerno.rotation.x = lado * 2.3
				_pieza(canon, _esfera(0.018), Color("ffb020"), Vector3(0.06, 0.17, lado * 0.045))
			_pieza(canon, _cilindro(0.04, 0.04, 0.01), boca, Vector3(0, 0.262, 0))
		"pimentero":
			for k in 3:
				var desvio := Vector2.from_angle(TAU * k / 3.0) * 0.04
				_pieza(canon, _cilindro(0.024, 0.03, 0.36), color, Vector3(desvio.x, 0.02, desvio.y))
				_pieza(canon, _cilindro(0.014, 0.014, 0.01), boca, Vector3(desvio.x, 0.202, desvio.y))
			for y: float in [-0.1, 0.1]:
				_pieza(canon, _cilindro(0.076, 0.076, 0.035), color.lightened(0.15), Vector3(0, y, 0))
		_:
			_pieza(canon, _cilindro(0.05, 0.065, 0.32), color, Vector3.ZERO)
			_pieza(canon, _cilindro(0.068, 0.068, 0.04), color, Vector3(0, 0.15, 0))
			_pieza(canon, _cilindro(0.032, 0.032, 0.01), boca, Vector3(0, 0.172, 0))


static func _entre(padre: Node3D, a: Vector3, b: Vector3, radio: float, color: Color) -> MeshInstance3D:
	var palo := _pieza(padre, _cilindro(radio, radio, a.distance_to(b)), color, (a + b) / 2.0)
	palo.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
	return palo


static func _popa(raiz: Node3D, pieza: Dictionary, tipo: String, largo: float, ancho: float, alto: float, casco: Color, adorno: Color) -> void:
	var estilo: String = pieza.get("estilo", pieza["id"])
	var pared: Color = pieza.get("color", casco.darkened(0.15))
	var luz: Color = pieza.get("luz", COLOR_VENTANA)
	var alto_camarote := alto * (0.95 if tipo == "galeon" else 0.6)
	if not estilo in ["camarote", "faroles", "castillo", "galeria"]:
		_popa_especial(raiz, estilo, largo, ancho, alto, alto_camarote, pared, adorno, luz)
		return
	if estilo == "castillo" or estilo == "galeria":
		alto_camarote *= 1.5
	var z := largo * 0.34
	var fondo := largo * 0.22
	var base := altura_cubierta(_t_de_z(z, largo), alto) - 0.12
	var techo := base + alto_camarote
	var trasera := z + fondo / 2.0 + 0.02
	_pieza(raiz, _caja(Vector3(ancho * 0.7, alto_camarote, fondo)), pared, Vector3(0, base + alto_camarote / 2.0, z))
	_pieza(raiz, _caja(Vector3(ancho * 0.78, 0.07, largo * 0.25)), COLOR_CUBIERTA, Vector3(0, techo + 0.035, z))
	var filas := 2 if estilo == "galeria" or estilo == "castillo" else 1
	for f in filas:
		var y := base + alto_camarote * (0.55 if filas == 1 else 0.33 + 0.36 * f)
		for i in 3:
			_pieza(raiz, _caja(Vector3(0.14, 0.12, 0.04)), luz, Vector3((i - 1) * ancho * 0.2, y, trasera)) \
				.material_override = _material(luz, true)

	match estilo:
		"faroles":
			for lado in [-1.0, 1.0]:
				var x: float = lado * ancho * 0.34
				var zf := z + fondo * 0.42
				_pieza(raiz, _cilindro(0.02, 0.025, 0.45), COLOR_MADERA, Vector3(x, techo + 0.25, zf))
				_pieza(raiz, _caja(Vector3(0.13, 0.17, 0.13)), luz, Vector3(x, techo + 0.55, zf)) \
					.material_override = _material(luz.darkened(0.05), true)
				_pieza(raiz, _cilindro(0.0, 0.1, 0.09), adorno, Vector3(x, techo + 0.68, zf))
		"castillo":
			for lado in [-1.0, 1.0]:
				_pieza(raiz, _caja(Vector3(0.04, 0.16, largo * 0.25)), adorno, Vector3(lado * ancho * 0.38, techo + 0.11, z))
			_pieza(raiz, _caja(Vector3(ancho * 0.78, 0.16, 0.04)), adorno, Vector3(0, techo + 0.11, z + largo * 0.125))
			_pieza(raiz, _caja(Vector3(ancho * 0.6, 0.06, 0.03)), adorno, Vector3(0, techo - 0.05, trasera + 0.01))
		"galeria":
			var y_balcon := base + alto_camarote * 0.12
			var z_balcon := trasera + 0.15
			_pieza(raiz, _caja(Vector3(ancho * 0.74, 0.05, 0.3)), COLOR_CUBIERTA, Vector3(0, y_balcon, z_balcon))
			_pieza(raiz, _caja(Vector3(ancho * 0.74, 0.13, 0.03)), adorno, Vector3(0, y_balcon + 0.09, z_balcon + 0.14))
			for lado in [-1.0, 1.0]:
				_pieza(raiz, _caja(Vector3(0.03, 0.13, 0.3)), adorno, Vector3(lado * ancho * 0.37, y_balcon + 0.09, z_balcon))
				_pieza(raiz, _cilindro(0.025, 0.025, alto_camarote * 0.85), adorno, Vector3(lado * ancho * 0.36, y_balcon + alto_camarote * 0.43, z_balcon + 0.13))
			_pieza(raiz, _caja(Vector3(ancho * 0.8, 0.05, 0.34)), adorno, Vector3(0, techo + 0.02, z_balcon - 0.02))


# Medidas y colores que comparten todos los camarotes especiales de popa.
class Camarote:
	var largo: float
	var h: float
	var z: float
	var fondo: float
	var w: float
	var base: float
	var trasera: float
	var pared: Color
	var adorno: Color
	var luz: Color
	var brillo: StandardMaterial3D


static func _popa_especial(raiz: Node3D, estilo: String, largo: float, ancho: float, alto: float, h: float, pared: Color, adorno: Color, luz: Color) -> void:
	var cam := Camarote.new()
	cam.largo = largo
	cam.h = h
	cam.z = largo * 0.34
	cam.fondo = largo * 0.22
	cam.w = ancho * 0.7
	cam.base = altura_cubierta(_t_de_z(cam.z, largo), alto) - 0.12
	cam.trasera = cam.z + cam.fondo / 2.0 + 0.02
	cam.pared = pared
	cam.adorno = adorno
	cam.luz = luz
	cam.brillo = _material(luz, true)
	match estilo:
		"pagoda":
			_camarote_pagoda(raiz, cam)
		"fortaleza":
			_camarote_fortaleza(raiz, cam)
		"timonera":
			_camarote_timonera(raiz, cam)
		"cupula":
			_camarote_cupula(raiz, cam)
		"torre":
			_camarote_torre(raiz, cam)
		"fanales":
			_camarote_fanales(raiz, cam)
		"toldo":
			_camarote_toldo(raiz, cam)
		"cabana":
			_camarote_cabana(raiz, cam)


static func _camarote_pagoda(raiz: Node3D, cam: Camarote) -> void:
	var alto_bajo := cam.h * 1.1
	_pieza(raiz, _caja(Vector3(cam.w * 0.9, alto_bajo, cam.fondo * 0.9)), cam.pared, Vector3(0, cam.base + alto_bajo / 2.0, cam.z))
	for i in 3:
		_pieza(raiz, _caja(Vector3(0.12, 0.14, 0.03)), cam.luz, Vector3((i - 1) * cam.w * 0.28, cam.base + alto_bajo * 0.55, cam.z + cam.fondo * 0.45 + 0.01)).material_override = cam.brillo
	for esquina in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_pieza(raiz, _cilindro(0.035, 0.035, alto_bajo), Color("b5302a"), Vector3(esquina.x * cam.w * 0.47, cam.base + alto_bajo / 2.0, cam.z + esquina.y * cam.fondo * 0.47))
	var y := cam.base + alto_bajo
	for piso in 2:
		var escala := 1.0 - 0.38 * piso
		var tejado := Node3D.new()
		tejado.position = Vector3(0, y + 0.12 * escala, cam.z)
		tejado.scale.x = cam.w / cam.fondo
		raiz.add_child(tejado)
		_pieza(tejado, _piramide(cam.fondo * 0.78 * escala, 0.05, 0.24 * escala), cam.pared.darkened(0.45), Vector3.ZERO).rotation.y = PI / 4.0
		for esquina in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var punta := _pieza(raiz, _cilindro(0.0, 0.035, 0.14), cam.adorno, Vector3(esquina.x * cam.w * 0.62 * escala, y + 0.06, cam.z + esquina.y * cam.fondo * 0.62 * escala))
			punta.rotation = Vector3(esquina.y * 0.7, 0.0, -esquina.x * 0.7)
		y += 0.24 * escala
		if piso == 0:
			var alto_alto := cam.h * 0.55
			_pieza(raiz, _caja(Vector3(cam.w * 0.5, alto_alto, cam.fondo * 0.5)), cam.pared, Vector3(0, y + alto_alto / 2.0, cam.z))
			y += alto_alto
	_pieza(raiz, _esfera(0.05), cam.adorno, Vector3(0, y + 0.05, cam.z))


static func _camarote_fortaleza(raiz: Node3D, cam: Camarote) -> void:
	var muro := cam.h * 1.25
	_pieza(raiz, _caja(Vector3(cam.w, muro, cam.fondo)), cam.pared, Vector3(0, cam.base + muro / 2.0, cam.z))
	_pieza(raiz, _caja(Vector3(cam.w * 1.04, 0.06, cam.fondo * 1.04)), cam.pared.darkened(0.2), Vector3(0, cam.base + muro, cam.z))
	var almena := Vector3(0.1, 0.13, 0.1)
	for i in 5:
		var x := lerpf(-cam.w / 2.0 + 0.05, cam.w / 2.0 - 0.05, i / 4.0)
		for lado_z in [-1.0, 1.0]:
			_pieza(raiz, _caja(almena), cam.pared, Vector3(x, cam.base + muro + 0.09, cam.z + lado_z * (cam.fondo / 2.0 - 0.05)))
	for i in 3:
		var zz := lerpf(cam.z - cam.fondo / 2.0 + 0.05, cam.z + cam.fondo / 2.0 - 0.05, (i + 1) / 4.0)
		for lado in [-1.0, 1.0]:
			_pieza(raiz, _caja(almena), cam.pared, Vector3(lado * (cam.w / 2.0 - 0.05), cam.base + muro + 0.09, zz))
	for i in 2:
		_pieza(raiz, _caja(Vector3(0.05, 0.16, 0.03)), Color("141414"), Vector3((i - 0.5) * cam.w * 0.4, cam.base + muro * 0.55, cam.trasera))
	for lado in [-1.0, 1.0]:
		var torre := Vector3(lado * cam.w / 2.0, 0, cam.z + cam.fondo / 2.0)
		_pieza(raiz, _cilindro(0.13, 0.15, muro * 1.35), cam.pared.lightened(0.08), torre + Vector3(0, cam.base + muro * 0.67, 0))
		_pieza(raiz, _cilindro(0.0, 0.18, 0.3), cam.adorno, torre + Vector3(0, cam.base + muro * 1.35 + 0.15, 0))
		_pieza(raiz, _caja(Vector3(0.04, 0.12, 0.04)), cam.luz, torre + Vector3(lado * 0.1, cam.base + muro * 0.9, 0.1)).material_override = cam.brillo


static func _camarote_timonera(raiz: Node3D, cam: Camarote) -> void:
	_pieza(raiz, _caja(Vector3(cam.w * 1.05, 0.2, cam.fondo * 1.1)), cam.pared, Vector3(0, cam.base + 0.1, cam.z))
	_pieza(raiz, _caja(Vector3(cam.w * 1.12, 0.04, cam.fondo * 1.16)), COLOR_CUBIERTA, Vector3(0, cam.base + 0.22, cam.z))
	var suelo := cam.base + 0.24
	for lado in [-1.0, 1.0]:
		_pieza(raiz, _caja(Vector3(0.03, 0.14, cam.fondo * 1.1)), cam.adorno, Vector3(lado * cam.w * 0.55, suelo + 0.07, cam.z))
	_pieza(raiz, _caja(Vector3(cam.w * 1.1, 0.14, 0.03)), cam.adorno, Vector3(0, suelo + 0.07, cam.z + cam.fondo * 0.55))
	var timon := _timon(cam.adorno, cam.largo * TALLA)
	timon.position = Vector3(0, suelo, cam.z + cam.fondo * 0.3)
	raiz.add_child(timon)
	var alto_toldo := 0.85 + cam.h * 0.3
	for esquina in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_pieza(raiz, _cilindro(0.022, 0.022, alto_toldo), COLOR_MADERA, Vector3(esquina.x * cam.w * 0.5, suelo + alto_toldo / 2.0, cam.z + esquina.y * cam.fondo * 0.5))
	for i in 5:
		var tira := _pieza(raiz, _caja(Vector3(cam.w * 1.08 / 5.0, 0.03, cam.fondo * 1.1)), cam.adorno if i % 2 == 0 else Color("f3ecdf"), Vector3((i - 2) * cam.w * 1.08 / 5.0, suelo + alto_toldo + 0.02, cam.z))
		tira.rotation.x = 0.08


# Timón delante del camarote de popa. El origen es donde pisa el timonel, mirando a proa;
# si un mástil estorba, timonel y rueda se adelantan hasta quedar delante de él.
static func _poner_timon(raiz: Node3D, largo: float, alto: float, mastiles: Array[Vector3], adorno: Color) -> void:
	var talla := largo * TALLA
	var z := largo * 0.23 - 0.1 * talla
	for datos in mastiles:
		if datos.x > z - 0.34 * talla - 0.09 and datos.x < z + 0.1 * talla + 0.09:
			z = minf(z, datos.x - 0.09 - 0.1 * talla)
	var timon := _timon(adorno, talla)
	timon.position = Vector3(0, altura_cubierta(_t_de_z(z, largo), alto) - 0.02, z)
	raiz.add_child(timon)


# Medido para un timonel de escala 1: rueda a la altura de sus manos con los brazos al frente.
static func _timon(adorno: Color, talla: float) -> Node3D:
	var timon := Node3D.new()
	timon.name = "Timon"
	timon.scale = Vector3.ONE * talla
	_pieza(timon, _caja(Vector3(0.18, 0.05, 0.18)), COLOR_MADERA, Vector3(0, 0.025, -0.31))
	_pieza(timon, _caja(Vector3(0.09, 0.5, 0.09)), COLOR_MADERA, Vector3(0, 0.25, -0.31))
	_pieza(timon, _caja(Vector3(0.12, 0.04, 0.12)), adorno, Vector3(0, 0.52, -0.31))
	_pieza(timon, _cilindro(0.018, 0.018, 0.08), COLOR_HIERRO, Vector3(0, 0.5, -0.27)).rotation.x = PI / 2.0
	var rueda := Node3D.new()
	rueda.name = "Rueda"
	rueda.position = Vector3(0, 0.5, -0.235)
	timon.add_child(rueda)
	var aro := TorusMesh.new()
	aro.inner_radius = 0.165
	aro.outer_radius = 0.2
	aro.rings = 24
	_pieza(rueda, aro, COLOR_MADERA, Vector3.ZERO).rotation.x = PI / 2.0
	var cubo := _pieza(rueda, _cilindro(0.04, 0.04, 0.05), adorno, Vector3.ZERO)
	cubo.rotation.x = PI / 2.0
	for k in 8:
		var giro := k * PI / 4.0
		_pieza(rueda, _cilindro(0.013, 0.013, 0.2), COLOR_MADERA, Vector3(sin(giro), cos(giro), 0) * 0.1).rotation.z = -giro
		_pieza(rueda, _cilindro(0.016, 0.02, 0.07), COLOR_MADERA, Vector3(sin(giro), cos(giro), 0) * 0.235).rotation.z = -giro
	return timon


static func _camarote_cupula(raiz: Node3D, cam: Camarote) -> void:
	_pieza(raiz, _caja(Vector3(cam.w, cam.h, cam.fondo)), cam.pared, Vector3(0, cam.base + cam.h / 2.0, cam.z))
	_pieza(raiz, _caja(Vector3(cam.w * 1.08, 0.06, cam.fondo * 1.08)), cam.adorno, Vector3(0, cam.base + cam.h, cam.z))
	for i in 3:
		_pieza(raiz, _caja(Vector3(0.12, 0.16, 0.03)), cam.luz, Vector3((i - 1) * cam.w * 0.28, cam.base + cam.h * 0.5, cam.trasera)).material_override = cam.brillo
	var radio := minf(cam.w, cam.fondo) * 0.4
	_pieza(raiz, _cilindro(radio, radio, 0.16), cam.pared.lightened(0.1), Vector3(0, cam.base + cam.h + 0.08, cam.z))
	for k in 6:
		var a := k * TAU / 6.0
		_pieza(raiz, _caja(Vector3(0.05, 0.08, 0.02)), cam.luz, Vector3(sin(a) * radio, cam.base + cam.h + 0.09, cam.z + cos(a) * radio)).rotation.y = a
	var cupula := _pieza(raiz, _esfera(radio * 1.05), cam.adorno, Vector3(0, cam.base + cam.h + 0.16, cam.z))
	cupula.scale.y = 0.85
	_pieza(raiz, _cilindro(0.0, 0.03, 0.2), cam.adorno, Vector3(0, cam.base + cam.h + 0.16 + radio * 0.9 + 0.08, cam.z))


static func _camarote_torre(raiz: Node3D, cam: Camarote) -> void:
	var radio := minf(cam.w, cam.fondo) * 0.36
	var alto_torre := cam.h * 0.9 + 0.7
	_pieza(raiz, _caja(Vector3(cam.w, cam.h * 0.7, cam.fondo)), cam.pared.darkened(0.15), Vector3(0, cam.base + cam.h * 0.35, cam.z))
	_pieza(raiz, _cilindro(radio * 0.9, radio, alto_torre), cam.pared, Vector3(0, cam.base + alto_torre / 2.0, cam.z))
	for franja in 2:
		_pieza(raiz, _cilindro(radio * 0.95, radio * 0.95, 0.07), cam.adorno, Vector3(0, cam.base + alto_torre * (0.4 + 0.3 * franja), cam.z))
	var y := cam.base + alto_torre
	_pieza(raiz, _cilindro(radio * 1.15, radio * 1.15, 0.05), COLOR_MADERA, Vector3(0, y, cam.z))
	_pieza(raiz, _cilindro(radio * 0.6, radio * 0.6, 0.2), cam.luz, Vector3(0, y + 0.12, cam.z)).material_override = cam.brillo
	_pieza(raiz, _cilindro(0.0, radio * 0.95, 0.3), cam.adorno, Vector3(0, y + 0.37, cam.z))


static func _camarote_fanales(raiz: Node3D, cam: Camarote) -> void:
	_pieza(raiz, _caja(Vector3(cam.w, cam.h, cam.fondo)), cam.pared, Vector3(0, cam.base + cam.h / 2.0, cam.z))
	_pieza(raiz, _caja(Vector3(cam.w * 1.1, 0.07, cam.largo * 0.25)), COLOR_CUBIERTA, Vector3(0, cam.base + cam.h + 0.035, cam.z))
	for i in 3:
		_pieza(raiz, _caja(Vector3(0.12, 0.12, 0.03)), cam.luz, Vector3((i - 1) * cam.w * 0.28, cam.base + cam.h * 0.5, cam.trasera)).material_override = cam.brillo
	for i in 3:
		var x := (i - 1) * cam.w * 0.36
		var grande := 1.75 if i == 1 else 1.4
		var y := cam.base + cam.h + 0.3 * grande + 0.1
		var farol := Vector3(x, y, cam.trasera + 0.14)
		_entre(raiz, Vector3(x, cam.base + cam.h, cam.trasera - 0.05), farol + Vector3(0, 0.15 * grande, 0), 0.02, cam.adorno)
		var vidrio := _cilindro(0.075 * grande, 0.06 * grande, 0.2 * grande)
		vidrio.radial_segments = 6
		_pieza(raiz, vidrio, cam.luz, farol).material_override = cam.brillo
		_pieza(raiz, _cilindro(0.0, 0.1 * grande, 0.12 * grande), cam.adorno, farol + Vector3(0, 0.15 * grande, 0))
		_pieza(raiz, _cilindro(0.06 * grande, 0.0, 0.08 * grande), cam.adorno, farol - Vector3(0, 0.14 * grande, 0))


static func _camarote_toldo(raiz: Node3D, cam: Camarote) -> void:
	_pieza(raiz, _caja(Vector3(cam.w * 1.05, 0.12, cam.fondo * 1.1)), COLOR_CUBIERTA, Vector3(0, cam.base + 0.06, cam.z))
	var alto_toldo := 0.7 + cam.h * 0.4
	for esquina in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_pieza(raiz, _cilindro(0.025, 0.025, alto_toldo), COLOR_MADERA, Vector3(esquina.x * cam.w * 0.5, cam.base + alto_toldo / 2.0, cam.z + esquina.y * cam.fondo * 0.5))
	for i in 4:
		var lona := PrismMesh.new()
		lona.size = Vector3(cam.w * 1.15, 0.4, cam.fondo * 1.15 / 4.0)
		_pieza(raiz, lona, cam.pared if i % 2 == 0 else Color("f3ecdf"), Vector3(0, cam.base + alto_toldo + 0.2, cam.z + (i - 1.5) * cam.fondo * 1.15 / 4.0))
	for i in 2:
		_pieza(raiz, _cilindro(0.09, 0.09, 0.22), COLOR_MADERA, Vector3((i - 0.5) * cam.w * 0.4, cam.base + 0.23, cam.z + cam.fondo * 0.1))
		_pieza(raiz, _cilindro(0.095, 0.095, 0.03), COLOR_HIERRO, Vector3((i - 0.5) * cam.w * 0.4, cam.base + 0.27, cam.z + cam.fondo * 0.1))
	_pieza(raiz, _esfera(0.05), cam.luz, Vector3(0, cam.base + alto_toldo - 0.1, cam.z)).material_override = cam.brillo


static func _camarote_cabana(raiz: Node3D, cam: Camarote) -> void:
	_pieza(raiz, _caja(Vector3(cam.w, cam.h, cam.fondo)), cam.pared, Vector3(0, cam.base + cam.h / 2.0, cam.z))
	for i in 4:
		_pieza(raiz, _caja(Vector3(cam.w * 1.01, 0.02, cam.fondo * 1.01)), cam.pared.darkened(0.3), Vector3(0, cam.base + cam.h * (0.2 + 0.2 * i), cam.z))
	var tejado := PrismMesh.new()
	tejado.size = Vector3(cam.w * 1.2, 0.45, cam.fondo * 1.15)
	_pieza(raiz, tejado, COLOR_MADERA.lightened(0.1), Vector3(0, cam.base + cam.h + 0.225, cam.z))
	var chimenea := Vector3(cam.w * 0.28, cam.base + cam.h + 0.35, cam.z - cam.fondo * 0.15)
	_pieza(raiz, _caja(Vector3(0.11, 0.4, 0.11)), cam.adorno, chimenea)
	_pieza(raiz, _caja(Vector3(0.14, 0.05, 0.14)), cam.adorno.darkened(0.3), chimenea + Vector3(0, 0.2, 0))
	var ventana := _pieza(raiz, _cilindro(0.08, 0.08, 0.03), cam.luz, Vector3(0, cam.base + cam.h * 0.55, cam.trasera))
	ventana.rotation.x = PI / 2.0
	ventana.material_override = cam.brillo
	_pieza(raiz, _caja(Vector3(0.2, 0.03, 0.04)), COLOR_MADERA, Vector3(0, cam.base + cam.h * 0.55, cam.trasera + 0.02))


static func _piramide(radio: float, arriba: float, alto: float) -> CylinderMesh:
	var malla := _cilindro(arriba, radio * sqrt(2.0), alto)
	malla.radial_segments = 4
	return malla


static func _proa(raiz: Node3D, pieza: Dictionary, largo: float, alto: float) -> void:
	var estilo: String = pieza.get("estilo", pieza["id"])
	if estilo == "sencilla":
		return
	var color: Color = pieza["color"]
	var figura := Node3D.new()
	# Va bajo el bauprés: más abajo e inclinada hacia delante para no cruzarse con él.
	figura.position = Vector3(0, altura_cubierta(1.0, alto) - 0.45, -largo / 2.0 - 0.04)
	figura.scale = Vector3.ONE * 1.7
	raiz.add_child(figura)
	match estilo:
		"espolon":
			figura.position = Vector3(0, alto * 0.05, -largo / 2.0 + 0.05)
			figura.scale = Vector3.ONE * 1.3
			_pieza(figura, _cilindro(0.0, 0.12, 0.7), color, Vector3(0, 0, -0.3)).rotation.x = -PI / 2.0
			_pieza(figura, _cilindro(0.13, 0.13, 0.08), color.darkened(0.3), Vector3(0, 0, 0.02)).rotation.x = -PI / 2.0
		"sirena":
			figura.rotation.x = -1.0
			var cuerpo := CapsuleMesh.new()
			cuerpo.radius = 0.065
			cuerpo.height = 0.36
			_pieza(figura, cuerpo, color, Vector3(0, 0.12, 0))
			_pieza(figura, _esfera(0.07), color, Vector3(0, 0.36, 0))
			_pieza(figura, _esfera(0.06), color.darkened(0.25), Vector3(0, 0.38, 0.04))
			_pieza(figura, _cilindro(0.06, 0.0, 0.26), color.darkened(0.15), Vector3(0, -0.16, 0.02))
			for lado in [-1.0, 1.0]:
				_pieza(figura, _caja(Vector3(0.03, 0.2, 0.03)), color, Vector3(lado * 0.08, 0.2, -0.03)).rotation.z = lado * 0.5
		"aguila":
			figura.rotation.x = -0.9
			_pieza(figura, _cilindro(0.05, 0.07, 0.22), Color("6b4a30"), Vector3(0, 0.05, 0))
			_pieza(figura, _esfera(0.1), color, Vector3(0, 0.22, -0.02))
			_pieza(figura, _cilindro(0.0, 0.045, 0.14), Color("e2b13a"), Vector3(0, 0.2, -0.16)).rotation.x = -PI / 2.0
			for lado in [-1.0, 1.0]:
				_pieza(figura, _esfera(0.02), Color("1b1b1b"), Vector3(lado * 0.06, 0.25, -0.08))
				var ala := _pieza(figura, _caja(Vector3(0.04, 0.16, 0.45)), Color("6b4a30"), Vector3(lado * 0.15, -0.1, 0.12))
				ala.rotation = Vector3(-0.75, lado * 0.35, 0.0)
		"dragon":
			figura.rotation.x = -0.9
			_pieza(figura, _cilindro(0.06, 0.08, 0.3), color, Vector3(0, 0.08, 0))
			var cabeza := Node3D.new()
			cabeza.position = Vector3(0, 0.28, -0.06)
			cabeza.rotation.x = 0.75
			figura.add_child(cabeza)
			_pieza(cabeza, _caja(Vector3(0.15, 0.12, 0.26)), color, Vector3(0, 0, -0.06))
			_pieza(cabeza, _caja(Vector3(0.12, 0.05, 0.2)), color.darkened(0.25), Vector3(0, -0.08, -0.08)).rotation.x = 0.25
			for lado in [-1.0, 1.0]:
				var cuerno := _pieza(cabeza, _cilindro(0.0, 0.03, 0.15), Color("e8e0c8"), Vector3(lado * 0.06, 0.05, 0.1))
				cuerno.rotation = Vector3(1.35, 0.0, -lado * 0.35)
				_pieza(cabeza, _caja(Vector3(0.03, 0.03, 0.03)), Color("ff4a2a"), Vector3(lado * 0.075, 0.03, -0.1)) \
					.material_override = _material(Color("ff4a2a"), true)
			for i in 3:
				_pieza(figura, _cilindro(0.0, 0.03, 0.09), color.darkened(0.3), Vector3(0, 0.02 + i * 0.1, 0.07)).rotation.x = 0.5
		_:
			figura.rotation.x = -0.9
			Mascarones.crear(figura, estilo, color)


static func altura_cubierta(t: float, alto: float) -> float:
	return alto + alto * _perfil["arrufo"] * (pow(1.0 - t, 4.0) * _perfil["popa"] + pow(t, 5.0) * _perfil["proa"])


static func media_manga(t: float, ancho: float) -> float:
	var espejo: float = _perfil["espejo"]
	return ancho / 2.0 * pow(maxf(0.0, sin(PI * (espejo + (1.0 - espejo) * t))), _perfil["llenura"])


static func _t_de_z(z: float, largo: float) -> float:
	return (largo / 2.0 - z) / largo


static func _casco(largo: float, ancho: float, alto: float, color: Color, adorno: Color, franja: Color) -> ArrayMesh:
	var filas: Array = []
	for i in SECCIONES + 1:
		var t := float(i) / SECCIONES
		var z := lerpf(largo / 2.0, -largo / 2.0, t)
		var media := media_manga(t, ancho)
		var cubierta := altura_cubierta(t, alto)
		var fondo := lerpf(-alto * _perfil["quilla"], alto * 0.25, pow(t, 3.0))
		var fila: Array[Vector3] = []
		for j in ANILLO + 1:
			var phi := PI / 2.0 * j / ANILLO
			fila.append(Vector3(media * cos(phi), lerpf(cubierta, fondo, sin(phi)), z))
		filas.append(fila)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in SECCIONES:
		var actual: Array[Vector3] = filas[i]
		var siguiente: Array[Vector3] = filas[i + 1]
		for j in ANILLO:
			var tono := color
			if j == 0:
				tono = adorno
			elif j == 2:
				tono = franja
			elif (actual[j].y + actual[j + 1].y) / 2.0 < 0.02:
				tono = COLOR_FONDO
			for lado in [1.0, -1.0]:
				var espejo := Vector3(lado, 1.0, 1.0)
				var a: Vector3 = actual[j] * espejo
				var b: Vector3 = siguiente[j] * espejo
				var c: Vector3 = siguiente[j + 1] * espejo
				var d: Vector3 = actual[j + 1] * espejo
				if lado > 0.0:
					_tri(st, a, b, c, tono)
					_tri(st, a, c, d, tono)
				else:
					_tri(st, a, c, b, tono)
					_tri(st, a, d, c, tono)

	var popa: Array[Vector3] = filas[0]
	var centro := Vector3(0, (popa[0].y + popa[ANILLO].y) / 2.0, popa[0].z)
	var tono_popa := color.darkened(0.2)
	_tri(st, centro, popa[0] * Vector3(-1, 1, 1), popa[0], tono_popa)
	for j in ANILLO:
		var derecha_a: Vector3 = popa[j]
		var derecha_b: Vector3 = popa[j + 1]
		var tono := COLOR_FONDO if (derecha_a.y + derecha_b.y) / 2.0 < 0.02 else tono_popa
		_tri(st, centro, derecha_a, derecha_b, tono)
		_tri(st, centro, derecha_b * Vector3(-1, 1, 1), derecha_a * Vector3(-1, 1, 1), tono)

	st.index()
	st.generate_normals()
	return st.commit()


static func _cubierta(largo: float, ancho: float, alto: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tablas := 6
	for i in SECCIONES:
		var t0 := float(i) / SECCIONES
		var t1 := float(i + 1) / SECCIONES
		var z0 := lerpf(largo / 2.0, -largo / 2.0, t0)
		var z1 := lerpf(largo / 2.0, -largo / 2.0, t1)
		var m0 := media_manga(t0, ancho) * 0.9
		var m1 := media_manga(t1, ancho) * 0.9
		var y0 := altura_cubierta(t0, alto) - 0.12
		var y1 := altura_cubierta(t1, alto) - 0.12
		for k in tablas:
			var u0 := lerpf(-1.0, 1.0, float(k) / tablas)
			var u1 := lerpf(-1.0, 1.0, float(k + 1) / tablas)
			var tono := COLOR_CUBIERTA if k % 2 == 0 else COLOR_CUBIERTA.darkened(0.1)
			var a := Vector3(u0 * m0, y0, z0)
			var b := Vector3(u1 * m0, y0, z0)
			var c := Vector3(u1 * m1, y1, z1)
			var d := Vector3(u0 * m1, y1, z1)
			_tri(st, a, c, b, tono)
			_tri(st, a, d, c, tono)
	st.generate_normals()
	return st.commit()


static func _vela(ancho: float, alto: float, comba: float) -> ArrayMesh:
	return _vela_esquinas(Vector2(-ancho / 2.0, -alto / 2.0), Vector2(ancho / 2.0, -alto / 2.0),
		Vector2(-ancho * 0.43, alto / 2.0), Vector2(ancho * 0.43, alto / 2.0), comba)


# Tela entre cuatro esquinas (si las dos de arriba coinciden, sale triangular).
static func _vela_esquinas(abajo_i: Vector2, abajo_d: Vector2, arriba_i: Vector2, arriba_d: Vector2, comba: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columnas := 6
	var filas := 5
	for i in columnas:
		for j in filas:
			var u0 := float(i) / columnas
			var u1 := float(i + 1) / columnas
			var v0 := float(j) / filas
			var v1 := float(j + 1) / filas
			for uv in [Vector2(u0, v0), Vector2(u1, v1), Vector2(u1, v0), Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v1)]:
				st.set_uv(Vector2(uv.x, 1.0 - uv.y))
				var punto: Vector2 = abajo_i.lerp(abajo_d, uv.x).lerp(arriba_i.lerp(arriba_d, uv.x), uv.y)
				var bolsa: float = sin(uv.x * PI) * sin(lerpf(0.15, 0.95, uv.y) * PI) * comba
				st.add_vertex(Vector3(punto.x, punto.y, -bolsa))
	st.generate_normals()
	return st.commit()


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	for punto in [a, b, c]:
		st.set_color(color)
		st.add_vertex(punto)


static func _agregar(raiz: Node3D, malla: ArrayMesh) -> void:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = _material_vertices()
	raiz.add_child(pieza)


static func _pieza(padre: Node3D, malla: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = _material(color)
	pieza.position = pos
	padre.add_child(pieza)
	return pieza


static func _tela(padre: Node3D, malla: Mesh, dibujo: Texture2D, pos: Vector3) -> MeshInstance3D:
	var pieza := _pieza(padre, malla, Color.WHITE, pos)
	pieza.material_override = _material_tela(dibujo)
	return pieza


static func _esfera(radio: float) -> SphereMesh:
	var esfera := SphereMesh.new()
	esfera.radius = radio
	esfera.height = radio * 2.0
	esfera.radial_segments = 10
	esfera.rings = 5
	return esfera


static func _caja(tam: Vector3) -> BoxMesh:
	var caja := BoxMesh.new()
	caja.size = tam
	return caja


static func _cilindro(radio_arriba: float, radio_abajo: float, alto: float) -> CylinderMesh:
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio_arriba
	cilindro.bottom_radius = radio_abajo
	cilindro.height = alto
	cilindro.radial_segments = 10
	cilindro.rings = 1
	return cilindro


static func _material(color: Color, brilla := false) -> StandardMaterial3D:
	var clave := "solido|%s|%s" % [color.to_html(), brilla]
	if not _materiales.has(clave):
		var material := StandardMaterial3D.new()
		material.albedo_color = Paleta.armonizar(color)
		material.roughness = 0.7
		if brilla:
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = 1.4
		else:
			Texturas.aplicar(material, Texturas.tipo_de_color(color))
		_materiales[clave] = material
	return _materiales[clave]


static func _material_tela(dibujo: Texture2D, bandera := false) -> ShaderMaterial:
	var clave := "tela|%d|%s" % [dibujo.get_instance_id(), bandera]
	if not _materiales.has(clave):
		var material := ShaderMaterial.new()
		material.shader = SHADER_TELA
		material.set_shader_parameter("dibujo", dibujo)
		material.set_shader_parameter("ondear", 1.0 if bandera else 0.0)
		if ResourceLoader.exists("res://texturas/tela.png"):
			material.set_shader_parameter("lona", load("res://texturas/tela.png"))
		_materiales[clave] = material
	return _materiales[clave]


static func _material_vertices() -> StandardMaterial3D:
	if not _materiales.has("vertices"):
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true
		material.roughness = 0.75
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		Texturas.aplicar(material, "casco")
		_materiales["vertices"] = material
	return _materiales["vertices"]
