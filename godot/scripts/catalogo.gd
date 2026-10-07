class_name Catalogo
extends RefCounted

const CATEGORIAS: Array[String] = ["tipo", "casco", "adorno", "velas", "bandera", "proa", "popa", "canones"]
const TITULOS := {
	"tipo": "Barco", "casco": "Casco", "adorno": "Adornos", "velas": "Velas",
	"bandera": "Bandera", "proa": "Proa", "popa": "Popa", "canones": "Cañones",
}
const DEFECTO := {"tipo": "bergantin"}
const CON_DIBUJO: Array[String] = ["velas", "bandera"]

# Piezas originales: sus ids no deben cambiar porque están en las partidas guardadas.
const BASICAS := {
	"tipo": [
		{"id": "balandro", "nombre": "Balandro", "precio": 0, "info": "Rápido y frágil."},
		{"id": "bergantin", "nombre": "Bergantín", "precio": 0, "info": "Equilibrado."},
		{"id": "galeon", "nombre": "Galeón", "precio": 0, "info": "Lento y duro."},
	],
	"casco": [
		{"id": "roble", "nombre": "Roble", "precio": 0, "color": Color("c98345")},
		{"id": "caoba", "nombre": "Caoba", "precio": 0, "color": Color("8d4a2b")},
		{"id": "ebano", "nombre": "Ébano", "precio": 8, "color": Color("3b2a22")},
		{"id": "carmesi", "nombre": "Carmesí", "precio": 12, "color": Color("a8402f")},
		{"id": "marino", "nombre": "Marino", "precio": 12, "color": Color("2f4f7a")},
		{"id": "esmeralda", "nombre": "Esmeralda", "precio": 15, "color": Color("2f6b4f")},
		{"id": "hueso", "nombre": "Hueso", "precio": 20, "color": Color("d8ccb0")},
		{"id": "corsario", "nombre": "Corsario", "precio": 26, "color": Color("1f1d22"), "franja": Color("b5302a"), "info": "Negro con franja roja."},
		{"id": "real", "nombre": "Real", "precio": 32, "color": Color("2a3f78"), "franja": Color("e2b13a"), "info": "Azul real con franja dorada."},
		{"id": "fantasma", "nombre": "Fantasma", "precio": 40, "color": Color("23262b"), "franja": Color("4fd0b0"), "info": "Casco oscuro con franja espectral."},
	],
	"adorno": [
		{"id": "oro", "nombre": "Molduras de oro", "precio": 0, "color": Color("d9b46a"), "estilo": "molduras", "info": "Molduras talladas a lo largo de la borda."},
		{"id": "madera", "nombre": "Barandilla de madera", "precio": 0, "color": Color("6b4a30"), "estilo": "barandilla", "info": "Barandilla con balaustres en cubierta."},
		{"id": "plata", "nombre": "Remaches de plata", "precio": 10, "color": Color("c9ced6"), "estilo": "remaches", "info": "Filas de remaches y un fleje en el costado."},
		{"id": "cobre", "nombre": "Faroles de cobre", "precio": 10, "color": Color("b8734a"), "estilo": "faroles", "info": "Faroles encendidos sobre la borda."},
		{"id": "negro", "nombre": "Pinchos negros", "precio": 15, "color": Color("202024"), "estilo": "pinchos", "info": "Pinchos afilados en toda la borda."},
		{"id": "turquesa", "nombre": "Escudos turquesa", "precio": 20, "color": Color("3fbfb0"), "estilo": "escudos", "info": "Escudos redondos colgados en los costados."},
	],
	"velas": [
		{"id": "lona", "nombre": "Lona", "precio": 0, "color": Color("f3ecdf"), "diseno": "lisa"},
		{"id": "arena", "nombre": "Arena", "precio": 0, "color": Color("e3cc98"), "diseno": "lisa"},
		{"id": "cielo", "nombre": "Cielo", "precio": 6, "color": Color("3e86d0"), "diseno": "lisa"},
		{"id": "sangre", "nombre": "Sangre", "precio": 10, "color": Color("c2453a"), "diseno": "lisa"},
		{"id": "noche", "nombre": "Noche", "precio": 15, "color": Color("2b2b2b"), "diseno": "lisa"},
		{"id": "remendada", "nombre": "Remendada", "precio": 12, "color": Color("e3cc98"), "color2": Color("9a7a4a"), "diseno": "parches"},
		{"id": "franjas_rojas", "nombre": "Franjas rojas", "precio": 18, "color": Color("f3ecdf"), "color2": Color("c2453a"), "diseno": "franjas"},
		{"id": "franjas_azules", "nombre": "Franjas azules", "precio": 18, "color": Color("f3ecdf"), "color2": Color("2f63c6"), "diseno": "franjas"},
		{"id": "cruzada", "nombre": "Cruzada", "precio": 22, "color": Color("f3ecdf"), "color2": Color("c2453a"), "diseno": "cruz"},
		{"id": "sol_rojo", "nombre": "Sol rojo", "precio": 28, "color": Color("e3cc98"), "color2": Color("c2453a"), "diseno": "sol"},
		{"id": "pirata", "nombre": "Pirata", "precio": 40, "color": Color("2b2b2b"), "color2": Color("f2f2f2"), "diseno": "calavera"},
	],
	"bandera": [
		{"id": "negra", "nombre": "Negra", "precio": 0, "color": Color("1b1b1b"), "diseno": "lisa"},
		{"id": "roja", "nombre": "Roja", "precio": 0, "color": Color("c62f2f"), "diseno": "lisa"},
		{"id": "rayas", "nombre": "Rayas", "precio": 8, "color": Color("2f63c6"), "color2": Color("f2f2f2"), "diseno": "franjas"},
		{"id": "partida", "nombre": "Partida", "precio": 10, "color": Color("1b1b1b"), "color2": Color("c62f2f"), "diseno": "diagonal"},
		{"id": "estrella", "nombre": "Estrella", "precio": 12, "color": Color("7a3fb0"), "color2": Color("e2b13a"), "diseno": "estrella"},
		{"id": "tibias", "nombre": "Tibias", "precio": 15, "color": Color("c62f2f"), "color2": Color("f2f2f2"), "diseno": "tibias"},
		{"id": "ancla", "nombre": "Ancla", "precio": 15, "color": Color("1f3a6b"), "color2": Color("f2f2f2"), "diseno": "ancla"},
		{"id": "jolly_roger", "nombre": "Jolly Roger", "precio": 20, "color": Color("1b1b1b"), "color2": Color("f2f2f2"), "diseno": "calavera"},
		{"id": "sol", "nombre": "Sol", "precio": 22, "color": Color("e2b13a"), "color2": Color("c62f2f"), "diseno": "sol"},
		{"id": "real", "nombre": "Real", "precio": 25, "color": Color("f2f2f2"), "color2": Color("e2b13a"), "diseno": "cruz"},
	],
	"proa": [
		{"id": "sencilla", "nombre": "Sencilla", "precio": 0, "info": "Sin mascarón."},
		{"id": "espolon", "nombre": "Espolón", "precio": 15, "color": Color("8a8f96"), "info": "Ariete de hierro en la proa."},
		{"id": "sirena", "nombre": "Sirena", "precio": 30, "color": Color("e2b13a"), "info": "Mascarón dorado de sirena."},
		{"id": "aguila", "nombre": "Águila", "precio": 35, "color": Color("f2efe6"), "info": "Mascarón de águila con alas."},
		{"id": "dragon", "nombre": "Dragón", "precio": 45, "color": Color("3f9a4f"), "info": "Cabeza de dragón con cuernos."},
	],
	"popa": [
		{"id": "camarote", "nombre": "Camarote", "precio": 0, "info": "Camarote sencillo."},
		{"id": "faroles", "nombre": "Faroles", "precio": 12, "info": "Dos faroles encendidos."},
		{"id": "castillo", "nombre": "Castillo", "precio": 25, "info": "Castillo de popa alto con barandilla."},
		{"id": "galeria", "nombre": "Galería", "precio": 35, "info": "Balcón trasero con dos filas de ventanas."},
	],
	"canones": [
		{"id": "hierro", "nombre": "Hierro", "precio": 0, "color": Color("26292c")},
		{"id": "bronce", "nombre": "Bronce", "precio": 10, "color": Color("b07a3c")},
		{"id": "plata", "nombre": "Plata", "precio": 18, "color": Color("c9ced6")},
		{"id": "oro", "nombre": "Oro", "precio": 30, "color": Color("e2b13a")},
	],
}

