shader_type spatial;
render_mode specular_schlick_ggx, blend_mix, depth_draw_always;

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
// Bajíos de las islas cercanas (Islas.BAJIOS): x, z, radio donde el agua es más clara
// y radio donde vuelve a ser opaca (metros). Radio 0 = vacío.
uniform vec4 bajios[8];

varying vec3 pos_mundo;
varying float altura;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

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

float rizos(vec2 p, float t) {
	return ola(p, vec2(-0.9, -0.2), 3.7, 0.045, t)
		+ ola(p, vec2(0.3, 1.0), 2.3, 0.025, t)
		+ ola(p, vec2(1.0, -0.5), 1.4, 0.016, t)
		+ ola(p, vec2(-0.6, 0.8), 0.95, 0.01, t)
		+ ola(p, vec2(-0.8, -0.6), 0.6, 0.006, t)
		+ (ruido(p * 3.1 + vec2(t * 0.6, t * 0.35)) - 0.5) * 0.012;
}

float superficie(vec2 p, float t, float fuera) {
	return altura_mar(p, t, fuera) + rizos(p, t) * (1.0 + fuera * 2.5);
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
	float t = tiempo;
	vec2 p = pos_mundo.xz;
	float fuera = fuera_de_zona(p);

	float e = 0.06;
	float h0 = superficie(p, t, fuera);
	float hx = superficie(p + vec2(e, 0.0), t, fuera);
	float hz = superficie(p + vec2(0.0, e), t, fuera);
	vec3 n = normalize(vec3(-(hx - h0) / e, 1.0, -(hz - h0) / e));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

	vec3 vista = normalize(CAMERA_POSITION_WORLD - pos_mundo);
	float fresnel = pow(1.0 - clamp(dot(n, vista), 0.0, 1.0), 4.0);
	float alto = clamp(0.5 + altura * 2.2, 0.0, 1.0);
	vec3 color = mix(color_hondo.rgb, color_claro.rgb, alto);
	color = mix(color, color_cielo.rgb, clamp(fresnel * 0.7, 0.0, 0.6));

	float manchas = ruido(p * 0.9 + vec2(t * 0.12, -t * 0.08)) * ruido(p * 2.3 - vec2(t * 0.2, t * 0.1));
	float espuma_calma = smoothstep(0.21, 0.3, altura) * smoothstep(0.35, 0.7, manchas);
	color = mix(color, color_espuma.rgb * 0.94, espuma_calma * 0.4);
	// Crestitas blancas en las olas pequeñas.
	float cresta = smoothstep(0.06, 0.1, h0 - altura) * smoothstep(0.62, 0.85, ruido(p * 4.0 + vec2(t * 0.25, -t * 0.18)));
	color = mix(color, color_espuma.rgb, cresta * 0.25);
	color *= 0.95 + 0.1 * clamp((h0 - altura) * 8.0, -0.5, 0.5);

	float d = length(p - zona_centro);
	float fuera_color = smoothstep(zona_radio - 0.6, zona_radio + 3.0, d);
	float espuma_brava = smoothstep(0.35, 0.75, altura) * (0.4 + 0.6 * manchas) + smoothstep(0.55, 0.85, manchas) * 0.25;
	float gotas = step(0.993, hash(floor(p * 5.0) + floor(t * 10.0)));
	vec3 bravo = mix(color_tormenta.rgb, vec3(0.08, 0.12, 0.16), alto) + espuma_brava * vec3(0.4, 0.43, 0.48) + gotas * 0.2;
	color = mix(color, bravo, fuera_color);
	color += vec3(0.55, 0.6, 0.8) * relampago * fuera_color * 0.3;
	float borde = 1.0 - smoothstep(0.0, 0.45, abs(d - zona_radio));

	// Sobre el fondo de las islas el agua se aclara y deja ver corales y peces.
	float claro = 0.0;
	for (int i = 0; i < 8; i++) {
		vec4 b = bajios[i];
		if (b.w > 0.0) {
			claro = max(claro, 1.0 - smoothstep(b.z, b.w, length(p - b.xy)));
		}
	}
	claro *= 1.0 - fuera_color;
	color = mix(color, color_bajio.rgb, claro * 0.35);

	ALBEDO = color;
	ALPHA = mix(1.0, 0.32, claro);
	EMISSION = color_espuma.rgb * borde * 0.9;
	ROUGHNESS = mix(0.18, 0.3, fuera_color);
	SPECULAR = 0.45;
}
