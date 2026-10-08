class_name Moba
extends Node3D

# Modo MOBA 1 contra 1: dos armadas, cada una con su nexo en una esquina del mapa y tres
# carriles (arriba, medio y abajo) defendidos por dos torres. Cada medio minuto salen botes
# por los carriles. Los barcos ganan oro y experiencia, suben de nivel, compran mejoras en la
# base y tienen una habilidad según su casco. Gana la armada que derribe el nexo rival.

const RADIO_MAPA := 1900.0
const BASES: Array[Vector2] = [Vector2(-1200.0, 1200.0), Vector2(1200.0, -1200.0)]
const ESQUINAS := {"arriba": Vector2(-1200.0, -1200.0), "abajo": Vector2(1200.0, 1200.0)}
const CARRILES: Array[String] = ["arriba", "medio", "abajo"]
const COLORES: Array[Color] = [Color("4fa8ff"), Color("ff5a4f")]
const COLOR_NOMBRE_ALIADO := Color("a8d4ff")
const POR_EQUIPO := 1
# Carril de cada capitán: el jugador (primero de la armada azul) va donde quiera.
const REPARTO: Array[String] = ["medio"]
# Dónde va cada torre, en fracción del carril desde la propia base: exterior e interior.
const FRACCIONES_TORRE: Array[float] = [0.41, 0.23]
const RADIO_TORRE := 52.0
# Las torres quedan a un lado del carril para que los botes no choquen con su islote.
const APARTE_TORRE := 120.0
const RADIO_NEXO := 95.0
const VIDA_TORRE := 440.0
const VIDA_NEXO := 900.0
const ALCANCE_TORRE := 270.0
const RECARGA_TORRE := 1.4
const RECARGA_NEXO := 1.0
const DANIO_TORRE := 20.0
const RADIO_FUENTE := 330.0
const DISTANCIA_SALIDA := 200.0
const VISION_BARCO := 420.0
const VISION_BOTE := 260.0
const VISION_TORRE := 360.0
const CURA_FUENTE := 0.14
const PRIMERA_OLEADA := 6.0
const ESPERA_OLEADA := 30.0
const BOTES_POR_OLEADA := 3
# Cada oleada sale un poco más fuerte para que las partidas no se estanquen.
const MEJORA_OLEADA := 0.08
const VIDA_BOTE := 45.0
const VEL_BOTE := 58.0
const ALCANCE_BOTE := 220.0
const RECARGA_BOTE := 1.7
const DANIO_BOTE := 4.0
# Contra los barcos de los capitanes los botes pegan menos que contra otros botes y fuertes.
const DANIO_BOTE_A_BARCO := 0.5
# Artilleros torpes: solo adelantan parte del movimiento del blanco, así que navegando se esquivan.
const PUNTERIA_BOTE := 0.6
const DESVIO_BOTE := 0.1
const RADIO_BOTE := 18.0
const LARGO_BOTE := 2.0
const ANCHO_BOTE := 0.8
const ALTO_BOTE := 0.32
const VEL_HEROE := 1.45
# Los capitanes giran más rápido que los barcos del resto de modos.
const GIRO_HEROE := 1.5
# Botón único de cañones: se arrastra para apuntar y, según hacia dónde quede el tiro respecto
# a la proa, dispara el cañón de proa o la andanada de un costado.
const BOTON_CANONES := Vector2(-140.0, -122.0)
const RADIO_CANONES := 44.0
const ALCANCE_CANON := Principal.VEL_BALA * Principal.VIDA_BALA
const ANGULO_PROA := PI / 4.0
const RADIO_AUTO := 20.0
const ORO_INICIAL := 150.0
const ORO_POR_SEGUNDO := 1.5
const ORO_BOTE := 8
const ORO_HEROE := 60
const ORO_TORRE := 80
const XP_BOTE := 15
const XP_HEROE := 45
const XP_TORRE := 50
const NIVEL_MAX := 12
const ALCANCE_XP := 650.0
const MAX_OBJETO := 3
const OBJETOS := {
	"casco": {"nombre": "Casco reforzado", "detalle": "+20% de vida", "precio": 250, "icono": "casco"},
	"canones": {"nombre": "Cañones de bronce", "detalle": "+15% de daño", "precio": 300, "icono": "canones"},
	"velas": {"nombre": "Velas de seda", "detalle": "+10% de velocidad", "precio": 200, "icono": "velas"},
	"polvora": {"nombre": "Pólvora fina", "detalle": "Recargas un 12% más rápido", "precio": 280, "icono": "recarga"},
}
const HABILIDADES := {
	"impulso": {"nombre": "Viento a favor", "corto": "Impulso", "espera": 12.0,
		"info": "Tu barco vuela un 80% más rápido durante 3 segundos."},
	"andanada": {"nombre": "Andanada circular", "corto": "Andanada", "espera": 14.0,
		"info": "Dispara 12 balas a la vez en todas las direcciones."},
	"escudo": {"nombre": "Casco de hierro", "corto": "Escudo", "espera": 18.0,
		"info": "Recibes un 60% menos de daño durante 4 segundos y reparas un 15%."},
	"fuego": {"nombre": "Bola de fuego", "corto": "Fuego", "espera": 9.0, "apuntar": true,
		"info": "Lanza una bola de fuego que daña al rival y lo deja ardiendo unos segundos."},
	"cadenas": {"nombre": "Balas encadenadas", "corto": "Cadenas", "espera": 11.0, "apuntar": true,
		"info": "Lanza cadenas que atrapan al rival: lo frenan y lo dañan mientras siga atrapado."},
	"reparar": {"nombre": "Marea curativa", "corto": "Curar", "espera": 16.0,
		"info": "Repara un 30% tu barco y un 20% a los aliados cercanos."},
	"remolino": {"nombre": "Remolino", "corto": "Remolino", "espera": 14.0, "apuntar": true, "area": 120.0, "alcance": 260.0,
		"info": "Abre un remolino donde apuntes que arrastra y daña a los rivales durante 4 segundos."},
	"kraken": {"nombre": "Tentáculos del kraken", "corto": "Kraken", "espera": 13.0, "apuntar": true, "area": 95.0, "alcance": 260.0,
		"info": "Los tentáculos salen del mar donde apuntes: golpean fuerte y dejan aturdido al rival."},
	"minas": {"nombre": "Barriles explosivos", "corto": "Minas", "espera": 12.0,
		"info": "Suelta tres barriles a popa que estallan cuando un rival los toca."},
	"niebla": {"nombre": "Velo de niebla", "corto": "Niebla", "espera": 16.0,
		"info": "Te vuelves invisible 4 segundos y navegas un 30% más rápido: los rivales te pierden."},
	"arpon": {"nombre": "Arpón ballenero", "corto": "Arpón", "espera": 10.0, "apuntar": true,
		"info": "Lanza un arpón que daña al rival y lo arrastra hasta tu barco."},
	"rayos": {"nombre": "Tormenta de rayos", "corto": "Rayos", "espera": 14.0,
		"info": "Tres rayos caen sobre los rivales más cercanos."},
}
# Capitanes del MOBA: cada uno con su barco (aspecto), su habilidad y su forma de navegar.
# Todos los barcos tienen el mismo tamaño en este modo; cambia el diseño.
const CAPITANES: Array[Dictionary] = [
	{"id": "brisa", "nombre": "Capitana Brisa", "corto": "Brisa", "barco": "La Golondrina", "habilidad": "impulso",
		"vida": 85.0, "velocidad": 50.0, "giro": 1.0, "info": "Rápida y escurridiza.",
		"aspecto": {"tipo": "balandro", "casco": "marino", "adorno": "plata", "velas": "cielo", "bandera": "estrella", "proa": "sirena", "popa": "faroles", "canones": "plata"},
		"figura": {"piel": "f1c7a0", "abrigo": "2f63c6", "sombrero": "1f3a6b", "pelo": "e8c070", "pluma": "f2f2f2", "barba": "", "parche": false, "melena": true, "saludo": "ola"}},
	{"id": "barbanegra", "nombre": "Barbanegra", "corto": "Barbanegra", "barco": "La Venganza", "habilidad": "andanada",
		"vida": 105.0, "velocidad": 42.0, "giro": 0.85, "info": "Pirata temido, todo cañones.",
		"aspecto": {"tipo": "bergantin", "casco": "corsario", "adorno": "negro", "velas": "pirata", "bandera": "jolly_roger", "proa": "dragon", "popa": "castillo", "canones": "hierro"},
		"figura": {"piel": "d9a27a", "abrigo": "1f1d22", "sombrero": "141414", "pelo": "141414", "pluma": "b5302a", "barba": "141414", "parche": true, "saludo": "espada"}},
	{"id": "hierro", "nombre": "Almirante Hierro", "corto": "Hierro", "barco": "El Coloso", "habilidad": "escudo",
		"vida": 140.0, "velocidad": 34.0, "giro": 0.72, "info": "Lento, pero casi imposible de hundir.",
		"aspecto": {"tipo": "galeon", "casco": "real", "adorno": "oro", "velas": "cruzada", "bandera": "real", "proa": "aguila", "popa": "galeria", "canones": "oro"},
		"figura": {"piel": "e8b892", "abrigo": "2a3f78", "sombrero": "1b1b1e", "pelo": "d8d8d8", "pluma": "e2b13a", "barba": "d8d8d8", "parche": false, "saludo": "militar"}},
	{"id": "escarlata", "nombre": "Lady Escarlata", "corto": "Escarlata", "barco": "Rosa de Fuego", "habilidad": "fuego",
		"vida": 100.0, "velocidad": 42.0, "giro": 0.85, "info": "Incendia de lejos a quien se le cruce.",
		"aspecto": {"tipo": "bergantin", "casco": "carmesi", "adorno": "cobre", "velas": "sol_rojo", "bandera": "sol", "proa": "sirena", "popa": "faroles", "canones": "bronce"},
		"figura": {"piel": "f3d0b0", "abrigo": "a8402f", "sombrero": "5a1830", "pelo": "c2453a", "pluma": "e2b13a", "barba": "", "parche": false, "melena": true, "saludo": "reverencia"}},
	{"id": "cadenas", "nombre": "Capitán Cadenas", "corto": "Cadenas", "barco": "El Ancla Negra", "habilidad": "cadenas",
		"vida": 130.0, "velocidad": 36.0, "giro": 0.75, "info": "Atrapa a sus presas para que no escapen.",
		"aspecto": {"tipo": "galeon", "casco": "ebano", "adorno": "plata", "velas": "remendada", "bandera": "tibias", "proa": "espolon", "popa": "castillo", "canones": "hierro"},
		"figura": {"piel": "8d5a3b", "abrigo": "55595e", "sombrero": "2e2b2b", "pelo": "2e2b2b", "pluma": "", "barba": "3b2a22", "parche": false, "saludo": "punos"}},
	{"id": "coral", "nombre": "Abuela Coral", "corto": "Coral", "barco": "La Perla Verde", "habilidad": "reparar",
		"vida": 95.0, "velocidad": 46.0, "giro": 0.95, "info": "Cuida de su armada en plena batalla.",
		"aspecto": {"tipo": "balandro", "casco": "esmeralda", "adorno": "turquesa", "velas": "arena", "bandera": "ancla", "proa": "sencilla", "popa": "camarote", "canones": "bronce"},
		"figura": {"piel": "e8b892", "abrigo": "2f8f6f", "sombrero": "e3cc98", "pelo": "f2f2f2", "pluma": "3fbfb0", "barba": "", "parche": false, "melena": true, "saludo": "abuela"}},
	{"id": "marea", "nombre": "Madame Marea", "corto": "Marea", "barco": "El Remolino", "habilidad": "remolino",
		"vida": 100.0, "velocidad": 42.0, "giro": 0.85, "info": "Bruja del mar que manda en las corrientes.",
		"aspecto": {"tipo": "bergantin_medusa", "casco": "g_amatista", "adorno": "g_lavanda", "velas": "g_luna_cielo_nieve", "bandera": "g_estrella_amatista_nieve", "proa": "sirena_amatista", "popa": "cupula_amatista", "canones": "g_lavanda"},
		"figura": {"piel": "c98e6a", "abrigo": "3a2a6b", "sombrero": "1f1a3a", "pelo": "e8e8f5", "pluma": "a88ad8", "barba": "", "parche": false, "melena": true, "saludo": "conjuro"}},
	{"id": "nautilo", "nombre": "Capitán Nautilo", "corto": "Nautilo", "barco": "El Abisal", "habilidad": "kraken",
		"vida": 125.0, "velocidad": 36.0, "giro": 0.75, "info": "Domó al kraken y ahora navega con él.",
		"aspecto": {"tipo": "galeon_kraken", "casco": "g_abismo", "adorno": "g_turquesa_claro", "velas": "g_marco_hielo_zafiro", "bandera": "g_tibias_abismo_hielo", "proa": "pulpo_esmeralda", "popa": "torre_hielo", "canones": "g_jade"},
		"figura": {"piel": "e0b090", "abrigo": "1f5a6b", "sombrero": "103040", "pelo": "6b4a30", "pluma": "3fe0d0", "barba": "6b4a30", "parche": false, "saludo": "catalejo"}},
	{"id": "mecha", "nombre": "Mecha Ruiz", "corto": "Mecha", "barco": "La Chispa", "habilidad": "minas",
		"vida": 90.0, "velocidad": 48.0, "giro": 0.95, "info": "Artillera loca: deja la pólvora a su paso.",
		"aspecto": {"tipo": "balandro_centella", "casco": "caoba", "adorno": "g_fuego", "velas": "g_sol_fuego_nieve", "bandera": "g_cuadros_carbon_fuego", "proa": "toro_cobre", "popa": "toldo_granate", "canones": "g_fuego_oscuro"},
		"figura": {"piel": "c58c64", "abrigo": "8a4a1a", "sombrero": "3a2a1a", "pelo": "1b1b1b", "pluma": "e0a030", "barba": "", "parche": true, "melena": true, "saludo": "baile"}},
	{"id": "niebla", "nombre": "Dama Niebla", "corto": "Niebla", "barco": "El Susurro", "habilidad": "niebla",
		"vida": 85.0, "velocidad": 50.0, "giro": 1.0, "info": "Nadie la ve llegar ni la ve irse.",
		"aspecto": {"tipo": "bergantin_bruma", "casco": "fantasma", "adorno": "g_ceniza_claro", "velas": "g_mitad_ceniza_hielo", "bandera": "g_luna_turquesa_sombra", "proa": "angel_plata", "popa": "fanales_carbon", "canones": "plata"},
		"figura": {"piel": "ece4f2", "abrigo": "4a5560", "sombrero": "2a2f36", "pelo": "1b1b1e", "pluma": "c9ced6", "barba": "", "parche": false, "melena": true, "saludo": "sigilo"}},
	{"id": "olaf", "nombre": "Olaf el Ballenero", "corto": "Olaf", "barco": "La Ballena Blanca", "habilidad": "arpon",
		"vida": 120.0, "velocidad": 38.0, "giro": 0.78, "info": "Cazador del norte: lo que arponea, no se escapa.",
		"aspecto": {"tipo": "galeon_narval", "casco": "hueso", "adorno": "madera", "velas": "franjas_rojas", "bandera": "g_franjas_plata_zafiro", "proa": "vikingo_bronce", "popa": "cabana_bronce", "canones": "g_caoba"},
		"figura": {"piel": "f0c8a8", "abrigo": "5a6b2f", "sombrero": "4a2a1a", "pelo": "e0a030", "pluma": "", "barba": "e0a030", "parche": false, "saludo": "arpon"}},
	{"id": "trueno", "nombre": "Señor Trueno", "corto": "Trueno", "barco": "La Tempestad", "habilidad": "rayos",
		"vida": 105.0, "velocidad": 40.0, "giro": 0.82, "info": "Llama a la tormenta y la tormenta responde.",
		"aspecto": {"tipo": "galeon_relampago", "casco": "g_zafiro", "adorno": "g_cielo_claro", "velas": "g_rombo_cielo_sombra", "bandera": "g_marco_carbon_hielo", "proa": "aguila_plata", "popa": "timonera_zafiro", "canones": "g_zafiro_claro"},
		"figura": {"piel": "a87050", "abrigo": "c9a227", "sombrero": "1b1b1e", "pelo": "2e2b2b", "pluma": "6fe6ff", "barba": "2e2b2b", "parche": false, "saludo": "trueno"}},
]
const LARGO_COMUN := 4.3
const RADIO_COMUN := 32.0
const ALTURA_COMUN := 5.4
# Escala del capitán en cubierta, en proporción al barco común.
const ALTURA_CAPITAN := 0.62
# Ángulo de cámara al elegir capitán: desde el lado del muelle, un poco hacia la proa.
const GIRO_SELECCION := -0.3
const DURACION_IMPULSO := 3.0
const DURACION_ESCUDO := 4.0
const BALAS_ANDANADA := 12
# Bola de fuego y cadenas: vuelan lo que una bala; sin apuntar, buscan al rival más cercano.
const ALCANCE_LANZADO := 270.0
const ESPERA_APUNTE := 0.22
const ZONA_APUNTE := 24.0
const DANIO_BOLA_FUEGO := 24.0
const DANIO_CADENAS := 10.0
const DANIO_ATRAPADO := 5.0
const DURACION_ATRAPADO := 3.5
const DURACION_REMOLINO := 4.0
const DANIO_REMOLINO := 7.0
const TIRON_REMOLINO := 75.0
const DANIO_KRAKEN := 30.0
const RETARDO_KRAKEN := 0.7
const ATURDIR_KRAKEN := 1.6
const DANIO_MINA := 28.0
const RADIO_MINA := 80.0
const TOQUE_MINA := 28.0
const DURACION_MINA := 25.0
const DURACION_NIEBLA := 4.0
const DANIO_ARPON := 14.0
const TIRON_ARPON := 300.0
const DURACION_ARPON := 0.7
const DANIO_RAYO := 22.0
const ALCANCE_RAYOS := 330.0
const RAYOS := 3
const ALCANCE_CURA := 320.0
const DURACION_ANUNCIO := 3.0
# Ensayo en el puerto: blancos quietos en el agua libre al oeste del muelle; la habilidad
# se recarga rápido y los blancos hundidos vuelven a los pocos segundos.
const ESPERA_ENSAYO := 3.0
const REPONER_DIANAS := 3.0
const DIANA_RIVAL := Vector2(-380.0, -30.0)
const DIANAS_BOTE: Array[Vector2] = [Vector2(-230.0, 140.0), Vector2(-270.0, -170.0), Vector2(-440.0, 90.0)]


class Torre:
	var pos := Vector2.ZERO
	var equipo := 0
	# "" para el nexo.
	var carril := ""
	# 0 exterior, 1 interior, 2 nexo.
	var orden := 0
	var vida := 0.0
	var vida_max := 0.0
	var viva := true
	var recarga := 0.0
	var destello := 0.0
	var isla: Circulo
	var nodo: Node3D
	var estructura: Node3D
	var ruinas: Node3D
	# Círculo sobre el agua hasta donde llegan sus cañones: contorno y un sombreado suave.
	var limite: Node3D
	var contorno: StandardMaterial3D
	var sombreado: StandardMaterial3D
	# Soportes giratorios de los cañones (miran a -Z) y su sitio en el plano.
	var canones: Array[Node3D] = []
	var sitios: Array[Vector2] = []
	var mira := Vector2.INF
	var pensar := 0.0


class Bote:
	var pos := Vector2.ZERO
	var pendiente := 0.0
	var rumbo := 0.0
	var equipo := 0
	var carril := ""
	var paso := 1
	var vida := VIDA_BOTE
	var vida_max := VIDA_BOTE
	var danio := DANIO_BOTE
	var recarga := 0.0
	var destello := 0.0
	var fase := 0.0
	var mira := Vector2.INF
	var nodo: Node3D
	var canon: Node3D
	var aparejo: Node3D
	var marinero: FiguraCapitan


class Heroe:
	var barco: Barco
	var capitan: Dictionary
	var equipo := 0
	var carril := "medio"
	var nivel := 1
	var xp := 0
	var oro := ORO_INICIAL
	var objetos := {"casco": 0, "canones": 0, "velas": 0, "polvora": 0}
	var reaparece := 0.0
	var habilidad := 0.0
	var impulso := 0.0
	var escudo := 0.0
	# Cadenas: segundos que le quedan atrapado, quién lo atrapó y las cadenas que lo rodean.
	var atrapado := 0.0
	var atrapador: Barco
	var grilletes: Node3D
	var oculto := 0.0
	var arrastre := 0.0
	var arrastrador: Barco
	var cuerda: MeshInstance3D
	var retirada := false
	var hundidos := 0
	var hundido := 0
	var pensar := 0.0
	var blanco = null
	var anillo: MeshInstance3D
	# En el ensayo, dónde vuelve a aparecer.
	var ancla := Vector2.ZERO


# Lo que deja una habilidad en el mar un rato: remolino, tentáculos, mina o rayo.
class Zona:
	var tipo := ""
	var pos := Vector2.ZERO
	var edad := 0.0
	var dura := 0.0
	var heroe: Heroe
	var nodo: Node3D
	var hecho := false


var mundo: Principal
var monstruos := MonstruosMarinos.new()
var torres: Array[Torre] = []
var zonas: Array[Zona] = []
var cuerdas := {}
var botes: Array[Bote] = []
var heroes: Array[Heroe] = []
var de_barco := {}
var espera_oleada := PRIMERA_OLEADA
var oleada := 0
var elegido := "barbanegra"
var figura_muelle: FiguraCapitan
var ensayo := false
var boton_terminar: Button
var ganador := -1
var anuncio := ""
var anuncio_color := Color.WHITE
var anuncio_vida := 0.0
var espera_protegida := 0.0
var mallas_bote := {}
var caja := BoxMesh.new()
var cilindro := CylinderMesh.new()
var cono := CylinderMesh.new()
var esfera := SphereMesh.new()
var toro := TorusMesh.new()
var toro_limite := TorusMesh.new()
var disco_limite := CylinderMesh.new()
var boton_habilidad: Button
# Habilidades que se apuntan: un toque tira recto por la proa; si se mantiene, se apunta
# arrastrando el dedo (o con el ratón mientras se aguanta la R) y se tira al soltar.
var dedo_apunte := -1
var tecla_apunte := false
var centro_apunte := Vector2.ZERO
var dedo_sitio := Vector2.ZERO
var apunte := Vector2.ZERO
var apunte_largo := 1.0
var tiempo_apunte := 0.0
var boton_canones: Button
var dedo_canon := -1
var tecla_canon := false
var centro_canon := Vector2.ZERO
var apunte_canon := Vector2.ZERO
var tiempo_canon := 0.0
# Piloto automático del jugador: su barco navega y dispara como un bot.
var auto := false
var dedo_auto := -1
var boton_tienda: Button
var panel_tienda: PanelContainer
var lista_tienda: VBoxContainer
var texto_oro_tienda: Label
var botones_tienda := {}
var panel_capitanes: PanelContainer
var botones_capitan := {}
var barras_capitan := {}
var icono_detalle: Control
var texto_capitan: Label
var texto_habilidad: Label
var texto_detalle: Label


