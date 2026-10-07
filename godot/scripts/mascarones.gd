class_name Mascarones
extends RefCounted

# Mascarones de proa. La figura está inclinada hacia delante; el eje +Y local
# recorre el cuerpo y las cabezas se enderezan con _cabeza() para mirar al frente (-Z).

const NEGRO := Color("1b1b1b")
const MARFIL := Color("ece4cc")
const BRILLO_OJOS := Color("ffcc33")


static func crear(figura: Node3D, estilo: String, c: Color) -> void:
	var o := c.darkened(0.3)
	var claro := c.lightened(0.25)
	match estilo:
		"leon":
			_figura_leon(figura, c, o, claro)
		"calavera":
			_figura_calavera(figura, c, o, claro)
		"caballo", "unicornio":
			_figura_caballo(figura, c, o, claro, estilo == "unicornio")
		"tiburon":
			_figura_tiburon(figura, c, o, claro)
		"pulpo":
			_figura_pulpo(figura, c, o, claro)
		"serpiente":
			_figura_serpiente(figura, c, o, claro)
		"triton":
			_figura_triton(figura, c, o, claro)
		"angel":
			_figura_angel(figura, c, o, claro)
		"lobo":
			_figura_lobo(figura, c, o, claro)
		"toro":
			_figura_toro(figura, c, o, claro)
		"sol":
			_figura_sol(figura, c, o, claro)
		"luna":
			_figura_luna(figura, c, o, claro)
		"estrella":
			_figura_estrella(figura, c, o, claro)
		"ancla":
			_figura_ancla(figura, c, o, claro)
		"delfin":
			_figura_delfin(figura, c, o, claro)
		"cisne":
			_figura_cisne(figura, c, o, claro)
		"buho":
			_figura_buho(figura, c, o, claro)
		"carnero":
			_figura_carnero(figura, c, o, claro)
		"reina":
			_figura_reina(figura, c, o, claro)
		"vikingo":
			_figura_vikingo(figura, c, o, claro)
		"hipocampo":
			_figura_hipocampo(figura, c, o, claro)


# Figuras: c es el color elegido, o una versión oscura y claro una más clara.

