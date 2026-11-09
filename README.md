# Última Marea

Batallas de barcos en 3D para móvil, en horizontal. Doce barcos entran al mar, la tormenta va cerrando el círculo y gana el último que siga a flote.

## English summary

Última Marea is a 3D naval survival game for mobile, played in landscape. You sail a ship, fight cursed pirates, collect souls and pick one of three blessings on each level-up; survive ten minutes and a pirate boss every three minutes. It is a solo project by Juan Carlos Cruz Ceballos ([@juanklowData](https://github.com/juanklowData)), written in GDScript with Godot 4.7 and no external game assets: the models, textures, sounds and music are generated or painted in the repository.

- **Stack:** Godot 4.7 (GDScript), GLSL shaders, Python for texture painting, GitHub Actions for iOS builds.
- **Run it:** open `godot/project.godot` with Godot 4.7 and press F5. WASD/arrows to sail, Space to fire, Q/E for the divine power.
- **Status:** playable prototype with a 12-ship battle royale mode and a survival mode; see [ROADMAP.md](ROADMAP.md) for what comes next.
- **License:** MIT.

## Cómo jugarlo en la computadora

1. Abre `Godot_v4.7.2-stable_win64.exe` desde el escritorio.
2. En el gestor de proyectos, abre **Última Marea** (o pulsa **Importar** y elige `godot/project.godot`).
3. Pulsa **F5**, o el botón ▶ arriba a la derecha.

El editor sale vacío en la vista 3D porque el mar, las islas y los barcos se crean por código al empezar el juego.

Navegas con **WASD** o las flechas y disparas con **Espacio**. El ratón funciona como un dedo: si mantienes pulsado en la mitad izquierda, navegas; en la mitad derecha, disparas.

En el celular, el dedo en la mitad izquierda es la palanca y aparece donde tocas. El dedo en la mitad derecha dispara.

## Qué hay en la partida

- Barcos en 3D con casco, cubierta, camarote, mástiles, velas, cañones y bandera. Se mecen con el oleaje, se inclinan al girar y se hunden al perder el casco.
- Tres barcos: el balandro es rápido y frágil, el bergantín es equilibrado y el galeón es lento y duro.
- El **Astillero**, para elegir tipo de barco y colores de casco, velas y bandera. Se guarda solo.
- Tablas flotantes con un aro dorado que reparan el casco.
- La tormenta cierra el círculo: el mar se oscurece fuera y una cortina morada marca el borde.
- Cañonazos en arco con humo, astillas al impactar y salpicaduras en el agua.

## Cómo se juega: supervivencia contra los piratas malditos

Última Marea tiene un único modo. Eliges un dios, zarpas y aguantas oleadas sin fin de piratas malditos. Si sigues a flote a los 10 minutos, ganas.

- **Tú apuntas y disparas**: mantén el botón de cañones, arrastra hacia donde quieres tirar y suelta (o mantén Espacio y apunta con el ratón). Navegas con la palanca (o WASD) y lanzas el **poder divino** con el botón del retrato (o Q/E).
- Cada pirata hundido suelta **almas** azules. Al juntar las suficientes subes de nivel y eliges **1 de 3 bendiciones**: más daño, más balas, recarga, vida, velocidad, imán de almas, balas de fuego, explosivas o encadenadas...
- A los 3, 6 y 9 minutos llega un **jefe pirata**. Cada minuto los piratas salen más seguido y más duros.
- Las **monedas** de cada partida sirven para **desbloquear dioses** nuevos (empiezas con Ares, Poseidón y Bachué). El récord de tiempo y de hundidos se guarda.

| Dios | Poder divino |
| --- | --- |
| Quetzalcóatl | Vuelo de Ehécatl: velocidad y vendaval |
| Ares | Furia de Ares: dos andanadas de 16 balas |
| Atenea | Égida: 4 s sin daño y repara |
| Ra | Disco solar: anillo de fuego |
| Anubis | Juicio de Anubis: frena, daña y atrae las almas |
| Bachué | Aguas de Iguaque: repara y empuja |
| Poseidón | Torbellino del tridente |
| Tiamat | Hijos de Tiamat: tentáculos que inmovilizan |
| Pele | Erupción: seis estallidos de lava |
| Loki | Ilusión: invisible 4 s |
| Odín | Gungnir: lanza que atraviesa en línea |
| Thor | Ira de Mjölnir: cinco rayos |

El modo está en `godot/scripts/supervivencia.gd`. La elección de dios usa el panel de `moba.gd`.

## Texturas pintadas a mano

Las 11 texturas de `godot/texturas/` (tablas de cubierta, casco con clavos, madera pintada, hierro, oro, lona, arena, hierba, roca, corteza de palmera y general) son propias del juego, con sombras frías y luces cálidas de acuarela. Cada pieza recibe la suya según su color (`Texturas.tipo_de_color`). Encima va un contorno de tinta de cuento ilustrado, que se puede apagar en Ajustes → Contornos (de serie, encendido desde gráficos Medio): las pinta `herramientas/pintar_texturas.py`. Se repiten sin costuras y van casi en gris, porque el color lo pone cada material. Para volver a generarlas: `python3 herramientas/pintar_texturas.py godot/texturas`.

## Archivos

En `godot/scripts/`:

- `principal.gd`: la partida, la cámara, la tormenta, los efectos, los controles y las pantallas.
- `barco.gd`: cómo navega cada barco y cómo piensan los rivales.
- `islas.gd` y `circulo.gd`: dónde caen las islas y rocas, su forma y su modelo 3D.
- `peligros.gd`: remolinos, ventiscas y el kraken.
- `fauna.gd`: gaviotas, cangrejos, tortugas, monos, delfines y peces.
- `modelo_barco.gd` y `mascarones.gd`: el modelo 3D de cada barco y sus figuras de proa.
- `catalogo.gd`, `dibujos.gd` y `miniaturas.gd`: las piezas de la tienda, sus velas y banderas, y sus fotos.
- `personalizacion.gd`: lo elegido en la tienda, monedas, nivel y guardado.
- `sonidos.gd` y `musica.gd`: efectos de sonido sintetizados y música.
- `ui.gd`, `boton_idioma.gd`, `moneda_voladora.gd`, `insignia.gd` e `idioma.gd`: piezas de la interfaz e idiomas.

`godot/shaders/` tiene el agua, las orillas, las nubes, la tormenta, las telas y el kraken.
- `prototipo/`: la primera versión de navegador, como referencia.

## Pasarlo al celular Android

Una sola vez:

1. En Godot: **Editor → Gestionar plantillas de exportación → Descargar e instalar**.
2. Instala [Android Studio](https://developer.android.com/studio) para tener el SDK de Android.
3. En Godot: **Editor → Configuración del editor → Exportar → Android**, y pon la ruta del SDK (suele ser `C:\Users\usuario\AppData\Local\Android\Sdk`).

Cada vez que quieras probar:

1. **Proyecto → Exportar → Añadir… → Android**.
2. Pulsa **Exportar proyecto** y guarda `UltimaMarea.apk`.
3. Pasa el APK al teléfono y ábrelo para instalarlo.

## Licencia

MIT. Ver [LICENSE](LICENSE).