func preparar(nuevo_mundo: Principal) -> void:
	mundo = nuevo_mundo
	add_child(monstruos)
	monstruos.preparar(self)
	cono.top_radius = 0.0
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cilindro.top_radius = 0.5
	cilindro.bottom_radius = 0.5
	cilindro.height = 1.0
	esfera.radius = 0.5
	esfera.height = 1.0
	toro.inner_radius = 0.92
	toro.outer_radius = 1.0
	toro.rings = 40
	toro.ring_segments = 4
	toro_limite.inner_radius = 0.985
	toro_limite.outer_radius = 1.0
	toro_limite.rings = 96
	toro_limite.ring_segments = 4
	disco_limite.top_radius = 0.985
	disco_limite.bottom_radius = 0.985
	disco_limite.height = 0.001
	disco_limite.radial_segments = 64
	disco_limite.rings = 1


# Carriles

func camino(carril: String, equipo: int) -> PackedVector2Array:
	var puntos := PackedVector2Array([BASES[0]])
	if ESQUINAS.has(carril):
		puntos.append(ESQUINAS[carril])
	puntos.append(BASES[1])
	if equipo == 1:
		puntos.reverse()
	return puntos


func _largo(puntos: PackedVector2Array) -> float:
	var total := 0.0
	for k in range(1, puntos.size()):
		total += puntos[k - 1].distance_to(puntos[k])
	return total


func _punto_en(puntos: PackedVector2Array, recorrido: float) -> Vector2:
	var resto := maxf(0.0, recorrido)
	for k in range(1, puntos.size()):
		var tramo := puntos[k - 1].distance_to(puntos[k])
		if resto <= tramo:
			return puntos[k - 1].lerp(puntos[k], resto / tramo)
		resto -= tramo
	return puntos[puntos.size() - 1]


# Cuánto ha avanzado un punto por el carril (proyección sobre el tramo más cercano).
func _progreso(puntos: PackedVector2Array, punto: Vector2) -> float:
	var mejor := 0.0
	var menor := INF
	var antes := 0.0
	for k in range(1, puntos.size()):
		var a := puntos[k - 1]
		var b := puntos[k]
		var tramo := b - a
		var t := clampf((punto - a).dot(tramo) / tramo.length_squared(), 0.0, 1.0)
		var d := punto.distance_to(a + tramo * t)
		if d < menor:
			menor = d
			mejor = antes + tramo.length() * t
		antes += tramo.length()
	return mejor


func _distancia_a_carriles(punto: Vector2) -> float:
	var menor := INF
	for carril in CARRILES:
		var puntos := camino(carril, 0)
		for k in range(1, puntos.size()):
			var a := puntos[k - 1]
			var tramo := puntos[k] - a
			var t := clampf((punto - a).dot(tramo) / tramo.length_squared(), 0.0, 1.0)
			menor = minf(menor, punto.distance_to(a + tramo * t))
	return menor


# Partida

func empezar() -> void:
	vaciar()
	mundo.zona_centro = Vector2.ZERO
	mundo.zona_radio = 99999.0
	mundo.islas._vaciar()
	_crear_islas()
	monstruos.empezar()
	for equipo in 2:
		_crear_torre(BASES[equipo], equipo, "", 2)
		for carril in CARRILES:
			var puntos := camino(carril, equipo)
			for orden in FRACCIONES_TORRE.size():
				var recorrido := _largo(puntos) * FRACCIONES_TORRE[orden]
				var tramo := (_punto_en(puntos, recorrido + 10.0) - _punto_en(puntos, recorrido - 10.0)).normalized()
				var punto := _punto_en(puntos, recorrido) + tramo.orthogonal() * APARTE_TORRE
				_crear_torre(punto, equipo, carril, orden)
	_crear_heroes()
	espera_oleada = PRIMERA_OLEADA
	oleada = 0
	_anunciar(tr("¡Derriba el nexo enemigo!"), Principal.COLOR_ORO)


func vaciar() -> void:
	monstruos.vaciar()
	for bote in botes:
		bote.nodo.queue_free()
	botes.clear()
	for zona in zonas:
		zona.nodo.queue_free()
	zonas.clear()
	for cuerda in cuerdas.values():
		cuerda.queue_free()
	cuerdas.clear()
	for heroe in heroes:
		if heroe.anillo != null:
			heroe.anillo.queue_free()
		_soltar_arpon(heroe)
		_mostrar_casco(heroe, 0.0)
	heroes.clear()
	de_barco.clear()
	for torre in torres:
		torre.limite.queue_free()
	torres.clear()
	ganador = -1
	anuncio_vida = 0.0
	auto = false
	dedo_auto = -1
	dedo_canon = -1
	tecla_canon = false
	apunte_canon = Vector2.ZERO
	cerrar_tienda()


func _crear_heroes() -> void:
	for equipo in 2:
		# Un capitán por armada; el jugador lleva el que eligió y el rival, otro al azar.
		var reparto := CAPITANES.duplicate()
		reparto.shuffle()
		if equipo == 0:
			reparto.erase(capitan_elegido())
			reparto.push_front(capitan_elegido())
		for k in POR_EQUIPO:
			var jugador := equipo == 0 and k == 0
			var capitan: Dictionary = reparto[k]
			var barco := mundo._crear_barco(aspecto_de(capitan), jugador, _salida(equipo, k))
			igualar_barco(barco, capitan)
			barco.rumbo = _rumbo_hacia(barco.pos, Vector2.ZERO)
			barco.equipo = equipo
			if jugador:
				barco.nombre = mundo.personalizacion.nombre_visible()
				mundo.jugador = barco
			else:
				barco.es_bot = true
				barco.nombre = tr(capitan["nombre"])
			var heroe := _sumar_heroe(barco, capitan, equipo)
			heroe.carril = REPARTO[k] if equipo == 0 else REPARTO[(k + 1) % POR_EQUIPO]


func _sumar_heroe(barco: Barco, capitan: Dictionary, equipo: int) -> Heroe:
	barco.equipo = equipo
	var heroe := Heroe.new()
	heroe.barco = barco
	heroe.capitan = capitan
	heroe.equipo = equipo
	heroe.ancla = barco.pos
	if barco != mundo.jugador:
		heroe.anillo = MeshInstance3D.new()
		heroe.anillo.mesh = toro
		var materia := StandardMaterial3D.new()
		materia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		materia.albedo_color = Color(COLORES[equipo], 0.55)
		heroe.anillo.material_override = materia
		heroe.anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(heroe.anillo)
	heroes.append(heroe)
	de_barco[barco] = heroe
	_aplicar(heroe)
	barco.vida = barco.vida_max
	return heroe


# Ensayo en el puerto: el barco suelta amarras y prueba su habilidad contra un barco rival
# y tres botes quietos, sin oleadas ni fuertes. Se sale con «Terminar ensayo».
func empezar_ensayo() -> void:
	vaciar()
	ensayo = true
	mundo.modo = "moba"
	mundo.zona_centro = Vector2.ZERO
	mundo.zona_radio = 99999.0
	mundo.islas.muelle.soltar()
	var jugador := mundo.jugador
	for hijo in jugador.modelo.get_children():
		if hijo is FiguraCapitan:
			hijo.visible = true
	_sumar_heroe(jugador, capitan_elegido(), 0)
	var otros := CAPITANES.filter(func(otro: Dictionary) -> bool: return otro["id"] != elegido)
	var capitan: Dictionary = otros.pick_random()
	var rival := mundo._crear_barco(aspecto_de(capitan), false, DIANA_RIVAL)
	igualar_barco(rival, capitan)
	rival.es_bot = true
	rival.nombre = tr("Blanco de práctica")
	rival.rumbo = _rumbo_hacia(DIANA_RIVAL, jugador.pos) + PI / 2.0
	_sumar_heroe(rival, capitan, 1)
	_poner_dianas()
	mundo._mostrar(Principal.Estado.JUGANDO)
	mundo._pintar_hud()
	_anunciar(tr("Ensaya tu habilidad contra los blancos"), Principal.COLOR_ORO)


func terminar_ensayo() -> void:
	ensayo = false
	boton_terminar.visible = false
	mundo._al_puerto(true)


func _poner_dianas() -> void:
	for punto in DIANAS_BOTE:
		var bote := Bote.new()
		bote.equipo = 1
		bote.pos = punto
		bote.rumbo = randf() * TAU
		_crear_bote(bote)
		add_child(bote.nodo)
		botes.append(bote)


func capitan_elegido() -> Dictionary:
	for capitan in CAPITANES:
		if capitan["id"] == elegido:
			return capitan
	return CAPITANES[0]


static func aspecto_de(capitan: Dictionary) -> Personalizacion:
	var aspecto := Personalizacion.new()
	for categoria in capitan["aspecto"]:
		aspecto.elegidos[categoria] = capitan["aspecto"][categoria]
	return aspecto


# Todos los barcos del MOBA miden lo mismo: el modelo se escala al largo común y el capitán
# sube a cubierta junto al timón.
func igualar_barco(barco: Barco, capitan: Dictionary) -> void:
	var tipo := barco.tipo
	var medidas: Dictionary = ModeloBarco.MEDIDAS[tipo]
	var escala: float = LARGO_COMUN / medidas["largo"]
	barco.modelo.scale = Vector3.ONE * escala
	barco.desgaste.scale = Vector3.ONE * escala
	barco.radio = RADIO_COMUN
	barco.altura = ALTURA_COMUN
	barco.set_meta("capitan", capitan["id"])
	if barco.es_jugador:
		barco._crear_aro()
	var figura := crear_figura(capitan["figura"])
	var timon: Node3D = barco.modelo.get_node("Timon")
	figura.position = timon.position
	figura.scale = timon.scale
	barco.modelo.add_child(figura)
	figura.tomar_timon(timon.get_node("Rueda"))


static func crear_figura(datos: Dictionary) -> FiguraCapitan:
	return FiguraCapitan.crear(datos)


# Salidas en arco frente al nexo, todas dentro de la fuente para poder comprar al aparecer.
func _salida(equipo: int, k: int) -> Vector2:
	var hacia := -BASES[equipo].normalized()
	return BASES[equipo] + hacia.rotated((k - (POR_EQUIPO - 1) / 2.0) * 0.36) * DISTANCIA_SALIDA


func _rumbo_hacia(desde: Vector2, hacia: Vector2) -> float:
	var d := hacia - desde
	return atan2(d.x, -d.y)


# Mapa: islas entre los carriles, puestas en espejo para que las dos armadas lo tengan igual.

func _crear_islas() -> void:
	var islas := mundo.islas
	var puestas: Array[Circulo] = []
	for _intento in 400:
		if puestas.size() >= 18:
			break
		var radio := randf_range(48.0, 92.0) if puestas.size() < 10 else randf_range(24.0, 34.0)
		var punto := Vector2(randf_range(-1500.0, 1500.0), randf_range(-1500.0, 1500.0))
		if punto.y > -punto.x:
			continue
		if _distancia_a_carriles(punto) < radio + 240.0 or punto.length() > RADIO_MAPA - 250.0:
			continue
		if punto.distance_to(BASES[0]) < 600.0 or punto.distance_to(BASES[1]) < 600.0:
			continue
		if absf(punto.y + punto.x) < radio * 2.0 + 60.0:
			continue
		var libre := true
		for otra in puestas:
			if punto.distance_to(otra.pos) < otra.radio + radio + 110.0:
				libre = false
				break
		if libre:
			puestas.append(Circulo.new(punto, radio))
	for isla in puestas:
		for espejo in [isla, Circulo.new(-isla.pos, isla.radio)]:
			var nodo: Node3D
			if espejo.radio <= Islas.RADIO_ROCAS:
				nodo = islas._crear_rocas(espejo)
			else:
				espejo.radio *= 1.15
				espejo.dar_forma()
				nodo = islas._crear_isla(espejo)
			islas.add_child(nodo)
			islas.islotes.append(espejo)


# Islote con una torre de piedra (o el nexo: un castillo con un faro del color de la armada).
func _crear_torre(punto: Vector2, equipo: int, carril: String, orden: int) -> void:
	var islas := mundo.islas
	var torre := Torre.new()
	torre.pos = punto
	torre.equipo = equipo
	torre.carril = carril
	torre.orden = orden
	torre.vida_max = VIDA_NEXO if orden == 2 else VIDA_TORRE
	torre.vida = torre.vida_max
	torre.recarga = randf()
	torre.isla = Circulo.new(punto, RADIO_NEXO if orden == 2 else RADIO_TORRE)
	var nodo := Node3D.new()
	nodo.position = mundo.a_3d(punto)
	var r := torre.isla.radio * Principal.ESCALA
	islas._malla(nodo, islas._arena(r, torre.isla), Islas.COLOR_ARENA, Vector3.ZERO)
	nodo.add_child(islas._orilla(r * 1.15))
	islas._fondo(nodo, r, torre.isla, int(8 + r * 2.0))
	nodo.set_meta("radio", r)
	var piedra := mundo.material(Color("a39e93"), "roca")
	var oscura := mundo.material(Color("7d786e"), "roca")
	var color := mundo.material(COLORES[equipo])
	torre.estructura = Node3D.new()
	nodo.add_child(torre.estructura)
	var madera := mundo.material(Color("5a3d24"), "madera")
	var bandera := {"color": COLORES[equipo], "color2": Color("f2f2f2"), "diseno": "estrella"}
	if orden == 2:
		# Ciudadela: muralla cuadrada con un baluarte en cada esquina y el torreón del faro.
		var lado := r * 0.6
		for k in 4:
			var a := TAU * k / 4.0
			var desde := Vector3(cos(a), 0, sin(a)) * lado * sqrt(2.0)
			var hasta := Vector3(cos(a + PI / 2.0), 0, sin(a + PI / 2.0)) * lado * sqrt(2.0)
			_muro(torre.estructura, desde.rotated(Vector3.UP, PI / 4.0), hasta.rotated(Vector3.UP, PI / 4.0), 1.3, 0.4, piedra, oscura)
		for k in 4:
			var esquina := Vector3(1 if k % 2 == 0 else -1, 0, 1 if k < 2 else -1) * lado
			_pieza(torre.estructura, cilindro, piedra, esquina + Vector3(0, 0.95, 0), Vector3(1.3, 1.9, 1.3))
			_pieza(torre.estructura, cilindro, oscura, esquina + Vector3(0, 1.95, 0), Vector3(1.45, 0.14, 1.45))
			for m in 6:
				var b := TAU * m / 6.0
				_pieza(torre.estructura, caja, piedra, esquina + Vector3(cos(b), 0, sin(b)) * 0.62 + Vector3(0, 2.15, 0), Vector3(0.2, 0.28, 0.2))
			_montar_canon(torre, esquina + Vector3(0, 2.02, 0), madera, 2.4)
		for k in 4:
			var a := TAU * k / 4.0
			var junto := Vector3(cos(a), 0, sin(a)) * (lado + 0.22)
			var pendon := _pieza(torre.estructura, caja, color, junto + Vector3(0, 0.7, 0), Vector3(0.03, 0.75, 0.5))
			pendon.rotation.y = -a
		_castillo(torre.estructura, piedra, oscura, color, madera, COLORES[equipo])
		var asta := Node3D.new()
		asta.position = Vector3(0, 5.85, 0)
		torre.estructura.add_child(asta)
		ModeloBarco._izar_bandera(asta, 0.0, 1.4, Principal.COLOR_ORO, bandera)
	else:
		# Fuerte: muralla octogonal almenada, un torreón con la bandera y dos cañones giratorios.
		var radio_muro := r * 0.78
		for k in 8:
			var a := TAU * k / 8.0
			_muro(torre.estructura, Vector3(cos(a), 0, sin(a)) * radio_muro, Vector3(cos(a + TAU / 8.0), 0, sin(a + TAU / 8.0)) * radio_muro, 0.9, 0.3, piedra, oscura)
		_pieza(torre.estructura, cilindro, oscura, Vector3(0, 0.12, 0), Vector3(radio_muro * 1.9, 0.24, radio_muro * 1.9))
		_pieza(torre.estructura, caja, piedra, Vector3(0, 0.85, 0), Vector3(1.5, 1.7, 1.5))
		_pieza(torre.estructura, caja, oscura, Vector3(0, 1.75, 0), Vector3(1.7, 0.12, 1.7))
		for m in 4:
			var b := TAU * m / 4.0 + PI / 4.0
			_pieza(torre.estructura, caja, piedra, Vector3(cos(b), 0, sin(b)) * 0.95 + Vector3(0, 1.95, 0), Vector3(0.28, 0.3, 0.28))
		_pieza(torre.estructura, caja, madera, Vector3(0, 0.45, 0.76), Vector3(0.5, 0.8, 0.04))
		for k in range(1, 4):
			var estandarte := _pieza(torre.estructura, caja, color, Vector3(0, 1.1, 0.77).rotated(Vector3.UP, TAU * k / 4.0), Vector3(0.36, 0.8, 0.03))
			estandarte.rotation.y = TAU * k / 4.0
		for k in 8:
			var a := TAU * (k + 0.5) / 8.0
			var junto := Vector3(cos(a), 0, sin(a)) * (radio_muro * cos(PI / 8.0) + 0.16)
			var pendon := _pieza(torre.estructura, caja, color, junto + Vector3(0, 0.5, 0), Vector3(0.03, 0.55, 0.3))
			pendon.rotation.y = -a
		for lado: float in [-1.0, 1.0]:
			_montar_canon(torre, Vector3(lado * 0.42, 1.82, 0), madera, 2.2)
		var asta := Node3D.new()
		asta.position = Vector3(-0.6, 1.8, -0.6)
		torre.estructura.add_child(asta)
		ModeloBarco._izar_bandera(asta, 0.0, 1.6, Principal.COLOR_ORO, bandera)
	torre.ruinas = Node3D.new()
	torre.ruinas.visible = false
	nodo.add_child(torre.ruinas)
	for k in 7:
		var a := randf() * TAU
		var trozo := _pieza(torre.ruinas, caja, piedra if k % 2 == 0 else oscura, Vector3(cos(a), 0, sin(a)) * randf_range(0.2, r * 0.5) + Vector3(0, 0.3, 0), Vector3.ONE * randf_range(0.4, 0.9))
		trozo.rotation = Vector3(randf(), randf() * TAU, randf())
	_crear_limite(torre)
	torre.nodo = nodo
	islas.add_child(nodo)
	islas.islotes.append(torre.isla)
	torres.append(torre)


# Castillo del centro de la ciudadela: torre del homenaje cuadrada y almenada con un portón
# en cada cara, cuatro torrecillas con tejado del color del equipo y una torre alta cuyas
# ventanas brillan con ese color.
func _castillo(padre: Node3D, piedra: Material, oscura: Material, color: Material, madera: Material, tono: Color) -> void:
	var luz := StandardMaterial3D.new()
	luz.albedo_color = tono
	luz.emission_enabled = true
	luz.emission = tono
	luz.emission_energy_multiplier = 2.0
	_pieza(padre, caja, oscura, Vector3(0, 0.12, 0), Vector3(2.5, 0.25, 2.5))
	_pieza(padre, caja, piedra, Vector3(0, 1.2, 0), Vector3(2.2, 2.4, 2.2))
	_pieza(padre, caja, oscura, Vector3(0, 2.45, 0), Vector3(2.4, 0.14, 2.4))
	for k in 4:
		var a := TAU * k / 4.0
		var fuera := Vector3(sin(a), 0, cos(a))
		var lado := fuera.cross(Vector3.UP)
		for m in 4:
			_pieza(padre, caja, piedra, fuera * 1.08 + lado * lerpf(-0.6, 0.6, m / 3.0) + Vector3(0, 2.66, 0), Vector3(0.24, 0.28, 0.24))
		var porton := _pieza(padre, caja, madera, fuera * 1.11 + Vector3(0, 0.5, 0), Vector3(0.6, 1.0, 0.04))
		porton.rotation.y = a
		var arco := _pieza(padre, cilindro, madera, fuera * 1.11 + Vector3(0, 1.0, 0), Vector3(0.6, 0.04, 0.6))
		arco.rotation = Vector3(PI / 2.0, a, 0)
		for s: float in [-1.0, 1.0]:
			var estandarte := _pieza(padre, caja, color, fuera * 1.115 + lado * s * 0.68 + Vector3(0, 1.45, 0), Vector3(0.34, 0.9, 0.03))
			estandarte.rotation.y = a
		var ventana := _pieza(padre, caja, luz, fuera * 0.66 + Vector3(0, 3.55, 0), Vector3(0.18, 0.36, 0.04))
		ventana.rotation.y = a
	for k in 4:
		var esquina := Vector3(1 if k % 2 == 0 else -1, 0, 1 if k < 2 else -1) * 1.1
		_pieza(padre, cilindro, piedra, esquina + Vector3(0, 1.7, 0), Vector3(0.75, 3.4, 0.75))
		_pieza(padre, cilindro, oscura, esquina + Vector3(0, 3.42, 0), Vector3(0.88, 0.1, 0.88))
		_pieza(padre, cono, color, esquina + Vector3(0, 3.95, 0), Vector3(0.95, 1.0, 0.95))
	_pieza(padre, cilindro, piedra, Vector3(0, 3.4, 0), Vector3(1.3, 2.0, 1.3))
	_pieza(padre, cilindro, oscura, Vector3(0, 4.42, 0), Vector3(1.45, 0.12, 1.45))
	_pieza(padre, cono, color, Vector3(0, 5.15, 0), Vector3(1.65, 1.45, 1.65))


func alcance_torre(torre: Torre) -> float:
	return ALCANCE_TORRE + torre.isla.radio * 0.5


func _crear_limite(torre: Torre) -> void:
	torre.limite = Node3D.new()
	torre.limite.position = mundo.a_3d(torre.pos) + Vector3(0, 0.14, 0)
	var r := alcance_torre(torre) * Principal.ESCALA
	torre.limite.scale = Vector3(r, 1.0, r)
	add_child(torre.limite)
	torre.contorno = _material_limite()
	torre.sombreado = _material_limite()
	for pieza: Array in [[toro_limite, torre.contorno], [disco_limite, torre.sombreado]]:
		var malla := MeshInstance3D.new()
		malla.mesh = pieza[0]
		malla.material_override = pieza[1]
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		torre.limite.add_child(malla)


func _material_limite() -> StandardMaterial3D:
	var materia := StandardMaterial3D.new()
	materia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materia.cull_mode = BaseMaterial3D.CULL_DISABLED
	return materia


