"""Pinta las texturas propias de Última Marea con aspecto de cuento pintado a mano.

Cada material tiene la suya: tablas de cubierta, casco con clavos, pintura descascarillada,
hierro martillado, oro, lona, arena, hierba, roca, corteza de palmera y una general.
Son de 256x256, se repiten sin costuras y van en tonos claros: el color de cada pieza lo pone
su material. Para que se vean pintadas, las sombras tiran a azul violeta y las luces a
amarillo cálido, como en una acuarela.

Uso: python3 pintar_texturas.py <carpeta_salida>
Imprime el brillo medio lineal de cada una (Texturas.MEDIAS).
"""
import math
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

LADO = 256
SOMBRA = np.array([0.70, 0.74, 0.98])
LUZ = np.array([1.0, 0.97, 0.86])


def ruido(escala, semilla, octavas=4):
    """Ruido suave que se repite en los bordes (suma de ondas en un toro)."""
    rng = np.random.default_rng(semilla)
    y, x = np.mgrid[0:LADO, 0:LADO] / LADO * 2 * math.pi
    total = np.zeros((LADO, LADO))
    amp = 1.0
    for o in range(octavas):
        f = escala * (2 ** o)
        for _ in range(6):
            kx, ky = rng.integers(-f, f + 1, size=2)
            if kx == 0 and ky == 0:
                continue
            total += amp * np.sin(kx * x + ky * y + rng.uniform(0, 2 * math.pi))
        amp *= 0.5
    total -= total.min()
    return total / max(total.max(), 1e-6)


def gris(valores):
    return Image.fromarray(np.clip(valores * 255, 0, 255).astype(np.uint8), "L")


def repetir(dibujar):
    """Llama a dibujar(dx, dy) nueve veces para que lo pintado cruce los bordes sin corte."""
    for dx in (-LADO, 0, LADO):
        for dy in (-LADO, 0, LADO):
            dibujar(dx, dy)


def pinceladas(base, cuantas, semilla, largo, ancho, angulo_fn, tono_fn, alfa=70, lados=14):
    rng = random.Random(semilla)
    capa = Image.new("LA", (LADO, LADO), (0, 0))
    dibujo = ImageDraw.Draw(capa, "LA")
    for _ in range(cuantas):
        x, y = rng.uniform(0, LADO), rng.uniform(0, LADO)
        l, a = rng.uniform(*largo), rng.uniform(*ancho)
        ang = angulo_fn(rng, x, y)
        tono = tono_fn(rng, x, y)
        puntos = []
        for k in range(lados):
            t = k / lados * 2 * math.pi
            # Pincelada: más gruesa por el centro y con la punta algo irregular.
            px = math.cos(t) * l / 2
            py = math.sin(t) * a / 2 * (0.8 + 0.4 * rng.random())
            puntos.append((px * math.cos(ang) - py * math.sin(ang), px * math.sin(ang) + py * math.cos(ang)))
        repetir(lambda dx, dy: dibujo.polygon([(x + px + dx, y + py + dy) for px, py in puntos], fill=(tono, alfa)))
    capa = capa.filter(ImageFilter.GaussianBlur(0.6))
    return Image.alpha_composite(base.convert("RGBA"), capa.convert("RGBA")).convert("L")


def suavizar(imagen, radio):
    grande = Image.new("L", (LADO * 3, LADO * 3))
    for i in range(3):
        for j in range(3):
            grande.paste(imagen, (i * LADO, j * LADO))
    return grande.filter(ImageFilter.GaussianBlur(radio)).crop((LADO, LADO, LADO * 2, LADO * 2))


def acuarela(imagen, minimo, maximo, deriva_semilla):
    """Normaliza el gris y lo colorea: sombras frías, luces cálidas, y una deriva de tono suave."""
    v = np.asarray(imagen, dtype=float) / 255
    v = (v - v.min()) / max(v.max() - v.min(), 1e-6)
    brillo = minimo + v * (maximo - minimo)
    mezcla = np.clip((v - 0.15) / 0.7, 0, 1)[..., None]
    color = SOMBRA * (1 - mezcla) + LUZ * mezcla
    deriva = ruido(1, deriva_semilla, 2)[..., None]
    color = color * (0.95 + 0.1 * np.concatenate([deriva, 1 - deriva, deriva * 0.5 + 0.25], axis=2))
    rgb = np.clip(brillo[..., None] * color / color.max(), 0, 1)
    return Image.fromarray((rgb * 255).astype(np.uint8), "RGB")