# [id, nombre, color]. Los nombres funcionan solos y detrás de "de".
const PALETA := [
	["rubi", "Rubí", "c62f2f"], ["granate", "Granate", "7a1f2a"], ["vino", "Vino", "5a1830"],
	["coral", "Coral", "e86a50"], ["fuego", "Fuego", "e07a2a"], ["ambar", "Ámbar", "e0a030"],
	["oro", "Oro", "e2b13a"], ["arena", "Arena", "e3cc98"], ["marfil", "Marfil", "f3ecdf"],
	["hueso", "Hueso", "d8ccb0"], ["nieve", "Nieve", "f7f7f7"], ["plata", "Plata", "c9ced6"],
	["acero", "Acero", "7a8590"], ["ceniza", "Ceniza", "55595e"], ["sombra", "Sombra", "1b1b1e"],
	["carbon", "Carbón", "2e2b2b"], ["abismo", "Abismo", "1f3a6b"], ["zafiro", "Zafiro", "2f63c6"],
	["cielo", "Cielo", "3e86d0"], ["hielo", "Hielo", "9cd4f2"], ["turquesa", "Turquesa", "3fbfb0"],
	["jade", "Jade", "2f8f6f"], ["esmeralda", "Esmeralda", "2f6b4f"], ["musgo", "Musgo", "5a6b2f"],
	["lima", "Lima", "9cc640"], ["oliva", "Oliva", "6f6a2a"], ["amatista", "Amatista", "7a3fb0"],
	["lavanda", "Lavanda", "a88ad8"], ["rosa", "Rosa", "e07aa8"], ["fucsia", "Fucsia", "b0306f"],
	["caoba", "Caoba", "8d4a2b"], ["roble", "Roble", "c98345"], ["cobre", "Cobre", "b8734a"],
	["bronce", "Bronce", "b07a3c"], ["cacao", "Cacao", "4a2a1a"], ["ebano", "Ébano", "3b2a22"],
]
const TONOS := [["", "", 0.0], ["_claro", " claro", 0.3], ["_oscuro", " oscuro", -0.35]]
const DISENOS := {
	"lisa": "Lisa", "franjas": "Franjas", "cruz": "Cruz", "diagonal": "Partida", "parches": "Remendada",
	"calavera": "Calavera", "tibias": "Tibias", "sol": "Sol", "estrella": "Estrella", "ancla": "Ancla",
	"circulo": "Luna llena", "marco": "Marco", "mitad": "Mitades", "cuadros": "Ajedrez", "luna": "Creciente",
	"rombo": "Rombo",
}
const MASCARONES := {
	"espolon": "Espolón", "sirena": "Sirena", "aguila": "Águila", "dragon": "Dragón", "leon": "León",
	"calavera": "Calavera", "caballo": "Caballo", "unicornio": "Unicornio", "tiburon": "Tiburón",
	"pulpo": "Pulpo", "serpiente": "Serpiente marina", "triton": "Tritón", "angel": "Ángel", "lobo": "Lobo",
	"toro": "Toro", "sol": "Sol", "luna": "Luna", "estrella": "Estrella", "ancla": "Ancla", "delfin": "Delfín",
	"cisne": "Cisne", "buho": "Búho", "carnero": "Carnero", "reina": "Reina", "vikingo": "Vikingo",
	"hipocampo": "Hipocampo",
}
const ACABADOS_MASCARON: Array[String] = ["oro", "plata", "bronce", "ebano", "marfil", "jade", "rubi", "zafiro", "amatista", "coral", "cobre", "esmeralda"]
# [nombre, descripción]. Las formas están en ModeloBarco._canon().
const ESTILOS_CANON := {
	"clasico": ["Cañón", "Cañón clásico de caña lisa."],
	"culebrina": ["Culebrina", "Caña larga y fina de gran alcance."],
	"carronada": ["Carronada", "Corta y gruesa, de boca ancha."],
	"anillado": ["Reforzado", "Caña con anillos de refuerzo."],
	"doble": ["Doble", "Dos cañas gemelas en cada tronera."],
	"bocina": ["Trabuco", "Boca abierta en forma de bocina."],
	"dragon": ["Dragón", "Boca tallada como cabeza de dragón."],
	"pimentero": ["Pimentero", "Tres cañas finas atadas en haz."],
}
# [nombre, descripción]. Las formas están en ModeloBarco._adornar().
const ESTILOS_ADORNO := {
	"molduras": ["Molduras", "Molduras talladas a lo largo de la borda."],
	"escudos": ["Escudos", "Escudos redondos colgados en los costados."],
	"barandilla": ["Barandilla", "Barandilla con balaustres en cubierta."],
	"faroles": ["Faroles", "Faroles encendidos sobre la borda."],
	"remaches": ["Remaches", "Filas de remaches y un fleje en el costado."],
	"banderines": ["Banderines", "Guirnaldas de banderines de proa a popa."],
	"pinchos": ["Pinchos", "Pinchos afilados en toda la borda."],
	"ojos": ["Ojos", "Ojos pintados en la proa que vigilan el mar."],
}
# [nombre, descripción]. Los cuatro primeros tienen 27 colores (ids guardados); los demás, menos.
const POPAS := {
	"camarote": ["Camarote", "Camarote sencillo con ventanas."],
	"faroles": ["Faroles", "Camarote con dos faroles en el techo."],
	"castillo": ["Castillo", "Castillo de popa alto con barandilla."],
	"galeria": ["Galería", "Balcón trasero con dos filas de ventanas."],
	"pagoda": ["Pagoda", "Pagoda de dos tejados con aleros curvos."],
	"fortaleza": ["Fortaleza", "Muros almenados y torrecillas de vigía."],
	"timonera": ["Timonera", "Rueda de timón al aire bajo un toldo a rayas."],
	"cupula": ["Cúpula", "Camarote coronado por una cúpula con lucernas."],
	"torre": ["Faro", "Torre alta con una linterna encendida en lo alto."],
	"fanales": ["Fanales", "Tres grandes fanales colgando sobre la popa."],
	"toldo": ["Tienda", "Tienda de lona a rayas con barriles."],
	"cabana": ["Cabaña", "Cabaña de tablones con tejado y chimenea."],
}
const COLORES_POPA_CLASICA := 27
const COLORES_POPA_NUEVA := 14
const LUCES: Array[String] = ["ffd27a", "ffb347", "9fe0ff", "b8ff9a", "ff8ad8"]
const APODOS: Array[String] = [
	"Gaviota", "Tiburón", "Albatros", "Delfín", "Mantarraya", "Barracuda", "Pelícano", "Cormorán",
	"Orca", "Narval", "Kraken", "Leviatán", "Tritón", "Medusa", "Tormenta", "Relámpago", "Huracán",
	"Ventisca", "Brisa", "Marejada", "Galerna", "Bruma", "Coral", "Perla", "Brújula", "Astrolabio",
	"Sextante", "Vigía", "Corsario", "Bucanero", "Filibustero", "Centella", "Tifón", "Sirena",
]