# El límite de las torres enemigas se pone rojo y late mientras el jugador está a tiro.
func _pintar_limites() -> void:
	var jugador := mundo.jugador
	var mio := heroe_jugador()
	for torre in torres:
		var cerca := torre.pos.distance_to(Vector2(mundo.foco.x, mundo.foco.z) / Principal.ESCALA) < alcance_torre(torre) + mundo.alcance_vista() / Principal.ESCALA
		torre.limite.visible = torre.viva and cerca
		if not torre.limite.visible:
			continue
		var enemiga := mio != null and torre.equipo != mio.equipo
		var a_tiro := enemiga and jugador != null and jugador.viva and jugador.pos.distance_to(torre.pos) < alcance_torre(torre)
		if a_tiro:
			var latido := 0.5 + 0.5 * sin(mundo.tiempo * 6.0)
			torre.contorno.albedo_color = Color(Principal.COLOR_PELIGRO, lerpf(0.55, 0.9, latido))
			torre.sombreado.albedo_color = Color(Principal.COLOR_PELIGRO, lerpf(0.08, 0.16, latido))
		else:
			torre.contorno.albedo_color = Color(COLORES[torre.equipo], 0.5 if enemiga else 0.3)
			torre.sombreado.albedo_color = Color(COLORES[torre.equipo], 0.06 if enemiga else 0.03)


# Lienzo de muralla entre dos puntos, con almenas encima.
func _muro(padre: Node3D, a: Vector3, b: Vector3, alto: float, grueso: float, piedra: Material, oscura: Material) -> void:
	var largo := a.distance_to(b)
	var medio := (a + b) / 2.0
	var giro := atan2(b.x - a.x, b.z - a.z)
	var muro := _pieza(padre, caja, piedra, medio + Vector3(0, alto / 2.0, 0), Vector3(grueso, alto, largo + grueso * 0.6))
	muro.rotation.y = giro
	var remate := _pieza(padre, caja, oscura, medio + Vector3(0, alto + 0.04, 0), Vector3(grueso + 0.08, 0.08, largo + grueso * 0.6))
	remate.rotation.y = giro
	var almenas := maxi(2, int(largo / 0.45))
	for k in almenas:
		var punto := a.lerp(b, (k + 0.5) / almenas)
		var almena := _pieza(padre, caja, piedra, punto + Vector3(0, alto + 0.2, 0), Vector3(grueso, 0.3, largo / almenas * 0.5))
		almena.rotation.y = giro


# Cureña de madera con su cañón sobre un soporte que gira para apuntar (mira a -Z).
func _montar_canon(torre: Torre, sitio: Vector3, madera: Material, escala: float) -> void:
	var soporte := Node3D.new()
	soporte.position = sitio
	torre.estructura.add_child(soporte)
	_pieza(soporte, cilindro, madera, Vector3(0, 0.05, 0), Vector3(0.75, 0.1, 0.75))
	for lado: float in [-1.0, 1.0]:
		_pieza(soporte, caja, madera, Vector3(lado * 0.17, 0.2, 0.05), Vector3(0.07, 0.24, 0.5))
	ModeloBarco._canon(soporte, "anillado", Color("2b2e31"), Vector3(0, 0.3, -0.05), Vector3(0, 0, -1), escala)
	soporte.rotation.y = randf() * TAU
	torre.canones.append(soporte)
	torre.sitios.append(Vector2(sitio.x, sitio.z) / Principal.ESCALA)