def tablas(filas, vetas_fuerza, semilla, clavos=False):
    vetas = ruido(1, semilla)
    y, x = np.mgrid[0:LADO, 0:LADO]
    alto = LADO / filas
    fila = (y // alto).astype(int)
    rng = np.random.default_rng(semilla + 1)
    desfase = rng.uniform(0, 1, filas)
    tono = rng.uniform(0.8, 1.0, filas)
    veta = 0.5 + 0.5 * np.sin((y / alto * 7 + vetas * 6 * vetas_fuerza + desfase[fila] * 10) * math.pi)
    base = (0.7 + 0.2 * veta) * tono[fila]
    junta = np.abs((y % alto) - alto / 2) / (alto / 2)
    base *= np.where(junta > 0.88, 0.45, 1.0)
    for f in range(filas):
        corte = int(desfase[f] * LADO)
        base[(fila == f) & (np.abs(((x - corte) % LADO) - LADO / 2) > LADO / 2 - 2)] *= 0.55
    imagen = gris(base)
    if clavos:
        dibujo = ImageDraw.Draw(imagen)
        for f in range(filas):
            corte = int(desfase[f] * LADO)
            for lado in (-7, 7):
                for fila_clavo in (0.3, 0.7):
                    cx = (corte + lado) % LADO
                    cy = f * alto + alto * fila_clavo
                    repetir(lambda dx, dy: dibujo.ellipse((cx - 2 + dx, cy - 2 + dy, cx + 2 + dx, cy + 2 + dy), fill=60))
    return imagen


def madera():
    imagen = tablas(4, 1.0, 11)
    imagen = pinceladas(imagen, 900, 21, (14, 40), (2, 4), lambda r, x, y: r.uniform(-0.06, 0.06),
                        lambda r, x, y: int(r.uniform(150, 240)), 55)
    return acuarela(suavizar(imagen, 0.5), 0.5, 1.0, 101)


def casco():
    """Casco: tablas más estrechas, clavos, brea en las juntas y chorretones de sal."""
    imagen = tablas(6, 0.6, 12, clavos=True)
    imagen = pinceladas(imagen, 600, 22, (16, 46), (2, 4), lambda r, x, y: r.uniform(-0.05, 0.05),
                        lambda r, x, y: int(r.uniform(140, 230)), 50)
    imagen = pinceladas(imagen, 120, 23, (20, 60), (2, 5), lambda r, x, y: math.pi / 2 + r.uniform(-0.1, 0.1),
                        lambda r, x, y: int(r.uniform(225, 255)), 35)
    return acuarela(suavizar(imagen, 0.5), 0.45, 1.0, 102)


def pintura():
    """Madera pintada: brochazos largos y desconchones que dejan ver la madera oscura."""
    imagen = gris(0.82 + ruido(2, 13) * 0.15)
    imagen = pinceladas(imagen, 500, 24, (30, 70), (4, 9), lambda r, x, y: r.uniform(-0.04, 0.04),
                        lambda r, x, y: int(r.uniform(200, 255)), 60)
    imagen = pinceladas(imagen, 35, 25, (6, 16), (3, 8), lambda r, x, y: r.uniform(0, math.pi),
                        lambda r, x, y: int(r.uniform(130, 165)), 150, lados=7)
    return acuarela(suavizar(imagen, 0.5), 0.55, 1.0, 103)


def metal():
    """Hierro martillado: golpes redondos, remaches y brillos cortos."""
    imagen = gris(0.7 + ruido(3, 14) * 0.2)
    rng = random.Random(26)
    dibujo = ImageDraw.Draw(imagen)
    for _ in range(140):
        cx, cy, r = rng.uniform(0, LADO), rng.uniform(0, LADO), rng.uniform(5, 13)
        g = int(rng.uniform(120, 230))
        repetir(lambda dx, dy: dibujo.ellipse((cx - r + dx, cy - r + dy, cx + r + dx, cy + r + dy), fill=g))
    for i in range(8):
        for j in range(8):
            cx, cy = i * 32 + 16, j * 32 + 16
            dibujo.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=250)
            dibujo.ellipse((cx - 3, cy + 1, cx + 3, cy + 4), fill=80)
    imagen = pinceladas(imagen, 250, 27, (6, 16), (1, 2), lambda r, x, y: -0.7 + r.uniform(-0.2, 0.2),
                        lambda r, x, y: 255, 90)
    return acuarela(suavizar(imagen, 0.9), 0.55, 1.0, 104)


