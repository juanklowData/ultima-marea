shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec2 zona_centro = vec2(0.0);
uniform float zona_radio = 80.0;
uniform float tiempo = 0.0;
// Distancia de la orilla en el plano, de 0 (centro) a 1 (borde).
uniform float orilla = 0.66;
// Parte del radio que llega a la orilla en cada ángulo (igual que Circulo.forma).
uniform float forma[64];

varying float altura;
varying vec2 local_xz;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Debe coincidir con agua.gdshader para que la espuma quede pegada al agua.
float ola(vec2 p, vec2 dir, float largo, float amp, float t) {
	float k = 6.2831853 / largo;
	float s = sin(dot(normalize(dir), p) * k - sqrt(9.8 * k) * t);
	return amp * (2.0 * pow(0.5 + 0.5 * s, 1.8) - 0.6);
}

float altura_mar(vec2 p, float t) {
	float fuera = smoothstep(zona_radio, zona_radio + 8.0, length(p - zona_centro));
	float h = ola(p, vec2(1.0, 0.3), 14.0, 0.12, t)
		+ ola(p, vec2(-0.4, 1.0), 9.0, 0.08, t)
		+ ola(p, vec2(0.7, -0.7), 6.0, 0.05, t)
		+ ola(p, vec2(-0.8, -0.35), 4.3, 0.04, t);
	return h * (1.0 + fuera * 2.0) + ola(p, vec2(0.2, 1.0), 21.0, 0.35, t) * fuera;
}

void vertex() {
	local_xz = VERTEX.xz;
	vec3 mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	altura = altura_mar(mundo.xz, tiempo);
	VERTEX.y += altura + 0.03;
}

float contorno(vec2 dir, float semilla, float escala, float velocidad) {
	return ruido(dir * escala + vec2(semilla, semilla * 0.7) + vec2(tiempo * velocidad, -tiempo * velocidad * 0.6));
}

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float d = length(c);
	vec2 dir = c / max(d, 0.0001);
	vec3 centro = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float semilla = hash(floor(centro.xz)) * 50.0;
	float t = tiempo;

	float u = fract(atan(local_xz.y, local_xz.x) / 6.2831853) * 64.0;
	int i = int(floor(u)) % 64;
	float perfil = mix(forma[i], forma[(i + 1) % 64], fract(u));
	float borde = orilla * perfil + (contorno(dir, semilla, 3.0, 0.05) - 0.5) * 0.06;
	float fuera = d - borde;
	if (fuera < -0.03 || d > 1.0) {
		discard;
	}

	// Agua clara poco profunda junto a la arena.
	float bajio = (1.0 - smoothstep(0.0, 0.25, fuera)) * 0.55;
	vec3 color = vec3(0.35, 0.8, 0.78);
	float alfa = bajio;

	// Espuma pegada a la orilla que respira con el oleaje.
	float pulso = 0.5 + 0.5 * sin(t * 1.6 + semilla);
	float grueso = 0.035 + 0.03 * pulso;
	float rotura = smoothstep(0.25, 0.6, contorno(dir, semilla + 9.0, 7.0, 0.25));
	float linea = (1.0 - smoothstep(grueso * 0.4, grueso, abs(fuera - 0.005))) * (0.55 + 0.45 * rotura);

	// Olas que nacen en la orilla y se alejan deshaciéndose.
	float olas = 0.0;
	for (int i = 0; i < 3; i++) {
		float fase = fract(t * 0.28 + float(i) / 3.0 + semilla * 0.13);
		float radio = 0.02 + fase * 0.28;
		float ancho = 0.016 + fase * 0.016;
		float trozos = smoothstep(0.35 + fase * 0.3, 0.75, contorno(dir, semilla + float(i) * 17.0, 6.0, 0.1));
		float anillo = 1.0 - smoothstep(0.0, ancho, abs(fuera - radio));
		olas += anillo * trozos * (1.0 - fase) * (1.0 - fase);
	}

	float espuma = clamp(linea + olas, 0.0, 1.0);
	color = mix(color, vec3(0.96, 0.98, 1.0), espuma);
	alfa = max(alfa, espuma * 0.9);
	alfa *= 1.0 - smoothstep(0.85, 1.0, d);
	alfa *= smoothstep(-0.03, 0.0, fuera);

	ALBEDO = color;
	ALPHA = alfa;
}