func _pieza(padre: Node3D, malla: Mesh, materia: Material, pos: Vector3, escala: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = malla
	pieza.material_override = materia
	pieza.position = pos
	pieza.scale = escala
	padre.add_child(pieza)
	return pieza


# Las torres interiores no se pueden dañar mientras siga en pie la exterior de su carril, y el
# nexo, mientras sigan en pie todas las interiores.
func vulnerable(torre: Torre) -> bool:
	if torre.orden == 0:
		return true
	for otra in torres:
		if otra.equipo != torre.equipo or otra.viva:
			continue
		if torre.orden == 1 and otra.carril == torre.carril and otra.orden == 0:
			return true
		if torre.orden == 2 and otra.orden == 1:
			return true
	return false


# Bucle

func actualizar(delta: float) -> void:
	_seguir_apunte(delta)
	_seguir_canones(delta)
	_animar_lanzados(delta)
	_actualizar_zonas(delta)
	anuncio_vida = maxf(0.0, anuncio_vida - delta)
	espera_protegida = maxf(0.0, espera_protegida - delta)
	if ganador >= 0:
		return
	if ensayo:
		if botes.is_empty():
			espera_oleada -= delta
			if espera_oleada <= 0.0:
				_poner_dianas()
		else:
			espera_oleada = REPONER_DIANAS
		for heroe in heroes:
			_atender(heroe, delta)
		_actualizar_interfaz()
		return
	espera_oleada -= delta
	if espera_oleada <= 0.0:
		espera_oleada = ESPERA_OLEADA
		_soltar_oleada()
	for i in range(botes.size() - 1, -1, -1):
		var paso := mundo.paso_lejano(botes[i], i, delta)
		if paso > 0.0:
			_mover_bote(botes[i], paso)
	for torre in torres:
		if torre.viva:
			_defender(torre, delta)
		torre.destello = maxf(0.0, torre.destello - delta * 3.0)
	monstruos.actualizar(delta)
	for heroe in heroes:
		_atender(heroe, delta)
	_actualizar_interfaz()


func _atender(heroe: Heroe, delta: float) -> void:
	var barco := heroe.barco
	heroe.oro += ORO_POR_SEGUNDO * delta
	heroe.habilidad = maxf(0.0, heroe.habilidad - delta)
	if heroe.impulso > 0.0:
		heroe.impulso -= delta
		if heroe.impulso <= 0.0:
			_aplicar(heroe)
	if heroe.escudo > 0.0:
		heroe.escudo -= delta
		if heroe.escudo <= 0.0:
			_aplicar(heroe)
	if heroe.atrapado > 0.0:
		heroe.atrapado -= delta
		if barco.viva and heroe.atrapado > 0.0:
			barco.recibir_danio(DANIO_ATRAPADO * delta, false, heroe.atrapador)
			barco.frenado = maxf(barco.frenado, heroe.atrapado)
			heroe.grilletes.scale = Vector3.ONE * (1.0 + sin(heroe.atrapado * 9.0) * 0.035)
		else:
			_soltar(heroe)
	if heroe.oculto > 0.0:
		heroe.oculto -= delta
		if heroe.oculto <= 0.0 or not barco.viva:
			heroe.oculto = 0.0
			_mostrar_casco(heroe, 0.0)
			_aplicar(heroe)
	if heroe.arrastre > 0.0:
		heroe.arrastre -= delta
		var tirador := heroe.arrastrador
		if heroe.arrastre > 0.0 and barco.viva and is_instance_valid(tirador) and tirador.viva \
				and barco.pos.distance_to(tirador.pos) > barco.radio + tirador.radio + 20.0:
			barco.pos = barco.pos.move_toward(tirador.pos, TIRON_ARPON * delta)
			barco.frenado = maxf(barco.frenado, 0.3)
			_tender_cuerda(heroe.cuerda, tirador.position + Vector3(0, 0.9, 0), barco.position + Vector3(0, 0.9, 0))
		else:
			_soltar_arpon(heroe)
	if not barco.viva:
		heroe.reaparece -= delta
		if heroe.reaparece <= 0.0:
			_reaparecer(heroe)
		return
	if en_fuente(barco):
		barco.vida = minf(barco.vida_max, barco.vida + barco.vida_max * CURA_FUENTE * delta)
		if barco.es_bot:
			_comprar_bot(heroe)
	elif barco.pos.distance_to(BASES[1 - heroe.equipo]) < RADIO_FUENTE:
		barco.recibir_danio(barco.vida_max * 0.25 * delta)


func en_fuente(barco: Barco) -> bool:
	return barco.equipo >= 0 and barco.pos.distance_to(BASES[barco.equipo]) < RADIO_FUENTE


func _reaparecer(heroe: Heroe) -> void:
	var barco := heroe.barco
	barco.pos = heroe.ancla if ensayo else _salida(heroe.equipo, randi_range(0, POR_EQUIPO - 1))
	barco.rumbo = _rumbo_hacia(barco.pos, Vector2.ZERO)
	barco.viva = true
	barco.vida = barco.vida_max
	barco.hundimiento = 0.0
	barco.velocidad = 0.0
	barco.quemadura = 0.0
	barco.frenado = 0.0
	barco.ultimo_atacante = null
	barco.visible = true
	heroe.retirada = false
	heroe.blanco = null
	if barco == mundo.jugador:
		_anunciar(tr("¡De vuelta al mar!"), COLOR_NOMBRE_ALIADO)


func experiencia_para(nivel: int) -> int:
	return 60 + 30 * nivel


func _ganar_xp(heroe: Heroe, cantidad: int) -> void:
	if heroe.nivel >= NIVEL_MAX:
		return
	heroe.xp += cantidad
	var subio := false
	while heroe.nivel < NIVEL_MAX and heroe.xp >= experiencia_para(heroe.nivel):
		heroe.xp -= experiencia_para(heroe.nivel)
		heroe.nivel += 1
		subio = true
	if not subio:
		return
	_aplicar(heroe)
	if heroe.barco == mundo.jugador:
		_anunciar(tr("¡Nivel %d!") % heroe.nivel, Color("7dffb2"))
		mundo.avisar_premio(heroe.barco.position + Vector3(0, 3.0, 0), tr("¡Nivel %d!") % heroe.nivel, Color("7dffb2"))


func _ganar_oro(heroe: Heroe, cantidad: int, punto: Vector3) -> void:
	heroe.oro += cantidad
	if heroe.barco == mundo.jugador:
		mundo.avisar_premio(punto, "+%d" % cantidad, Principal.COLOR_ORO)


# Vida, daño, velocidad y recarga según el nivel, las mejoras compradas y la habilidad activa.
func _aplicar(heroe: Heroe) -> void:
	var barco := heroe.barco
	var datos := heroe.capitan
	barco.giro_max = datos["giro"] * GIRO_HEROE
	barco.agil = true
	var proporcion := barco.vida / barco.vida_max if barco.vida_max > 0.0 else 1.0
	var nivel := heroe.nivel - 1
	barco.vida_max = datos["vida"] * (1.0 + 0.08 * nivel) * (1.0 + 0.2 * heroe.objetos["casco"])
	barco.vida = barco.vida_max * proporcion
	barco.factor_danio = (1.0 + 0.06 * nivel) * (1.0 + 0.15 * heroe.objetos["canones"])
	barco.factor_recarga = pow(0.88, heroe.objetos["polvora"])
	barco.vel_max = datos["velocidad"] * VEL_HEROE * (1.0 + 0.1 * heroe.objetos["velas"]) * (1.8 if heroe.impulso > 0.0 else 1.0) \
			* (1.3 if heroe.oculto > 0.0 else 1.0)
	barco.factor_defensa = 0.4 if heroe.escudo > 0.0 else 1.0


# Oleadas de botes

func _soltar_oleada() -> void:
	oleada += 1
	var fuerza := 1.0 + MEJORA_OLEADA * (oleada - 1)
	for equipo in 2:
		for carril in CARRILES:
			var puntos := camino(carril, equipo)
			var salida := _punto_en(puntos, RADIO_NEXO + 60.0)
			var hacia := (puntos[1] - puntos[0]).normalized()
			var extra := 0
			for torre in torres:
				if not torre.viva and torre.equipo != equipo and torre.carril == carril:
					extra += 1
			for k in BOTES_POR_OLEADA + extra:
				var bote := Bote.new()
				bote.equipo = equipo
				bote.carril = carril
				bote.pos = salida - hacia * k * 40.0 + hacia.orthogonal() * (k - 1) * 18.0
				bote.rumbo = _rumbo_hacia(bote.pos, bote.pos + hacia)
				bote.recarga = randf() * RECARGA_BOTE
				bote.vida_max = VIDA_BOTE * fuerza
				bote.vida = bote.vida_max
				bote.danio = DANIO_BOTE * fuerza
				_crear_bote(bote)
				add_child(bote.nodo)
				botes.append(bote)


# Balandra de guerra: casco de verdad con franja del color de la armada, un palo con su vela
# (se hincha con el viento y se balancea), un gallardete, un marinero a popa y un cañón
# giratorio en la proa.
func _crear_bote(bote: Bote) -> void:
	var equipo := bote.equipo
	bote.fase = randf() * TAU
	var nodo := Node3D.new()
	bote.nodo = nodo
	ModeloBarco._perfil = ModeloBarco.PERFILES["plano"]
	if not mallas_bote.has(equipo):
		mallas_bote[equipo] = ModeloBarco._casco(LARGO_BOTE, ANCHO_BOTE, ALTO_BOTE, Color("8a5a32"), COLORES[equipo].lightened(0.2), COLORES[equipo])
		mallas_bote["cubierta"] = ModeloBarco._cubierta(LARGO_BOTE, ANCHO_BOTE, ALTO_BOTE)
		mallas_bote["vela"] = ModeloBarco._vela(1.05, 0.85, 0.22)
	for malla in [mallas_bote[equipo], mallas_bote["cubierta"]]:
		var pieza := MeshInstance3D.new()
		pieza.mesh = malla
		pieza.material_override = ModeloBarco._material_vertices()
		nodo.add_child(pieza)
	var cubierta := ModeloBarco.altura_cubierta(0.5, ALTO_BOTE)
	var palo := Node3D.new()
	palo.position = Vector3(0, cubierta - 0.05, 0.1)
	nodo.add_child(palo)
	ModeloBarco._pieza(palo, ModeloBarco._cilindro(0.03, 0.045, 1.7), ModeloBarco.COLOR_MADERA, Vector3(0, 0.85, 0))
	bote.aparejo = Node3D.new()
	palo.add_child(bote.aparejo)
	var dibujo := Dibujos.textura({"color": Color("f3ecdf"), "color2": COLORES[equipo], "diseno": "franjas"}, 64, 64)
	ModeloBarco._tela(bote.aparejo, mallas_bote["vela"], dibujo, Vector3(0, 0.98, -0.06))
	ModeloBarco._pieza(bote.aparejo, ModeloBarco._cilindro(0.018, 0.018, 1.2), ModeloBarco.COLOR_MADERA, Vector3(0, 1.42, -0.04)).rotation.z = PI / 2.0
	ModeloBarco._pieza(bote.aparejo, ModeloBarco._cilindro(0.016, 0.016, 1.15), ModeloBarco.COLOR_MADERA, Vector3(0, 0.56, -0.04)).rotation.z = PI / 2.0
	var tope := Node3D.new()
	tope.position = Vector3(0, 1.55, 0)
	tope.scale = Vector3.ONE * 0.55
	palo.add_child(tope)
	ModeloBarco._izar_bandera(tope, 0.0, 0.6, COLORES[equipo], {"color": COLORES[equipo], "diseno": "lisa"})
	var marinero := crear_figura({"piel": "e8b892", "abrigo": COLORES[equipo].darkened(0.3).to_html(false), "sombrero": "2e2b2b",
		"pelo": "", "pluma": "", "barba": "", "parche": false, "saludo": "marinero"})
	bote.marinero = marinero
	marinero.scale = Vector3.ONE * 0.4
	marinero.position = Vector3(0, ModeloBarco.altura_cubierta(0.15, ALTO_BOTE) - 0.06, LARGO_BOTE * 0.33)
	marinero.rotation.y = PI
	nodo.add_child(marinero)
	bote.canon = Node3D.new()
	bote.canon.position = Vector3(0, ModeloBarco.altura_cubierta(0.8, ALTO_BOTE) - 0.03, -LARGO_BOTE * 0.3)
	nodo.add_child(bote.canon)
	ModeloBarco._pieza(bote.canon, ModeloBarco._cilindro(0.05, 0.07, 0.16), ModeloBarco.COLOR_MADERA, Vector3(0, 0.08, 0))
	ModeloBarco._canon(bote.canon, "clasico", Color("2b2e31"), Vector3(0, 0.2, -0.06), Vector3(0, 0, -1), 1.5)


func _mover_bote(bote: Bote, delta: float) -> void:
	bote.recarga -= delta
	bote.destello = maxf(0.0, bote.destello - delta * 3.0)
	var blanco := _blanco_bote(bote)
	bote.mira = Vector2.INF if blanco.is_empty() else blanco[0]
	var parado := false
	if not blanco.is_empty():
		var punto: Vector2 = blanco[0]
		var dist: float = bote.pos.distance_to(punto) - blanco[2]
		if dist <= ALCANCE_BOTE:
			parado = true
			bote.rumbo = lerp_angle(bote.rumbo, _rumbo_hacia(bote.pos, punto), minf(1.0, delta * 3.0))
			if bote.recarga <= 0.0:
				bote.recarga = RECARGA_BOTE
				var adelanto := randf_range(0.0, PUNTERIA_BOTE)
				var previsto: Vector2 = punto + blanco[1] * bote.pos.distance_to(punto) / Principal.VEL_BALA * adelanto
				var direccion := (previsto - bote.pos).normalized().rotated(randf_range(-DESVIO_BOTE, DESVIO_BOTE))
				var danio := bote.danio * (DANIO_BOTE_A_BARCO if blanco.size() > 3 else 1.0)
				mundo.disparar_desde(bote.pos + direccion * (RADIO_BOTE + 4.0), direccion, null, null, bote.equipo, danio)
				if bote.nodo.visible:
					bote.marinero.vitorear()
	var destino := Vector2.INF
	if not parado:
		if not blanco.is_empty():
			destino = blanco[0]
		else:
			var puntos := camino(bote.carril, bote.equipo)
			if bote.paso < puntos.size() and bote.pos.distance_to(puntos[bote.paso]) < 60.0:
				bote.paso = mini(bote.paso + 1, puntos.size() - 1)
			destino = puntos[bote.paso]
	# Sin derrapes: el casco gira hacia donde quiere ir (rodeando islas) y solo avanza por la
	# proa; si lleva un compañero justo delante, frena en vez de apartarse de lado.
	if destino != Vector2.INF:
		var deseo := (destino - bote.pos).normalized()
		for isla in mundo.islas.cerca(bote.pos, RADIO_BOTE + 50.0):
			var sep: Vector2 = bote.pos - isla.pos
			var limite: float = isla.radio + RADIO_BOTE + 50.0
			var d := sep.length()
			if d < limite and d > 0.0 and deseo.dot(-sep / d) > 0.0:
				deseo += sep / d * (1.0 - d / limite) * 2.0
		bote.rumbo = lerp_angle(bote.rumbo, atan2(deseo.x, -deseo.y), minf(1.0, delta * 2.0))
		var proa := Vector2.UP.rotated(bote.rumbo)
		var marcha := 1.0
		for otro in botes:
			if otro == bote or otro.equipo != bote.equipo:
				continue
			var hacia := otro.pos - bote.pos
			var d := hacia.length()
			if d < RADIO_BOTE * 2.6 and d > 0.0 and proa.dot(hacia / d) > 0.3:
				marcha = minf(marcha, clampf((d - RADIO_BOTE * 1.4) / (RADIO_BOTE * 1.2), 0.0, 1.0))
		bote.pos += proa * VEL_BOTE * marcha * delta
	for isla in mundo.islas.cerca(bote.pos, RADIO_BOTE):
		var sep: Vector2 = bote.pos - isla.pos
		var minimo: float = isla.borde(bote.pos) + RADIO_BOTE
		if sep.length() < minimo and sep != Vector2.ZERO:
			bote.pos = isla.pos + sep.normalized() * minimo


# [punto, velocidad, radio] del blanco más cercano: primero otros botes, luego torres y barcos
# (con un cuarto valor si es un barco).
func _blanco_bote(bote: Bote) -> Array:
	var vista := ALCANCE_BOTE + 60.0
	var mejor: Array = []
	var menor := vista
	for otro in botes:
		if otro.equipo != bote.equipo:
			var d := otro.pos.distance_to(bote.pos)
			if d < menor:
				menor = d
				mejor = [otro.pos, Vector2.UP.rotated(otro.rumbo) * VEL_BOTE, 0.0]
	if not mejor.is_empty():
		return mejor
	for torre in torres:
		if torre.viva and torre.equipo != bote.equipo and vulnerable(torre):
			var d := torre.pos.distance_to(bote.pos) - torre.isla.radio
			if d < menor:
				menor = d
				mejor = [torre.pos, Vector2.ZERO, torre.isla.radio]
	if not mejor.is_empty():
		return mejor
	for heroe in heroes:
		var barco := heroe.barco
		if barco.viva and heroe.equipo != bote.equipo and heroe.oculto <= 0.0:
			var d := barco.pos.distance_to(bote.pos)
			if d < menor:
				menor = d
				mejor = [barco.pos, barco.proa() * barco.velocidad, 0.0, true]
	return mejor


# Balas que alcanzan a un bote rival; devuelve true si la bala se detiene.
func recibir_bala(bala: Principal.Bala) -> bool:
	for i in range(botes.size() - 1, -1, -1):
		var bote := botes[i]
		if bote.equipo == bala.equipo or bote.pos.distance_to(bala.pos) > RADIO_BOTE + 4.0:
			continue
		bote.vida -= mundo._danio_bala(bala)
		bote.destello = 1.0
		mundo.salpicar(bala.pos, 4)
		if bote.vida <= 0.0:
			_hundir_bote(i, bala.dueno)
		return true
	return monstruos.recibir_bala(bala)


func _hundir_bote(i: int, verdugo: Barco) -> void:
	var bote := botes[i]
	mundo.salpicar(bote.pos, 12)
	mundo.astillas(mundo.a_3d(bote.pos, 0.4))
	bote.nodo.queue_free()
	botes.remove_at(i)
	for heroe in heroes:
		if heroe.equipo != bote.equipo and heroe.barco.viva and heroe.barco.pos.distance_to(bote.pos) < ALCANCE_XP:
			_ganar_xp(heroe, XP_BOTE)
	if verdugo != null and de_barco.has(verdugo):
		_ganar_oro(de_barco[verdugo], ORO_BOTE, mundo.a_3d(bote.pos, 1.5))


# Torres

func _defender(torre: Torre, delta: float) -> void:
	torre.recarga -= delta
	torre.pensar -= delta
	if torre.pensar <= 0.0:
		torre.pensar = 0.2
		var blanco := _blanco_torre(torre)
		torre.mira = Vector2.INF if blanco.is_empty() else blanco[0] + blanco[1] * torre.pos.distance_to(blanco[0]) / Principal.VEL_BALA
	if torre.mira == Vector2.INF:
		return
	# Cada cañón gira hacia el blanco; dispara el que esté más cerca y ya apunte bien.
	var mejor := -1
	var menor := INF
	for k in torre.canones.size():
		var desde := torre.pos + torre.sitios[k]
		var deseado := -_rumbo_hacia(desde, torre.mira)
		var soporte := torre.canones[k]
		soporte.rotation.y = lerp_angle(soporte.rotation.y, deseado, minf(1.0, delta * 4.0))
		var d := desde.distance_to(torre.mira)
		if absf(angle_difference(soporte.rotation.y, deseado)) < 0.25 and d < menor:
			menor = d
			mejor = k
	if torre.recarga > 0.0 or mejor < 0:
		return
	torre.recarga = RECARGA_NEXO if torre.orden == 2 else RECARGA_TORRE
	var boca := torre.pos + torre.sitios[mejor]
	var direccion := (torre.mira - boca).normalized()
	torre.canones[mejor].position -= Vector3(direccion.x, 0, direccion.y) * 0.12
	var soporte_disparo := torre.canones[mejor]
	var vuelta := soporte_disparo.position + Vector3(direccion.x, 0, direccion.y) * 0.12
	create_tween().tween_property(soporte_disparo, "position", vuelta, 0.35)
	mundo.disparar_desde(boca + direccion * 20.0, direccion, null, torre.isla, torre.equipo, DANIO_TORRE * (1.5 if torre.orden == 2 else 1.0))


# Como en los MOBA: la torre dispara a los botes, salvo que un barco rival ataque a uno aliado
# bajo su protección.
func _blanco_torre(torre: Torre) -> Array:
	var alcance := alcance_torre(torre)
	var ahora := Time.get_ticks_msec()
	for heroe in heroes:
		var aliado := heroe.barco
		if heroe.equipo != torre.equipo or not aliado.viva or aliado.pos.distance_to(torre.pos) > alcance:
			continue
		var agresor := aliado.ultimo_atacante
		if agresor != null and is_instance_valid(agresor) and agresor.viva and agresor.equipo != torre.equipo and not escondido(agresor) \
				and ahora - aliado.hora_ataque < 2000 and agresor.pos.distance_to(torre.pos) < alcance:
			return [agresor.pos, agresor.proa() * agresor.velocidad]
	var mejor: Array = []
	var menor := alcance
	for bote in botes:
		if bote.equipo != torre.equipo:
			var d := bote.pos.distance_to(torre.pos)
			if d < menor:
				menor = d
				mejor = [bote.pos, Vector2.UP.rotated(bote.rumbo) * VEL_BOTE]
	if not mejor.is_empty():
		return mejor
	var bestia := monstruos.aliado_rival_cerca(torre.pos, alcance, torre.equipo)
	if bestia != null:
		return [bestia.pos, Vector2.ZERO]
	for heroe in heroes:
		var barco := heroe.barco
		if barco.viva and heroe.equipo != torre.equipo and heroe.oculto <= 0.0:
			var d := barco.pos.distance_to(torre.pos)
			if d < menor:
				menor = d
				mejor = [barco.pos, barco.proa() * barco.velocidad]
	return mejor


func torre_de(isla: Circulo) -> Torre:
	for torre in torres:
		if torre.isla == isla:
			return torre
	return null


# Una bala choca con el islote de una torre rival.
func golpear_isla(isla: Circulo, bala: Principal.Bala) -> void:
	var torre := torre_de(isla)
	if torre == null or not torre.viva or bala.equipo < 0 or bala.equipo == torre.equipo or bala.equipo == MonstruosMarinos.EQUIPO:
		return
	if not vulnerable(torre):
		if bala.dueno == mundo.jugador and espera_protegida <= 0.0:
			espera_protegida = 4.0
			_anunciar(tr("Protegido: derriba antes el fuerte de delante") if torre.orden < 2 else tr("Protegido: derriba antes un fuerte interior"), Color(1, 1, 1, 0.9))
		return
	torre.vida -= mundo._danio_bala(bala)
	torre.destello = 1.0
	if torre.vida <= 0.0:
		_derribar(torre)


func _derribar(torre: Torre) -> void:
	torre.viva = false
	torre.vida = 0.0
	torre.estructura.visible = false
	torre.ruinas.visible = true
	var centro := mundo.a_3d(torre.pos, 2.0)
	for _i in 16:
		var vel := Vector3(randf_range(-2.0, 2.0), randf_range(1.0, 4.0), randf_range(-2.0, 2.0))
		mundo.crear_efecto(mundo.malla_humo, Color(0.4, 0.38, 0.36, 0.8), centro, vel, randf_range(2.0, 3.0), 1.2, 3.0, 0.0, true)
	mundo._sonar_en_vista(mundo.voces_explosion, centro, -6.0, -20.0, 60.0)
	var rival := 1 - torre.equipo
	for heroe in heroes:
		if heroe.equipo == rival:
			_ganar_oro(heroe, ORO_TORRE, mundo.a_3d(torre.pos, 4.0))
			_ganar_xp(heroe, XP_TORRE)
	if torre.orden == 2:
		ganador = rival
		_anunciar(tr("¡Nexo enemigo derribado!") if rival == 0 else tr("¡Han derribado tu nexo!"), Principal.COLOR_ORO if rival == 0 else Principal.COLOR_PELIGRO)
	elif rival == 0:
		_anunciar(tr("¡Fuerte enemigo derribado!"), Principal.COLOR_ORO)
	else:
		_anunciar(tr("¡Han derribado uno de tus fuertes!"), Principal.COLOR_PELIGRO)


# Barcos

func al_hundirse(barco: Barco, verdugo: Barco) -> void:
	var heroe: Heroe = de_barco.get(barco)
	if heroe == null:
		return
	heroe.hundido += 1
	heroe.reaparece = REPONER_DIANAS if ensayo else 6.0 + 2.0 * heroe.nivel
	heroe.impulso = 0.0
	heroe.escudo = 0.0
	heroe.oculto = 0.0
	_mostrar_casco(heroe, 0.0)
	_soltar(heroe)
	_soltar_arpon(heroe)
	_aplicar(heroe)
	var cazador: Heroe = de_barco.get(verdugo) if verdugo != null else null
	if cazador != null and cazador.equipo != heroe.equipo:
		cazador.hundidos += 1
		_ganar_oro(cazador, ORO_HEROE + 10 * heroe.nivel, barco.position + Vector3(0, 3.0, 0))
		_ganar_xp(cazador, XP_HEROE + 10 * heroe.nivel)
	for otro in heroes:
		if otro != cazador and otro.equipo != heroe.equipo and otro.barco.viva and otro.barco.pos.distance_to(barco.pos) < ALCANCE_XP:
			_ganar_xp(otro, (XP_HEROE + 10 * heroe.nivel) / 2)
	if barco == mundo.jugador:
		_anunciar(tr("Te hundieron. Vuelves en %d s") % ceili(heroe.reaparece), Principal.COLOR_PELIGRO)
	elif verdugo == mundo.jugador:
		_anunciar(tr("¡Hundiste a %s!") % barco.nombre, Principal.COLOR_ORO)


# El rival más cercano (para la música de combate).
func rival_de(barco: Barco) -> Barco:
	var mejor: Barco = null
	var menor := Principal.DISTANCIA_COMBATE
	for heroe in heroes:
		var otro := heroe.barco
		if otro.viva and otro.equipo != barco.equipo and otro.pos.distance_to(barco.pos) < menor:
			menor = otro.pos.distance_to(barco.pos)
			mejor = otro
	return mejor


func color_de(barco: Barco) -> Color:
	return COLORES[barco.equipo] if barco.equipo >= 0 else Principal.COLOR_PELIGRO


func tinta(barco: Barco) -> Color:
	return COLOR_NOMBRE_ALIADO if barco.equipo == 0 else Principal.COLOR_PELIGRO


# Inteligencia de los capitanes bot: se retiran a curarse, pelean con lo que tengan cerca y,
# si no, acompañan a sus botes por el carril sin meterse solos bajo una torre rival.
func pilotar(barco: Barco, delta: float) -> void:
	var heroe: Heroe = de_barco.get(barco)
	if heroe == null or ensayo:
		return
	var puntos := camino(heroe.carril, heroe.equipo)
	var avance := _progreso(puntos, barco.pos)
	if barco.vida < barco.vida_max * 0.3:
		heroe.retirada = true
	if heroe.retirada:
		if barco.vida >= barco.vida_max * 0.95:
			heroe.retirada = false
		else:
			if barco.es_bot and heroe.capitan["habilidad"] in ["impulso", "escudo", "reparar", "niebla", "minas"] and heroe.habilidad <= 0.0 and rival_de(barco) != null:
				usar_habilidad(heroe)
			_navegar(barco, BASES[heroe.equipo] if avance < 350.0 else _punto_en(puntos, avance - 300.0), delta)
			return
	heroe.pensar -= delta
	if heroe.pensar <= 0.0:
		heroe.pensar = 0.3
		heroe.blanco = _elegir_blanco(heroe)
	var datos := _datos_blanco(heroe.blanco, heroe.equipo)
	if not datos.is_empty():
		if barco.es_bot:
			_usar_habilidad_bot(heroe, datos)
		_combatir(barco, datos[0], datos[1], datos[2], delta)
		return
	_navegar(barco, _puesto_en_carril(heroe, puntos), delta)


func _elegir_blanco(heroe: Heroe):
	var barco := heroe.barco
	var mejor = null
	var menor_vida := INF
	for otro in heroes:
		var rival := otro.barco
		if otro.equipo == heroe.equipo or not rival.viva or otro.oculto > 0.0 or rival.pos.distance_to(barco.pos) > 380.0:
			continue
		if _bajo_torre(rival.pos, heroe.equipo) and rival.vida > rival.vida_max * 0.35:
			continue
		var proporcion := rival.vida / rival.vida_max
		if proporcion < menor_vida:
			menor_vida = proporcion
			mejor = rival
	if mejor != null:
		return mejor
	var menor := 340.0
	for bote in botes:
		if bote.equipo != heroe.equipo and bote.pos.distance_to(barco.pos) < menor and not (_bajo_torre(bote.pos, heroe.equipo) and not _botes_cerca(bote.pos, heroe.equipo)):
			menor = bote.pos.distance_to(barco.pos)
			mejor = bote
	if mejor != null:
		return mejor
	for torre in torres:
		if torre.viva and torre.equipo != heroe.equipo and vulnerable(torre) and torre.pos.distance_to(barco.pos) < 420.0 \
				and _botes_cerca(torre.pos, heroe.equipo):
			return torre
	return null


# [punto, velocidad, radio] del blanco si sigue siendo válido.
func _datos_blanco(blanco, equipo: int) -> Array:
	if blanco is Barco:
		if is_instance_valid(blanco) and blanco.viva and not escondido(blanco):
			return [blanco.pos, blanco.proa() * blanco.velocidad, 0.0]
	elif blanco is Bote:
		if botes.has(blanco):
			return [blanco.pos, Vector2.UP.rotated(blanco.rumbo) * VEL_BOTE, 0.0]
	elif blanco is Torre:
		if blanco.viva and vulnerable(blanco) and blanco.equipo != equipo:
			return [blanco.pos, Vector2.ZERO, blanco.isla.radio]
	return []


# Dentro del alcance de una torre (o el nexo) del rival de "equipo".
func _bajo_torre(punto: Vector2, equipo: int) -> bool:
	for torre in torres:
		if torre.viva and torre.equipo != equipo and punto.distance_to(torre.pos) < ALCANCE_TORRE + 40.0:
			return true
	return false


func _botes_cerca(punto: Vector2, equipo: int) -> bool:
	for bote in botes:
		if bote.equipo == equipo and bote.pos.distance_to(punto) < ALCANCE_TORRE:
			return true
	return false


# Detrás del bote propio más adelantado del carril; sin botes, junto a la torre propia más
# adelantada. Nunca entra solo en el alcance de la siguiente torre rival.
func _puesto_en_carril(heroe: Heroe, puntos: PackedVector2Array) -> Vector2:
	var largo := _largo(puntos)
	var frente := -1.0
	for bote in botes:
		if bote.equipo == heroe.equipo and bote.carril == heroe.carril:
			frente = maxf(frente, _progreso(puntos, bote.pos))
	var meta := frente - 70.0
	if frente < 0.0:
		meta = RADIO_NEXO + 250.0
		for torre in torres:
			if torre.viva and torre.equipo == heroe.equipo and torre.carril == heroe.carril:
				meta = maxf(meta, _progreso(puntos, torre.pos) + 120.0)
	var rival_cerca := largo
	for torre in torres:
		if torre.viva and torre.equipo != heroe.equipo and (torre.carril == heroe.carril or torre.orden == 2):
			var donde := _progreso(puntos, torre.pos)
			if donde < rival_cerca:
				rival_cerca = donde
				if not _botes_cerca(torre.pos, heroe.equipo):
					meta = minf(meta, donde - ALCANCE_TORRE - 70.0)
	return _punto_en(puntos, clampf(meta, 0.0, largo))


func _navegar(barco: Barco, destino: Vector2, delta: float) -> void:
	var hacia := destino - barco.pos
	var dist := hacia.length()
	if dist < 50.0:
		barco._girar_hacia(barco.rumbo, 0.0, delta)
		barco.acelerador = 0.0
		return
	var direccion := hacia / dist + _esquivar(barco)
	barco._girar_hacia(atan2(direccion.x, -direccion.y), 1.0, delta)
	barco.acelerador = 1.0 if dist > 140.0 else 0.5


func _combatir(barco: Barco, punto: Vector2, velocidad: Vector2, radio: float, delta: float) -> void:
	var dist := barco.pos.distance_to(punto) - radio
	var previsto := punto + velocidad * dist / Principal.VEL_BALA * 0.85
	var angulo := angle_difference(barco.rumbo, barco._angulo_hacia(previsto))
	var rumbo := barco._angulo_hacia(previsto)
	if dist < 130.0:
		rumbo = barco._angulo_hacia(barco.pos - (previsto - barco.pos))
	elif dist < 250.0:
		rumbo -= signf(angulo) * PI / 2.0
	if dist < 265.0:
		if absf(angulo) < 0.2:
			mundo.disparar(barco, "proa")
		if absf(angulo - PI / 2.0) < 0.3:
			mundo.disparar(barco, "estribor")
		if absf(angulo + PI / 2.0) < 0.3:
			mundo.disparar(barco, "babor")
	var direccion := Vector2.UP.rotated(rumbo) + _esquivar(barco)
	barco._girar_hacia(atan2(direccion.x, -direccion.y) + sin(barco.deriva) * 0.1, 1.0, delta)
	barco.acelerador = 1.0


# Empuje para rodear las islas que tiene delante.
func _esquivar(barco: Barco) -> Vector2:
	var empuje := Vector2.ZERO
	for isla in mundo.islotes:
		var sep: Vector2 = barco.pos - isla.pos
		var limite: float = isla.radio + barco.radio + 110.0
		var d := sep.length()
		if d < limite and d > 0.0 and barco.proa().dot(-sep / d) > -0.2:
			empuje += sep / d * (1.0 - d / limite) * 1.6
	return empuje


# Habilidades

# "hacia" es la dirección apuntada por el jugador; sin ella, los bots apuntan solos.
func usar_habilidad(heroe: Heroe, hacia := Vector2.ZERO, largo := 1.0) -> void:
	var barco := heroe.barco
	if not barco.viva or heroe.habilidad > 0.0:
		return
	var clave: String = heroe.capitan["habilidad"]
	heroe.habilidad = ESPERA_ENSAYO if ensayo else HABILIDADES[clave]["espera"]
	match clave:
		"impulso":
			heroe.impulso = DURACION_IMPULSO
			_aplicar(heroe)
			barco.velocidad = barco.vel_max
			for _i in 8:
				mundo.salpicar(barco.pos - barco.proa() * barco.radio, 3)
		"andanada":
			for k in BALAS_ANDANADA:
				var direccion := Vector2.from_angle(TAU * k / BALAS_ANDANADA)
				mundo.disparar_desde(barco.pos + direccion * barco.radio * 0.9, direccion, barco, null, barco.equipo, Principal.DANIO_BALA * 1.1 * barco.factor_danio)
		"escudo":
			heroe.escudo = DURACION_ESCUDO
			_aplicar(heroe)
			barco.vida = minf(barco.vida_max, barco.vida + barco.vida_max * 0.15)
			mundo.voz_equipar.play()
		"fuego":
			_lanzar(heroe, "bola_fuego", hacia, DANIO_BOLA_FUEGO, Color(1.0, 0.55, 0.15, 0.95))
		"cadenas":
			_lanzar(heroe, "cadenas", hacia, DANIO_CADENAS, Color(0.85, 0.85, 0.85, 0.8))
			mundo._sonar_en_vista(mundo.voces_canon, barco.position, -8.0, -24.0, 40.0)
		"reparar":
			barco.vida = minf(barco.vida_max, barco.vida + barco.vida_max * 0.3)
			mundo._brillo_reparacion(barco.position + Vector3(0, 0.6, 0))
			for otro in heroes:
				var aliado := otro.barco
				if otro != heroe and otro.equipo == heroe.equipo and aliado.viva and aliado.pos.distance_to(barco.pos) < ALCANCE_CURA:
					aliado.vida = minf(aliado.vida_max, aliado.vida + aliado.vida_max * 0.2)
					mundo._brillo_reparacion(aliado.position + Vector3(0, 0.6, 0))
			mundo.voz_equipar.play()
		"remolino":
			_abrir_zona(heroe, "remolino", _punto_objetivo(heroe, clave, hacia, largo, 0.0), DURACION_REMOLINO, _remolino())
		"kraken":
			_abrir_zona(heroe, "kraken", _punto_objetivo(heroe, clave, hacia, largo, RETARDO_KRAKEN), 2.2, _tentaculos())
		"minas":
			var popa := barco.pos - barco.proa() * (barco.radio + 26.0)
			for k in 3:
				var sitio := popa + barco.proa().orthogonal() * (k - 1) * 70.0 + barco.proa() * absf(k - 1) * 14.0
				_abrir_zona(heroe, "mina", sitio, DURACION_MINA, _barril_mina())
				mundo.salpicar(sitio, 3)
		"niebla":
			heroe.oculto = DURACION_NIEBLA
			_aplicar(heroe)
			_mostrar_casco(heroe, 0.6)
			for _i in 14:
				var nube := Vector3(randf_range(-1.5, 1.5), randf_range(0.2, 0.8), randf_range(-1.5, 1.5))
				mundo.crear_efecto(mundo.malla_humo, Color(0.85, 0.88, 0.92, 0.75), barco.position + Vector3(nube.x, 0.6, nube.z), nube * 0.6, randf_range(1.0, 1.6), 1.2, 3.0)
		"arpon":
			_lanzar(heroe, "arpon", hacia, DANIO_ARPON, Color(0.9, 0.95, 1.0, 0.8))
			mundo._sonar_en_vista(mundo.voces_canon, barco.position, -10.0, -26.0, 40.0)
		"rayos":
			_tormenta(heroe)


# Centro de un remolino o de los tentáculos: donde apuntó el jugador (a la distancia que
# arrastró) o, para los bots, donde estará el rival más cercano dentro del alcance.
func _punto_objetivo(heroe: Heroe, clave: String, hacia: Vector2, largo: float, adelanto: float) -> Vector2:
	var barco := heroe.barco
	var alcance: float = HABILIDADES[clave]["alcance"]
	if hacia != Vector2.ZERO:
		return barco.pos + hacia * alcance * clampf(largo, 0.3, 1.0)
	var mejor: Barco = null
	var menor := alcance + 60.0
	for rival in _rivales_cerca(heroe, menor):
		if rival.pos.distance_to(barco.pos) < menor:
			menor = rival.pos.distance_to(barco.pos)
			mejor = rival
	if mejor == null:
		return barco.pos + barco.proa() * alcance
	return mejor.pos + mejor.proa() * mejor.velocidad * adelanto


func escondido(barco: Barco) -> bool:
	var heroe: Heroe = de_barco.get(barco)
	return heroe != null and heroe.oculto > 0.0


# Con la niebla el propio barco se ve medio transparente; 0 lo deja normal.
func _mostrar_casco(heroe: Heroe, transparencia: float) -> void:
	if is_instance_valid(heroe.barco):
		_transparentar(heroe.barco, transparencia)


func _transparentar(nodo: Node, transparencia: float) -> void:
	for hijo in nodo.get_children():
		if hijo is GeometryInstance3D:
			hijo.transparency = transparencia
		_transparentar(hijo, transparencia)


func _abrir_zona(heroe: Heroe, tipo: String, punto: Vector2, dura: float, nodo: Node3D) -> void:
	var zona := Zona.new()
	zona.tipo = tipo
	zona.pos = punto
	zona.dura = dura
	zona.heroe = heroe
	zona.nodo = nodo
	nodo.position = mundo.a_3d(punto)
	add_child(nodo)
	zonas.append(zona)


func _actualizar_zonas(delta: float) -> void:
	for i in range(zonas.size() - 1, -1, -1):
		var zona := zonas[i]
		zona.edad += delta
		var sigue := true
		match zona.tipo:
			"remolino":
				_tragar(zona, delta)
			"kraken":
				sigue = _azotar(zona)
			"mina":
				sigue = _vigilar_mina(zona)
			"rayo":
				zona.nodo.visible = fmod(zona.edad, 0.1) < 0.07
		if not sigue or zona.edad >= zona.dura or ganador >= 0:
			zona.nodo.queue_free()
			zonas.remove_at(i)


# El remolino gira, crece al abrirse, mengua al cerrarse y arrastra hacia el centro.
func _tragar(zona: Zona, delta: float) -> void:
	var radio: float = HABILIDADES["remolino"]["area"]
	var abre := minf(1.0, zona.edad / 0.35) * minf(1.0, (zona.dura - zona.edad) / 0.4)
	zona.nodo.scale = Vector3(abre, 1.0, abre)
	zona.nodo.rotation.y -= delta * 2.6
	for k in zona.nodo.get_child_count():
		zona.nodo.get_child(k).rotation.y += delta * (1.2 + k * 0.6)
	var dueno := zona.heroe.barco
	for otro in heroes:
		var barco := otro.barco
		var d := barco.pos.distance_to(zona.pos)
		if otro.equipo == zona.heroe.equipo or not barco.viva or d > radio:
			continue
		barco.pos = barco.pos.move_toward(zona.pos, TIRON_REMOLINO * delta * (1.0 - d / radio * 0.5))
		barco.frenado = maxf(barco.frenado, 0.3)
		barco.recibir_danio(DANIO_REMOLINO * dueno.factor_danio * delta, false, dueno)
	for i in range(botes.size() - 1, -1, -1):
		var bote := botes[i]
		if bote.equipo != zona.heroe.equipo and bote.pos.distance_to(zona.pos) < radio:
			bote.pos = bote.pos.move_toward(zona.pos, TIRON_REMOLINO * delta)
			bote.vida -= DANIO_REMOLINO * 1.5 * delta
			bote.destello = 0.5
			if bote.vida <= 0.0:
				_hundir_bote(i, dueno)
	for monstruo in monstruos.vivos_cerca(zona.pos, radio, zona.heroe.equipo):
		monstruos.danar(monstruo, DANIO_REMOLINO * 1.5 * dueno.factor_danio * delta, dueno)
	if randf() < delta * 12.0:
		var a := randf() * TAU
		mundo.salpicar(zona.pos + Vector2.from_angle(a) * radio * randf_range(0.4, 0.9), 1)


# Burbujas mientras el kraken sube; al salir golpea una vez y los tentáculos se hunden.
func _azotar(zona: Zona) -> bool:
	var radio: float = HABILIDADES["kraken"]["area"]
	var subida := clampf((zona.edad - RETARDO_KRAKEN) / 0.25, 0.0, 1.0) * clampf((zona.dura - zona.edad) / 0.5, 0.0, 1.0)
	var brazos: Node3D = zona.nodo.get_node("Brazos")
	brazos.position.y = lerpf(-3.2, 0.0, subida)
	brazos.rotation.y += 0.02
	for k in brazos.get_child_count():
		brazos.get_child(k).rotation.x = sin(zona.edad * 5.0 + k) * 0.18
	zona.nodo.get_node("Aviso").visible = zona.edad < RETARDO_KRAKEN
	if zona.edad < RETARDO_KRAKEN:
		if randf() < 0.4:
			mundo.salpicar(zona.pos + Vector2.from_angle(randf() * TAU) * randf() * radio * 0.7, 1)
		return true
	if not zona.hecho:
		zona.hecho = true
		var dueno := zona.heroe.barco
		mundo.salpicar(zona.pos, 16)
		mundo._sonar_en_vista(mundo.voces_explosion, mundo.a_3d(zona.pos), -6.0, -22.0, 50.0)
		for otro in heroes:
			var barco := otro.barco
			if otro.equipo != zona.heroe.equipo and barco.viva and barco.pos.distance_to(zona.pos) < radio + barco.radio * 0.5:
				barco.recibir_danio(DANIO_KRAKEN * dueno.factor_danio, true, dueno)
				barco.frenado = maxf(barco.frenado, ATURDIR_KRAKEN)
				barco.velocidad = 0.0
				mundo.avisar_premio(barco.position + Vector3(0, barco.altura * 0.5, 0), tr("¡Aturdido!"), Color("c08ad8"))
		_danar_botes(zona.heroe, zona.pos, radio, DANIO_KRAKEN * 1.3, Vector2.ZERO)
	return true


# La mina se arma al momento de caer y estalla con el primer rival que la roce.
func _vigilar_mina(zona: Zona) -> bool:
	var t := mundo.tiempo + zona.pos.x
	zona.nodo.position.y = sin(t * 2.0) * 0.06
	zona.nodo.rotation = Vector3(sin(t * 1.4) * 0.12, zona.nodo.rotation.y, cos(t * 1.1) * 0.12)
	zona.nodo.get_node("Luz").visible = fmod(zona.edad, 0.8) < 0.4
	if zona.edad < 0.8:
		return true
	var toca := false
	for otro in heroes:
		if otro.equipo != zona.heroe.equipo and otro.barco.viva and otro.barco.pos.distance_to(zona.pos) < TOQUE_MINA + otro.barco.radio * 0.5:
			toca = true
	for bote in botes:
		if bote.equipo != zona.heroe.equipo and bote.pos.distance_to(zona.pos) < TOQUE_MINA:
			toca = true
	if not monstruos.vivos_cerca(zona.pos, TOQUE_MINA, zona.heroe.equipo).is_empty():
		toca = true
	if not toca:
		return true
	var dueno := zona.heroe.barco
	var centro := mundo.a_3d(zona.pos, 0.6)
	mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.9, 0.55, 0.95), centro, Vector3.ZERO, 0.25, 1.0, 6.0)
	mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.45, 0.1, 0.9), centro, Vector3(0, 1.0, 0), 0.6, 1.2, 4.0)
	for _i in 4:
		mundo.crear_efecto(mundo.malla_humo, Color(0.2, 0.18, 0.17, 0.7), centro + Vector3(0, 0.6, 0), Vector3(randf_range(-0.6, 0.6), randf_range(0.8, 1.6), randf_range(-0.6, 0.6)), 1.6, 0.9, 2.5, 0.0, true)
	mundo.astillas(centro)
	mundo.salpicar(zona.pos, 10)
	mundo.sonar_explosion(centro)
	for otro in heroes:
		if otro.equipo != zona.heroe.equipo and otro.barco.viva and otro.barco.pos.distance_to(zona.pos) < RADIO_MINA + otro.barco.radio * 0.5:
			otro.barco.recibir_danio(DANIO_MINA * dueno.factor_danio, true, dueno)
	_danar_botes(zona.heroe, zona.pos, RADIO_MINA, DANIO_MINA * 1.5, Vector2.ZERO)
	return false