def oro():
    """Oro y bronce: trazos curvos brillantes y huecos oscuros, como dorado a pincel."""
    imagen = gris(0.75 + ruido(2, 15) * 0.2)
    imagen = pinceladas(imagen, 400, 28, (10, 30), (2, 5), lambda r, x, y: math.sin(x / 30) * 0.8,
                        lambda r, x, y: int(r.choice([110, 255, 255])), 90)
    return acuarela(suavizar(imagen, 0.6), 0.6, 1.0, 105)


def tela():
    y, x = np.mgrid[0:LADO, 0:LADO]
    trama = 0.5 + 0.25 * np.sin(x / LADO * 2 * math.pi * 64) + 0.25 * np.sin(y / LADO * 2 * math.pi * 64)
    base = 0.84 + trama * 0.07 + ruido(2, 16) * 0.09
    base = np.where(np.abs((x % 64) - 32) > 29, base * 0.82, base)
    imagen = gris(base)
    imagen = pinceladas(imagen, 160, 29, (30, 80), (6, 14), lambda r, x, y: math.pi / 2 + r.uniform(-0.1, 0.1),
                        lambda r, x, y: int(r.uniform(200, 255)), 45)
    # Remiendos.
    dibujo = ImageDraw.Draw(imagen)
    rng = random.Random(30)
    for _ in range(3):
        cx, cy, w, h = rng.uniform(0, LADO), rng.uniform(0, LADO), rng.uniform(18, 34), rng.uniform(14, 26)
        repetir(lambda dx, dy: dibujo.rectangle((cx + dx, cy + dy, cx + w + dx, cy + h + dy), fill=int(rng.uniform(190, 215)), outline=150))
    return acuarela(suavizar(imagen, 0.5), 0.72, 1.0, 106)


def arena():
    imagen = gris(0.78 + (ruido(2, 5) * 0.5 + ruido(6, 6) * 0.5) * 0.2)
    imagen = pinceladas(imagen, 260, 31, (30, 70), (3, 6), lambda r, x, y: 0.35 + math.sin(y / 40) * 0.15,
                        lambda r, x, y: int(r.uniform(205, 250)), 60)
    imagen = pinceladas(imagen, 500, 32, (2, 4), (2, 4), lambda r, x, y: 0, lambda r, x, y: int(r.uniform(150, 255)), 90)
    # Conchas pequeñas.
    imagen = pinceladas(imagen, 30, 33, (5, 8), (4, 6), lambda r, x, y: r.uniform(0, math.pi), lambda r, x, y: 255, 200, lados=9)
    return acuarela(suavizar(imagen, 0.6), 0.72, 1.0, 107)


def hierba():
    imagen = gris(0.7 + ruido(2, 7) * 0.25)
    imagen = pinceladas(imagen, 70, 41, (40, 90), (25, 50), lambda r, x, y: r.uniform(0, math.pi),
                        lambda r, x, y: int(r.choice([140, 240])), 45)
    imagen = pinceladas(imagen, 1800, 42, (8, 16), (2, 3), lambda r, x, y: -1.2 + r.uniform(-0.4, 0.4),
                        lambda r, x, y: int(r.uniform(130, 255)), 85)
    # Florecitas claras.
    imagen = pinceladas(imagen, 40, 43, (3, 5), (3, 5), lambda r, x, y: 0, lambda r, x, y: 255, 230, lados=8)
    return acuarela(suavizar(imagen, 0.5), 0.66, 1.0, 108)