const APAREJOS := {
	"cuadrado": "velas cuadradas", "latino": "velas latinas", "cangrejo": "velas cangrejas",
	"junco": "velas de junco", "mixto": "aparejo mixto",
}
const PERFILES := {
	"clasico": "casco clásico", "plano": "casco bajo y plano", "alto": "casco alto",
	"media_luna": "casco de media luna", "panzudo": "casco panzudo",
}
const MASTILES_TIPO := {"balandro": [1, 2], "bergantin": [2, 3], "galeon": [3, 4]}
const PRECIO_MIN := 5
const PRECIO_MAX := 25

static var _piezas := {}
static var _indice := {}


static func lista(categoria: String) -> Array:
	_preparar()
	return _piezas[categoria]


static func buscar(categoria: String, id: String) -> Dictionary:
	_preparar()
	return _indice[categoria].get(id, _piezas[categoria][0])


static func existe(categoria: String, id: String) -> bool:
	_preparar()
	return _indice[categoria].has(id)


static func inicial(categoria: String) -> String:
	return DEFECTO.get(categoria, BASICAS[categoria][0]["id"])


static func _preparar() -> void:
	if not _piezas.is_empty():
		return
	for categoria in CATEGORIAS:
		var piezas: Array = BASICAS[categoria].duplicate(true)
		piezas.append_array(_generar(categoria))
		var vistos := {}
		var unicas: Array = []
		for pieza in piezas:
			if not vistos.has(pieza["id"]):
				if pieza["precio"] > 0:
					pieza["precio"] = _azar("precio/" + pieza["id"]).randi_range(PRECIO_MIN, PRECIO_MAX)
				vistos[pieza["id"]] = pieza
				unicas.append(pieza)
		# Las gratis primero; el resto en un orden mezclado pero siempre el mismo.
		unicas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if (a["precio"] == 0) != (b["precio"] == 0):
				return a["precio"] == 0
			return ("orden/" + a["id"]).hash() < ("orden/" + b["id"]).hash())
		_piezas[categoria] = unicas
		_indice[categoria] = vistos