# Hasta tres rayos sobre los rivales más cercanos (barcos primero, luego botes).
func _tormenta(heroe: Heroe) -> void:
	var barco := heroe.barco
	var blancos: Array = []
	var rivales := _rivales_cerca(heroe, ALCANCE_RAYOS)
	rivales.sort_custom(func(a: Barco, b: Barco) -> bool: return a.pos.distance_to(barco.pos) < b.pos.distance_to(barco.pos))
	for rival in rivales:
		if blancos.size() < RAYOS:
			blancos.append(rival)
	var cercanos := botes.filter(func(bote: Bote) -> bool: return bote.equipo != heroe.equipo and bote.pos.distance_to(barco.pos) < ALCANCE_RAYOS)
	cercanos.sort_custom(func(a: Bote, b: Bote) -> bool: return a.pos.distance_to(barco.pos) < b.pos.distance_to(barco.pos))
	for bote in cercanos:
		if blancos.size() < RAYOS:
			blancos.append(bote)
	var bestias := monstruos.vivos_cerca(barco.pos, ALCANCE_RAYOS, heroe.equipo)
	bestias.sort_custom(func(a: MonstruosMarinos.Monstruo, b: MonstruosMarinos.Monstruo) -> bool: return a.pos.distance_to(barco.pos) < b.pos.distance_to(barco.pos))
	for bestia in bestias:
		if blancos.size() < RAYOS:
			blancos.append(bestia)
	if blancos.is_empty():
		var a := barco.rumbo
		for k in RAYOS:
			blancos.append(barco.pos + Vector2.UP.rotated(a + (k - 1) * 0.6) * 180.0)
	for blanco in blancos:
		var punto: Vector2 = blanco if blanco is Vector2 else blanco.pos
		_abrir_zona(heroe, "rayo", punto, 0.35, _rayo())
		var centro := mundo.a_3d(punto, 0.8)
		mundo.crear_efecto(mundo.malla_humo, Color(0.85, 0.95, 1.0, 0.95), centro, Vector3.ZERO, 0.2, 1.0, 5.0)
		for _i in 6:
			mundo.crear_efecto(mundo.malla_humo, Color(0.6, 0.9, 1.0, 0.95), centro, Vector3(randf_range(-2.5, 2.5), randf_range(1.0, 3.0), randf_range(-2.5, 2.5)), 0.35, 0.22, 0.4, 4.0)
		if blanco is Barco:
			blanco.recibir_danio(DANIO_RAYO * barco.factor_danio, true, barco)
		elif blanco is Bote:
			var i := botes.find(blanco)
			blanco.vida -= DANIO_RAYO * 1.5
			blanco.destello = 1.0
			if blanco.vida <= 0.0 and i >= 0:
				_hundir_bote(i, barco)
		elif blanco is MonstruosMarinos.Monstruo:
			monstruos.danar(blanco, DANIO_RAYO * 1.5 * barco.factor_danio, barco)
	mundo._sonar_en_vista(mundo.voces_trueno, barco.position, -4.0, -20.0, 60.0)


func _rivales_cerca(heroe: Heroe, alcance: float) -> Array[Barco]:
	var lista: Array[Barco] = []
	for otro in heroes:
		if otro.equipo != heroe.equipo and otro.barco.viva and otro.oculto <= 0.0 and otro.barco.pos.distance_to(heroe.barco.pos) < alcance:
			lista.append(otro.barco)
	return lista


# Daña a los botes rivales en un radio; con "hacia" distinto de cero, solo a los de delante.
func _danar_botes(heroe: Heroe, centro: Vector2, alcance: float, cantidad: float, hacia: Vector2) -> void:
	if hacia == Vector2.ZERO:
		monstruos.danar_zona(centro, alcance, cantidad, heroe.barco)
	for i in range(botes.size() - 1, -1, -1):
		var bote := botes[i]
		if bote.equipo == heroe.equipo or bote.pos.distance_to(centro) > alcance:
			continue
		if hacia != Vector2.ZERO and hacia.dot((bote.pos - centro).normalized()) < 0.45:
			continue
		bote.vida -= cantidad
		bote.destello = 1.0
		if bote.vida <= 0.0:
			_hundir_bote(i, heroe.barco)


# Hacia el rival más cercano a tiro (el jugador, solo si lo tiene por delante), con el
# adelanto justo para alcanzarlo si sigue su rumbo; si no hay nadie, recto por la proa.
func _apuntar_lanzado(heroe: Heroe) -> Vector2:
	var barco := heroe.barco
	var proa := barco.proa()
	var cono := 0.5 if barco == mundo.jugador else -1.0
	var mejor: Barco = null
	var menor := ALCANCE_LANZADO
	for rival in _rivales_cerca(heroe, ALCANCE_LANZADO):
		var d := rival.pos.distance_to(barco.pos)
		if d < menor and proa.dot((rival.pos - barco.pos).normalized()) > cono:
			menor = d
			mejor = rival
	if mejor == null:
		return proa
	var previsto := mejor.pos + mejor.proa() * mejor.velocidad * menor / Principal.VEL_BALA
	return (previsto - barco.pos).normalized()


# Bola de fuego y cadenas viajan como balas del mundo (chocan con barcos, botes, torres e
# islas), pero con su propio dibujo; al acabar, el mundo llama a impacto().
func _lanzar(heroe: Heroe, tipo: String, hacia: Vector2, danio: float, chispa: Color) -> void:
	var barco := heroe.barco
	var direccion := hacia if hacia != Vector2.ZERO else _apuntar_lanzado(heroe)
	var salida := barco.pos + direccion * barco.radio * 1.15
	var bala := mundo.disparar_desde(salida, direccion, barco, null, barco.equipo, danio * barco.factor_danio)
	bala.tipo = tipo
	bala.nodo.mesh = null
	bala.nodo.material_override = null
	match tipo:
		"bola_fuego":
			bala.nodo.add_child(_bola_de_fuego())
		"cadenas":
			bala.nodo.add_child(_bala_de_cadenas())
		"arpon":
			var lanza := _lanza_arpon()
			lanza.rotation.y = atan2(-direccion.x, -direccion.y)
			bala.nodo.add_child(lanza)
			cuerdas[bala] = _cuerda()
	for _i in 6:
		var empuje := Vector3(direccion.x, 0.25, direccion.y) * randf_range(0.8, 2.0)
		mundo.crear_efecto(mundo.malla_humo, chispa, mundo.a_3d(salida, 1.2), empuje, randf_range(0.25, 0.45), 0.5, 2.2)


func impacto(bala: Principal.Bala, golpeado: Barco) -> void:
	var centro := mundo.a_3d(bala.pos, 0.9)
	match bala.tipo:
		"bola_fuego":
			mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.92, 0.6, 0.95), centro, Vector3.ZERO, 0.25, 1.0, 5.0)
			mundo.crear_efecto(mundo.malla_humo, Color(1.0, 0.45, 0.1, 0.9), centro, Vector3(0, 0.8, 0), 0.55, 1.0, 3.5)
			for _i in 12:
				var chispa := Vector3(randf_range(-2.5, 2.5), randf_range(1.5, 3.5), randf_range(-2.5, 2.5))
				mundo.crear_efecto(mundo.malla_humo, Color(1.0, randf_range(0.4, 0.75), 0.1, 0.95), centro, chispa, randf_range(0.4, 0.7), 0.25, 0.5, 4.0)
			for _i in 3:
				var humo := Vector3(randf_range(-0.4, 0.4), randf_range(0.8, 1.4), randf_range(-0.4, 0.4))
				mundo.crear_efecto(mundo.malla_humo, Color(0.2, 0.18, 0.17, 0.7), centro + Vector3(0, 0.5, 0), humo, 1.5, 0.8, 2.5, 0.0, true)
			mundo.sonar_explosion(centro)
			if golpeado != null and golpeado.viva:
				golpeado.quemadura = Comercio.DURACION_FUEGO
				golpeado.quemador = bala.dueno
				mundo.avisar_premio(golpeado.position + Vector3(0, golpeado.altura * 0.5, 0), tr("¡En llamas!"), Color("ff8a3d"))
		"cadenas":
			mundo.salpicar(bala.pos, 8)
			var heroe: Heroe = de_barco.get(golpeado) if golpeado != null else null
			if heroe != null and golpeado.viva:
				_atrapar(heroe, bala.dueno)
		"arpon":
			if cuerdas.has(bala):
				cuerdas[bala].queue_free()
				cuerdas.erase(bala)
			mundo.salpicar(bala.pos, 6)
			var heroe: Heroe = de_barco.get(golpeado) if golpeado != null else null
			if heroe != null and golpeado.viva and is_instance_valid(bala.dueno) and bala.dueno.viva:
				_soltar_arpon(heroe)
				heroe.arrastre = DURACION_ARPON
				heroe.arrastrador = bala.dueno
				heroe.cuerda = _cuerda()
				mundo.astillas(centro)
				mundo.avisar_premio(golpeado.position + Vector3(0, golpeado.altura * 0.5, 0), tr("¡Arponeado!"), Color("e8eef2"))


func _soltar_arpon(heroe: Heroe) -> void:
	heroe.arrastre = 0.0
	heroe.arrastrador = null
	if heroe.cuerda != null:
		heroe.cuerda.queue_free()
		heroe.cuerda = null


func _cuerda() -> MeshInstance3D:
	var cuerda := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = 0.035
	malla.bottom_radius = 0.035
	malla.height = 1.0
	malla.radial_segments = 6
	cuerda.mesh = malla
	cuerda.material_override = mundo.material(Color("a8875a"))
	cuerda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cuerda)
	return cuerda


# Estira una vara de alto 1 (cilindro) de "a" a "b".
func _tender_cuerda(vara: Node3D, a: Vector3, b: Vector3) -> void:
	if vara == null:
		return
	var largo := maxf(0.01, a.distance_to(b))
	vara.transform = Transform3D(Basis(Quaternion(Vector3.UP, (b - a) / largo)) * Basis.from_scale(Vector3(1, largo, 1)), (a + b) / 2.0)


# Las cadenas se enrollan alrededor del casco: lo frenan y lo van dañando hasta soltarse.
func _atrapar(heroe: Heroe, quien: Barco) -> void:
	var barco := heroe.barco
	heroe.atrapado = DURACION_ATRAPADO
	heroe.atrapador = quien
	if heroe.grilletes == null:
		heroe.grilletes = _cadena_casco()
		barco.add_child(heroe.grilletes)
	mundo.avisar_premio(barco.position + Vector3(0, barco.altura * 0.5, 0), tr("¡Atrapado!"), Color("cfd6dc"))
	for _i in 6:
		mundo.crear_efecto(mundo.malla_humo, Color(0.85, 0.87, 0.9, 0.9), barco.position + Vector3(0, 0.8, 0), Vector3(randf_range(-2, 2), randf_range(1, 2.5), randf_range(-2, 2)), 0.4, 0.2, 0.5, 4.0)


func _soltar(heroe: Heroe) -> void:
	heroe.atrapado = 0.0
	heroe.atrapador = null
	if heroe.grilletes != null:
		heroe.grilletes.queue_free()
		heroe.grilletes = null


# Giro de las balas encadenadas y llama viva de la bola de fuego mientras vuelan.
func _animar_lanzados(delta: float) -> void:
	for bala in mundo.balas:
		if bala.tipo == "cadenas":
			bala.nodo.rotation.y += delta * 16.0
		elif bala.tipo == "bola_fuego":
			bala.nodo.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.03) * 0.1)
		elif bala.tipo == "arpon" and cuerdas.has(bala) and is_instance_valid(bala.dueno):
			_tender_cuerda(cuerdas[bala], bala.dueno.position + Vector3(0, 0.9, 0), bala.nodo.global_position)


func _brillo(color: Color, energia: float, alfa := 1.0) -> StandardMaterial3D:
	var materia := StandardMaterial3D.new()
	materia.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materia.albedo_color = Color(color, alfa)
	materia.emission_enabled = true
	materia.emission = color
	materia.emission_energy_multiplier = energia
	if alfa < 1.0:
		materia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return materia


func _bola_de_fuego() -> Node3D:
	var bola := Node3D.new()
	var nucleo := MeshInstance3D.new()
	nucleo.mesh = SphereMesh.new()
	nucleo.mesh.radius = 0.3
	nucleo.mesh.height = 0.6
	nucleo.material_override = _brillo(Color("fff1b0"), 3.0)
	bola.add_child(nucleo)
	var halo := MeshInstance3D.new()
	halo.mesh = SphereMesh.new()
	halo.mesh.radius = 0.52
	halo.mesh.height = 1.04
	halo.material_override = _brillo(Color("ff7a1e"), 2.0, 0.55)
	bola.add_child(halo)
	var llamas := CPUParticles3D.new()
	llamas.local_coords = false
	llamas.amount = 56
	llamas.lifetime = 0.5
	var chispa := SphereMesh.new()
	chispa.radius = 0.2
	chispa.height = 0.4
	chispa.radial_segments = 8
	chispa.rings = 4
	var tinta := StandardMaterial3D.new()
	tinta.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tinta.vertex_color_use_as_albedo = true
	tinta.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	chispa.material = tinta
	llamas.mesh = chispa
	llamas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	llamas.emission_sphere_radius = 0.3
	llamas.direction = Vector3.UP
	llamas.spread = 180.0
	llamas.initial_velocity_min = 0.2
	llamas.initial_velocity_max = 0.7
	llamas.gravity = Vector3(0, 1.4, 0)
	llamas.scale_amount_min = 0.8
	llamas.scale_amount_max = 1.7
	var mengua := Curve.new()
	mengua.add_point(Vector2(0, 1))
	mengua.add_point(Vector2(1, 0.1))
	llamas.scale_amount_curve = mengua
	var fuego := Gradient.new()
	fuego.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	fuego.set_color(1, Color(0.35, 0.15, 0.1, 0.0))
	fuego.add_point(0.35, Color(1.0, 0.5, 0.12, 0.9))
	llamas.color_ramp = fuego
	bola.add_child(llamas)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ff8a30")
	luz.omni_range = 3.5
	luz.light_energy = 1.8
	bola.add_child(luz)
	return bola


# Dos balas de hierro unidas por una cadena, girando como una boleadora.
func _bala_de_cadenas() -> Node3D:
	var giro := Node3D.new()
	var hierro := mundo.material(Color("3a3d42"))
	var eslabon := mundo.material(Color("8d949c"))
	for lado: float in [-1.0, 1.0]:
		var bola := MeshInstance3D.new()
		bola.mesh = mundo.malla_bala
		bola.material_override = hierro
		bola.position.x = lado * 0.5
		giro.add_child(bola)
	for k in 7:
		var anillo := MeshInstance3D.new()
		var malla := TorusMesh.new()
		malla.inner_radius = 0.03
		malla.outer_radius = 0.06
		anillo.mesh = malla
		anillo.material_override = eslabon
		anillo.position.x = lerpf(-0.36, 0.36, k / 6.0)
		anillo.scale = Vector3(1.5, 1.0, 1.0)
		if k % 2 == 0:
			anillo.rotation.x = PI / 2.0
		giro.add_child(anillo)
	return giro


# Cadena alrededor del casco (el barco mira a -Z y mide LARGO_COMUN).
func _cadena_casco() -> Node3D:
	var cadena := Node3D.new()
	var eslabon := mundo.material(Color("9aa1a8"))
	var malla := TorusMesh.new()
	malla.inner_radius = 0.06
	malla.outer_radius = 0.12
	var semi := Vector2(0.95, LARGO_COMUN * 0.47)
	var total := 34
	for k in total:
		var a := TAU * k / total
		var anillo := MeshInstance3D.new()
		anillo.mesh = malla
		anillo.material_override = eslabon
		anillo.position = Vector3(cos(a) * semi.x, 0.62 + sin(a * 3.0) * 0.08, sin(a) * semi.y)
		var tangente := Vector2(-sin(a) * semi.x, cos(a) * semi.y)
		anillo.rotation.y = -atan2(tangente.y, tangente.x)
		anillo.scale = Vector3(1.6, 1.0, 1.0)
		if k % 2 == 0:
			anillo.rotation.x = PI / 2.0
		cadena.add_child(anillo)
	for lado: float in [-1.0, 1.0]:
		var bola := MeshInstance3D.new()
		bola.mesh = mundo.malla_bala
		bola.material_override = mundo.material(Color("3a3d42"))
		bola.scale = Vector3.ONE * 1.6
		bola.position = Vector3(lado * semi.x * 1.02, 0.35, lado * semi.y * 0.3)
		cadena.add_child(bola)
	return cadena


# Arpón de ballenero mirando a -Z: asta de madera, punta de hierro con lengüetas y la anilla.
func _lanza_arpon() -> Node3D:
	var lanza := Node3D.new()
	var madera := mundo.material(Color("7a5532"))
	var hierro := mundo.material(Color("c9ced6"))
	var asta := _pieza(lanza, cilindro, madera, Vector3(0, 0, 0.25), Vector3(0.07, 1.5, 0.07))
	asta.rotation.x = PI / 2.0
	var punta := MeshInstance3D.new()
	punta.mesh = CylinderMesh.new()
	punta.mesh.top_radius = 0.0
	punta.mesh.bottom_radius = 0.13
	punta.mesh.height = 0.4
	punta.material_override = hierro
	punta.position.z = -0.68
	punta.rotation.x = -PI / 2.0
	lanza.add_child(punta)
	for lado: float in [-1.0, 1.0]:
		var lengueta := _pieza(lanza, caja, hierro, Vector3(lado * 0.1, 0, -0.45), Vector3(0.04, 0.04, 0.26))
		lengueta.rotation.y = lado * 0.5
	var anilla := MeshInstance3D.new()
	anilla.mesh = toro
	anilla.material_override = hierro
	anilla.scale = Vector3.ONE * 0.12
	anilla.position.z = 1.0
	anilla.rotation.x = PI / 2.0
	lanza.add_child(anilla)
	return lanza