def roca():
    imagen = gris(0.65 + ruido(2, 9) * 0.3)
    rng = random.Random(51)
    capa = Image.new("LA", (LADO, LADO), (0, 0))
    dibujo = ImageDraw.Draw(capa, "LA")
    for _ in range(45):
        cx, cy, r = rng.uniform(0, LADO), rng.uniform(0, LADO), rng.uniform(20, 46)
        lados = rng.randint(5, 7)
        puntos = [(cx + math.cos(a) * r * rng.uniform(0.7, 1.1), cy + math.sin(a) * r * rng.uniform(0.7, 1.1))
                  for a in sorted(rng.uniform(0, 2 * math.pi) for _ in range(lados))]
        g = int(rng.uniform(150, 240))
        repetir(lambda dx, dy: dibujo.polygon([(px + dx, py + dy) for px, py in puntos], fill=(g, 110), outline=(80, 160)))
    capa = capa.filter(ImageFilter.GaussianBlur(1.0))
    imagen = Image.alpha_composite(imagen.convert("RGBA"), capa.convert("RGBA")).convert("L")
    imagen = pinceladas(imagen, 400, 52, (6, 14), (2, 3), lambda r, x, y: r.uniform(-0.5, 0.5) - 0.8,
                        lambda r, x, y: int(r.uniform(200, 255)), 70)
    return acuarela(suavizar(imagen, 0.7), 0.6, 1.0, 109)


def corteza():
    """Tronco de palmera: anillos horizontales con escamas en diagonal."""
    y, x = np.mgrid[0:LADO, 0:LADO]
    anillos = 0.5 + 0.5 * np.sin(y / LADO * 2 * math.pi * 10 + ruido(1, 17) * 2)
    base = 0.62 + anillos * 0.3
    imagen = gris(base)
    imagen = pinceladas(imagen, 500, 53, (10, 20), (3, 5), lambda r, x, y: 0.6 if int(y / 25.6) % 2 else -0.6,
                        lambda r, x, y: int(r.uniform(120, 230)), 80)
    return acuarela(suavizar(imagen, 0.5), 0.55, 1.0, 110)


def general():
    imagen = gris(0.85 + ruido(2, 18) * 0.12)
    imagen = pinceladas(imagen, 700, 71, (10, 26), (3, 6), lambda r, x, y: r.uniform(0, math.pi),
                        lambda r, x, y: int(r.uniform(195, 255)), 50)
    return acuarela(suavizar(imagen, 0.7), 0.78, 1.0, 111)


TEXTURAS = {"madera": madera, "casco": casco, "pintura": pintura, "metal": metal, "oro": oro, "tela": tela,
            "arena": arena, "hierba": hierba, "roca": roca, "corteza": corteza, "general": general}


if __name__ == "__main__" and not (len(sys.argv) > 2 and sys.argv[2] == "papel"):
    salida = sys.argv[1] if len(sys.argv) > 1 else "."
    for nombre, pintar in TEXTURAS.items():
        imagen = pintar()
        imagen.save(f"{salida}/{nombre}.png", optimize=True)
        rgb = (np.asarray(imagen, dtype=float) / 255) ** 2.2
        media = float((rgb[..., 0] * 0.2126 + rgb[..., 1] * 0.7152 + rgb[..., 2] * 0.0722).mean())
        print(f'"{nombre}": {media:.3f},')


def papel():
    """Grano de papel de acuarela para el filtro de pantalla (gris medio, 0.5 = sin cambio)."""
    base = ruido(4, 19, 3) * 0.5 + ruido(12, 20, 2) * 0.5
    imagen = gris(0.42 + base * 0.16)
    imagen = pinceladas(imagen, 900, 81, (6, 18), (1, 1.6), lambda r, x, y: r.uniform(0, math.pi),
                        lambda r, x, y: int(r.choice([95, 160])), 40)
    return suavizar(imagen, 0.4)


if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[2] == "papel":
    papel().save(f"{sys.argv[1]}/papel.png", optimize=True)
    print("papel")
