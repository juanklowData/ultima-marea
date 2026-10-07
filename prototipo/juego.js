// Última Marea: prototipo de battle royale naval.
// Un archivo, sin motor. Abre index.html en el navegador.

const TIPOS = {
  balandro: { nombre: "Balandro", hp: 78, velocidad: 188, color: "#a56b45" },
  bergantin: { nombre: "Bergantín", hp: 100, velocidad: 156, color: "#8d5a38" },
  galeon: { nombre: "Galeón", hp: 142, velocidad: 118, color: "#5c3d2e" },
};

const FASES = [
  { dur: 22, radio: 1280 },
  { dur: 18, radio: 960 },
  { dur: 16, radio: 680 },
  { dur: 14, radio: 430 },
  { dur: 18, radio: 230 },
];

const MUNDO = 1880;
const ZOOM = 1.85;
const DANIO_BALA = 11;
const RECARGA = 0.82;

const canvas = document.getElementById("mar");
const ctx = canvas.getContext("2d");
const hud = document.getElementById("hud");
const controles = document.getElementById("controles");
const menu = document.getElementById("menu");
const finalPanel = document.getElementById("final");
const vidaBarra = document.getElementById("vida");
const vivosTxt = document.getElementById("vivos");
const tormentaTxt = document.getElementById("tormenta");
const joystick = document.getElementById("joystick");
const knob = document.getElementById("knob");
const fuegoBtn = document.getElementById("fuego");

const islotesBase = [
  { x: 240, y: -340, r: 78 },
  { x: -520, y: 220, r: 96 },
  { x: 640, y: 380, r: 64 },
  { x: -180, y: -760, r: 84 },
  { x: 860, y: -180, r: 58 },
  { x: -780, y: -420, r: 70 },
];

const estado = {
  modo: "menu",
  naves: [],
  balas: [],
  barriles: [],
  estelas: [],
  salpicaduras: [],
  islotes: [],
  espuma: [],
  zona: { x: 0, y: 0, r: 1600, desde: 1600, fase: 0, edad: 0 },
  cam: { x: 0, y: 0 },
  jugador: null,
  stick: { x: 0, y: 0, activo: false, teclas: false },
  teclas: {},
  fuego: false,
  cierre: 0,
  resultado: "",
  golpe: 0,
  tiempo: 0,
  fuegoBoton: false,
  w: 1,
  h: 1,
};

for (let i = 0; i < 70; i += 1) {
  estado.espuma.push({
    x: (Math.random() - 0.5) * MUNDO * 2,
    y: (Math.random() - 0.5) * MUNDO * 2,
    r: 2 + Math.random() * 5,
  });
}

function anguloDelta(a, b) {
  let d = b - a;
  d = ((d + Math.PI) % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2) - Math.PI;
  return d;
}

function girarHacia(actual, destino, maximo) {
  const d = anguloDelta(actual, destino);
  if (Math.abs(d) <= maximo) return destino;
  return actual + Math.sign(d) * maximo;
}

function crearNave(id, x, y, tipo, esJugador) {
  const datos = TIPOS[tipo];
  return {
    id,
    x,
    y,
    angulo: Math.random() * Math.PI * 2,
    velocidad: 0,
    acelerador: 0,
    hp: datos.hp,
    hpMax: datos.hp,
    velMax: datos.velocidad,
    color: datos.color,
    jugador: esJugador,
    viva: true,
    hundiendose: 0,
    recarga: esJugador ? 0.15 : 1.6,
    deriva: Math.random() * Math.PI * 2,
    estela: 0,
  };
}

function puntoLibre(radioMin, radioMax) {
  for (let intento = 0; intento < 50; intento += 1) {
    const ang = Math.random() * Math.PI * 2;
    const radio = radioMin + Math.random() * (radioMax - radioMin);
    const x = Math.cos(ang) * radio;
    const y = Math.sin(ang) * radio;
    const chocaIslote = estado.islotes.some((isla) => Math.hypot(x - isla.x, y - isla.y) < isla.r + 50);
    const chocaNave = estado.naves.some((nave) => Math.hypot(x - nave.x, y - nave.y) < 220);
    if (!chocaIslote && !chocaNave) return { x, y };
  }
  return { x: 0, y: 0 };
}

