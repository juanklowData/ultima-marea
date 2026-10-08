class_name Desgaste
extends Node3D

# Daño a la vista de un barco: según la vida perdida se abren grietas en cubierta y en
# los costados, saltan astillas y sale humo cada vez más negro. Al repararse con tablas
# desaparece en el mismo orden.

# Fracción de vida perdida a partir de la que sale humo.
const HUMO_DESDE := 0.3
const COLOR_GRIETA := Color("140d09")
const COLOR_BORDE := Color("a7835a")
const COLOR_ASTILLA := Color("8a6a45")
const GRIETAS_CUBIERTA := 3
const GRIETAS_COSTADO := 6

static var _textura_humo: GradientTexture2D
static var _rampa_humo: Gradient
static var _curva_humo: Curve

var mundo: Principal
# Cada marca: [nodo, fracción de vida perdida desde la que se ve].
var marcas: Array = []
var humo: CPUParticles3D
var caja := BoxMesh.new()


func preparar(nuevo_mundo: Principal, tipo: String) -> void:
	mundo = nuevo_mundo
	var medidas: Dictionary = ModeloBarco.MEDIDAS[tipo]
	var largo: float = medidas["largo"]
	var ancho: float = medidas["ancho"]
	var alto: float = medidas["alto"]

	var umbrales: Array[float] = []
	for i in GRIETAS_CUBIERTA + GRIETAS_COSTADO:
		umbrales.append(0.12 + i * 0.09)
	umbrales.shuffle()
	var n := 0
	for i in GRIETAS_CUBIERTA:
		var origen := Vector3(randf_range(-0.22, 0.22) * ancho, alto + 0.012, randf_range(-0.25, 0.25) * largo)
		var nodo := _grieta(origen, Vector3.UP, Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU), ancho * randf_range(0.45, 0.7))
		marcas.append([nodo, umbrales[n]])
		n += 1
	for i in GRIETAS_COSTADO:
		var lado := -1.0 if i % 2 == 0 else 1.0
		var origen := Vector3(lado * ancho * 0.49, alto * randf_range(0.4, 0.75), randf_range(-0.2, 0.2) * largo)
		var normal := Vector3(lado, 0, 0)
		var rumbo := Vector3(0, randf_range(-0.6, 0.6), 1.0 if randf() < 0.5 else -1.0).normalized()
		var nodo := _grieta(origen, normal, rumbo, largo * randf_range(0.2, 0.28), 1.5)
		# Astillas que asoman de la grieta del casco.
		for k in 2:
			var astilla := _barra(nodo, origen + normal * 0.03 + Vector3(0, randf_range(-0.05, 0.05), randf_range(-0.1, 0.1)),
				(normal + Vector3(0, randf_range(-0.4, 0.6), randf_range(-0.8, 0.8))).normalized(), Vector3.UP,
				randf_range(0.12, 0.2), 0.035, 0.02, COLOR_ASTILLA)
			astilla.position += astilla.basis.z.normalized() * 0.05
		marcas.append([nodo, umbrales[n]])
		n += 1

	# Sale por popa para que las velas no lo tapen desde la cámara.
	humo = _crear_humo(ancho)
	humo.position = Vector3(0, alto + 0.3, largo * 0.32)
	add_child(humo)
	actualizar(0.0, 0.0, 0.0)


# Grieta que parte de "origen" y avanza en zigzag por el plano perpendicular a "normal",
# con una rama lateral. El borde claro de madera rota la hace resaltar sobre la cubierta.
func _grieta(origen: Vector3, normal: Vector3, direccion: Vector3, largo: float, grosor_base := 1.0) -> Node3D:
	var nodo := Node3D.new()
	add_child(nodo)
	var tramos := 5
	var punto := origen
	var rumbo := direccion
	for t in tramos:
		rumbo = rumbo.rotated(normal, randf_range(-0.7, 0.7)).normalized()
		var paso := largo / tramos * randf_range(0.7, 1.3)
		var grosor := lerpf(0.05, 0.015, float(t) / tramos) * grosor_base
		var siguiente := punto + rumbo * paso
		_barra(nodo, (punto + siguiente) * 0.5 - normal * 0.002, rumbo, normal, paso * 1.08, grosor * 1.9, 0.012, COLOR_BORDE)
		_barra(nodo, (punto + siguiente) * 0.5 + normal * 0.004, rumbo, normal, paso * 1.08, grosor, 0.014, COLOR_GRIETA)
		if t == 1:
			var rama := rumbo.rotated(normal, PI * 0.35 * (1.0 if randf() < 0.5 else -1.0))
			var fin := siguiente + rama * paso * 1.2
			_barra(nodo, (siguiente + fin) * 0.5 + normal * 0.004, rama, normal, paso * 1.2, grosor * 0.6, 0.014, COLOR_GRIETA)
		punto = siguiente
	return nodo


