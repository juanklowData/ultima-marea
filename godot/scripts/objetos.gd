class_name Objetos
extends RefCounted

# Catálogo de mercancías del mar libre: 7 categorías de 16 objetos, cada una con su lámina de
# iconos de 4 x 4 en interfaz/objetos. El id de cada objeto es "categoría:posición".

const LADO_LAMINA := 4
const RAREZAS: Array[String] = ["Común", "Raro", "Épico", "Legendario"]
const COLORES_RAREZA: Array[Color] = [Color("c9d1d3"), Color("5fb8ff"), Color("c77dff"), Color("ffb83a")]
# Probabilidad de cada rareza al abrir unos restos flotantes.
const SUERTE_RAREZA: Array[float] = [0.6, 0.28, 0.1, 0.02]
const ICONOS_MEJORA := {
	"madera": 0, "metal": 1, "tela": 2, "buscado": 3, "casco": 4, "canones": 5, "recarga": 6, "velas": 7,
	"bodega": 8, "taberna": 9, "baterias": 10, "arsenal": 11, "legendario": 12, "fuerte": 13, "soborno": 14, "cazador": 15,
}

# [nombre, valor en monedas, rareza]
const CATEGORIAS := {
	"viveres": {"nombre": "Especias y víveres", "objetos": [
		["Saco de café", 4, 0], ["Pimienta negra", 6, 1], ["Canela", 5, 0], ["Clavo de olor", 6, 1],
		["Nuez moscada", 7, 1], ["Azafrán", 18, 2], ["Vainilla", 12, 1], ["Jengibre", 3, 0],
		["Cacao", 8, 1], ["Té de Oriente", 9, 1], ["Azúcar de caña", 3, 0], ["Sal marina", 2, 0],
		["Miel silvestre", 5, 0], ["Queso curado", 4, 0], ["Pescado salado", 2, 0], ["Galletas de barco", 2, 0],
	]},
	"telas": {"nombre": "Telas y ropa", "objetos": [
		["Rollo de seda", 16, 2], ["Algodón", 3, 0], ["Lino", 4, 0], ["Terciopelo rojo", 11, 1],
		["Lana de oveja", 3, 0], ["Tapiz bordado", 14, 1], ["Alfombra persa", 22, 2], ["Piel de zorro", 10, 1],
		["Cuero curtido", 5, 0], ["Plumas exóticas", 9, 1], ["Sombrero de capitán", 13, 1], ["Casaca de gala", 20, 2],
		["Pañuelo de encaje", 6, 0], ["Botas de cuero", 5, 0], ["Cinturón con hebilla", 4, 0], ["Bandera antigua", 12, 1],
	]},
	"joyas": {"nombre": "Joyas y gemas", "objetos": [
		["Perla blanca", 12, 1], ["Perla negra", 30, 2], ["Rubí", 26, 2], ["Zafiro", 26, 2],
		["Esmeralda", 28, 2], ["Diamante", 55, 3], ["Amatista", 14, 1], ["Topacio", 13, 1],
		["Anillo de oro", 16, 1], ["Collar de perlas", 24, 2], ["Brazalete de plata", 11, 1], ["Corona enjoyada", 80, 3],
		["Pendientes de oro", 15, 1], ["Broche de rubí", 22, 2], ["Lingotes de oro", 45, 3], ["Lingotes de plata", 20, 2],
	]},
	"armas": {"nombre": "Armas y herramientas", "objetos": [
		["Sable pirata", 9, 1], ["Florete", 11, 1], ["Pistola de chispa", 14, 1], ["Mosquete", 16, 2],
		["Daga curva", 6, 0], ["Hacha de abordaje", 7, 0], ["Arpón", 6, 0], ["Garfio de abordaje", 5, 0],
		["Mazo de madera", 3, 0], ["Serrucho", 3, 0], ["Cuerda gruesa", 2, 0], ["Ancla pequeña", 8, 1],
		["Farol de aceite", 4, 0], ["Cubo de brea", 3, 0], ["Clavos de hierro", 2, 0], ["Pedernal", 4, 0],
	]},
	"navegacion": {"nombre": "Navegación", "objetos": [
		["Catalejo", 12, 1], ["Brújula de latón", 10, 1], ["Sextante", 18, 2], ["Astrolabio", 24, 2],
		["Reloj de arena", 6, 0], ["Carta náutica", 9, 1], ["Globo terráqueo", 20, 2], ["Cuaderno de bitácora", 5, 0],
		["Campana de barco", 8, 1], ["Timón tallado", 7, 0], ["Farol de señales", 5, 0], ["Botella con mensaje", 4, 0],
		["Barco en botella", 15, 1], ["Cuerno de niebla", 6, 0], ["Compás de puntas", 4, 0], ["Reloj de bolsillo", 17, 2],
	]},
	"exoticos": {"nombre": "Bebidas y exóticos", "objetos": [
		["Barril de ron", 8, 1], ["Botella de vino", 6, 0], ["Jarra de grog", 3, 0], ["Jarra de sidra", 3, 0],
		["Ánfora de aceite", 5, 0], ["Hojas de tabaco", 7, 1], ["Caja de puros", 13, 1], ["Coco", 2, 0],
		["Piña", 3, 0], ["Plátanos", 2, 0], ["Mango", 3, 0], ["Pluma de loro", 8, 1],
		["Caparazón de tortuga", 12, 1], ["Caracola rosa", 7, 0], ["Coral rojo", 16, 2], ["Estrella de mar", 4, 0],
	]},
	"reliquias": {"nombre": "Reliquias y curiosidades", "objetos": [
		["Ídolo de jade", 34, 2], ["Máscara tribal", 15, 1], ["Cáliz de oro", 32, 2], ["Moneda antigua", 10, 1],
		["Doblón maldito", 22, 2], ["Vasija antigua", 9, 1], ["Diente de tiburón", 6, 0], ["Colmillo de morsa", 12, 1],
		["Calavera de cristal", 70, 3], ["Amuleto maldito", 40, 3], ["Tablilla rúnica", 18, 2], ["Llave oxidada", 5, 0],
		["Caja de música", 19, 2], ["Huevo de serpiente marina", 50, 3], ["Escama de kraken", 45, 3], ["Tridente dorado", 90, 3],
	]},
}