static func _generar(categoria: String) -> Array:
	match categoria:
		"tipo":
			return _generar_barcos()
		"casco":
			return _generar_cascos()
		"canones":
			return _generar_con_estilo(ESTILOS_CANON, 3, 5)
		"adorno":
			return _generar_con_estilo(ESTILOS_ADORNO, 5, 3)
		"velas":
			return _generar_dibujos(0)
		"bandera":
			return _generar_dibujos(17)
		"proa":
			return _generar_mascarones()
		"popa":
			return _generar_popas()
	return []


# Cada barco básico tiene una variante por apodo, con aparejo, casco y medidas propios.
static func _generar_barcos() -> Array:
	var nuevas: Array = []
	for base in ["balandro", "bergantin", "galeon"]:
		var combinaciones := _combinaciones(base)
		for k in APODOS.size():
			nuevas.append(_variante_barco(base, APODOS[k], combinaciones[k]))
	return nuevas


static func _variante_barco(base: String, apodo: String, combo: Array) -> Dictionary:
	var datos: Dictionary = _basica("tipo", base)
	var azar := _azar(base + apodo)
	var perfil: String = combo[1]
	var mastiles: int = combo[2]
	var castillo := perfil != "media_luna" and azar.randf() < 0.45
	var forma := {
		"aparejo": combo[0], "perfil": perfil, "mastiles": mastiles,
		"castillo": castillo, "cofa": azar.randf() < 0.5,
		"foques": 0 if combo[0] == "junco" else azar.randi_range(0, 2),
		"baupres": azar.randf_range(0.6, 1.4), "inclinacion": azar.randf_range(0.0, 0.18),
		"largo": azar.randf_range(0.9, 1.12), "ancho": azar.randf_range(0.88, 1.12) * (1.12 if perfil == "panzudo" else 1.0),
		"alto": azar.randf_range(0.9, 1.2), "mastil": azar.randf_range(0.85, 1.15),
		"vela": azar.randf_range(0.85, 1.15),
	}
	var detalles := "%d %s con %s y %s" % [mastiles, "mástil" if mastiles == 1 else "mástiles", APAREJOS[combo[0]], PERFILES[perfil]]
	if castillo:
		detalles += " y castillo de proa"
	return {
		"id": "%s_%s" % [base, _sin_tildes(apodo)],
		"nombre": "%s %s" % [datos["nombre"], apodo],
		"precio": 1,
		"base": base,
		"forma": forma,
		"info": "%s: %s. %s" % [datos["nombre"], detalles, datos["info"]],
	}