# Caja fina orientada a lo largo de "direccion", apoyada en el plano de "normal".
func _barra(padre: Node3D, centro: Vector3, direccion: Vector3, normal: Vector3, largo: float, ancho: float, grueso: float, color: Color) -> MeshInstance3D:
	var z := direccion.normalized()
	var x := normal.cross(z).normalized()
	var y := z.cross(x)
	var pieza := MeshInstance3D.new()
	pieza.mesh = caja
	pieza.material_override = mundo.material(color)
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pieza.transform = Transform3D(Basis(x * ancho, y * grueso, z * largo), centro)
	padre.add_child(pieza)
	return pieza


func _crear_humo(ancho: float) -> CPUParticles3D:
	if _textura_humo == null:
		var degradado := Gradient.new()
		degradado.set_color(0, Color(1, 1, 1, 1))
		degradado.set_color(1, Color(1, 1, 1, 0))
		degradado.add_point(0.45, Color(1, 1, 1, 0.65))
		_textura_humo = GradientTexture2D.new()
		_textura_humo.gradient = degradado
		_textura_humo.fill = GradientTexture2D.FILL_RADIAL
		_textura_humo.fill_from = Vector2(0.5, 0.5)
		_textura_humo.fill_to = Vector2(0.5, 0.0)
		_textura_humo.width = 64
		_textura_humo.height = 64
		_rampa_humo = Gradient.new()
		_rampa_humo.set_color(0, Color(1, 1, 1, 0))
		_rampa_humo.set_color(1, Color(1, 1, 1, 0))
		_rampa_humo.add_point(0.15, Color(1, 1, 1, 0.75))
		_rampa_humo.add_point(0.6, Color(1, 1, 1, 0.4))
		_curva_humo = Curve.new()
		_curva_humo.add_point(Vector2(0, 0.35))
		_curva_humo.add_point(Vector2(1, 1))
	var materia := StandardMaterial3D.new()
	materia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materia.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	materia.vertex_color_use_as_albedo = true
	materia.albedo_texture = _textura_humo
	materia.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var plano := QuadMesh.new()
	plano.size = Vector2.ONE
	plano.material = materia

	var particulas := CPUParticles3D.new()
	particulas.mesh = plano
	particulas.amount = 24
	particulas.lifetime = 3.0
	particulas.local_coords = false
	particulas.emitting = false
	particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = ancho * 0.3
	particulas.direction = Vector3.UP
	particulas.spread = 15.0
	particulas.gravity = Vector3(0.5, 0.3, 0.35)
	particulas.initial_velocity_min = 1.2
	particulas.initial_velocity_max = 1.7
	particulas.damping_min = 0.2
	particulas.damping_max = 0.4
	particulas.angle_min = 0.0
	particulas.angle_max = 360.0
	particulas.angular_velocity_min = -25.0
	particulas.angular_velocity_max = 25.0
	particulas.scale_amount_min = 0.7
	particulas.scale_amount_max = 1.0
	particulas.scale_amount_curve = _curva_humo
	particulas.color_ramp = _rampa_humo
	particulas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particulas


# danio: fracción de vida perdida (0 entero, 1 a punto de hundirse). Al hundirse se apaga el humo.
func actualizar(_delta: float, danio: float, hundimiento: float) -> void:
	for marca in marcas:
		marca[0].visible = danio >= marca[1]
	var cerca := mundo != null and global_position.distance_to(mundo.foco) < Principal.DISTANCIA_VISIBLE
	var humea := cerca and danio >= HUMO_DESDE and hundimiento < 0.5
	if humea != humo.emitting:
		humo.emitting = humea
	if humea:
		var fuerza := clampf((danio - HUMO_DESDE) / (1.0 - HUMO_DESDE), 0.0, 1.0)
		var gris := lerpf(0.7, 0.12, fuerza)
		humo.color = Color(gris, gris, gris, lerpf(0.55, 0.9, fuerza))
		humo.speed_scale = lerpf(0.8, 1.2, fuerza)
		humo.scale_amount_min = lerpf(0.6, 1.1, fuerza)
		humo.scale_amount_max = lerpf(0.9, 2.0, fuerza)