# Remolino de espuma: un pozo oscuro y cuatro brazos en espiral que giran a distinto ritmo.
func _remolino() -> Node3D:
	var nodo := Node3D.new()
	var radio: float = HABILIDADES["remolino"]["area"] * Principal.ESCALA
	var pozo := MeshInstance3D.new()
	pozo.mesh = CylinderMesh.new()
	pozo.mesh.top_radius = radio * 0.45
	pozo.mesh.bottom_radius = radio * 0.45
	pozo.mesh.height = 0.02
	pozo.material_override = _brillo(Color("07243a"), 0.3, 0.75)
	pozo.position.y = 0.18
	nodo.add_child(pozo)
	var espuma := _brillo(Color("dff4ff"), 0.9, 0.8)
	var agua := _brillo(Color("4fb3d9"), 0.6, 0.55)
	for k in 4:
		var brazo := Node3D.new()
		brazo.rotation.y = TAU * k / 4.0
		nodo.add_child(brazo)
		for j in 16:
			var parte := j / 15.0
			var a := parte * 4.2
			var r := lerpf(radio * 0.18, radio, parte)
			var trozo := _pieza(brazo, caja, espuma if j % 2 == 0 else agua, Vector3(cos(a) * r, 0.22 + parte * 0.04, sin(a) * r), Vector3(0.18 + parte * 0.25, 0.05, 0.55 + parte * 0.5))
			trozo.rotation.y = -a
	for hijo in nodo.find_children("*", "GeometryInstance3D", true, false):
		hijo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return nodo


# Aviso en el agua y cinco tentáculos de kraken que salen enroscándose hacia dentro.
func _tentaculos() -> Node3D:
	var nodo := Node3D.new()
	var radio: float = HABILIDADES["kraken"]["area"] * Principal.ESCALA
	var aviso := MeshInstance3D.new()
	aviso.name = "Aviso"
	aviso.mesh = TorusMesh.new()
	aviso.mesh.inner_radius = radio * 0.92
	aviso.mesh.outer_radius = radio
	aviso.material_override = _brillo(Color("b45fd0"), 1.2, 0.6)
	aviso.position.y = 0.2
	aviso.scale = Vector3(1, 0.05, 1)
	nodo.add_child(aviso)
	var brazos := Node3D.new()
	brazos.name = "Brazos"
	brazos.position.y = -3.2
	nodo.add_child(brazos)
	var piel := mundo.material(Color("7a3f6b"))
	var ventosa := mundo.material(Color("e6a8c8"))
	for k in 5:
		var tentaculo := Node3D.new()
		var a := TAU * k / 5.0
		tentaculo.position = Vector3(cos(a), 0, sin(a)) * radio * 0.6
		tentaculo.rotation.y = -a - PI / 2.0
		brazos.add_child(tentaculo)
		for j in 9:
			var parte := j / 8.0
			var grueso := lerpf(0.5, 0.12, parte)
			var sitio := Vector3(0, parte * 3.4, -sin(parte * 2.6) * 1.3)
			_pieza(tentaculo, esfera, piel, sitio, Vector3.ONE * grueso * 2.0)
			if j % 2 == 1:
				_pieza(tentaculo, esfera, ventosa, sitio + Vector3(0, 0, grueso * 0.8), Vector3.ONE * grueso * 0.6)
	return nodo


# Barril de pólvora flotando con aros de hierro y una mecha que parpadea en rojo.
func _barril_mina() -> Node3D:
	var nodo := Node3D.new()
	var madera := mundo.material(Color("6b4423"))
	var hierro := mundo.material(Color("3a3d42"))
	_pieza(nodo, cilindro, madera, Vector3(0, 0.15, 0), Vector3(0.7, 0.75, 0.7))
	for alto: float in [-0.12, 0.42]:
		_pieza(nodo, cilindro, hierro, Vector3(0, alto, 0), Vector3(0.74, 0.06, 0.74))
	_pieza(nodo, cilindro, mundo.material(Color("d9cfb8")), Vector3(0, 0.6, 0), Vector3(0.04, 0.16, 0.04))
	var luz := _pieza(nodo, esfera, _brillo(Color("ff3a2a"), 3.0), Vector3(0, 0.7, 0), Vector3.ONE * 0.12)
	luz.name = "Luz"
	return nodo


# Rayo en zigzag del cielo al agua, con un halo y un fogonazo de luz.
func _rayo() -> Node3D:
	var nodo := Node3D.new()
	var nucleo := _brillo(Color("f4fbff"), 4.0)
	var halo := _brillo(Color("6fd8ff"), 2.5, 0.45)
	var puntos: Array[Vector3] = []
	for k in 9:
		var alto := 16.0 * (1.0 - k / 8.0)
		var desvio := Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8)) if 0 < k and k < 8 else Vector3.ZERO
		puntos.append(Vector3(0, alto, 0) + desvio)
	for k in 8:
		var vara := MeshInstance3D.new()
		vara.mesh = cilindro
		vara.material_override = nucleo
		nodo.add_child(vara)
		_tender_cuerda(vara, puntos[k], puntos[k + 1])
		vara.scale = Vector3(0.12, vara.scale.y, 0.12)
		var brillo := MeshInstance3D.new()
		brillo.mesh = cilindro
		brillo.material_override = halo
		nodo.add_child(brillo)
		_tender_cuerda(brillo, puntos[k], puntos[k + 1])
		brillo.scale = Vector3(0.45, brillo.scale.y, 0.45)
	var luz := OmniLight3D.new()
	luz.light_color = Color("9fe4ff")
	luz.light_energy = 4.0
	luz.omni_range = 8.0
	luz.position.y = 1.5
	nodo.add_child(luz)
	for hijo in nodo.find_children("*", "GeometryInstance3D", true, false):
		hijo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return nodo


func _usar_habilidad_bot(heroe: Heroe, datos: Array) -> void:
	var barco := heroe.barco
	if heroe.habilidad > 0.0:
		return
	var dist := barco.pos.distance_to(datos[0])
	match heroe.capitan["habilidad"]:
		"impulso":
			if heroe.blanco is Barco and dist > 260.0:
				usar_habilidad(heroe)
		"andanada":
			var cerca := _rivales_cerca(heroe, 200.0).size() * 2
			for bote in botes:
				if bote.equipo != heroe.equipo and bote.pos.distance_to(barco.pos) < 200.0:
					cerca += 1
			if cerca >= 3:
				usar_habilidad(heroe)
		"fuego", "cadenas", "arpon":
			if heroe.blanco is Barco and dist < ALCANCE_LANZADO * 0.9:
				usar_habilidad(heroe)
		"remolino", "kraken":
			if heroe.blanco is Barco and dist < HABILIDADES[heroe.capitan["habilidad"]]["alcance"]:
				usar_habilidad(heroe)
		"minas":
			if heroe.blanco is Barco and dist < 220.0 or heroe.blanco is Bote and dist < 120.0:
				usar_habilidad(heroe)
		"rayos":
			if heroe.blanco is Barco and dist < ALCANCE_RAYOS * 0.9 or _rivales_cerca(heroe, ALCANCE_RAYOS).size() >= 2:
				usar_habilidad(heroe)
		"reparar":
			var herido := barco.vida < barco.vida_max * 0.55
			for otro in heroes:
				if otro.equipo == heroe.equipo and otro.barco.viva and otro.barco.vida < otro.barco.vida_max * 0.45 \
						and otro.barco.pos.distance_to(barco.pos) < ALCANCE_CURA:
					herido = true
			if herido:
				usar_habilidad(heroe)
		_:
			if barco.vida < barco.vida_max * 0.6 and dist < 300.0:
				usar_habilidad(heroe)


func _comprar_bot(heroe: Heroe) -> void:
	var opciones: Array[String] = []
	for clave in OBJETOS:
		if heroe.objetos[clave] < MAX_OBJETO and heroe.oro >= OBJETOS[clave]["precio"]:
			opciones.append(clave)
	if not opciones.is_empty():
		comprar(heroe, opciones.pick_random())


func comprar(heroe: Heroe, clave: String) -> void:
	var precio: int = OBJETOS[clave]["precio"]
	if heroe.oro < precio or heroe.objetos[clave] >= MAX_OBJETO:
		return
	heroe.oro -= precio
	heroe.objetos[clave] += 1
	_aplicar(heroe)
	if heroe.barco == mundo.jugador:
		mundo.voz_monedas.play()
		_llenar_tienda()


func heroe_jugador() -> Heroe:
	return de_barco.get(mundo.jugador)


func torres_en_pie(equipo: int) -> int:
	return torres.filter(func(torre: Torre) -> bool: return torre.viva and torre.equipo == equipo and torre.orden < 2).size()


func texto_estado() -> String:
	var heroe := heroe_jugador()
	if heroe == null:
		return ""
	var texto := tr("Nivel %d") % heroe.nivel
	if heroe.nivel < NIVEL_MAX:
		texto += " (%d%%)" % roundi(100.0 * heroe.xp / experiencia_para(heroe.nivel))
	return texto + "  ·  " + tr("Oro: %d") % int(heroe.oro)


func texto_aviso() -> String:
	var heroe := heroe_jugador()
	if heroe != null and not heroe.barco.viva:
		return ""
	if ensayo:
		if apuntable():
			return tr("Ensayo: toca la habilidad para tirar recto o mantenla para apuntar")
		return tr("Ensayo: usa tu habilidad con el botón o la tecla R")
	return tr("Fuertes: %d contra %d") % [torres_en_pie(0), torres_en_pie(1)]


func marcador() -> Vector2i:
	var heroe := heroe_jugador()
	if heroe == null:
		return Vector2i(-1, -1)
	return Vector2i(heroe.hundidos, heroe.hundido)


func _anunciar(texto: String, color: Color) -> void:
	anuncio = texto
	anuncio_color = color
	anuncio_vida = DURACION_ANUNCIO


# Teclado: Espacio apunta los cañones con el ratón (al soltar, disparan), R usa la habilidad,
# T activa el piloto automático y B abre la tienda en la base.
func tecla(evento: InputEvent) -> bool:
	var pulsada := evento as InputEventKey
	if pulsada == null or pulsada.echo:
		return false
	if pulsada.keycode == KEY_SPACE:
		if pulsada.pressed and boton_canones.visible and dedo_canon == -1 and not tecla_canon:
			tecla_canon = true
			tiempo_canon = 0.0
			apunte_canon = Vector2.ZERO
		elif not pulsada.pressed and tecla_canon:
			tecla_canon = false
			_disparar_canones()
		return true
	if pulsada.keycode == KEY_T:
		if pulsada.pressed and boton_canones.visible and not ensayo:
			cambiar_auto()
		return true
	if pulsada.keycode == KEY_R and apuntable():
		if pulsada.pressed and _lista_para_apuntar():
			_empezar_apunte()
			tecla_apunte = true
		elif not pulsada.pressed and tecla_apunte:
			if sobre_cancelar(mundo.get_viewport().get_mouse_position()):
				cancelar_apunte()
			else:
				tecla_apunte = false
				_soltar_apunte()
		return true
	if not pulsada.pressed:
		return false
	match pulsada.keycode:
		KEY_R:
			if boton_habilidad.visible:
				_usar_jugador()
		KEY_B:
			if boton_tienda.visible:
				abrir_tienda()
		_:
			return false
	return true


# Interfaz

func crear_interfaz(capa: CanvasLayer) -> void:
	var comercio := mundo.comercio
	boton_habilidad = comercio._boton_redondo(Comercio.BOTON_MUNICION, _dibujar_habilidad, _usar_jugador)
	capa.add_child(boton_habilidad)
	boton_canones = comercio._boton_redondo(BOTON_CANONES, _dibujar_canones, func() -> void: pass)
	var lado := (RADIO_CANONES + 8.0) * 2.0
	Ui.anclar(boton_canones, Vector2(1, 1), BOTON_CANONES - Vector2.ONE * lado / 2.0, Vector2.ONE * lado)
	capa.add_child(boton_canones)
	boton_tienda = comercio.boton_lugar(func() -> void:
		comercio.dibujar_boton_lugar(boton_tienda, Objetos.icono_mejora("canones"), tr("Tienda")), abrir_tienda)
	capa.add_child(boton_tienda)
	boton_terminar = Ui.boton(tr("Terminar ensayo"), false)
	Ui.estilo_volver(boton_terminar)
	boton_terminar.add_theme_font_size_override("font_size", 24)
	Ui.anclar(boton_terminar, Vector2(0.5, 0.0), Vector2(-140, 18), Vector2(280, 64))
	boton_terminar.visible = false
	boton_terminar.pressed.connect(terminar_ensayo)
	capa.add_child(boton_terminar)

	panel_tienda = PanelContainer.new()
	var estilo := Ui.estilo_panel()
	estilo.set_content_margin_all(22)
	estilo.bg_color.a = 0.97
	panel_tienda.add_theme_stylebox_override("panel", estilo)
	Ui.anclar(panel_tienda, Vector2(0.5, 0.5), Vector2(-430, -290), Vector2(860, 580))
	panel_tienda.visible = false
	capa.add_child(panel_tienda)
	var cuerpo := VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 14)
	panel_tienda.add_child(cuerpo)
	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	cuerpo.add_child(cabecera)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(columna)
	columna.add_child(Ui.etiqueta_panel(tr("Tienda de la base"), 30, Comercio.COLOR_MERCADO))
	columna.add_child(Ui.etiqueta_panel(tr("Gasta el oro de la batalla en mejoras para tu barco"), 17, Color("c9d1d3")))
	cabecera.add_child(Ui.icono_moneda(30))
	texto_oro_tienda = Ui.etiqueta_panel("", 28, Principal.COLOR_ORO)
	texto_oro_tienda.autowrap_mode = TextServer.AUTOWRAP_OFF
	cabecera.add_child(texto_oro_tienda)
	var cerrar_boton := Ui.boton(tr("Cerrar"), false)
	Ui.estilo_volver(cerrar_boton)
	cerrar_boton.custom_minimum_size = Vector2(150, 70)
	cerrar_boton.add_theme_font_size_override("font_size", 24)
	cerrar_boton.pressed.connect(cerrar_tienda)
	cabecera.add_child(cerrar_boton)
	lista_tienda = VBoxContainer.new()
	lista_tienda.add_theme_constant_override("separation", 16)
	cuerpo.add_child(lista_tienda)
	_crear_seleccion(capa)


# Elección de capitán: panel a la derecha y, en el muelle, su barco con él en cubierta.

func _crear_seleccion(capa: CanvasLayer) -> void:
	var partes := Ui.panel_lateral(capa)
	panel_capitanes = partes[0]
	panel_capitanes.visible = false
	var cuerpo: VBoxContainer = partes[1]
	cuerpo.add_theme_constant_override("separation", 6)
	cuerpo.add_child(Ui.etiqueta_panel(tr("Elige tu capitán"), 34, Principal.COLOR_ORO))
	cuerpo.add_child(Ui.etiqueta_panel(tr("Cada capitán navega su propio barco y tiene una habilidad única"), 17, Color("c9d1d3")))
	var rejilla := GridContainer.new()
	rejilla.columns = 6
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	cuerpo.add_child(rejilla)
	for capitan in CAPITANES:
		var boton := Button.new()
		boton.focus_mode = Control.FOCUS_NONE
		boton.custom_minimum_size = Vector2(0, 84)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.draw.connect(_dibujar_tarjeta.bind(boton, capitan))
		boton.pressed.connect(elegir.bind(capitan["id"]))
		rejilla.add_child(boton)
		botones_capitan[capitan["id"]] = boton

	texto_capitan = Ui.etiqueta_panel("", 20, Principal.COLOR_TEXTO)
	cuerpo.add_child(texto_capitan)
	var detalle := HBoxContainer.new()
	detalle.add_theme_constant_override("separation", 14)
	cuerpo.add_child(detalle)
	icono_detalle = Control.new()
	icono_detalle.custom_minimum_size = Vector2(64, 64)
	icono_detalle.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	icono_detalle.draw.connect(func() -> void:
		var c := icono_detalle.size / 2.0
		icono_detalle.draw_circle(c, 31.0, Principal.COLOR_ORO)
		icono_detalle.draw_circle(c, 28.0, Color("16384a"))
		dibujar_icono(icono_detalle, c, capitan_elegido()["habilidad"], 1.0))
	detalle.add_child(icono_detalle)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 2)
	detalle.add_child(columna)
	texto_habilidad = Ui.etiqueta_panel("", 22, Principal.COLOR_ORO)
	columna.add_child(texto_habilidad)
	texto_detalle = Ui.etiqueta_panel("", 16, Principal.COLOR_TEXTO)
	columna.add_child(texto_detalle)
	for nombre in ["Vida", "Velocidad"]:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		var etiqueta := Ui.etiqueta_panel(tr(nombre), 16, Color("c9d1d3"))
		etiqueta.custom_minimum_size = Vector2(100, 0)
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
		fila.add_child(etiqueta)
		var barra := Ui.barra_progreso()
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(barra)
		barras_capitan[nombre] = barra
		cuerpo.add_child(fila)
	var ensayar := Ui.boton(tr("Ensayar habilidad"), false)
	ensayar.custom_minimum_size = Vector2(0, 50)
	ensayar.add_theme_font_size_override("font_size", 22)
	ensayar.pressed.connect(empezar_ensayo)
	cuerpo.add_child(ensayar)

	var espacio := Control.new()
	espacio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(espacio)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	cuerpo.add_child(botones)
	var volver := Ui.boton(tr("Volver"), false)
	Ui.estilo_volver(volver)
	volver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volver.pressed.connect(mundo._mostrar.bind(Principal.Estado.MENU))
	botones.add_child(volver)
	var zarpar := Ui.boton(tr("¡Zarpar!"), true)
	zarpar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zarpar.pressed.connect(mundo._buscar_partida.bind("moba"))
	botones.add_child(zarpar)


func abrir_seleccion() -> void:
	mundo._mostrar(Principal.Estado.CAPITANES)
	mundo.angulo_puerto = GIRO_SELECCION
	mundo.distancia_vitrina = 10.0
	mundo.altura_vitrina = 3.0
	mundo.pausa_giro = Principal.PAUSA_GIRO_MANUAL
	elegir(elegido, false)


# Mientras se elige, el capitán espera de pie en el muelle mirando a la cámara.
func _poner_en_muelle(capitan: Dictionary) -> void:
	quitar_del_muelle()
	figura_muelle = crear_figura(capitan["figura"])
	figura_muelle.position = Vector3(Muelle.PUNTA + 0.55, Muelle.ALTO, Muelle.LADO + 0.05)
	figura_muelle.rotation.y = GIRO_SELECCION + PI
	figura_muelle.scale = Vector3.ONE * ALTURA_CAPITAN
	mundo.islas.muelle.add_child(figura_muelle)


func quitar_del_muelle() -> void:
	if figura_muelle != null:
		figura_muelle.queue_free()
		figura_muelle = null


func elegir(id: String, con_sonido := true) -> void:
	elegido = id
	var capitan := capitan_elegido()
	var jugador := mundo.jugador
	if jugador != null:
		jugador.vestir(aspecto_de(capitan))
		igualar_barco(jugador, capitan)
		for hijo in jugador.modelo.get_children():
			if hijo is FiguraCapitan:
				hijo.visible = false
		_poner_en_muelle(capitan)
	if con_sonido:
		mundo.voz_equipar.play()
	for clave in botones_capitan:
		var boton: Button = botones_capitan[clave]
		Ui.estilo_boton(boton, clave == id)
		boton.queue_redraw()
	var habilidad: Dictionary = HABILIDADES[capitan["habilidad"]]
	texto_capitan.text = tr(capitan["nombre"]) + "  ·  " + tr(capitan["barco"])
	texto_habilidad.text = tr(habilidad["nombre"])
	texto_detalle.text = tr(habilidad["info"]) + "\n" + tr(capitan["info"])
	barras_capitan["Vida"].set_meta("avance", capitan["vida"] / 140.0)
	barras_capitan["Velocidad"].set_meta("avance", capitan["velocidad"] / 50.0)
	for barra in barras_capitan.values():
		barra.queue_redraw()
	icono_detalle.queue_redraw()


# Al volver al menú el barco del muelle vuelve a ser el del jugador.
func restaurar_puerto() -> void:
	var jugador := mundo.jugador
	if jugador != null and jugador.has_meta("capitan"):
		jugador.remove_meta("capitan")
		jugador.vestir(mundo.personalizacion)


func _dibujar_tarjeta(boton: Button, capitan: Dictionary) -> void:
	dibujar_retrato(boton, Vector2(boton.size.x / 2.0, 34.0), 27.0, capitan["figura"])
	var fuente := ThemeDB.fallback_font
	var claro: bool = capitan["id"] == elegido
	boton.draw_string(fuente, Vector2(2, boton.size.y - 7), tr(capitan["corto"]), HORIZONTAL_ALIGNMENT_CENTER, boton.size.x - 4, 13, Color("2a1a0c") if claro else Principal.COLOR_TEXTO)


