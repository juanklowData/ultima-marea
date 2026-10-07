shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec2 zona_centro = vec2(0.0);
uniform float zona_radio = 80.0;
uniform float tiempo = 0.0;
uniform vec2 centro = vec2(0.0);
uniform float radio = 8.0;
uniform float profundidad = 1.8;
// 1 o -1: sentido de giro. Debe coincidir con el arrastre de Peligros.
uniform float giro = 1.0;
uniform float fuerza = 1.0;

varying vec2 plano;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * ruido(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

// Debe coincidir con agua.gdshader para que el remolino quede pegado al agua.
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

vec2 girar(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

void vertex() {
	vec3 mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float d = length(mundo.xz - centro) / radio;
	float k = clamp(1.0 - (sqrt(d * d + 0.0225) - 0.15) / 0.8662, 0.0, 1.0);
	float h = altura_mar(mundo.xz, tiempo) * (1.0 - 0.6 * smoothstep(0.0, 1.0, k)) - profundidad * pow(k, 2.4);
	VERTEX.y += h + 0.05 + 0.1 * k;
	plano = mundo.xz;
}

void fragment() {
	vec2 rel = plano - centro;
	float d = length(rel) / radio;
	if (d > 1.0) {
		discard;
	}
	float t = tiempo;
	float ang = atan(rel.y, rel.x);
	float ld = log(max(d, 0.015));
	vec2 unidad = rel / radio;

	// Todo gira en bloque, pero torcido en espiral logarítmica: a la vista el agua
	// da vueltas y a la vez cae hacia el centro, sin estirarse con el tiempo.
	float brazos = 5.0;
	float espiral = sin(brazos * (ang - giro * 0.9 * t) - giro * 7.0 * ld) * 0.65
		+ sin(3.0 * (ang - giro * 0.7 * t) - giro * 5.0 * ld + 1.3) * 0.35;
	float n1 = fbm(girar(unidad, giro * (1.0 * t + 1.3 * ld)) * 4.0 + 5.0);
	float n2 = fbm(girar(unidad, giro * (1.7 * t + 2.3 * ld)) * 9.0 + 3.1);
	float n3 = ruido(girar(unidad, giro * (0.6 * t + 0.8 * ld)) * 14.0);

	float banda = 0.5 + 0.5 * espiral;
	float arcos = smoothstep(0.52, 0.9, banda + (n1 - 0.5) * 0.75);
	float vetas = smoothstep(0.6, 0.78, n2) * 0.55 + smoothstep(0.72, 0.9, n3) * 0.25;
	float zona_espuma = smoothstep(0.05, 0.3, d) * (1.0 - smoothstep(0.8, 1.0, d));
	float espuma = clamp((arcos * 0.85 + vetas) * zona_espuma, 0.0, 1.0);
	espuma *= mix(0.35, 1.0, smoothstep(0.08, 0.6, d));

	// Borde de agua revuelta que respira.
	float pulso = 0.5 + 0.5 * sin(t * 1.4 + n1 * 4.0);
	float anillo = 1.0 - smoothstep(0.0, 0.05 + 0.03 * pulso, abs(d - 0.84 - (n1 - 0.5) * 0.1));
	float borde = anillo * smoothstep(0.3, 0.65, n2 + 0.15);

	// Color del agua: más honda y oscura hacia el ojo; en la tormenta, gris.
	float fuera = smoothstep(zona_radio - 0.6, zona_radio + 3.0, length(plano - zona_centro));
	vec3 claro = mix(vec3(0.05, 0.36, 0.40), vec3(0.08, 0.12, 0.16), fuera);
	vec3 hondo = mix(vec3(0.02, 0.15, 0.23), vec3(0.04, 0.05, 0.09), fuera);
	vec3 abismo = vec3(0.0, 0.02, 0.045);
	float cerca = 1.0 - d;
	vec3 color = mix(claro, hondo, smoothstep(0.0, 0.55, cerca));
	color = mix(color, abismo, smoothstep(0.5, 0.95, cerca));

	// Luz falsa sobre la pared del embudo para que se vea hondo.
	float k = clamp(cerca, 0.0, 1.0);
	float pendiente = profundidad * 2.4 * pow(k, 1.4) / radio;
	vec2 hacia_fuera = rel / max(length(rel), 0.0001);
	vec3 normal = normalize(vec3(-hacia_fuera.x * pendiente, 1.0, -hacia_fuera.y * pendiente));
	float luz = clamp(0.62 + 0.55 * dot(normal, normalize(vec3(0.45, 0.8, 0.4))), 0.25, 1.15);
	color *= luz;

	vec3 blanco = vec3(0.86, 0.94, 0.97) * mix(0.7, 1.08, clamp(luz, 0.0, 1.0));
	color = mix(color, blanco, espuma);
	color = mix(color, vec3(0.93, 0.97, 1.0), borde * 0.75);
	color = mix(color, abismo * 0.4, 1.0 - smoothstep(0.02, 0.1, d));

	float alfa = 1.0 - smoothstep(0.55, 0.98, d);
	alfa = max(alfa, espuma * (1.0 - smoothstep(0.9, 1.0, d)));
	alfa = max(alfa, borde * 0.9 * (1.0 - smoothstep(0.93, 1.0, d)));
	ALBEDO = color;
	ALPHA = clamp(alfa, 0.0, 1.0) * fuerza;
}