function prepararMar() {
  estado.islotes = islotesBase.map((isla) => ({
    x: isla.x + (Math.random() - 0.5) * 70,
    y: isla.y + (Math.random() - 0.5) * 70,
    r: isla.r,
  }));
  estado.naves = [];
  estado.balas = [];
  estado.barriles = [];
  estado.estelas = [];
  estado.salpicaduras = [];
  estado.cierre = 0;
  estado.resultado = "";
  estado.golpe = 0;
  estado.zona = { x: 0, y: 0, r: 1580, desde: 1580, fase: 0, edad: 0 };

  const spawnJugador = puntoLibre(180, 360);
  estado.jugador = crearNave(0, spawnJugador.x, spawnJugador.y, "bergantin", true);
  estado.naves.push(estado.jugador);

  const tiposRival = ["balandro", "bergantin", "galeon"];
  for (let i = 1; i < 12; i += 1) {
    const punto = puntoLibre(1050, 1420);
    const tipo = tiposRival[i % tiposRival.length];
    estado.naves.push(crearNave(i, punto.x, punto.y, tipo, false));
  }

  for (let i = 0; i < 7; i += 1) soltarBarril();
  estado.cam.x = estado.jugador.x;
  estado.cam.y = estado.jugador.y;
}

function soltarBarril() {
  for (let intento = 0; intento < 20; intento += 1) {
    const ang = Math.random() * Math.PI * 2;
    const radio = Math.random() * Math.max(120, estado.zona.r * 0.75);
    const x = estado.zona.x + Math.cos(ang) * radio;
    const y = estado.zona.y + Math.sin(ang) * radio;
    const enIsla = estado.islotes.some((isla) => Math.hypot(x - isla.x, y - isla.y) < isla.r + 24);
    const enNave = estado.naves.some((nave) => nave.viva && Math.hypot(x - nave.x, y - nave.y) < 56);
    if (!enIsla && !enNave) {
      estado.barriles.push({ x, y });
      return;
    }
  }
}

function disparar(nave) {
  if (!nave.viva || nave.recarga > 0) return;
  nave.recarga = RECARGA;
  for (let i = -1; i <= 1; i += 1) {
    const ang = nave.angulo + i * 0.09;
    const rapidez = 390;
    estado.balas.push({
      x: nave.x + Math.sin(nave.angulo) * 28,
      y: nave.y - Math.cos(nave.angulo) * 28,
      vx: Math.sin(ang) * rapidez + Math.sin(nave.angulo) * nave.velocidad * 0.2,
      vy: -Math.cos(ang) * rapidez - Math.cos(nave.angulo) * nave.velocidad * 0.2,
      vida: 0.95,
      dueno: nave.id,
      gracia: 0.12,
    });
  }
}

function salpicar(x, y, cantidad) {
  for (let i = 0; i < cantidad; i += 1) {
    const ang = Math.random() * Math.PI * 2;
    const rapidez = 30 + Math.random() * 90;
    estado.salpicaduras.push({
      x,
      y,
      vx: Math.cos(ang) * rapidez,
      vy: Math.sin(ang) * rapidez,
      vida: 0.35 + Math.random() * 0.2,
    });
  }
}

function hundir(nave) {
  if (!nave.viva) return;
  nave.viva = false;
  nave.hp = 0;
  salpicar(nave.x, nave.y, 16);
}

function rivalMasCercano(nave) {
  let mejor = null;
  let mejorDist = Infinity;
  for (const otra of estado.naves) {
    if (!otra.viva || otra === nave) continue;
    const dist = Math.hypot(otra.x - nave.x, otra.y - nave.y);
    if (dist < mejorDist) {
      mejor = otra;
      mejorDist = dist;
    }
  }
  return mejor;
}

function barrilCercano(nave) {
  let mejor = null;
  let mejorDist = Infinity;
  for (const barril of estado.barriles) {
    const dist = Math.hypot(barril.x - nave.x, barril.y - nave.y);
    if (dist < mejorDist) {
      mejor = barril;
      mejorDist = dist;
    }
  }
  return mejorDist < 760 ? mejor : null;
}

