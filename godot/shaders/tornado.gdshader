shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

// Embudo de un tornado sobre un cilindro abierto de radio 1 y alto 1 (y de -0.5 a 0.5):
// se estrecha abajo, se abre arriba, se mece y sus franjas suben girando.
uniform float tiempo = 0.0;
uniform float giro = 1.0;
uniform float fuerza = 1.0;
uniform float alto = 7.0;
uniform float radio_base = 0.35;
uniform float radio_alto = 2.6;
uniform float vueltas = 1.0;
uniform vec2 inclina = vec2(0.0);
uniform vec3 color_claro : source_color = vec3(0.93, 0.95, 0.97);
uniform vec3 color_oscuro : source_color = vec3(0.45, 0.52, 0.58);
uniform float opacidad = 0.7;

varying float altura;

void vertex() {
	float h = VERTEX.y + 0.5;
	altura = h;
	vec2 dir = normalize(VERTEX.xz + vec2(0.0001));
	float r = mix(radio_base, radio_alto, pow(h, 1.7)) * (0.92 + 0.08 * sin(h * 9.0 - tiempo * 3.0));
	r *= mix(0.3, 1.0, fuerza);
	vec2 meneo = vec2(sin(tiempo * 1.3 + h * 3.0), cos(tiempo * 1.1 + h * 2.5)) * 0.25 * h;
	vec2 lado = inclina * pow(h, 1.5) + meneo;
	VERTEX = vec3(dir.x * r + lado.x, h * alto * mix(0.4, 1.0, fuerza), dir.y * r + lado.y);
}

void fragment() {
	float h = altura;
	float a = UV.x * 6.2832;
	float franja = sin(a * 3.0 + h * 9.0 * giro - tiempo * 7.0 * giro * vueltas);
	float fina = sin(a * 7.0 - h * 15.0 * giro - tiempo * 11.0 * giro * vueltas + sin(h * 6.0 + tiempo));
	float mezcla = clamp(0.5 + 0.35 * franja + 0.25 * fina, 0.0, 1.0);
	ALBEDO = mix(color_oscuro, color_claro, mezcla);
	float bordes = smoothstep(0.0, 0.06, h) * (1.0 - smoothstep(0.6, 1.0, h));
	ALPHA = clamp(opacidad * bordes * fuerza * (0.45 + 0.55 * mezcla), 0.0, 1.0);
}
