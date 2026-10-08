shader_type spatial;
// Mar estilizado y ligero: dos ondas largas mueven la malla y unas ondulaciones finas solo
// cambian la luz. La normal es suave (calculada de las ondas), así no hay facetas que parpadeen.
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
// Remolinos cercanos: x, z, radio y profundidad del embudo (metros). Radio 0 = vacío.
uniform vec4 remolinos[6];
// Bajíos de las islas cercanas (Islas.BAJIOS): x, z, radio interior y exterior del agua
// más clara (metros). Radio 0 = vacío.
uniform vec4 bajios[8];

const vec3 SOL = vec3(0.39, 0.86, 0.33);

varying vec3 pos_mundo;
varying float altura;

float fuera_de_zona(vec2 p) {
	return smoothstep(zona_radio, zona_radio + 8.0, length(p - zona_centro));
}

// Altura (x) y pendiente en x y z (y, z) de una onda.
vec3 ola(vec2 p, vec2 dir, float largo, float amp, float t) {
	vec2 d = normalize(dir);
	float k = 6.2831853 / largo;
	float fase = dot(d, p) * k - sqrt(9.8 * k) * t * 0.75;
	return vec3(sin(fase), cos(fase) * k * d) * amp;
}

// Debe coincidir con Principal.altura_mar() para que los barcos floten sobre la ola.
vec3 mar(vec2 p, float t, float fuera) {
	vec3 h = ola(p, vec2(1.0, 0.3), 22.0, 0.11, t) + ola(p, vec2(-0.4, 1.0), 13.0, 0.06, t);
	return h * (1.0 + fuera * 1.5) + ola(p, vec2(0.2, 1.0), 21.0, 0.3, t) * fuera;
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
	float h = con_remolinos(mundo.xz, mar(mundo.xz, tiempo, fuera_de_zona(mundo.xz)).x);
	VERTEX.y += h;
	altura = h;
	pos_mundo = mundo + vec3(0.0, h, 0.0);
}

void fragment() {
	vec2 p = pos_mundo.xz;
	float d = length(p - zona_centro);
	float fuera_color = step(zona_radio, d);

	// Pendiente de las ondas grandes más unas ondulaciones finas que solo dan textura a la luz.
	vec3 m = mar(p, tiempo, fuera_de_zona(p))
		+ ola(p, vec2(0.7, -0.7), 5.0, 0.03, tiempo)
		+ ola(p, vec2(-0.8, -0.35), 3.2, 0.015, tiempo);
	vec3 n = normalize(vec3(-m.y, 1.0, -m.z));
	vec3 vista = normalize(CAMERA_POSITION_WORLD - pos_mundo);
	float luz = clamp(dot(n, SOL), 0.0, 1.0);

	vec3 color = mix(color_hondo.rgb, color_claro.rgb, clamp(0.6 + altura * 2.5, 0.0, 1.0));
	color *= 0.8 + 0.3 * luz;
	// A lo lejos el agua refleja más el cielo.
	float reflejo = pow(1.0 - clamp(dot(n, vista), 0.0, 1.0), 3.0);
	color = mix(color, color_cielo.rgb, 0.12 + reflejo * 0.45);
	// Brillos del sol y espuma suave en lo alto de las ondas.
	float brillo = pow(clamp(dot(reflect(-SOL, n), vista), 0.0, 1.0), 48.0);
	color += vec3(1.0, 0.97, 0.88) * brillo * 0.35;
	color = mix(color, color_espuma.rgb, smoothstep(0.1, 0.16, altura) * 0.3);

	vec3 bravo = mix(color_tormenta.rgb, vec3(0.08, 0.12, 0.16), clamp(0.5 + altura, 0.0, 1.0)) * (0.8 + 0.3 * luz)
		+ smoothstep(0.3, 0.4, altura) * vec3(0.3, 0.33, 0.37);
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
