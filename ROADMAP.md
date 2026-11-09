# Hoja de ruta

Trabajo pendiente en Última Marea, ordenado por lo que más acerca el juego a poder publicarse. Las horas son estimaciones de trabajo de diseño, código y pruebas.

## Ahora

- [ ] **1 contra 1 por wifi estable** (16 h). `red.gd` ya sincroniza la partida, pero falta cerrar reconexiones, fin de partida y pruebas en dos teléfonos distintos. La descripción de red local ya está en el preset de iOS.
- [ ] **Tutorial jugable de la primera partida** (8 h). Hoy los controles se explican solo en el README; faltan carteles dentro del juego para la palanca, el botón de cañones y el poder divino.
- [ ] **Ajustes de dificultad por oleada** (6 h). Curvas de vida, daño y frecuencia de los piratas en `supervivencia.gd`, con una tabla editable en vez de valores sueltos.
- [ ] **Pruebas en pantallas pequeñas y equipos de gama baja** (6 h). Medir cuadros por segundo en Android, bajar divisiones del mar y límites de efectos cuando haga falta (`principal.gd`, `texturas.gd`).

## Después

- [ ] **Dos dioses nuevos con su poder** (12 h). Cada uno necesita figura de proa, efecto, sonido y su entrada en la tienda y en `idioma.gd`.
- [ ] **Variedad de jefes pirata** (14 h). Hoy los tres jefes comparten comportamiento; faltan patrones de ataque distintos y avisos en pantalla.
- [ ] **Progresión guardada entre partidas** (8 h). Monedas, dioses desbloqueados y récords ya se guardan; falta una pantalla de progreso y migrar partidas viejas sin perder datos.
- [ ] **Sonido y música configurables** (4 h). Volumen separado para música y efectos, y mezcla de los sonidos sintetizados de `sonidos.gd`.
- [ ] **Accesibilidad básica** (6 h). Tamaño de texto, contraste de la interfaz y una opción para reducir el movimiento de la cámara y del oleaje.
- [ ] **Publicación en Android** (10 h). Firma de la versión, ficha de la tienda, iconos y capturas, y una prueba cerrada con amigos.
- [ ] **Publicación en iOS** (10 h). El flujo de GitHub Actions ya genera el `.ipa` sin firmar; falta la firma con la cuenta de desarrollador y la ficha en App Store Connect.

## Algún día

- [ ] Modo de dos jugadores en el mismo teléfono.
- [ ] Barcos y banderas desbloqueables por temporada.
- [ ] Traducción completa a inglés y portugués (la base de idiomas ya existe en `idioma.gd`).
- [ ] Replays de las partidas guardadas en el dispositivo, sin subir datos a ningún servidor.