static func _figura_leon(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	_cuello(figura, c)
	var cab := _cabeza(figura, Vector3(0, 0.3, -0.04))
	_p(cab, _esf(0.15), o, Vector3(0, 0, 0.04)).scale = Vector3(1.0, 1.0, 0.6)
	_p(cab, _esf(0.1), c, Vector3(0, 0, -0.06))
	_p(cab, _caja(Vector3(0.09, 0.07, 0.08)), claro, Vector3(0, -0.03, -0.15))
	_p(cab, _esf(0.022), NEGRO, Vector3(0, 0.0, -0.19))
	for lado in [-1.0, 1.0]:
		_p(cab, _esf(0.016), NEGRO, Vector3(lado * 0.04, 0.04, -0.14))
		_p(cab, _esf(0.035), o, Vector3(lado * 0.08, 0.1, -0.02))


static func _figura_calavera(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	_cuello(figura, o)
	var cab := _cabeza(figura, Vector3(0, 0.3, -0.03))
	_p(cab, _esf(0.12), c, Vector3.ZERO)
	_p(cab, _caja(Vector3(0.13, 0.06, 0.1)), c, Vector3(0, -0.1, -0.04))
	for lado in [-1.0, 1.0]:
		_p(cab, _esf(0.034), NEGRO, Vector3(lado * 0.045, 0.0, -0.095))
		var tibia := _p(cab, _cil(0.018, 0.018, 0.42), claro, Vector3(0, -0.02, 0.06))
		tibia.rotation = Vector3(0, 0, lado * 0.8)
		for punta in [-1.0, 1.0]:
			_p(tibia, _esf(0.03), claro, Vector3(0, punta * 0.21, 0))
	_p(cab, _caja(Vector3(0.025, 0.03, 0.02)), NEGRO, Vector3(0, -0.045, -0.115))
	for i in 4:
		_p(cab, _caja(Vector3(0.02, 0.025, 0.02)), MARFIL, Vector3(-0.03 + i * 0.02, -0.075, -0.1))


static func _figura_caballo(figura: Node3D, c: Color, o: Color, claro: Color, con_cuerno: bool) -> void:
	var cuello := _p(figura, _capsula(0.06, 0.32), c, Vector3(0, 0.1, 0.02))
	cuello.rotation.x = 0.2
	var cab := _cabeza(figura, Vector3(0, 0.3, -0.04))
	_p(cab, _caja(Vector3(0.1, 0.1, 0.24)), c, Vector3(0, 0, -0.08)).rotation.x = 0.25
	_p(cab, _caja(Vector3(0.085, 0.08, 0.08)), claro, Vector3(0, -0.05, -0.19))
	for lado in [-1.0, 1.0]:
		_p(cab, _cil(0.0, 0.025, 0.08), c, Vector3(lado * 0.035, 0.08, 0.0))
		_p(cab, _esf(0.015), NEGRO, Vector3(lado * 0.052, 0.02, -0.08))
	for i in 4:
		_p(figura, _caja(Vector3(0.02, 0.07, 0.05)), o, Vector3(0, 0.0 + i * 0.08, 0.08 - i * 0.01))
	if con_cuerno:
		var cuerno := _p(cab, _cil(0.0, 0.025, 0.2), MARFIL.lerp(Color("e2b13a"), 0.4), Vector3(0, 0.1, -0.1))
		cuerno.rotation.x = -0.9


static func _figura_tiburon(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	_p(figura, _capsula(0.075, 0.46), c, Vector3(0, 0.12, 0))
	_p(figura, _esf(0.07), claro, Vector3(0, 0.12, -0.03)).scale = Vector3(0.9, 2.6, 0.6)
	var aleta := _p(figura, _cil(0.0, 0.07, 0.16), o, Vector3(0, 0.12, 0.09))
	aleta.scale = Vector3(0.25, 1.0, 1.0)
	aleta.rotation.x = 0.5
	for lado in [-1.0, 1.0]:
		_p(figura, _caja(Vector3(0.14, 0.02, 0.06)), o, Vector3(lado * 0.09, 0.05, -0.01)).rotation.z = lado * -0.4
		_p(figura, _caja(Vector3(0.02, 0.12, 0.05)), o, Vector3(lado * 0.04, -0.15, 0.0)).rotation.z = lado * 0.6
		_p(figura, _esf(0.014), NEGRO, Vector3(lado * 0.055, 0.28, -0.03))
	_p(figura, _caja(Vector3(0.09, 0.025, 0.02)), NEGRO, Vector3(0, 0.26, -0.07))
	for i in 4:
		_p(figura, _cil(0.0, 0.009, 0.025), MARFIL, Vector3(-0.03 + i * 0.02, 0.27, -0.07)).rotation.x = PI


static func _figura_pulpo(figura: Node3D, c: Color, _o: Color, claro: Color) -> void:
	_p(figura, _esf(0.13), c, Vector3(0, 0.3, 0)).scale = Vector3(1.0, 1.3, 1.0)
	for lado in [-1.0, 1.0]:
		_p(figura, _esf(0.04), MARFIL, Vector3(lado * 0.055, 0.22, -0.1))
		_p(figura, _esf(0.02), NEGRO, Vector3(lado * 0.055, 0.22, -0.135))
	for k in 6:
		var angulo := TAU * k / 6.0 + 0.5
		var lado := Vector3(cos(angulo), 0.0, sin(angulo))
		for s in 9:
			var t := s / 8.0
			var pos := lado * (0.07 + t * 0.12 + sin(t * PI) * 0.03) + Vector3(0, 0.18 - t * 0.32 + t * t * 0.14, 0)
			_p(figura, _esf(0.036 * (1.0 - t * 0.6)), c if s < 7 else claro, pos)


static func _figura_serpiente(figura: Node3D, c: Color, o: Color, _claro: Color) -> void:
	for i in 7:
		var pos := Vector3(0, -0.12 + i * 0.065, sin(i * 0.9) * 0.06)
		_p(figura, _esf(0.06 - i * 0.004), c if i % 2 == 0 else o, pos)
	var cab := _cabeza(figura, Vector3(0, 0.36, 0.0))
	_p(cab, _caja(Vector3(0.11, 0.07, 0.18)), c, Vector3(0, 0, -0.07))
	_p(cab, _caja(Vector3(0.09, 0.03, 0.14)), o, Vector3(0, -0.05, -0.07))
	for lado in [-1.0, 1.0]:
		_p(cab, _cil(0.0, 0.012, 0.05), MARFIL, Vector3(lado * 0.03, -0.07, -0.13)).rotation.x = PI
		_brilla(_p(cab, _caja(Vector3(0.025, 0.02, 0.02)), Color("ff4a2a"), Vector3(lado * 0.05, 0.03, -0.1)))
	_p(cab, _caja(Vector3(0.02, 0.005, 0.08)), Color("c62f2f"), Vector3(0, -0.04, -0.2))


static func _figura_triton(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	_p(figura, _capsula(0.07, 0.36), c, Vector3(0, 0.1, 0))
	_p(figura, _cil(0.07, 0.0, 0.22), o, Vector3(0, -0.18, 0.02))
	_p(figura, _esf(0.07), c, Vector3(0, 0.36, 0))
	_p(figura, _cil(0.05, 0.0, 0.12), claro, Vector3(0, 0.28, -0.04)).rotation.x = 0.4
	_corona(figura, Vector3(0, 0.42, 0), 0.055, claro)
	_p(figura, _cil(0.012, 0.012, 0.62), Color("e2b13a"), Vector3(0.12, 0.15, -0.02))
	for i in 3:
		_p(figura, _cil(0.0, 0.014, 0.08), Color("e2b13a"), Vector3(0.12 + (i - 1) * 0.03, 0.5, -0.02))
	_p(figura, _caja(Vector3(0.08, 0.012, 0.012)), Color("e2b13a"), Vector3(0.12, 0.46, -0.02))


static func _figura_angel(figura: Node3D, c: Color, _o: Color, claro: Color) -> void:
	_p(figura, _capsula(0.065, 0.36), c, Vector3(0, 0.1, 0))
	_p(figura, _cil(0.03, 0.1, 0.24), c, Vector3(0, -0.12, 0))
	_p(figura, _esf(0.065), c, Vector3(0, 0.36, 0))
	_brilla(_p(figura, _toro(0.05, 0.065), Color("ffe680"), Vector3(0, 0.45, 0.02)))
	for lado in [-1.0, 1.0]:
		var ala := _p(figura, _caja(Vector3(0.03, 0.34, 0.14)), claro, Vector3(lado * 0.13, 0.2, 0.08))
		ala.rotation = Vector3(0.3, lado * 0.5, lado * -0.35)


static func _figura_lobo(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	_cuello(figura, c)
	var cab := _cabeza(figura, Vector3(0, 0.3, -0.03))
	_p(cab, _esf(0.1), c, Vector3.ZERO)
	_p(cab, _cil(0.0, 0.06, 0.17), claro, Vector3(0, -0.02, -0.14)).rotation.x = -PI / 2.0
	_p(cab, _esf(0.018), NEGRO, Vector3(0, -0.01, -0.22))
	for lado in [-1.0, 1.0]:
		var oreja := _p(cab, _cil(0.0, 0.035, 0.1), o, Vector3(lado * 0.055, 0.1, 0.0))
		oreja.rotation.z = lado * -0.2
		_brilla(_p(cab, _esf(0.016), BRILLO_OJOS, Vector3(lado * 0.04, 0.03, -0.08)))


static func _figura_toro(figura: Node3D, c: Color, _o: Color, claro: Color) -> void:
	_cuello(figura, c)
	var cab := _cabeza(figura, Vector3(0, 0.3, -0.03))
	_p(cab, _caja(Vector3(0.15, 0.13, 0.16)), c, Vector3.ZERO)
	_p(cab, _caja(Vector3(0.12, 0.08, 0.06)), claro, Vector3(0, -0.04, -0.1))
	_p(cab, _toro(0.02, 0.03), Color("e2b13a"), Vector3(0, -0.08, -0.13)).rotation.x = PI / 2.0
	for lado in [-1.0, 1.0]:
		var cuerno := _p(cab, _cil(0.0, 0.028, 0.2), MARFIL, Vector3(lado * 0.14, 0.09, 0.0))
		cuerno.rotation = Vector3(0, 0, lado * -1.0)
		_p(cab, _esf(0.016), NEGRO, Vector3(lado * 0.05, 0.03, -0.08))


static func _figura_sol(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	_poste(figura, o)
	var cara := _de_lado(figura)
	_p(cara, _cil(0.13, 0.13, 0.04), c, Vector3.ZERO).rotation.x = PI / 2.0
	for i in 12:
		var rayo := _p(cara, _cil(0.0, 0.025, 0.08), claro, Vector3(cos(TAU * i / 12.0), sin(TAU * i / 12.0), 0) * 0.17)
		rayo.rotation.z = TAU * i / 12.0 - PI / 2.0
	for frente in [-1.0, 1.0]:
		for lado in [-1.0, 1.0]:
			_p(cara, _esf(0.016), o, Vector3(lado * 0.04, 0.03, frente * 0.025))
		_p(cara, _caja(Vector3(0.06, 0.012, 0.01)), o, Vector3(0, -0.04, frente * 0.025))


static func _figura_luna(figura: Node3D, c: Color, o: Color, _claro: Color) -> void:
	_poste(figura, o)
	var cara := _de_lado(figura)
	for i in 13:
		var angulo := lerpf(-1.9, 1.9, i / 12.0)
		_p(cara, _esf(0.055 * (1.0 - absf(angulo) / 2.4)), c, Vector3(cos(angulo) * -0.12, sin(angulo) * 0.14, 0))
	_brilla(_p(cara, _esf(0.025), Color("fff2b0"), Vector3(0.08, 0.12, 0)))
	for frente in [-1.0, 1.0]:
		_p(cara, _esf(0.014), o, Vector3(-0.12, 0.03, frente * 0.045))


static func _figura_estrella(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	_poste(figura, o)
	var cara := _de_lado(figura)
	_p(cara, _esf(0.06), c, Vector3.ZERO).scale = Vector3(1.0, 1.0, 0.6)
	for i in 5:
		var angulo := TAU * i / 5.0
		var punta := _p(cara, _cil(0.0, 0.045, 0.14), c if i % 2 == 0 else claro, Vector3(-sin(angulo), cos(angulo), 0) * 0.1)
		punta.rotation.z = angulo
		punta.scale = Vector3(1.0, 1.0, 0.5)


static func _figura_ancla(figura: Node3D, c: Color, _o: Color, _claro: Color) -> void:
	var ancla := _cabeza(figura, Vector3(0, 0.0, 0), 0.9)
	_p(ancla, _cil(0.022, 0.022, 0.46), c, Vector3(0, 0.12, 0))
	_p(ancla, _toro(0.03, 0.05), c, Vector3(0, 0.38, 0)).rotation.x = PI / 2.0
	_p(ancla, _cil(0.016, 0.016, 0.24), Color("6b4a30"), Vector3(0, 0.3, 0)).rotation.z = PI / 2.0
	for lado in [-1.0, 1.0]:
		var brazo := _p(ancla, _caja(Vector3(0.03, 0.17, 0.03)), c, Vector3(lado * 0.06, -0.08, 0))
		brazo.rotation.z = lado * 0.9
		var una := _p(ancla, _cil(0.0, 0.035, 0.08), c, Vector3(lado * 0.13, -0.01, 0))
		una.rotation.z = lado * -0.4


static func _figura_delfin(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	for i in 6:
		var t := i / 5.0
		_p(figura, _esf(0.065 - absf(t - 0.4) * 0.05), c, Vector3(0, -0.12 + t * 0.4, sin(t * PI) * -0.05))
	_p(figura, _esf(0.05), claro, Vector3(0, 0.12, -0.08)).scale = Vector3(0.8, 2.0, 0.5)
	var cab := _cabeza(figura, Vector3(0, 0.3, -0.02))
	_p(cab, _cil(0.0, 0.025, 0.1), c, Vector3(0, -0.01, -0.09)).rotation.x = -PI / 2.0
	var aleta := _p(figura, _cil(0.0, 0.05, 0.12), o, Vector3(0, 0.16, 0.06))
	aleta.scale = Vector3(0.25, 1.0, 1.0)
	aleta.rotation.x = 0.6
	for lado in [-1.0, 1.0]:
		_p(figura, _caja(Vector3(0.12, 0.02, 0.05)), o, Vector3(lado * 0.06, -0.16, 0.0)).rotation.z = lado * 0.5
		_p(cab, _esf(0.013), NEGRO, Vector3(lado * 0.04, 0.02, -0.04))


static func _figura_cisne(figura: Node3D, c: Color, _o: Color, claro: Color) -> void:
	_p(figura, _esf(0.11), c, Vector3(0, 0.0, 0.02)).scale = Vector3(1.0, 1.3, 0.8)
	for i in 6:
		var t := i / 5.0
		_p(figura, _esf(0.032), c, Vector3(0, 0.12 + t * 0.26, sin(t * PI * 1.2) * 0.06))
	var cab := _cabeza(figura, Vector3(0, 0.4, -0.02))
	_p(cab, _esf(0.045), c, Vector3.ZERO)
	_p(cab, _cil(0.0, 0.02, 0.08), Color("e07a2a"), Vector3(0, -0.01, -0.07)).rotation.x = -PI / 2.0
	for lado in [-1.0, 1.0]:
		var ala := _p(figura, _caja(Vector3(0.03, 0.26, 0.14)), claro, Vector3(lado * 0.1, 0.04, 0.06))
		ala.rotation = Vector3(0.2, lado * 0.4, lado * -0.25)
		_p(cab, _esf(0.01), NEGRO, Vector3(lado * 0.03, 0.015, -0.03))


static func _figura_buho(figura: Node3D, c: Color, o: Color, claro: Color) -> void:
	_p(figura, _esf(0.12), c, Vector3(0, 0.08, 0)).scale = Vector3(1.0, 1.3, 0.9)
	var cab := _cabeza(figura, Vector3(0, 0.3, 0), 0.9)
	_p(cab, _esf(0.1), c, Vector3.ZERO)
	_p(cab, _cil(0.0, 0.02, 0.05), Color("e2b13a"), Vector3(0, -0.03, -0.1)).rotation.x = PI
	for lado in [-1.0, 1.0]:
		_p(cab, _cil(0.04, 0.04, 0.02), claro, Vector3(lado * 0.045, 0.01, -0.085)).rotation.x = PI / 2.0
		_brilla(_p(cab, _esf(0.018), BRILLO_OJOS, Vector3(lado * 0.045, 0.01, -0.1)))
		var penacho := _p(cab, _cil(0.0, 0.025, 0.08), o, Vector3(lado * 0.06, 0.1, 0))
		penacho.rotation.z = lado * -0.4
		_p(figura, _caja(Vector3(0.03, 0.18, 0.1)), o, Vector3(lado * 0.11, 0.08, 0.02)).rotation.z = lado * 0.15


static func _figura_carnero(figura: Node3D, c: Color, _o: Color, claro: Color) -> void:
	_cuello(figura, c)
	var cab := _cabeza(figura, Vector3(0, 0.3, -0.03))
	_p(cab, _esf(0.09), c, Vector3(0, 0, -0.02)).scale = Vector3(1.0, 1.0, 1.5)
	_p(cab, _caja(Vector3(0.07, 0.06, 0.06)), claro, Vector3(0, -0.04, -0.14))
	for lado in [-1.0, 1.0]:
		var cuerno := _p(cab, _toro(0.03, 0.075), MARFIL.darkened(0.15), Vector3(lado * 0.1, 0.02, 0.02))
		cuerno.rotation.z = PI / 2.0
		_p(cab, _esf(0.014), NEGRO, Vector3(lado * 0.05, 0.03, -0.09))


static func _figura_reina(figura: Node3D, c: Color, o: Color, _claro: Color) -> void:
	_p(figura, _cil(0.035, 0.12, 0.3), o, Vector3(0, -0.06, 0))
	_p(figura, _capsula(0.055, 0.22), c, Vector3(0, 0.17, 0))
	_p(figura, _esf(0.065), c, Vector3(0, 0.35, 0))
	_p(figura, _esf(0.07), o, Vector3(0, 0.36, 0.03))
	_corona(figura, Vector3(0, 0.41, 0), 0.05, Color("e2b13a"))
	for lado in [-1.0, 1.0]:
		_p(figura, _caja(Vector3(0.03, 0.18, 0.03)), c, Vector3(lado * 0.07, 0.17, -0.04)).rotation.z = lado * 0.3


static func _figura_vikingo(figura: Node3D, c: Color, o: Color, _claro: Color) -> void:
	_p(figura, _capsula(0.075, 0.34), c, Vector3(0, 0.1, 0))
	_p(figura, _esf(0.07), c, Vector3(0, 0.35, 0))
	_p(figura, _esf(0.075), Color("8a8f96"), Vector3(0, 0.38, 0)).scale = Vector3(1.0, 0.7, 1.0)
	_p(figura, _cil(0.06, 0.0, 0.16), o, Vector3(0, 0.25, -0.04)).rotation.x = 0.3
	for lado in [-1.0, 1.0]:
		var cuerno := _p(figura, _cil(0.0, 0.025, 0.14), MARFIL, Vector3(lado * 0.1, 0.44, 0))
		cuerno.rotation.z = lado * -0.7
	var escudo := _p(figura, _cil(0.1, 0.1, 0.02), o, Vector3(0, 0.12, -0.08))
	escudo.rotation.x = PI / 2.0
	_p(figura, _esf(0.03), Color("c9ced6"), Vector3(0, 0.12, -0.095))


static func _figura_hipocampo(figura: Node3D, c: Color, o: Color, _claro: Color) -> void:
	for i in 7:
		var t := i / 6.0
		_p(figura, _esf(0.055 - t * 0.02), c if i % 2 == 0 else o, Vector3(0, 0.3 - t * 0.42, sin(t * PI * 1.5) * 0.07))
	_p(figura, _toro(0.015, 0.04), o, Vector3(0, -0.15, -0.04)).rotation.z = PI / 2.0
	var cab := _cabeza(figura, Vector3(0, 0.34, 0))
	_p(cab, _esf(0.055), c, Vector3.ZERO)
	_p(cab, _cil(0.018, 0.022, 0.12), c, Vector3(0, -0.02, -0.08)).rotation.x = -PI / 2.0
	var cresta := _p(figura, _caja(Vector3(0.015, 0.22, 0.05)), o, Vector3(0, 0.15, 0.06))
	cresta.rotation.x = 0.1
	for lado in [-1.0, 1.0]:
		_p(cab, _esf(0.012), NEGRO, Vector3(lado * 0.035, 0.02, -0.02))


# Piezas comunes

static func _cabeza(figura: Node3D, pos: Vector3, giro := 0.8) -> Node3D:
	var cab := Node3D.new()
	cab.position = pos
	cab.rotation.x = giro
	figura.add_child(cab)
	return cab


# Símbolos planos de cara al costado, para que se vean desde la cámara del juego.
static func _de_lado(figura: Node3D) -> Node3D:
	var vertical := _cabeza(figura, Vector3(0, 0.3, 0), 0.9)
	var plano := Node3D.new()
	plano.rotation.y = PI / 2.0
	vertical.add_child(plano)
	return plano


static func _cuello(figura: Node3D, color: Color) -> void:
	_p(figura, _cil(0.06, 0.08, 0.28), color, Vector3(0, 0.08, 0))


static func _poste(figura: Node3D, color: Color) -> void:
	_p(figura, _cil(0.03, 0.05, 0.3), color, Vector3(0, 0.06, 0))


static func _corona(padre: Node3D, pos: Vector3, radio: float, color: Color) -> void:
	_p(padre, _cil(radio, radio, 0.03), color, pos)
	for i in 5:
		var angulo := TAU * i / 5.0
		_p(padre, _cil(0.0, 0.012, 0.045), color, pos + Vector3(cos(angulo) * radio, 0.035, sin(angulo) * radio))


static func _brilla(pieza: MeshInstance3D) -> void:
	var color: Color = (pieza.material_override as StandardMaterial3D).albedo_color
	pieza.material_override = ModeloBarco._material(color, true)


static func _p(padre: Node3D, malla: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	return ModeloBarco._pieza(padre, malla, color, pos)


static func _esf(radio: float) -> SphereMesh:
	return ModeloBarco._esfera(radio)


static func _caja(tam: Vector3) -> BoxMesh:
	return ModeloBarco._caja(tam)


static func _cil(arriba: float, abajo: float, alto: float) -> CylinderMesh:
	return ModeloBarco._cilindro(arriba, abajo, alto)


static func _capsula(radio: float, alto: float) -> CapsuleMesh:
	var capsula := CapsuleMesh.new()
	capsula.radius = radio
	capsula.height = alto
	capsula.radial_segments = 10
	capsula.rings = 4
	return capsula


static func _toro(interior: float, exterior: float) -> TorusMesh:
	var toro := TorusMesh.new()
	toro.inner_radius = interior
	toro.outer_radius = exterior
	toro.rings = 16
	toro.ring_segments = 6
	return toro
