# Última Marea

Batallas de barcos en 3D para móvil, en horizontal. Doce barcos entran al mar, la tormenta va cerrando el círculo y gana el último que siga a flote.

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