function moverNave(nave, dt) {
  if (!nave.viva) {
    nave.hundiendose = Math.min(1, nave.hundiendose + dt * 0.8);
    return;
  }

  nave.recarga = Math.max(0, nave.recarga - dt);
  nave.deriva += dt * 0.7;

  if (nave.jugador) {
    if (estado.stick.activo) {
      const deseo = Math.atan2(estado.stick.x, -estado.stick.y);
      const fuerza = Math.min(1, Math.hypot(estado.stick.x, estado.stick.y));
      const giro = 2.8 * (0.42 + 0.58 * (1 - nave.velocidad / nave.velMax));
      nave.angulo = girarHacia(nave.angulo, deseo, giro * dt);
      nave.acelerador = fuerza;
    } else {
      nave.acelerador = 0;
    }
    if (estado.fuego) disparar(nave);
  } else {
    pilotarRival(nave, dt);
  }

  const meta = nave.acelerador * nave.velMax;
  nave.velocidad += (meta - nave.velocidad) * Math.min(1, dt * 1.7);
  nave.x += Math.sin(nave.angulo) * nave.velocidad * dt;
  nave.y -= Math.cos(nave.angulo) * nave.velocidad * dt;

  const lejos = Math.hypot(nave.x, nave.y);
  if (lejos > MUNDO) {
    nave.x = (nave.x / lejos) * MUNDO;
    nave.y = (nave.y / lejos) * MUNDO;
  }

  for (const isla of estado.islotes) {
    const dx = nave.x - isla.x;
    const dy = nave.y - isla.y;
    const dist = Math.hypot(dx, dy) || 1;
    const minimo = isla.r + 18;
    if (dist < minimo) {
      nave.x = isla.x + (dx / dist) * minimo;
      nave.y = isla.y + (dy / dist) * minimo;
    }
  }

  const distZona = Math.hypot(nave.x - estado.zona.x, nave.y - estado.zona.y);
  if (distZona > estado.zona.r) {
    const profundidad = (distZona - estado.zona.r) / 180;
    nave.hp -= (12 + profundidad * 22) * dt;
    if (nave.jugador) estado.golpe = Math.max(estado.golpe, 0.05);
  }

  nave.estela -= dt;
  if (nave.velocidad > 36 && nave.estela <= 0) {
    nave.estela = 0.05;
    estado.estelas.push({
      x: nave.x - Math.sin(nave.angulo) * 18,
      y: nave.y + Math.cos(nave.angulo) * 18,
      vida: 0.7,
      angulo: nave.angulo,
    });
  }

  if (nave.hp <= 0) hundir(nave);
}

function pilotarRival(nave, dt) {
  const distZona = Math.hypot(nave.x - estado.zona.x, nave.y - estado.zona.y);
  let destinoX = estado.zona.x;
  let destinoY = estado.zona.y;
  let blanco = null;

  if (distZona > estado.zona.r - 130) {
    destinoX = estado.zona.x;
    destinoY = estado.zona.y;
  } else if (nave.hp < nave.hpMax * 0.48) {
    const barril = barrilCercano(nave);
    if (barril) {
      destinoX = barril.x;
      destinoY = barril.y;
    } else {
      blanco = rivalMasCercano(nave);
    }
  } else {
    blanco = rivalMasCercano(nave);
  }

  if (blanco) {
    const dist = Math.hypot(blanco.x - nave.x, blanco.y - nave.y);
    const adelanto = dist / 390;
    const px = blanco.x + Math.sin(blanco.angulo) * blanco.velocidad * adelanto * 0.85;
    const py = blanco.y - Math.cos(blanco.angulo) * blanco.velocidad * adelanto * 0.85;
    if (dist < 150) {
      destinoX = nave.x - (px - nave.x);
      destinoY = nave.y - (py - nave.y);
    } else {
      destinoX = px;
      destinoY = py;
    }
    if (dist < 400 && dist > 80) {
      const punteria = Math.atan2(px - nave.x, -(py - nave.y));
      if (Math.abs(anguloDelta(nave.angulo, punteria)) < 0.22) disparar(nave);
    }
  }

  let deseo = Math.atan2(destinoX - nave.x, -(destinoY - nave.y));
  deseo += Math.sin(nave.deriva) * 0.18;
  const giro = nave.velocidad > nave.velMax * 0.75 ? 1.55 : 2.25;
  nave.angulo = girarHacia(nave.angulo, deseo, giro * dt);
  nave.acelerador = 1;
}