# Un casco liso por color y dos con franja: una dorada y otra que contrasta.
static func _generar_cascos() -> Array:
	var nuevas: Array = []
	for i in PALETA.size():
		var color := _color(i)
		nuevas.append(_pieza_color("g_" + PALETA[i][0], PALETA[i][1], color, 4, 20))
		var oro := _indice_color("oro") if i != _indice_color("oro") else _indice_color("sombra")
		var contraste := _contraste(i, i * 7 + 5)
		for otra in [oro, contraste]:
			var pieza := _pieza_color("g_%s_%s" % [PALETA[i][0], PALETA[otra][0]], "%s y %s" % [PALETA[i][1], PALETA[otra][1].to_lower()], color, 14, 45)
			pieza["franja"] = _color(otra)
			pieza["info"] = "Casco de %s con franja de %s." % [PALETA[i][1].to_lower(), PALETA[otra][1].to_lower()]
			nuevas.append(pieza)
	return nuevas


# Cañones y adornos: cada color en tres tonos, con un estilo repartido según
# paso_color y paso_tono para que los vecinos no se repitan.
static func _generar_con_estilo(estilos_info: Dictionary, paso_color: int, paso_tono: int) -> Array:
	var nuevas: Array = []
	var estilos: Array = estilos_info.keys()
	for i in PALETA.size():
		for t in TONOS.size():
			var tono: Array = TONOS[t]
			var color := _color(i)
			color = color.lightened(tono[2]) if tono[2] > 0.0 else color.darkened(-tono[2])
			var estilo: String = estilos[(i * paso_color + t * paso_tono) % estilos.size()]
			var nombre := "%s %s" % [estilos_info[estilo][0], (PALETA[i][1] + tono[1]).to_lower()]
			var pieza := _pieza_color("g_" + PALETA[i][0] + tono[0], nombre, color, 5, 35)
			pieza["estilo"] = estilo
			pieza["info"] = estilos_info[estilo][1]
			nuevas.append(pieza)
	return nuevas


