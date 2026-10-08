class_name Paleta
extends RefCounted

# Paleta propia de Última Marea, «Caribe dorado»: sol cálido de media tarde sobre un mar
# turquesa. Las luces tiran a oro y las sombras a azul verdoso; los acentos son coral y oro.
# Todo color nuevo del juego debería salir de aquí o mezclarse con estos.

# Luz y cielo
const SOL := Color("ffd59e")
const SOL_ENERGIA := 0.92
const SOL_TORMENTA := 0.35
const AMBIENTE := Color("8fd0dc")
const AMBIENTE_ENERGIA := 0.42
const AMBIENTE_TORMENTA := 0.2
const CIELO_ALTO := Color("3fa9d6")
const CIELO_HORIZONTE := Color("ffe2b0")
const NIEBLA := Color("7cc3c8")

# Mar
const MAR_HONDO := Color("021f38")
const MAR_CLARO := Color("077080")
const MAR_REFLEJO := Color("74c6cf")
const MAR_BAJIO := Color("2fd2c0")
const MAR_TORMENTA := Color("0a0d18")
const ESPUMA := Color("fff7ea")

# Tierra
const ARENA := Color("f4dba6")
const HIERBA := Color("5cb148")
const HIERBA_OSCURA := Color("2a8a55")
const ROCA := Color("a09184")
const TRONCO := Color("9c6a40")
const HOJA := Color("38ad5c")
const COCO := Color("7b4924")
const MUSGO := Color("4f8f4a")

# Madera, hierro y adornos
const MADERA_MIEL := Color("bc844e")
const MADERA := Color("9a6538")
const MADERA_OSCURA := Color("553120")
const CASCO_FONDO := Color("7a2c22")
const HIERRO := Color("2b2f38")
const TEJA := Color("c4512f")
const CUERDA := Color("dcc08a")
const FAROL := Color("ffc95e")

# Acentos
const ORO := Color("f2b84b")
const ORO_CLARO := Color("ffe08a")
const CORAL := Color("ff7a5c")
const TURQUESA := Color("27c2b4")
const PELIGRO := Color("ff6650")
const EXITO := Color("4fd889")

# Interfaz
const TEXTO := Color("fff4e0")
const TEXTO_OSCURO := Color("3a1f0c")
const PANEL := Color(0.03, 0.17, 0.21, 0.92)
const PANEL_BORDE := Color(0.95, 0.72, 0.29, 0.45)
const BOTON := Color("f2a541")
const BOTON_CRISTAL := Color(1.0, 0.96, 0.88, 0.08)
const BOTON_BORDE := Color(1.0, 0.92, 0.75, 0.35)
const VOLVER := Color("16938f")
const VOLVER_BORDE := Color("8ff0e6")
const CONTORNO := Color("08161c")

# Ajuste final de la imagen.
const SATURACION := 1.08
const CONTRASTE := 1.06


# Lleva cualquier color del juego hacia la paleta: más vivo, y los grises y pardos
# apagados se calientan un poco, para que nada quede con el gris neutro de serie.
static func armonizar(color: Color) -> Color:
	var s := color.s
	var nuevo := color
	if s < 0.12:
		nuevo = color.lerp(Color(color.v, color.v * 0.93, color.v * 0.82, color.a), 0.35)
	else:
		nuevo.s = minf(1.0, s * 1.08)
	return nuevo