function separarNaves() {
  for (let i = 0; i < estado.naves.length; i += 1) {
    const a = estado.naves[i];
    if (!a.viva) continue;
    for (let j = i + 1; j < estado.naves.length; j += 1) {
      const b = estado.naves[j];
      if (!b.viva) continue;
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const dist = Math.hypot(dx, dy) || 1;
      const minimo = 34;
      if (dist < minimo) {
        const empuje = (minimo - dist) / 2;
        const nx = dx / dist;
        const ny = dy / dist;
        a.x -= nx * empuje;
        a.y -= ny * empuje;
        b.x += nx * empuje;
        b.y += ny * empuje;
      }
    }
  }
}

function recogerBarriles() {
  estado.barriles = estado.barriles.filter((barril) => {
    for (const nave of estado.naves) {
      if (!nave.viva) continue;
      if (Math.hypot(nave.x - barril.x, nave.y - barril.y) < 30) {
        nave.hp = Math.min(nave.hpMax, nave.hp + 28);
        salpicar(barril.x, barril.y, 6);
        return false;
      }
    }
    return true;
  });
  while (estado.barriles.length < 7 && estado.modo === "play") {
    const antes = estado.barriles.length;
    soltarBarril();
    if (estado.barriles.length === antes) break;
  }
}

function moverBalas(dt) {
  for (const bala of estado.balas) {
    bala.x += bala.vx * dt;
    bala.y += bala.vy * dt;
    bala.vida -= dt;
    bala.gracia -= dt;

    for (const isla of estado.islotes) {
      if (Math.hypot(bala.x - isla.x, bala.y - isla.y) < isla.r) {
        bala.vida = 0;
        salpicar(bala.x, bala.y, 4);
      }
    }

    if (bala.vida <= 0) continue;
    for (const nave of estado.naves) {
      if (!nave.viva) continue;
      if (nave.id === bala.dueno && bala.gracia > 0) continue;
      if (Math.hypot(nave.x - bala.x, nave.y - bala.y) < 24) {
        nave.hp -= DANIO_BALA;
        bala.vida = 0;
        salpicar(bala.x, bala.y, 7);
        if (nave.jugador) estado.golpe = 0.18;
        if (nave.hp <= 0) hundir(nave);
        break;
      }
    }
  }
  estado.balas = estado.balas.filter((bala) => bala.vida > 0);
}

function moverZona(dt) {
  const fase = FASES[Math.min(estado.zona.fase, FASES.length - 1)];
  estado.zona.edad += dt;
  const t = Math.min(1, estado.zona.edad / fase.dur);
  estado.zona.r = estado.zona.desde + (fase.radio - estado.zona.desde) * t;
  if (estado.zona.edad >= fase.dur && estado.zona.fase < FASES.length - 1) {
    estado.zona.fase += 1;
    estado.zona.edad = 0;
    estado.zona.desde = estado.zona.r;
    const ang = Math.random() * Math.PI * 2;
    const corrimiento = 160;
    estado.zona.x = Math.max(-420, Math.min(420, estado.zona.x + Math.cos(ang) * corrimiento));
    estado.zona.y = Math.max(-420, Math.min(420, estado.zona.y + Math.sin(ang) * corrimiento));
  }
}

