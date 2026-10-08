shader_type spatial;
// Estilo retro low poly: opaco, sin luz por píxel, facetas planas y colores por bandas.
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec4 color_hondo : source_color = vec4(0.02, 0.15, 0.23, 1.0);
uniform vec4 color_claro : source_color = vec4(0.05, 0.36, 0.40, 1.0);
uniform vec4 color_cielo : source_color = vec4(0.55, 0.76, 0.82, 1.0);
uniform vec4 color_tormenta : source_color = vec4(0.04, 0.05, 0.09, 1.0);
uniform vec4 color_bajio : source_color = vec4(0.1, 0.58, 0.58, 1.0);
uniform vec4 color_espuma : source_color = vec4(0.9, 0.96, 0.98, 1.0);
uniform vec2 zona_centro = vec2(0.0);
uniform float zona_radio = 80.0;
uniform float relampago = 0.0;
uniform float tiempo = 0.0;
// Con detalle las crestas de espuma se ven más blancas.
uniform bool detalle = true;
// Remolinos cercanos: x, z, radio y profundidad del embudo (metros). Radio 0 = vacío.
uniform vec4 remolinos[6];
// Bajíos de las islas cercanas (Islas.BAJIOS): x, z, radio interior y exterior del agua
// más clara (metros). Radio 0 = vacío.
uniform vec4 bajios[8];

varying vec3 pos_mundo;
varying float altura;

float fuera_de_zona(vec2 p) {
	return smoothstep(zona_radio, zona_radio + 8.0, length(p - zona_centro));
}

// Debe coincidir con Principal.altura_mar() para que los barcos floten sobre la ola.
float ola(vec2 p, vec2 dir, float largo, float amp, float t) {
	float k = 6.2831853 / largo;
	float s = sin(dot(normalize(dir), p) * k - sqrt(9.8 * k) * t);
	return amp * (2.0 * pow(0.5 + 0.5 * s, 1.8) - 0.6);
}

float altura_mar(vec2 p, float t, float fuera) {
	float h = ola(p, vec2(1.0, 0.3), 14.0, 0.12, t)
		+ ola(p, vec2(-0.4, 1.0), 9.0, 0.08, t)
		+ ola(p, vec2(0.7, -0.7), 6.0, 0.05, t)
		+ ola(p, vec2(-0.8, -0.35), 4.3, 0.04, t);
	return h * (1.0 + fuera * 2.0) + ola(p, vec2(0.2, 1.0), 21.0, 0.35, t) * fuera;
}

// Debe coincidir con Peligros.ajustar_mar(): el remolino calma las olas y hunde el agua.
float con_remolinos(vec2 p, float h) {
	float calma = 0.0;
	float hundido = 0.0;
	for (int i = 0; i < 6; i++) {
		vec4 r = remolinos[i];
		if (r.z > 0.0) {
			// Distancia suavizada para que el fondo del embudo sea redondo y no en punta.
			float d = length(p - r.xy) / r.z;
			float k = clamp(1.0 - (sqrt(d * d + 0.0225) - 0.15) / 0.8662, 0.0, 1.0);
			calma = max(calma, k);
			hundido += r.w * pow(k, 2.4);
		}
	}
	return h * (1.0 - 0.6 * smoothstep(0.0, 1.0, calma)) - hundido;
}

void vertex() {
	vec3 mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = con_remolinos(mundo.xz, altura_mar(mundo.xz, tiempo, fuera_de_zona(mundo.xz)));
	VERTEX.y += h;
	altura = h;
	pos_mundo = mundo + vec3(0.0, h, 0.0);
}

void fragment() {
	vec2 p = pos_mundo.xz;
	// Normal de cada triángulo de la malla: las olas se ven como facetas planas.
	vec3 n = normalize(cross(dFdx(pos_mundo), dFdy(pos_mundo)));
	if (n.y < 0.0) {
		n = -n;
	}
	float luz = clamp(dot(n, normalize(vec3(0.45, 1.0, 0.3))), 0.0, 1.0);

	// Tres tonos según la altura de la ola, sin degradados.
	float alto = clamp(0.5 + altura * 2.2, 0.0, 1.0);
	float banda = min(floor(alto * 3.0) * 0.5, 1.0);
	vec3 color = mix(color_hondo.rgb, color_claro.rgb, banda);
	color = mix(color, color_cielo.rgb, 0.12);
	color *= 0.78 + 0.32 * luz;
	// Crestas blancas planas en lo alto de las olas.
	color = mix(color, color_espuma.rgb, step(0.22, altura) * (detalle ? 0.55 : 0.4));

	float d = length(p - zona_centro);
	float fuera_color = step(zona_radio, d);
	vec3 bravo = mix(color_tormenta.rgb, vec3(0.08, 0.12, 0.16), banda) * (0.8 + 0.3 * luz)
		+ step(0.3, altura) * vec3(0.35, 0.38, 0.42);
	color = mix(color, bravo, fuera_color);
	color += vec3(0.55, 0.6, 0.8) * relampago * fuera_color * 0.3;
	color = mix(color, color_espuma.rgb, 1.0 - step(0.4, abs(d - zona_radio)));

	// Bajíos de las islas: dos anillos de agua más clara.
	float claro = 0.0;
	for (int i = 0; i < 8; i++) {
		vec4 b = bajios[i];
		if (b.w > 0.0) {
			float r = length(p - b.xy);
			claro = max(claro, (1.0 - step(b.w, r)) * 0.5 + (1.0 - step(mix(b.z, b.w, 0.4), r)) * 0.5);
		}
	}
	claro *= 1.0 - fuera_color;
	color = mix(color, color_bajio.rgb, claro * 0.55);

	ALBEDO = color;
}