# Retrato del capitán en un medallón dorado: hombros con abrigo y charreteras, cara con ojos,
# cejas y boca, pelo o melena, barba, parche y sombrero de tres picos con hebilla y pluma.
static func dibujar_retrato(lienzo: CanvasItem, c: Vector2, r: float, datos: Dictionary) -> void:
	var oro := Color("d9b46a")
	var tinta := Color("1b1410")
	var piel := Color(datos["piel"])
	var abrigo := Color(datos["abrigo"])
	var sombra := piel.darkened(0.14)
	var melena: bool = datos.get("melena", false)
	var trazo := maxf(1.2, r * 0.06)
	var dentro := r - 1.5
	lienzo.draw_circle(c, r + 2.5, Color("08161c"))
	lienzo.draw_circle(c, r + 1.0, oro)
	lienzo.draw_circle(c, dentro, Color("1d4656"))
	lienzo.draw_circle(c + Vector2(0, -r * 0.2), r * 0.7, Color("2b6479"))
	var pelo := Color(datos["pelo"]) if datos["pelo"] != "" else Color.TRANSPARENT
	if melena and datos["pelo"] != "":
		lienzo.draw_colored_polygon(_recortar(c, dentro, _elipse(c + Vector2(0, r * 0.28), r * 0.47, r * 0.6)), pelo)

	lienzo.draw_colored_polygon(_recortar(c, dentro, _elipse(c + Vector2(0, r * 1.08), r * 0.82, r * 0.58)), abrigo)
	lienzo.draw_colored_polygon(_recortar(c, dentro, PackedVector2Array([c + Vector2(-r * 0.2, r * 0.5), c + Vector2(r * 0.2, r * 0.5), c + Vector2(0, r * 0.97)])), Color("f2ead8"))
	for lado: float in [-1.0, 1.0]:
		lienzo.draw_line(c + Vector2(lado * r * 0.2, r * 0.5), c + Vector2(lado * r * 0.02, r * 0.95), abrigo.darkened(0.35), trazo, true)
		lienzo.draw_colored_polygon(_recortar(c, dentro, _elipse(c + Vector2(lado * r * 0.56, r * 0.64), r * 0.2, r * 0.08, lado * 0.45)), oro)
	lienzo.draw_rect(Rect2(c + Vector2(-r * 0.12, r * 0.26), Vector2(r * 0.24, r * 0.26)), sombra)

	for lado: float in [-1.0, 1.0]:
		lienzo.draw_circle(c + Vector2(lado * r * 0.33, r * 0.03), r * 0.08, sombra)
	lienzo.draw_colored_polygon(_elipse(c, r * 0.33, r * 0.38), piel)
	if datos["pelo"] != "":
		for lado: float in [-1.0, 1.0]:
			if melena:
				lienzo.draw_colored_polygon(_elipse(c + Vector2(lado * r * 0.3, r * 0.04), r * 0.1, r * 0.27), pelo)
			else:
				lienzo.draw_colored_polygon(_elipse(c + Vector2(lado * r * 0.3, -r * 0.12), r * 0.06, r * 0.13), pelo)
	if melena:
		for lado: float in [-1.0, 1.0]:
			lienzo.draw_circle(c + Vector2(lado * r * 0.19, r * 0.12), r * 0.065, Color(0.95, 0.5, 0.45, 0.45))

	var feroz: bool = datos["parche"] or datos["barba"] != ""
	if datos["barba"] != "":
		var barba := Color(datos["barba"])
		lienzo.draw_colored_polygon(_elipse(c + Vector2(0, r * 0.14), r * 0.33, r * 0.33, 0.0, 0.0, PI), barba)
		for lado: float in [-1.0, 1.0]:
			lienzo.draw_colored_polygon(_elipse(c + Vector2(lado * r * 0.09, r * 0.13), r * 0.11, r * 0.045, lado * -0.25), barba.darkened(0.1))
		lienzo.draw_line(c + Vector2(-r * 0.06, r * 0.22), c + Vector2(r * 0.06, r * 0.22), tinta, trazo, true)
	else:
		lienzo.draw_arc(c + Vector2(0, r * 0.08), r * 0.12, PI * 0.2, PI * 0.8, 8, Color("8a3a2a"), trazo, true)

	var ceja: Color = (Color(datos["barba"]) if datos["barba"] != "" else pelo if datos["pelo"] != "" else tinta).darkened(0.2)
	for lado: float in [-1.0, 1.0]:
		var dentro_ceja := Vector2(lado * r * 0.05, -r * (0.09 if feroz else 0.13))
		lienzo.draw_line(c + dentro_ceja, c + Vector2(lado * r * 0.21, -r * 0.15), ceja, trazo * 1.2, true)
		if datos["parche"] and lado > 0.0:
			continue
		lienzo.draw_colored_polygon(_elipse(c + Vector2(lado * r * 0.13, -r * 0.02), r * 0.07, r * 0.055), Color("f6f2ea"))
		lienzo.draw_circle(c + Vector2(lado * r * 0.13, -r * 0.015), r * 0.037, tinta)
		lienzo.draw_circle(c + Vector2(lado * r * 0.12, -r * 0.03), r * 0.013, Color.WHITE)
	if datos["parche"]:
		lienzo.draw_line(c + Vector2(-r * 0.33, -r * 0.2), c + Vector2(r * 0.33, r * 0.04), tinta, trazo, true)
		lienzo.draw_colored_polygon(_elipse(c + Vector2(r * 0.13, -r * 0.02), r * 0.095, r * 0.08), tinta)
	lienzo.draw_colored_polygon(_elipse(c + Vector2(0, r * 0.06), r * 0.045, r * 0.06), sombra)

	var tela := Color(datos["sombrero"])
	lienzo.draw_colored_polygon(_elipse(c + Vector2(0, -r * 0.5), r * 0.34, r * 0.27), tela.darkened(0.2))
	var ala := PackedVector2Array()
	for punto: Vector2 in [Vector2(-0.82, -0.22), Vector2(-0.5, -0.36), Vector2(0, -0.31), Vector2(0.5, -0.36), Vector2(0.82, -0.22),
			Vector2(0.62, -0.52), Vector2(0.3, -0.6), Vector2(0, -0.5), Vector2(-0.3, -0.6), Vector2(-0.62, -0.52)]:
		ala.append(c + punto * r)
	lienzo.draw_colored_polygon(_recortar(c, dentro, ala), tela)
	var ribete := PackedVector2Array()
	for k in range(4, 10):
		ribete.append(ala[k])
	ribete.append(ala[0])
	lienzo.draw_polyline(_recortar(c, dentro, ribete), oro, trazo, true)
	lienzo.draw_polyline(PackedVector2Array([ala[0], ala[1], ala[2], ala[3], ala[4]]), tela.darkened(0.45), trazo * 0.8, true)
	lienzo.draw_circle(c + Vector2(0, -r * 0.42), r * 0.07, oro)
	lienzo.draw_circle(c + Vector2(0, -r * 0.42), r * 0.035, tela)
	if datos["pluma"] != "":
		var pluma := Color(datos["pluma"])
		lienzo.draw_colored_polygon(_recortar(c, dentro, _elipse(c + Vector2(r * 0.42, -r * 0.62), r * 0.3, r * 0.085, -0.65)), pluma)
		lienzo.draw_line(c + Vector2(r * 0.22, -r * 0.46), c + Vector2(r * 0.6, -r * 0.78), pluma.darkened(0.3), maxf(1.0, trazo * 0.6), true)


static func _elipse(centro: Vector2, rx: float, ry: float, giro := 0.0, desde := 0.0, hasta := TAU) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	var abierta := hasta - desde < TAU - 0.001
	var pasos := 24
	for k in pasos + (1 if abierta else 0):
		var a := desde + (hasta - desde) * k / float(pasos)
		puntos.append(centro + Vector2(cos(a) * rx, sin(a) * ry).rotated(giro))
	return puntos


# Mete en el círculo los puntos que se salen, sin dejar puntos repetidos.
static func _recortar(c: Vector2, radio: float, puntos: PackedVector2Array) -> PackedVector2Array:
	var dentro := PackedVector2Array()
	for punto in puntos:
		var p: Vector2 = punto
		if p.distance_to(c) > radio:
			p = c + (p - c).normalized() * radio
		if dentro.is_empty() or dentro[-1].distance_to(p) > 0.4:
			dentro.append(p)
	if dentro.size() > 2 and dentro[0].distance_to(dentro[-1]) <= 0.4:
		dentro.remove_at(dentro.size() - 1)
	return dentro


func abrir_tienda() -> void:
	panel_tienda.visible = true
	mundo.voz_equipar.play()
	_llenar_tienda()


func cerrar_tienda() -> void:
	if panel_tienda != null:
		panel_tienda.visible = false


func ocultar() -> void:
	cerrar_tienda()
	cancelar_apunte()
	if boton_habilidad != null:
		boton_habilidad.visible = false
		boton_tienda.visible = false
		boton_terminar.visible = false


func _llenar_tienda() -> void:
	var heroe := heroe_jugador()
	if heroe == null or not panel_tienda.visible:
		return
	texto_oro_tienda.text = str(int(heroe.oro))
	for hijo in lista_tienda.get_children():
		hijo.queue_free()
	for clave in OBJETOS:
		var datos: Dictionary = OBJETOS[clave]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 14)
		lista_tienda.add_child(fila)
		var icono := TextureRect.new()
		icono.texture = Objetos.icono_mejora(datos["icono"])
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.custom_minimum_size = Vector2(58, 58)
		fila.add_child(icono)
		var columna := VBoxContainer.new()
		columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columna.add_theme_constant_override("separation", 0)
		fila.add_child(columna)
		columna.add_child(Ui.etiqueta_panel(tr(datos["nombre"]), 22, Principal.COLOR_TEXTO))
		columna.add_child(Ui.etiqueta_panel(tr(datos["detalle"]), 15, Color("c9d1d3")))
		columna.add_child(Ui.etiqueta_panel(tr("Tienes: %d de %d") % [heroe.objetos[clave], MAX_OBJETO], 16, Principal.COLOR_ORO))
		var lleno: bool = heroe.objetos[clave] >= MAX_OBJETO
		var boton := Ui.boton(tr("Completo") if lleno else tr("Comprar: %d") % datos["precio"], true)
		boton.custom_minimum_size = Vector2(210, 60)
		boton.add_theme_font_size_override("font_size", 22)
		boton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		boton.pressed.connect(comprar.bind(heroe, clave))
		fila.add_child(boton)
		botones_tienda[clave] = boton
		_habilitar_compra(heroe, clave)


# El oro sigue entrando con la tienda abierta: el botón se enciende en cuanto alcanza.
func _habilitar_compra(heroe: Heroe, clave: String) -> void:
	var boton: Button = botones_tienda.get(clave)
	if boton == null or not is_instance_valid(boton):
		return
	var bloqueado: bool = heroe.objetos[clave] >= MAX_OBJETO or heroe.oro < OBJETOS[clave]["precio"]
	if boton.disabled == bloqueado and boton.has_meta("estilo"):
		return
	boton.disabled = bloqueado
	boton.set_meta("estilo", true)
	Ui.estilo_boton(boton, not bloqueado)


func _usar_jugador() -> void:
	var heroe := heroe_jugador()
	if heroe != null and not apuntable():
		usar_habilidad(heroe)


func apuntable() -> bool:
	var heroe := heroe_jugador()
	return heroe != null and HABILIDADES[heroe.capitan["habilidad"]].get("apuntar", false)


func _lista_para_apuntar() -> bool:
	var heroe := heroe_jugador()
	return boton_habilidad.visible and heroe != null and heroe.habilidad <= 0.0 and dedo_apunte == -1 and not tecla_apunte


func _empezar_apunte() -> void:
	apunte = Vector2.ZERO
	apunte_largo = 1.0
	tiempo_apunte = 0.0


# Dedo sobre el botón de una habilidad apuntable: arrastrarlo fija la dirección en el mar.
func toque_habilidad(evento: InputEvent) -> bool:
	var toque := evento as InputEventScreenTouch
	if toque:
		if toque.pressed:
			if apuntable() and _lista_para_apuntar() and boton_habilidad.get_global_rect().grow(10.0).has_point(toque.position):
				_empezar_apunte()
				dedo_apunte = toque.index
				centro_apunte = boton_habilidad.get_global_rect().get_center()
				dedo_sitio = toque.position
				return true
		elif toque.index == dedo_apunte:
			if sobre_cancelar(toque.position):
				cancelar_apunte()
			else:
				dedo_apunte = -1
				_soltar_apunte()
			return true
		return false
	var arrastre := evento as InputEventScreenDrag
	if arrastre and arrastre.index == dedo_apunte:
		dedo_sitio = arrastre.position
		if sobre_cancelar(dedo_sitio):
			return true
		var tiron := arrastre.position - centro_apunte
		if tiron.length() > ZONA_APUNTE:
			apunte = _direccion_en_mar(tiron)
			apunte_largo = clampf(tiron.length() / 140.0, 0.3, 1.0)
		return true
	return false


func _seguir_apunte(delta: float) -> void:
	if dedo_apunte == -1 and not tecla_apunte:
		return
	var heroe := heroe_jugador()
	if heroe == null or not heroe.barco.viva or mundo.panel_partida.visible:
		cancelar_apunte()
		return
	tiempo_apunte += delta
	if tecla_apunte and tiempo_apunte >= ESPERA_APUNTE:
		var hacia := _suelo(mundo.get_viewport().get_mouse_position()) - heroe.barco.pos
		if hacia.length() > 1.0:
			apunte = hacia.normalized()
			apunte_largo = clampf(hacia.length() / _alcance_apunte(heroe), 0.3, 1.0)


func _soltar_apunte() -> void:
	var heroe := heroe_jugador()
	if heroe != null and heroe.barco.viva:
		usar_habilidad(heroe, apunte if apunte != Vector2.ZERO else heroe.barco.proa(), apunte_largo)
	_empezar_apunte()


func cancelar_apunte() -> void:
	dedo_apunte = -1
	tecla_apunte = false
	_empezar_apunte()


func mostrando_apunte() -> bool:
	return (dedo_apunte != -1 or tecla_apunte) and (tiempo_apunte >= ESPERA_APUNTE or apunte != Vector2.ZERO)


# Botón pequeño encima del de la habilidad: soltar el dedo (o la tecla con el ratón) ahí
# anula el tiro.
func _boton_cancelar() -> Array:
	var rect := boton_habilidad.get_global_rect()
	var radio := rect.size.x * 0.3
	return [rect.get_center() - Vector2(0.0, rect.size.y / 2.0 + radio + 18.0), radio]


func sobre_cancelar(sitio: Vector2) -> bool:
	if not mostrando_apunte():
		return false
	var boton := _boton_cancelar()
	return sitio.distance_to(boton[0]) <= boton[1] + 12.0


func _dibujar_cancelar(lienzo: Control) -> void:
	var boton := _boton_cancelar()
	var c: Vector2 = boton[0]
	var r: float = boton[1]
	var sitio := dedo_sitio if dedo_apunte != -1 else mundo.get_viewport().get_mouse_position()
	var encima := sobre_cancelar(sitio)
	lienzo.draw_circle(c, r, Principal.COLOR_PELIGRO if encima else Color(0.05, 0.16, 0.2, 0.9))
	lienzo.draw_arc(c, r, 0.0, TAU, 32, Color.WHITE if encima else Color(Principal.COLOR_PELIGRO, 0.9), 2.5, true)
	var brazo := r * 0.38
	var trazo := Color.WHITE if encima else Color("fff3dc")
	lienzo.draw_line(c + Vector2(-brazo, -brazo), c + Vector2(brazo, brazo), trazo, 4.0, true)
	lienzo.draw_line(c + Vector2(brazo, -brazo), c + Vector2(-brazo, brazo), trazo, 4.0, true)
	var texto := tr("Cancelar")
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var base := c + Vector2(-ancho / 2.0, r + 15.0)
	lienzo.draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.8))
	lienzo.draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, trazo)


# Cañones: el dedo sobre el botón y arrastrado apunta; al soltarlo dispara el cañón que mira
# hacia ahí. Un toque sin arrastrar apunta solo al enemigo más cercano.
func toque_canones(evento: InputEvent) -> bool:
	var toque := evento as InputEventScreenTouch
	if toque:
		if toque.pressed:
			if boton_canones.visible and dedo_canon == -1 and not tecla_canon \
					and boton_canones.get_global_rect().grow(10.0).has_point(toque.position):
				dedo_canon = toque.index
				centro_canon = boton_canones.get_global_rect().get_center()
				apunte_canon = Vector2.ZERO
				return true
		elif toque.index == dedo_canon:
			dedo_canon = -1
			_disparar_canones()
			return true
		return false
	var arrastre := evento as InputEventScreenDrag
	if arrastre and arrastre.index == dedo_canon:
		var tiron := arrastre.position - centro_canon
		apunte_canon = _direccion_en_mar(tiron) if tiron.length() > ZONA_APUNTE else Vector2.ZERO
		return true
	return false


func _seguir_canones(delta: float) -> void:
	if dedo_canon == -1 and not tecla_canon:
		return
	var heroe := heroe_jugador()
	if heroe == null or not heroe.barco.viva or mundo.panel_partida.visible:
		dedo_canon = -1
		tecla_canon = false
		apunte_canon = Vector2.ZERO
		return
	tiempo_canon += delta
	if tecla_canon and tiempo_canon >= ESPERA_APUNTE:
		var hacia := _suelo(mundo.get_viewport().get_mouse_position()) - heroe.barco.pos
		if hacia.length() > 1.0:
			apunte_canon = hacia.normalized()


func _disparar_canones() -> void:
	var heroe := heroe_jugador()
	var hacia := apunte_canon
	apunte_canon = Vector2.ZERO
	if heroe == null or not heroe.barco.viva:
		return
	var barco := heroe.barco
	if hacia == Vector2.ZERO:
		hacia = _apuntar_solo(heroe)
	var arma := canon_hacia(barco, hacia)
	mundo.disparar(barco, arma, _direccion_canon(barco, arma, hacia))


# "proa" si el tiro queda a menos de 45° de la proa; si no, el costado de ese lado.
func canon_hacia(barco: Barco, hacia: Vector2) -> String:
	var angulo := angle_difference(barco.rumbo, atan2(hacia.x, -hacia.y))
	if absf(angulo) <= ANGULO_PROA:
		return "proa"
	return "estribor" if angulo > 0.0 else "babor"


# Las andanadas salen como mucho 45° desviadas de la perpendicular de su costado.
func _direccion_canon(barco: Barco, arma: String, hacia: Vector2) -> Vector2:
	if arma == "proa":
		return hacia
	var costado := barco.rumbo + (PI / 2.0 if arma == "estribor" else -PI / 2.0)
	var desvio := clampf(angle_difference(costado, atan2(hacia.x, -hacia.y)), -ANGULO_PROA, ANGULO_PROA)
	return Vector2.UP.rotated(costado + desvio)


# Hacia el capitán rival más cercano a tiro (con adelanto); si no hay, un bote, un monstruo
# o un fuerte atacable; sin nada cerca, al frente.
func _apuntar_solo(heroe: Heroe) -> Vector2:
	var barco := heroe.barco
	var alcance := ALCANCE_CANON + 30.0
	var mejor := Vector2.INF
	var menor := alcance
	for otro in heroes:
		var rival := otro.barco
		if otro.equipo == heroe.equipo or not rival.viva or escondido(rival):
			continue
		var d := rival.pos.distance_to(barco.pos)
		if d < menor:
			menor = d
			mejor = rival.pos + rival.proa() * rival.velocidad * d / Principal.VEL_BALA * 0.85
	if mejor == Vector2.INF:
		for bote in botes:
			var d := bote.pos.distance_to(barco.pos)
			if bote.equipo != heroe.equipo and d < menor:
				menor = d
				mejor = bote.pos
	if mejor == Vector2.INF:
		for monstruo in monstruos.vivos_cerca(barco.pos, alcance, heroe.equipo):
			var d := monstruo.pos.distance_to(barco.pos)
			if d < menor:
				menor = d
				mejor = monstruo.pos
	if mejor == Vector2.INF:
		for torre in torres:
			var d := torre.pos.distance_to(barco.pos) - torre.isla.radio
			if torre.viva and torre.equipo != heroe.equipo and vulnerable(torre) and d < menor:
				menor = d
				mejor = torre.pos
	if mejor == Vector2.INF or mejor.distance_to(barco.pos) < 1.0:
		return barco.proa()
	return (mejor - barco.pos).normalized()


func apuntando_canones() -> bool:
	return (dedo_canon != -1 and apunte_canon != Vector2.ZERO) or (tecla_canon and tiempo_canon >= ESPERA_APUNTE)


# Línea de tiro sobre el agua con el nombre del cañón que disparará.
func _dibujar_apunte_canon(lienzo: Control, camara: Camera3D) -> void:
	var barco := mundo.jugador
	var hacia := apunte_canon if apunte_canon != Vector2.ZERO else barco.proa()
	var arma := canon_hacia(barco, hacia)
	var direccion := _direccion_canon(barco, arma, hacia)
	var listo: bool = barco.recargas[arma] <= 0.0
	var puntos := PackedVector2Array()
	for k in 13:
		var sitio := mundo.a_3d(barco.pos + direccion * lerpf(barco.radio, ALCANCE_CANON, k / 12.0), 0.3)
		if camara.is_position_behind(sitio):
			return
		puntos.append(camara.unproject_position(sitio))
	var color := Principal.COLOR_ORO if listo else Color(0.6, 0.6, 0.6)
	lienzo.draw_polyline(puntos, Color(color, 0.25), 22.0, true)
	lienzo.draw_polyline(puntos, Color(color, 0.9), 3.0, true)
	var fin := puntos[-1]
	lienzo.draw_arc(fin, 18.0, 0.0, TAU, 32, Color(color, 0.8), 2.5, true)
	var texto: String = tr({"proa": "Frente", "babor": "Izq.", "estribor": "Der."}[arma])
	if not listo:
		texto += " · %.1f s" % barco.recargas[arma]
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var base := fin + Vector2(-ancho / 2.0, -26.0)
	lienzo.draw_string_outline(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color(0, 0, 0, 0.8))
	lienzo.draw_string(fuente, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)