function revisarFin(dt) {
  if (estado.cierre > 0) {
    estado.cierre -= dt;
    if (estado.cierre <= 0) {
      estado.modo = "end";
      const titulo = document.getElementById("final-titulo");
      const texto = document.getElementById("final-texto");
      if (estado.resultado === "victoria") {
        titulo.textContent = "Victoria";
        texto.textContent = "Tu barco quedó solo en el mar.";
      } else {
        titulo.textContent = "Hundido";
        texto.textContent = "La marea se quedó con tu barco.";
      }
      sincronizarPantallas();
    }
    return;
  }

  const vivos = estado.naves.filter((nave) => nave.viva);
  if (!estado.jugador.viva) {
    estado.resultado = "hundido";
    estado.cierre = 0.85;
  } else if (vivos.length === 1) {
    estado.resultado = "victoria";
    estado.cierre = 0.7;
  }
}

function actualizar(dt) {
  leerTeclas();
  moverZona(dt);
  for (const nave of estado.naves) moverNave(nave, dt);
  separarNaves();
  recogerBarriles();
  moverBalas(dt);

  for (const estela of estado.estelas) estela.vida -= dt;
  estado.estelas = estado.estelas.filter((estela) => estela.vida > 0);
  for (const splash of estado.salpicaduras) {
    splash.x += splash.vx * dt;
    splash.y += splash.vy * dt;
    splash.vida -= dt;
  }
  estado.salpicaduras = estado.salpicaduras.filter((splash) => splash.vida > 0);

  const jugador = estado.jugador;
  estado.cam.x += (jugador.x - estado.cam.x) * Math.min(1, dt * 4.2);
  estado.cam.y += (jugador.y - estado.cam.y) * Math.min(1, dt * 4.2);
  estado.golpe = Math.max(0, estado.golpe - dt);
  revisarFin(dt);
  pintarHud();
}

function leerTeclas() {
  let x = 0;
  let y = 0;
  if (estado.teclas.left) x -= 1;
  if (estado.teclas.right) x += 1;
  if (estado.teclas.up) y -= 1;
  if (estado.teclas.down) y += 1;
  const fuerza = Math.hypot(x, y);
  if (fuerza > 0) {
    estado.stick.x = x / fuerza;
    estado.stick.y = y / fuerza;
    estado.stick.activo = true;
    estado.stick.teclas = true;
  } else if (estado.stick.teclas) {
    estado.stick.x = 0;
    estado.stick.y = 0;
    estado.stick.activo = false;
    estado.stick.teclas = false;
  }
  estado.fuego = Boolean(estado.teclas.space || estado.fuegoBoton);
  colocarPomo();
}

function pintarHud() {
  const jugador = estado.jugador;
  const vivos = estado.naves.filter((nave) => nave.viva).length;
  const fase = FASES[Math.min(estado.zona.fase, FASES.length - 1)];
  const restante = Math.max(0, Math.ceil(fase.dur - estado.zona.edad));
  const afuera = Math.hypot(jugador.x - estado.zona.x, jugador.y - estado.zona.y) > estado.zona.r;
  vidaBarra.style.width = `${Math.max(0, (jugador.hp / jugador.hpMax) * 100)}%`;
  vivosTxt.textContent = `A flote: ${vivos}`;
  tormentaTxt.textContent = afuera ? "Estás en la tormenta" : `Tormenta: ${restante}s`;
}

function ajustarLienzo() {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  estado.w = canvas.clientWidth || window.innerWidth;
  estado.h = canvas.clientHeight || window.innerHeight;
  canvas.width = Math.floor(estado.w * dpr);
  canvas.height = Math.floor(estado.h * dpr);
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}

