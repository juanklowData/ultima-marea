class_name Idioma
extends RefCounted

# El juego está escrito en español; aquí van sus textos en inglés. Los Label y Button se
# traducen solos si su texto es una clave exacta; los textos con números pasan por tr().

const IDIOMAS: Array[String] = ["es", "en"]

const INGLES := {
	# Menú
	"El mar no perdona.\n¿Serás el último a flote?": "The sea shows no mercy.\nWill you be the last afloat?",
	"Tienda": "Shop",
	"Buscar partida": "Find match",
	"Configuración": "Settings",
	"Tesoro: %d monedas": "Treasure: %d coins",
	"Idioma": "Language",
	# Niveles
	"Nivel %d · %s": "Level %d · %s",
	"%d XP · ¡Nivel máximo!": "%d XP · Max level!",
	"%d XP · faltan %d para %s": "%d XP · %d more to reach %s",
	"Niveles": "Levels",
	"Ganas experiencia (XP) según tu puesto (ganar da +30) y +3 por cada barco que hundes. Si quedas del puesto 31 en adelante pierdes 8 XP, y retirarte resta 12: puedes bajar de nivel. Al subir tienes 3 partidas de protección. El premio de monedas se cobra solo la primera vez.":
		"You earn experience (XP) based on your placement (winning gives +30) and +3 for each ship you sink. Finishing 31st or worse costs 8 XP, and retreating costs 12: you can drop a level. After leveling up you get 3 protected matches. The coin reward is paid only the first time.",
	"Protegido de bajar: %d partidas": "Protected from dropping: %d matches",
	"Experiencia -%d": "Experience -%d",
	"Experiencia sin cambios": "Experience unchanged",
	"Bajaste a %s": "You dropped to %s",
	"Tu rango te protegió de bajar de nivel": "Your rank protected you from dropping a level",
	"Desde %d XP": "From %d XP",
	"Premio: +%d monedas": "Reward: +%d coins",
	"Superado": "Completed",
	"Estás aquí": "You are here",
	"Te faltan %d XP": "%d XP to go",
	"¡Subiste a %s!": "You reached %s!",
	"Experiencia +%d": "Experience +%d",
	"Grumete": "Cabin Boy",
	"Marinero": "Sailor",
	"Corsario": "Corsair",
	"Capitán": "Captain",
	"Almirante": "Admiral",
	"Leyenda del Mar": "Sea Legend",
	# Configuración y opciones
	"Opciones": "Options",
	"Música": "Music",
	"Efectos": "Effects",
	"Seguir jugando": "Keep playing",
	"Salir de la partida": "Leave match",
	"¿Seguro? Toca otra vez": "Sure? Tap again",
	"Nombre del barco": "Ship name",
	"Mi barco": "My ship",
	"Listo": "Done",
	# Búsqueda
	"TODOS CONTRA TODOS": "FREE FOR ALL",
	"Buscando partida": "Searching for a match",
	"Completando con bots": "Filling with bots",
	"Capitanes en el puerto: 1/%d\nEsperando %ds": "Captains in port: 1/%d\nWaiting %ds",
	"No hay más capitanes conectados.\nSe unen %d bots a la marea.": "No more captains online.\n%d bots join the tide.",
	"Cancelar": "Cancel",
	# Tienda
	"Arrastra para girar el barco": "Drag to rotate the ship",
	"%d monedas": "%d coins",
	"Barco": "Ship",
	"Casco": "Hull",
	"Adornos": "Trim",
	"Velas": "Sails",
	"Bandera": "Flag",
	"Proa": "Bow",
	"Popa": "Stern",
	"Cañones": "Cannons",
	"\nTienes %d de %d": "\nYou own %d of %d",
	"Equipado": "Equipped",
	"Equipar": "Equip",
	"Tuyo": "Owned",
	"Comprar · %d monedas": "Buy · %d coins",
	"Te faltan %d monedas": "You need %d more coins",
	"Balandro": "Sloop",
	"Bergantín": "Brig",
	"Galeón": "Galleon",
	"Rápido y frágil.": "Fast and fragile.",
	"Equilibrado.": "Balanced.",
	"Lento y duro.": "Slow and tough.",
	# Partida
	"A flote: %d": "Afloat: %d",
	"Tormenta: %ds": "Storm: %ds",
	"Estás en la tormenta": "You're in the storm",
	"Círculo final": "Final circle",
	"Botín a bordo: %d": "Loot aboard: %d",
	"¡Atrapado en un remolino!": "Caught in a whirlpool!",
	"¡Cuidado con el Kraken!": "Beware the Kraken!",
	"¡Viento a favor!": "Tailwind!",
	"Ventisca: navega con el viento": "Gale: sail with the wind",
	"Frente": "Bow",
	"Izq.": "Left",
	"Der.": "Right",
	"SE BUSCA": "WANTED",
	# Final
	"MAREA CERRADA": "BATTLE OVER",
	"Victoria": "Victory",
	"Hundido": "Sunk",
	"Retirada": "Retreat",
	"Tu barco quedó solo en el mar.": "Your ship is the last one afloat.",
	"La marea se quedó con tu barco. Terminaste en el puesto %d de %d.": "The tide took your ship. You finished #%d of %d.",
	"Abandonaste la partida en el puesto %d de %d.": "You left the match at #%d of %d.",
	"+%d monedas": "+%d coins",
	"Tu tesoro para la tienda: %d monedas": "Your treasure for the shop: %d coins",
	"Tu tesoro para la tienda: %d + %d = %d monedas": "Your treasure for the shop: %d + %d = %d coins",
	"Al puerto": "To port",
	"Otra partida": "Play again",
	"Botín a bordo": "Loot aboard",
	"Botín perdido: -%d": "Loot lost: -%d",
}


# El español también se registra (clave = texto): sin él Godot caería al inglés de respaldo.
static func instalar() -> void:
	var ingles := Translation.new()
	ingles.locale = "en"
	var espanol := Translation.new()
	espanol.locale = "es"
	for clave in INGLES:
		ingles.add_message(clave, INGLES[clave])
		espanol.add_message(clave, clave)
	TranslationServer.add_translation(ingles)
	TranslationServer.add_translation(espanol)


static func usar(idioma: String) -> void:
	TranslationServer.set_locale(idioma)