# Botón de cañones: una bala en el centro y tres marcas (frente, izquierda y derecha) que se
# llenan según la recarga de cada cañón.
func _dibujar_canones() -> void:
	var barco := mundo.jugador
	if barco == null:
		return
	var c := boton_canones.size / 2.0
	var r := RADIO_CANONES
	var pulsado := dedo_canon != -1 or tecla_canon
	if pulsado:
		c.y += 2.0
	boton_canones.draw_circle(c + Vector2(0, 4), r + 3.0, Color(0, 0, 0, 0.3))
	boton_canones.draw_circle(c, r + 3.0, Principal.COLOR_ORO)
	boton_canones.draw_circle(c, r, Color("16384a"))
	boton_canones.draw_circle(c + Vector2(0, -r * 0.28), r * 0.68, Color(1, 1, 1, 0.07))
	boton_canones.draw_circle(c + Vector2(0, -4), 11.0, Color("1d2024"))
	boton_canones.draw_circle(c + Vector2(-3, -7), 3.5, Color(1, 1, 1, 0.35))
	for arma: String in ["proa", "babor", "estribor"]:
		var giro: float = {"proa": 0.0, "babor": -PI / 2.0, "estribor": PI / 2.0}[arma]
		var carga: float = 1.0 - barco.recargas[arma] / (Principal.RECARGAS[arma] * barco.factor_recarga)
		var centro := -PI / 2.0 + giro
		var abierto := 0.5
		boton_canones.draw_arc(c, r - 6.0, centro - abierto, centro + abierto, 12, Color(0, 0, 0, 0.45), 6.0, true)
		boton_canones.draw_arc(c, r - 6.0, centro - abierto, centro - abierto + abierto * 2.0 * clampf(carga, 0.0, 1.0), 12,
				Principal.COLOR_ORO if carga >= 1.0 else Color(Principal.COLOR_ORO, 0.5), 6.0, true)
	var texto := tr("Cañones")
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	boton_canones.draw_string_outline(fuente, c + Vector2(-ancho / 2.0, 22), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.8))
	boton_canones.draw_string(fuente, c + Vector2(-ancho / 2.0, 22), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff3dc"))


func cambiar_auto() -> void:
	auto = not auto
	if not auto and mundo.jugador != null:
		mundo.jugador.acelerador = 0.0
	_anunciar(tr("Piloto automático") if auto else tr("Piloto manual"), COLOR_NOMBRE_ALIADO)


# Botón pequeño «Auto» arriba a la derecha de la palanca de mover el barco.
func _boton_auto() -> Array:
	var escala := mundo.escala_controles
	return [mundo._posicion_palanca_reposo() + Vector2(98.0, -78.0) * escala, RADIO_AUTO * escala]


func toque_auto(evento: InputEvent) -> bool:
	if not boton_canones.visible or ensayo:
		return false
	var toque := evento as InputEventScreenTouch
	if toque == null:
		return false
	var boton := _boton_auto()
	if toque.pressed and dedo_auto == -1 and toque.position.distance_to(boton[0]) <= boton[1] + 8.0:
		dedo_auto = toque.index
		return true
	if not toque.pressed and toque.index == dedo_auto:
		dedo_auto = -1
		if toque.position.distance_to(boton[0]) <= boton[1] + 14.0:
			cambiar_auto()
		return true
	return false


func _dibujar_auto(lienzo: Control) -> void:
	var boton := _boton_auto()
	var c: Vector2 = boton[0]
	var r: float = boton[1]
	var latido := 0.5 + 0.5 * sin(mundo.tiempo * 4.0)
	if auto:
		lienzo.draw_circle(c, r + 4.0 + 3.0 * latido, Color(Color("7dffb2"), 0.25))
	lienzo.draw_circle(c + Vector2(0, 2), r + 2.0, Color(0, 0, 0, 0.3))
	lienzo.draw_circle(c, r, Color("1f6b4a") if auto else Color(0.05, 0.16, 0.22, 0.85))
	lienzo.draw_arc(c, r, 0.0, TAU, 32, Color("7dffb2") if auto else Color(Principal.COLOR_ORO, 0.8), 2.0, true)
	var texto := "AUTO"
	var tam := int(round(11.0 * mundo.escala_controles))
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	lienzo.draw_string(fuente, c + Vector2(-ancho / 2.0, tam * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color.WHITE if auto else Color("fff3dc"))


# Punto del mar bajo un punto de la pantalla.
func _suelo(pantalla: Vector2) -> Vector2:
	var origen := mundo.camara.project_ray_origin(pantalla)
	var rayo := mundo.camara.project_ray_normal(pantalla)
	if absf(rayo.y) < 0.001:
		return mundo.jugador.pos
	var punto := origen - rayo * origen.y / rayo.y
	return Vector2(punto.x, punto.z) / Principal.ESCALA


# Un tirón del dedo en pantalla, pasado a una dirección sobre el mar desde el barco.
func _direccion_en_mar(tiron: Vector2) -> Vector2:
	var desde := mundo.camara.unproject_position(mundo.jugador.position)
	var hacia := _suelo(desde + tiron.normalized() * 120.0) - _suelo(desde)
	return hacia.normalized() if hacia.length() > 0.01 else mundo.jugador.proa()


func _alcance_apunte(heroe: Heroe) -> float:
	return HABILIDADES[heroe.capitan["habilidad"]].get("alcance", ALCANCE_LANZADO)


# Franja sobre el agua con la trayectoria del tiro mientras se apunta; con remolino o
# tentáculos, el círculo que abarcarán donde caigan.
func _dibujar_apunte(lienzo: Control, camara: Camera3D) -> void:
	var barco := mundo.jugador
	var heroe := heroe_jugador()
	var hacia := apunte if apunte != Vector2.ZERO else barco.proa()
	var datos: Dictionary = HABILIDADES[heroe.capitan["habilidad"]]
	var alcance := _alcance_apunte(heroe) * (apunte_largo if datos.has("area") else 1.0)
	var puntos := PackedVector2Array()
	for k in 13:
		var sitio := mundo.a_3d(barco.pos + hacia * lerpf(barco.radio, alcance, k / 12.0), 0.3)
		if camara.is_position_behind(sitio):
			return
		puntos.append(camara.unproject_position(sitio))
	if datos.has("area"):
		var centro := barco.pos + hacia * alcance
		var borde := PackedVector2Array()
		for k in 33:
			var sitio := mundo.a_3d(centro + Vector2.from_angle(TAU * k / 32.0) * datos["area"], 0.3)
			if camara.is_position_behind(sitio):
				return
			borde.append(camara.unproject_position(sitio))
		lienzo.draw_polyline(puntos, Color(0.75, 0.55, 1.0, 0.7), 3.0, true)
		lienzo.draw_colored_polygon(borde, Color(0.6, 0.35, 0.9, 0.22))
		lienzo.draw_polyline(borde, Color(0.85, 0.7, 1.0, 0.9), 3.0, true)
		return
	lienzo.draw_polyline(puntos, Color(1.0, 0.45, 0.1, 0.28), 26.0, true)
	lienzo.draw_polyline(puntos, Color(1.0, 0.75, 0.3, 0.85), 3.0, true)
	var fin := puntos[-1]
	var largo := (fin - puntos[-2]).normalized()
	var lado := largo.orthogonal()
	lienzo.draw_colored_polygon(PackedVector2Array([fin + largo * 16.0, fin + lado * 13.0, fin - lado * 13.0]), Color(1.0, 0.55, 0.15, 0.95))
	lienzo.draw_arc(fin, 22.0, 0.0, TAU, 32, Color(1.0, 0.75, 0.3, 0.7), 2.5, true)


func _actualizar_interfaz() -> void:
	var heroe := heroe_jugador()
	var jugando := heroe != null and heroe.barco.viva and mundo.estado == Principal.Estado.JUGANDO and not mundo.panel_partida.visible
	boton_habilidad.visible = jugando
	boton_canones.visible = jugando
	boton_canones.queue_redraw()
	if mundo.estado != Principal.Estado.JUGANDO or ensayo:
		auto = false
	boton_terminar.visible = ensayo and mundo.estado == Principal.Estado.JUGANDO and not mundo.panel_partida.visible
	boton_habilidad.queue_redraw()
	boton_tienda.queue_redraw()
	_pintar_limites()
	boton_tienda.visible = jugando and en_fuente(heroe.barco)
	if panel_tienda.visible:
		if not boton_tienda.visible:
			cerrar_tienda()
		else:
			texto_oro_tienda.text = str(int(heroe.oro))
			for clave in botones_tienda:
				_habilitar_compra(heroe, clave)
	for otro in heroes:
		if otro.anillo != null:
			var barco := otro.barco
			otro.anillo.visible = barco.visible and barco.viva
			if otro.anillo.visible:
				var r := barco.radio * Principal.ESCALA * 1.25
				otro.anillo.position = Vector3(barco.position.x, 0.12, barco.position.z)
				otro.anillo.scale = Vector3(r, 1.0, r)


# Dibujo de cada habilidad centrado en "c" (unos 30 px de lado).
static func dibujar_icono(lienzo: CanvasItem, c: Vector2, clave: String, alfa: float) -> void:
	var trazo := Color(Color("fff3dc"), alfa)
	match clave:
		"impulso":
			for k in 3:
				var y := -3.0 + k * 7.0
				lienzo.draw_line(c + Vector2(-14, y - 4), c + Vector2(8 - k * 4, y - 4), trazo, 3.0, true)
			lienzo.draw_colored_polygon(PackedVector2Array([c + Vector2(6, -11), c + Vector2(16, 0), c + Vector2(6, 11)]), trazo)
		"andanada":
			lienzo.draw_circle(c, 5.0, trazo)
			for k in 8:
				lienzo.draw_circle(c + Vector2.from_angle(TAU * k / 8.0) * 13.0, 2.6, trazo)
		"escudo":
			var escudo := PackedVector2Array([c + Vector2(-11, -12), c + Vector2(11, -12), c + Vector2(11, 1), c + Vector2(0, 12), c + Vector2(-11, 1)])
			lienzo.draw_colored_polygon(escudo, Color(Principal.COLOR_ORO, alfa))
		"fuego":
			var llama := PackedVector2Array([c + Vector2(0, -14), c + Vector2(7, -3), c + Vector2(10, 5), c + Vector2(6, 12), c + Vector2(-6, 12), c + Vector2(-10, 5), c + Vector2(-5, -4)])
			lienzo.draw_colored_polygon(llama, Color(1.0, 0.45, 0.12, alfa))
			lienzo.draw_circle(c + Vector2(0, 6), 4.5, Color(1.0, 0.85, 0.3, alfa))
		"cadenas":
			for k in 3:
				var centro := c + Vector2(-10 + k * 10, -6 + k * 6)
				lienzo.draw_arc(centro, 5.5, 0.0, TAU, 16, trazo, 2.6, true)
		"reparar":
			lienzo.draw_rect(Rect2(c + Vector2(-4, -12), Vector2(8, 24)), Color(Color("7dffb2"), alfa))
			lienzo.draw_rect(Rect2(c + Vector2(-12, -4), Vector2(24, 8)), Color(Color("7dffb2"), alfa))
		"remolino":
			var espiral := PackedVector2Array()
			for k in 40:
				espiral.append(c + Vector2.from_angle(k * 0.38) * (1.5 + k * 0.33))
			lienzo.draw_polyline(espiral, Color(Color("8fd8ff"), alfa), 2.8, true)
		"kraken":
			for k in 3:
				var base := c + Vector2(-9 + k * 9, 13)
				var brazo := PackedVector2Array()
				for j in 10:
					var s := j / 9.0
					brazo.append(base + Vector2(sin(s * 4.0 + k) * 4.0, -s * 24.0))
				lienzo.draw_polyline(brazo, Color(Color("d08ae0"), alfa), 4.0 - k * 0.3, true)
		"minas":
			lienzo.draw_rect(Rect2(c + Vector2(-9, -7), Vector2(18, 19)), Color(Color("b07a45"), alfa))
			for y: float in [-3.0, 7.0]:
				lienzo.draw_line(c + Vector2(-10, y), c + Vector2(10, y), Color(Color("3a3d42"), alfa), 2.5)
			lienzo.draw_line(c + Vector2(0, -7), c + Vector2(4, -13), trazo, 2.0, true)
			lienzo.draw_circle(c + Vector2(5, -14), 3.0, Color(1.0, 0.4, 0.2, alfa))
		"niebla":
			for k in 3:
				var nube := PackedVector2Array()
				for j in 13:
					nube.append(c + Vector2(-13 + j * 26.0 / 12.0, -8 + k * 8 + sin(j * 1.1 + k) * 2.2))
				lienzo.draw_polyline(nube, Color(Color("dfe6ee"), alfa * (1.0 - k * 0.2)), 3.0, true)
		"arpon":
			lienzo.draw_line(c + Vector2(-12, 12), c + Vector2(8, -8), trazo, 3.0, true)
			lienzo.draw_colored_polygon(PackedVector2Array([c + Vector2(14, -14), c + Vector2(3, -9), c + Vector2(9, -3)]), trazo)
			lienzo.draw_line(c + Vector2(4, -4), c + Vector2(0, -2), trazo, 2.0, true)
		"rayos":
			var rayo := PackedVector2Array([c + Vector2(3, -15), c + Vector2(-7, 1), c + Vector2(0, 1), c + Vector2(-4, 15), c + Vector2(8, -3), c + Vector2(1, -3), c + Vector2(6, -15)])
			lienzo.draw_colored_polygon(rayo, Color(Color("ffe24a"), alfa))


# Botón de la habilidad con su dibujo y la recarga como un reloj que se vacía.
func _dibujar_habilidad() -> void:
	var heroe := heroe_jugador()
	if heroe == null:
		return
	var tipo: String = heroe.capitan["habilidad"]
	var listo := heroe.habilidad <= 0.0
	var c := mundo.comercio._fondo_boton(boton_habilidad, listo)
	var trazo := Color("fff3dc") if listo else Color(1, 1, 1, 0.45)
	dibujar_icono(boton_habilidad, c + Vector2(0, -7), tipo, 1.0 if listo else 0.45)
	if not listo:
		var parte: float = heroe.habilidad / HABILIDADES[tipo]["espera"]
		boton_habilidad.draw_arc(c, Comercio.RADIO_BOTON - 3.0, -PI / 2.0, -PI / 2.0 + TAU * parte, 32, Color(0, 0, 0, 0.55), 6.0, true)
	var texto := str(ceili(heroe.habilidad)) if not listo else tr(HABILIDADES[tipo]["corto"])
	var fuente := ThemeDB.fallback_font
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	boton_habilidad.draw_string_outline(fuente, c + Vector2(-ancho / 2.0, 22), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.8))
	boton_habilidad.draw_string(fuente, c + Vector2(-ancho / 2.0, 22), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, trazo)


# Barras de vida de torres y botes, nivel de cada capitán, escudos y el anuncio.
func dibujar(lienzo: Control, camara: Camera3D) -> void:
	if mostrando_apunte():
		_dibujar_apunte(lienzo, camara)
		_dibujar_cancelar(lienzo)
	if apuntando_canones() and mundo.jugador != null and mundo.jugador.viva:
		_dibujar_apunte_canon(lienzo, camara)
	if boton_canones.visible and not ensayo:
		_dibujar_auto(lienzo)
	var fuente := ThemeDB.fallback_font
	for torre in torres:
		if not torre.viva:
			continue
		var punto := mundo.a_3d(torre.pos, 6.4 if torre.orden == 2 else 5.5)
		if camara.is_position_behind(punto) or punto.distance_to(mundo.foco) > Principal.DISTANCIA_VISIBLE:
			continue
		var pantalla := camara.unproject_position(punto)
		var ancho := 130.0 if torre.orden == 2 else 84.0
		_barra(lienzo, pantalla, ancho, torre.vida / torre.vida_max, COLORES[torre.equipo], torre.destello)
		if not vulnerable(torre):
			var candado := pantalla + Vector2(ancho / 2.0 + 12.0, 0.0)
			lienzo.draw_rect(Rect2(candado + Vector2(-6, -3), Vector2(12, 9)), Color("c9d1d3"))
			lienzo.draw_arc(candado + Vector2(0, -3), 4.0, PI, TAU, 10, Color("c9d1d3"), 2.0, true)
	for bote in botes:
		bote.nodo.visible = mundo.a_3d(bote.pos).distance_to(Vector3(mundo.foco.x, 0.0, mundo.foco.z)) < mundo.alcance_vista()
		if not bote.nodo.visible:
			continue
		var sitio := mundo.a_3d(bote.pos)
		var t := mundo.tiempo + bote.fase
		bote.nodo.position = Vector3(sitio.x, mundo.altura_mar(sitio.x, sitio.z) + sin(t * 2.1) * 0.04, sitio.z)
		bote.nodo.rotation = Vector3(sin(t * 1.7) * 0.06, -bote.rumbo, sin(t * 1.3) * 0.08)
		bote.aparejo.rotation.y = sin(t * 0.9) * 0.22
		var giro := 0.0
		if bote.mira != Vector2.INF:
			giro = bote.rumbo - _rumbo_hacia(bote.pos, bote.mira)
		bote.canon.rotation.y = lerp_angle(bote.canon.rotation.y, giro, 0.15)
		var arriba := sitio + Vector3(0, 2.6, 0)
		if camara.is_position_behind(arriba):
			continue
		_barra(lienzo, camara.unproject_position(arriba), 34.0, bote.vida / bote.vida_max, COLORES[bote.equipo], bote.destello)
	for heroe in heroes:
		var barco := heroe.barco
		if not barco.viva or not barco.visible:
			continue
		var punto := barco.position + Vector3(0.0, barco.altura, 0.0)
		if camara.is_position_behind(punto):
			continue
		var pantalla := camara.unproject_position(punto)
		var insignia := pantalla + Vector2(-38.0 - 13.0, 0.0)
		lienzo.draw_circle(insignia, 11.0, Color("0b1a20"))
		lienzo.draw_arc(insignia, 11.0, 0.0, TAU, 24, COLORES[heroe.equipo], 2.0, true)
		var cifra := str(heroe.nivel)
		var ancho_cifra := fuente.get_string_size(cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		lienzo.draw_string(fuente, insignia + Vector2(-ancho_cifra / 2.0, 5.0), cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		if heroe.escudo > 0.0:
			var centro := camara.unproject_position(barco.position + Vector3(0, 0.8, 0))
			lienzo.draw_arc(centro, 46.0, 0.0, TAU, 40, Color(Principal.COLOR_ORO, 0.8), 4.0, true)
	monstruos.dibujar(lienzo, camara)
	var propio := heroe_jugador()
	if not ensayo:
		_dibujar_nexos(lienzo, fuente, propio.equipo if propio != null else 0)
	if propio != null and not propio.barco.viva:
		_dibujar_regreso(lienzo, fuente, ceili(propio.reaparece))
	if anuncio_vida > 0.0:
		var alfa := clampf(anuncio_vida / 0.5, 0.0, 1.0)
		var tam := 30
		var ancho := fuente.get_string_size(anuncio, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var sitio := Vector2(lienzo.size.x / 2.0 - ancho / 2.0, 230.0 if propio != null and not propio.barco.viva else 190.0)
		lienzo.draw_string_outline(fuente, sitio, anuncio, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 8, Color(0, 0, 0, 0.7 * alfa))
		lienzo.draw_string(fuente, sitio, anuncio, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color(anuncio_color, alfa))


# Vida de los dos nexos arriba en el centro: el propio a la izquierda y el rival a la derecha.
func _dibujar_nexos(lienzo: Control, fuente: Font, equipo: int) -> void:
	var largo := 150.0
	var mitad := lienzo.size.x / 2.0
	for lado in 2:
		var bando := equipo if lado == 0 else 1 - equipo
		var nexo: Torre = null
		for torre in torres:
			if torre.orden == 2 and torre.equipo == bando:
				nexo = torre
		if nexo == null:
			continue
		var parte := nexo.vida / nexo.vida_max if nexo.viva else 0.0
		var x := mitad - 18.0 - largo if lado == 0 else mitad + 18.0
		var fondo := Rect2(x - 34.0, 14.0, largo + 40.0, 34.0)
		lienzo.draw_rect(fondo, Color(0.03, 0.09, 0.12, 0.75))
		lienzo.draw_rect(fondo, COLORES[bando], false, 2.0)
		var icono := Vector2(x - 17.0, 31.0)
		var piedra := COLORES[bando].lerp(Color.WHITE, 0.25)
		lienzo.draw_rect(Rect2(icono + Vector2(-9, -3), Vector2(18, 11)), piedra)
		lienzo.draw_rect(Rect2(icono + Vector2(-4, -10), Vector2(8, 8)), piedra)
		for k in 3:
			lienzo.draw_rect(Rect2(icono + Vector2(-9 + k * 7, -6), Vector2(4, 3)), piedra)
		lienzo.draw_rect(Rect2(x, 24.0, largo, 14.0), Color(0, 0, 0, 0.6))
		var relleno := COLORES[bando].lerp(Color.WHITE, nexo.destello * 0.6)
		lienzo.draw_rect(Rect2(x + 2.0, 26.0, (largo - 4.0) * clampf(parte, 0.0, 1.0), 10.0), relleno)
		var cifra := "%d%%" % ceili(parte * 100.0)
		var ancho := fuente.get_string_size(cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var sitio := Vector2(x + largo / 2.0 - ancho / 2.0, 36.0)
		lienzo.draw_string_outline(fuente, sitio, cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, 0.8))
		lienzo.draw_string(fuente, sitio, cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)


func _dibujar_regreso(lienzo: Control, fuente: Font, segundos: int) -> void:
	var titulo := tr("Vuelves en")
	var cifra := "%d s" % segundos
	var ancho_titulo := fuente.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var ancho_cifra := fuente.get_string_size(cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x
	var ancho := maxf(ancho_titulo, ancho_cifra) + 56.0
	var mitad := lienzo.size.x / 2.0
	var caja := Rect2(mitad - ancho / 2.0, 92.0, ancho, 96.0)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.03, 0.09, 0.12, 0.78)
	fondo.border_color = Principal.COLOR_PELIGRO
	fondo.set_border_width_all(2)
	fondo.set_corner_radius_all(14)
	lienzo.draw_style_box(fondo, caja)
	lienzo.draw_string(fuente, Vector2(mitad - ancho_titulo / 2.0, caja.position.y + 30.0), titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Principal.COLOR_TEXTO)
	var sitio := Vector2(mitad - ancho_cifra / 2.0, caja.position.y + 82.0)
	lienzo.draw_string_outline(fuente, sitio, cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 52, 8, Color(0, 0, 0, 0.6))
	lienzo.draw_string(fuente, sitio, cifra, HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Principal.COLOR_ORO)


func _barra(lienzo: Control, centro: Vector2, ancho: float, parte: float, color: Color, destello: float) -> void:
	lienzo.draw_rect(Rect2(centro + Vector2(-ancho / 2.0, -5.0), Vector2(ancho, 10.0)), Color(0, 0, 0, 0.55))
	lienzo.draw_rect(Rect2(centro + Vector2(-ancho / 2.0 + 2.0, -3.0), Vector2((ancho - 4.0) * clampf(parte, 0.0, 1.0), 6.0)), color.lerp(Color.WHITE, destello * 0.6))


# Niebla de guerra: un rival solo se ve si algo de tu equipo está cerca para avistarlo.
func a_la_vista(punto: Vector2, equipo: int) -> bool:
	if punto.distance_to(BASES[equipo]) < RADIO_FUENTE + VISION_TORRE:
		return true
	for heroe in heroes:
		if heroe.equipo == equipo and heroe.barco.viva and punto.distance_to(heroe.barco.pos) < VISION_BARCO:
			return true
	for torre in torres:
		if torre.equipo == equipo and torre.viva and punto.distance_to(torre.pos) < VISION_TORRE:
			return true
	for bote in botes:
		if bote.equipo == equipo and punto.distance_to(bote.pos) < VISION_BOTE:
			return true
	return false


# Mapa entero: carriles, bases, torres, botes y los barcos que tu equipo tiene a la vista.
func dibujar_minimapa(lienzo: Control, centro: Vector2, escala: float) -> void:
	for carril in CARRILES:
		var trazo := PackedVector2Array()
		for punto in camino(carril, 0):
			trazo.append(centro + punto * escala)
		lienzo.draw_polyline(trazo, Color(1, 1, 1, 0.22), 5.0, true)
	for equipo in 2:
		lienzo.draw_circle(centro + BASES[equipo] * escala, RADIO_FUENTE * escala, Color(COLORES[equipo], 0.22))
	for torre in torres:
		var punto := centro + torre.pos * escala
		var lado := 9.0 if torre.orden == 2 else 6.0
		var color := COLORES[torre.equipo] if torre.viva else Color(0.35, 0.35, 0.35)
		lienzo.draw_rect(Rect2(punto - Vector2.ONE * (lado / 2.0 + 1.5), Vector2.ONE * (lado + 3.0)), Color("08161c"))
		lienzo.draw_rect(Rect2(punto - Vector2.ONE * lado / 2.0, Vector2.ONE * lado), color)
	monstruos.dibujar_minimapa(lienzo, centro, escala)
	var propio := mundo.jugador.equipo if mundo.jugador != null else 0
	for bote in botes:
		if bote.equipo == propio or a_la_vista(bote.pos, propio):
			lienzo.draw_circle(centro + bote.pos * escala, 1.8, COLORES[bote.equipo].lightened(0.3))
	for heroe in heroes:
		var barco := heroe.barco
		if barco.viva and barco != mundo.jugador and (heroe.equipo == propio or (a_la_vista(barco.pos, propio) and heroe.oculto <= 0.0)):
			lienzo.draw_circle(centro + barco.pos * escala, 4.5, Color("08161c"))
			lienzo.draw_circle(centro + barco.pos * escala, 3.5, COLORES[heroe.equipo])