function dibujarMar() {
  const { w, h, cam } = estado;
  const cielo = ctx.createLinearGradient(0, 0, 0, h);
  cielo.addColorStop(0, "#8fd0c6");
  cielo.addColorStop(0.45, "#3aa7ab");
  cielo.addColorStop(1, "#1f7f8c");
  ctx.fillStyle = cielo;
  ctx.fillRect(0, 0, w, h);

  const bruma = ctx.createRadialGradient(w * 0.15, h * 0.2, 20, w * 0.2, h * 0.25, w * 0.7);
  bruma.addColorStop(0, "rgba(255, 214, 150, 0.18)");
  bruma.addColorStop(1, "rgba(255, 214, 150, 0)");
  ctx.fillStyle = bruma;
  ctx.fillRect(0, 0, w, h);

  ctx.save();
  ctx.translate(w / 2, h / 2);
  ctx.scale(ZOOM, ZOOM);
  ctx.translate(-cam.x, -cam.y);

  ctx.strokeStyle = "rgba(255,255,255,0.07)";
  ctx.lineWidth = 2;
  const mitadAncho = w / (2 * ZOOM);
  const mitadAlto = h / (2 * ZOOM);
  const izquierda = cam.x - mitadAncho - 40;
  const arriba = cam.y - mitadAlto - 40;
  for (let fila = 0; fila < 16; fila += 1) {
    const yBase = arriba + fila * (h / 12);
    ctx.beginPath();
    for (let x = izquierda; x < cam.x + mitadAncho + 40; x += 24) {
      const y = yBase + Math.sin(x * 0.012 + estado.tiempo * 1.4 + fila) * 7;
      if (x === izquierda) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();
  }

  for (const punto of estado.espuma) {
    ctx.fillStyle = "rgba(255,255,255,0.22)";
    ctx.beginPath();
    ctx.ellipse(punto.x, punto.y, punto.r * 1.8, punto.r, 0, 0, Math.PI * 2);
    ctx.fill();
  }

  for (const isla of estado.islotes) {
    ctx.beginPath();
    ctx.arc(isla.x, isla.y, isla.r, 0, Math.PI * 2);
    ctx.fillStyle = "#1b6d62";
    ctx.fill();
    ctx.lineWidth = 7;
    ctx.strokeStyle = "#e6d3ae";
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(isla.x - isla.r * 0.15, isla.y - isla.r * 0.12, isla.r * 0.42, 0, Math.PI * 2);
    ctx.fillStyle = "#2f8f78";
    ctx.fill();
  }

  for (const barril of estado.barriles) {
    ctx.save();
    ctx.translate(barril.x, barril.y);
    ctx.fillStyle = "#8a5a32";
    ctx.beginPath();
    ctx.ellipse(0, 0, 11, 8, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#e6d2a8";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(-8, 0);
    ctx.lineTo(8, 0);
    ctx.stroke();
    ctx.restore();
  }

  for (const estela of estado.estelas) {
    ctx.globalAlpha = Math.max(0, estela.vida);
    ctx.strokeStyle = "rgba(255,255,255,0.55)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(estela.x, estela.y);
    ctx.lineTo(estela.x - Math.sin(estela.angulo) * 16, estela.y + Math.cos(estela.angulo) * 16);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }

  for (const bala of estado.balas) {
    ctx.strokeStyle = "rgba(255,255,255,0.85)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(bala.x, bala.y);
    ctx.lineTo(bala.x - bala.vx * 0.045, bala.y - bala.vy * 0.045);
    ctx.stroke();
    ctx.fillStyle = "#243038";
    ctx.beginPath();
    ctx.arc(bala.x, bala.y, 3.2, 0, Math.PI * 2);
    ctx.fill();
  }

  const navesOrden = [...estado.naves].sort((a, b) => a.y - b.y);
  for (const nave of navesOrden) dibujarNave(nave);

  for (const splash of estado.salpicaduras) {
    ctx.globalAlpha = Math.max(0, splash.vida * 2);
    ctx.fillStyle = "rgba(255,255,255,0.8)";
    ctx.beginPath();
    ctx.arc(splash.x, splash.y, 3, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
  }

  ctx.beginPath();
  const margen = 280;
  ctx.rect(cam.x - mitadAncho - margen, cam.y - mitadAlto - margen, mitadAncho * 2 + margen * 2, mitadAlto * 2 + margen * 2);
  ctx.arc(estado.zona.x, estado.zona.y, estado.zona.r, 0, Math.PI * 2, true);
  ctx.fillStyle = "rgba(8, 30, 58, 0.4)";
  ctx.fill("evenodd");

  ctx.beginPath();
  ctx.arc(estado.zona.x, estado.zona.y, estado.zona.r, 0, Math.PI * 2);
  ctx.strokeStyle = "rgba(255, 244, 214, 0.9)";
  ctx.lineWidth = 4;
  ctx.stroke();

  ctx.restore();
}

function dibujarNave(nave) {
  ctx.save();
  ctx.translate(nave.x, nave.y);
  ctx.rotate(nave.angulo);
  ctx.scale(1.2, 1.2);
  const hundida = nave.hundiendose;
  ctx.globalAlpha = 1 - hundida * 0.75;
  ctx.scale(1 - hundida * 0.35, 1 - hundida * 0.35);

  ctx.fillStyle = "rgba(0,0,0,0.18)";
  ctx.beginPath();
  ctx.ellipse(0, 16, 14, 7, 0, 0, Math.PI * 2);
  ctx.fill();

  ctx.beginPath();
  ctx.moveTo(0, -34);
  ctx.lineTo(11, -10);
  ctx.lineTo(13, 12);
  ctx.lineTo(7, 22);
  ctx.lineTo(-7, 22);
  ctx.lineTo(-13, 12);
  ctx.lineTo(-11, -10);
  ctx.closePath();
  ctx.fillStyle = nave.jugador ? "#d4894a" : nave.color;
  ctx.fill();
  ctx.strokeStyle = "rgba(40, 22, 12, 0.35)";
  ctx.lineWidth = 1.5;
  ctx.stroke();

  ctx.fillStyle = nave.jugador ? "#3e86d0" : "#f3ecdf";
  ctx.beginPath();
  ctx.moveTo(0, -2);
  ctx.quadraticCurveTo(16, 2, 0, 12);
  ctx.closePath();
  ctx.fill();

  ctx.strokeStyle = "#3b291c";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(0, -1);
  ctx.lineTo(0, 10);
  ctx.stroke();

  if (nave.jugador) {
    ctx.fillStyle = "#1b1b1b";
    ctx.fillRect(-1, -26, 2, 8);
    ctx.beginPath();
    ctx.moveTo(1, -26);
    ctx.lineTo(11, -23);
    ctx.lineTo(1, -19);
    ctx.fill();
  }

  ctx.restore();

  if (!nave.viva) return;
  const ancho = 36;
  ctx.fillStyle = "rgba(0,0,0,0.4)";
  ctx.fillRect(nave.x - ancho / 2, nave.y - 40, ancho, 5);
  ctx.fillStyle = nave.jugador ? "#3dde7a" : "#e23d3d";
  ctx.fillRect(nave.x - ancho / 2, nave.y - 40, ancho * Math.max(0, nave.hp / nave.hpMax), 5);
}

function dibujarMinimapa() {
  const radio = 58;
  const cx = estado.w - radio - 18;
  const cy = radio + 16;
  const escala = radio / MUNDO;
  const dpr = Math.min(window.devicePixelRatio || 1, 2);

  ctx.save();
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.beginPath();
  ctx.arc(cx, cy, radio, 0, Math.PI * 2);
  ctx.clip();
  ctx.fillStyle = "#0e2f38";
  ctx.fillRect(cx - radio, cy - radio, radio * 2, radio * 2);

  ctx.beginPath();
  ctx.arc(cx + estado.zona.x * escala, cy + estado.zona.y * escala, Math.max(4, estado.zona.r * escala), 0, Math.PI * 2);
  ctx.fillStyle = "#1f7f86";
  ctx.fill();
  ctx.strokeStyle = "rgba(255,244,214,0.95)";
  ctx.lineWidth = 2;
  ctx.stroke();

  for (const nave of estado.naves) {
    if (!nave.viva) continue;
    ctx.fillStyle = nave.jugador ? "#7dffb2" : "#ffd8b0";
    ctx.fillRect(cx + nave.x * escala - 2, cy + nave.y * escala - 2, 4, 4);
  }
  ctx.restore();

  ctx.beginPath();
  ctx.arc(cx, cy, radio, 0, Math.PI * 2);
  ctx.strokeStyle = "rgba(255,248,230,0.95)";
  ctx.lineWidth = 3;
  ctx.stroke();
}

function dibujar() {
  ajustarLienzo();
  dibujarMar();
  if (estado.modo !== "menu") dibujarMinimapa();

  if (estado.golpe > 0) {
    ctx.fillStyle = `rgba(180, 30, 30, ${estado.golpe})`;
    ctx.fillRect(0, 0, estado.w, estado.h);
  }

  if (estado.modo === "play" && estado.jugador) {
    const afuera = Math.hypot(estado.jugador.x - estado.zona.x, estado.jugador.y - estado.zona.y) > estado.zona.r;
    if (afuera) {
      ctx.fillStyle = "rgba(18, 42, 82, 0.22)";
      ctx.fillRect(0, 0, estado.w, estado.h);
    }
  }
}

function sincronizarPantallas() {
  menu.hidden = estado.modo !== "menu";
  finalPanel.hidden = estado.modo !== "end";
  controles.hidden = estado.modo !== "play";
  hud.hidden = estado.modo === "menu";
}

function zarpar() {
  prepararMar();
  estado.modo = "play";
  sincronizarPantallas();
  pintarHud();
}

function colocarPomo() {
  const max = 34;
  const x = estado.stick.x * max;
  const y = estado.stick.y * max;
  knob.style.transform = `translate(calc(-50% + ${x}px), calc(-50% + ${y}px))`;
}

function vectorPalanca(evento) {
  const rect = joystick.getBoundingClientRect();
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  const dx = evento.clientX - cx;
  const dy = evento.clientY - cy;
  const max = rect.width * 0.34;
  const dist = Math.hypot(dx, dy) || 1;
  const usado = Math.min(max, dist);
  estado.stick.x = (dx / dist) * (usado / max);
  estado.stick.y = (dy / dist) * (usado / max);
  estado.stick.activo = true;
  estado.stick.teclas = false;
  colocarPomo();
}

function soltarPalanca() {
  if (estado.stick.teclas) return;
  estado.stick.x = 0;
  estado.stick.y = 0;
  estado.stick.activo = false;
  colocarPomo();
}

joystick.addEventListener("pointerdown", (evento) => {
  joystick.setPointerCapture(evento.pointerId);
  vectorPalanca(evento);
});
joystick.addEventListener("pointermove", (evento) => {
  if (joystick.hasPointerCapture(evento.pointerId)) vectorPalanca(evento);
});
joystick.addEventListener("pointerup", soltarPalanca);
joystick.addEventListener("pointercancel", soltarPalanca);

function pulsarFuego(activo) {
  estado.fuegoBoton = activo;
}
fuegoBtn.addEventListener("pointerdown", (evento) => {
  evento.preventDefault();
  pulsarFuego(true);
});
fuegoBtn.addEventListener("pointerup", () => pulsarFuego(false));
fuegoBtn.addEventListener("pointerleave", () => pulsarFuego(false));
fuegoBtn.addEventListener("pointercancel", () => pulsarFuego(false));

const mapaTeclas = {
  arrowleft: "left",
  arrowright: "right",
  arrowup: "up",
  arrowdown: "down",
  a: "left",
  d: "right",
  w: "up",
  s: "down",
  " ": "space",
};

window.addEventListener("keydown", (evento) => {
  const accion = mapaTeclas[evento.key.toLowerCase()];
  if (!accion) return;
  evento.preventDefault();
  estado.teclas[accion] = true;
  if (accion === "space" && estado.modo === "menu") zarpar();
});
window.addEventListener("keyup", (evento) => {
  const accion = mapaTeclas[evento.key.toLowerCase()];
  if (!accion) return;
  estado.teclas[accion] = false;
});

document.getElementById("zarpar").addEventListener("click", zarpar);
document.getElementById("otra").addEventListener("click", zarpar);

window.addEventListener("resize", ajustarLienzo);
window.addEventListener("contextmenu", (evento) => evento.preventDefault());

let ultimo = performance.now();
function cuadro(ahora) {
  const dt = Math.min(0.033, (ahora - ultimo) / 1000 || 0);
  ultimo = ahora;
  estado.tiempo += dt;
  if (estado.modo === "play") actualizar(dt);
  else if (estado.modo === "end") {
    estado.golpe = Math.max(0, estado.golpe - dt);
  }
  dibujar();
  requestAnimationFrame(cuadro);
}

sincronizarPantallas();
requestAnimationFrame(cuadro);