# Velas y banderas: lisas de cada color y seis de cada diseño; el desfase hace
# que velas y banderas no salgan con los mismos colores.
static func _generar_dibujos(desfase: int) -> Array:
	var nuevas: Array = []
	var disenos: Array = DISENOS.keys()
	for d in disenos.size():
		var diseno: String = disenos[d]
		var cuantos := PALETA.size() if diseno == "lisa" else 6
		for k in cuantos:
			var fondo := (d * 5 + k * 5 + desfase) % PALETA.size() if diseno != "lisa" else k
			var figura := _contraste(fondo, d * 3 + k * 7 + 13 + desfase)
			var nombre := "%s %s" % [DISENOS[diseno], PALETA[fondo][1].to_lower()]
			if diseno == "lisa":
				nombre = PALETA[fondo][1]
			var pieza := _pieza_color("g_%s_%s_%s" % [diseno, PALETA[fondo][0], PALETA[figura][0]], nombre, _color(fondo), 4 if diseno == "lisa" else 10, 18 if diseno == "lisa" else 50)
			pieza["diseno"] = diseno
			if diseno != "lisa":
				pieza["color2"] = _color(figura)
				pieza["info"] = "%s de %s sobre %s." % [DISENOS[diseno], PALETA[figura][1].to_lower(), PALETA[fondo][1].to_lower()]
			nuevas.append(pieza)
	return nuevas


