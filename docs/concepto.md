# Concepto

## La partida

Doce barcos aparecen repartidos en un mar circular. Once los controla la máquina; el tuyo es un bergantín. El círculo seguro se encoge por fases. Fuera de ese círculo, la tormenta daña el casco. El último barco a flote gana.

Una partida del prototipo dura pocos minutos. Ese es el objetivo del formato: entrar, pelear y salir con una victoria o un hundimiento claro.

## Cómo se juega

La proa apunta hacia donde empujas la palanca. La distancia del dedo al centro de la palanca marca la velocidad. Si sueltas, el barco pierde impulso.

**Fuego** lanza tres balas hacia adelante, con una pequeña apertura. Hay que apuntar la proa y anticipar hacia dónde navega el rival. La ráfaga tiene una recarga corta.

Los barriles reparan el casco al tocarlos. Los islotes paran las balas y empujan a los barcos: sirven de cobertura.

Si dos barcos se rozan, se separan. El daño de verdad llega por los cañones y por la tormenta.

## Barcos

| Barco | Casco | Velocidad | Papel |
| --- | --- | --- | --- |
| Balandro | Bajo | Alta | Entra, dispara y sale |
| Bergantín | Medio | Media | El barco del jugador |
| Galeón | Alto | Baja | Aguanta más disparos |

En el prototipo el jugador siempre lleva el bergantín. Los rivales salen de los tres tipos. Más adelante cada tipo puede tener un cañón distinto: el galeón con andanada lateral, el balandro con tiro rápido de proa.

## La tormenta

El círculo empieza amplio y se cierra en cinco fases, cada una más chica. Al cambiar de fase, el centro se corre un poco para que no baste con quedarse quieto en el medio.

El daño aumenta cuanto más adentro de la tormenta estés. Quedarse a pelear en el borde es una decisión: tienes cobertura de islote, pero el casco se va gastando.

## Controles de móvil

La pantalla va en vertical, como el anuncio.

- Abajo a la izquierda: palanca de navegación.
- Abajo a la derecha: botón de fuego.
- Arriba: vida, barcos que siguen a flote y el tiempo de la fase.
- Arriba a la derecha: mapa con el círculo y los barcos.

En la computadora, WASD o las flechas hacen de palanca y Espacio dispara. Así se puede probar el prototipo sin publicar nada.

## Qué se ve

Mar en tonos verdes y azules, barco de madera con vela, estela blanca detrás de la popa y tres trazos de cañón hacia la proa. La vida del jugador va en verde; la de los rivales, en rojo. Es un estilo cercano a la referencia, dibujado desde cero en el prototipo.

## Fuera del prototipo

Estas piezas esperan a que la partida ya divierta:

- Multijugador con otras personas.
- Oro, gemas, nivel de capitán y mejoras entre partidas.
- Más mapas, niebla y eventos en el agua.
- Animación final de hundimiento y arte hecho a mano.
- Publicación en Google Play y App Store.

## Camino técnico

El prototipo está en HTML y Canvas para poder jugarlo hoy, abriendo un archivo. No hace falta instalar un motor.

Cuando el manejo esté cerrado, el juego puede pasar a Godot 4. Es gratis y exporta a Android e iOS. Las reglas de este documento se quedan; se rehacen la cámara, los barcos y la interfaz con el arte definitivo.

## Orden de trabajo

1. Jugar el prototipo y ajustar velocidad, daño, recarga y tamaño de la tormenta.
2. Hacer que los rivales rodeen, flanqueen y no se amontonen.
3. Añadir un segundo tipo de tiro, para que elegir barco cambie la pelea.
4. Pasar el prototipo a Godot y probarlo en un teléfono de verdad.