static var _laminas := {}
static var _iconos := {}


static func ids() -> Array[String]:
	var todos: Array[String] = []
	for categoria in CATEGORIAS:
		for i in CATEGORIAS[categoria]["objetos"].size():
			todos.append("%s:%d" % [categoria, i])
	return todos


static func total() -> int:
	return ids().size()


static func _datos(id: String) -> Array:
	var partes := id.split(":")
	return CATEGORIAS[partes[0]]["objetos"][int(partes[1])]


static func existe(id: String) -> bool:
	var partes := id.split(":")
	return partes.size() == 2 and CATEGORIAS.has(partes[0]) and int(partes[1]) < CATEGORIAS[partes[0]]["objetos"].size()


static func nombre(id: String) -> String:
	return _datos(id)[0]


static func valor(id: String) -> int:
	return _datos(id)[1]


static func rareza(id: String) -> int:
	return _datos(id)[2]


static func categoria(id: String) -> String:
	return id.split(":")[0]


static func icono(id: String) -> Texture2D:
	return _recorte(categoria(id), int(id.split(":")[1]))


# Dibujos de materiales, mejoras y del mar libre (lámina "mejoras").
static func icono_mejora(nombre: String) -> Texture2D:
	return _recorte("mejoras", ICONOS_MEJORA[nombre])


# Recorte de una lámina de 4 x 4; se guarda para no repetirlo.
static func _recorte(lamina_nombre: String, i: int) -> Texture2D:
	var clave := "%s:%d" % [lamina_nombre, i]
	if _iconos.has(clave):
		return _iconos[clave]
	if not _laminas.has(lamina_nombre):
		_laminas[lamina_nombre] = load("res://interfaz/objetos/%s.jpg" % lamina_nombre)
	var lamina: Texture2D = _laminas[lamina_nombre]
	var celda := Vector2(lamina.get_width(), lamina.get_height()) / LADO_LAMINA
	var recorte := AtlasTexture.new()
	recorte.atlas = lamina
	recorte.region = Rect2(Vector2(i % LADO_LAMINA, i / LADO_LAMINA) * celda, celda)
	_iconos[clave] = recorte
	return recorte


# Un objeto al azar según la suerte de cada rareza.
static func al_azar() -> String:
	var tirada := randf()
	var buscada := 0
	for r in SUERTE_RAREZA.size():
		if tirada < SUERTE_RAREZA[r]:
			buscada = r
			break
		tirada -= SUERTE_RAREZA[r]
	return de_rareza(buscada)


static func de_rareza(buscada: int) -> String:
	var candidatos: Array[String] = []
	for id in ids():
		if rareza(id) == buscada:
			candidatos.append(id)
	return candidatos.pick_random()