# Cinco acabados por figura de proa.
static func _generar_mascarones() -> Array:
	var nuevas: Array = []
	var estilos: Array = MASCARONES.keys()
	for s in estilos.size():
		var estilo: String = estilos[s]
		for k in 5:
			var i := _indice_color(ACABADOS_MASCARON[(s * 5 + k) % ACABADOS_MASCARON.size()])
			var pieza := _pieza_color("%s_%s" % [estilo, PALETA[i][0]], "%s de %s" % [MASCARONES[estilo], PALETA[i][1].to_lower()], _color(i), 15, 60)
			pieza["estilo"] = estilo
			pieza["info"] = "Mascarón de %s tallado en %s." % [MASCARONES[estilo].to_lower(), PALETA[i][1].to_lower()]
			nuevas.append(pieza)
	return nuevas


# Las cuatro popas clásicas salen en más colores que las nuevas.
static func _generar_popas() -> Array:
	var nuevas: Array = []
	for estilo in POPAS:
		var numero := POPAS.keys().find(estilo)
		for i in (COLORES_POPA_CLASICA if numero < 4 else COLORES_POPA_NUEVA):
			var c := (i * 7 + numero * 9) % PALETA.size()
			var pieza := _pieza_color("%s_%s" % [estilo, PALETA[c][0]], "%s de %s" % [POPAS[estilo][0], PALETA[c][1].to_lower()], _color(c), 10, 55)
			pieza["estilo"] = estilo
			pieza["info"] = POPAS[estilo][1]
			pieza["luz"] = Color(LUCES[(i + c) % LUCES.size()])
			nuevas.append(pieza)
	return nuevas


# Aparejo, casco y número de mástiles: cada variante de un mismo barco recibe
# una combinación distinta y ninguna repite la del barco básico.
static func _combinaciones(base: String) -> Array:
	var basico: int = {"balandro": 1, "bergantin": 2, "galeon": 3}[base]
	var todas: Array = []
	for aparejo in APAREJOS:
		for perfil in PERFILES:
			for mastiles in MASTILES_TIPO[base]:
				if aparejo == "mixto" and mastiles == 1:
					continue
				if aparejo == "cuadrado" and perfil == "clasico" and mastiles == basico:
					continue
				todas.append([aparejo, perfil, mastiles])
	var azar := _azar("formas/" + base)
	for i in range(todas.size() - 1, 0, -1):
		var j := azar.randi_range(0, i)
		var cambio = todas[i]
		todas[i] = todas[j]
		todas[j] = cambio
	return todas


static func _pieza_color(id: String, nombre: String, color: Color, precio_min: int, precio_max: int) -> Dictionary:
	return {"id": id, "nombre": nombre, "precio": _azar(id).randi_range(precio_min, precio_max), "color": color}


static func _basica(categoria: String, id: String) -> Dictionary:
	for pieza in BASICAS[categoria]:
		if pieza["id"] == id:
			return pieza
	return {}


static func _color(i: int) -> Color:
	return Color(PALETA[i][2])


static func _indice_color(id: String) -> int:
	for i in PALETA.size():
		if PALETA[i][0] == id:
			return i
	return 0


# Busca a partir de "desde" un color que se distinga bien del fondo.
static func _contraste(fondo: int, desde: int) -> int:
	var base := _color(fondo).get_luminance()
	for paso in PALETA.size():
		var i := (desde + paso * 7) % PALETA.size()
		if i != fondo and absf(_color(i).get_luminance() - base) > 0.35:
			return i
	return _indice_color("nieve") if base < 0.5 else _indice_color("sombra")


static func _azar(semilla: String) -> RandomNumberGenerator:
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla.hash()
	return azar


static func _sin_tildes(texto: String) -> String:
	var limpio := texto.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"]]:
		limpio = limpio.replace(par[0], par[1])
	return limpio
