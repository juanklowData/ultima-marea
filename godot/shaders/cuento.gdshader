// Filtro de "cuento pintado" sobre toda la imagen 3D (va por debajo de la interfaz).
// Da el estilo propio de Última Marea: color de acuarela con sombras frías y luces cálidas,
// tonos en bandas suaves (como pintado a capas), un trazo de tinta donde cambia el brillo,
// grano de papel y bordes oscurecidos. Cuesta 3 lecturas de la pantalla por píxel.
shader_type canvas_item;

uniform sampler2D pantalla : hint_screen_texture, filter_linear;
uniform sampler2D papel : repeat_enable, filter_linear_mipmap;
uniform float fuerza : hint_range(0.0, 1.0) = 1.0;
uniform float bandas = 6.0;
uniform float tinta_umbral = 0.11;
uniform vec4 tinta_color : source_color = vec4(0.16, 0.10, 0.09, 1.0);
uniform vec3 sombra : source_color = vec3(0.20, 0.27, 0.48);
uniform vec3 luz : source_color = vec3(1.0, 0.86, 0.62);

float brillo(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 original = texture(pantalla, uv).rgb;
	vec3 c = original;
	float l = brillo(c);

	// Trazo de tinta: diferencia de brillo con los vecinos de la derecha y de abajo.
	vec2 paso = SCREEN_PIXEL_SIZE * 1.5;
	float lx = brillo(texture(pantalla, uv + vec2(paso.x, 0.0)).rgb);
	float ly = brillo(texture(pantalla, uv + vec2(0.0, paso.y)).rgb);
	float borde = smoothstep(tinta_umbral, tinta_umbral * 2.2, abs(l - lx) + abs(l - ly));

	// Color en capas: el brillo se cuantiza suave y el tono se conserva.
	float capas = (floor(l * bandas) + smoothstep(0.35, 0.65, fract(l * bandas))) / bandas;
	c *= mix(1.0, capas / max(l, 0.001), 0.55);

	// Virado de acuarela: sombras hacia azul tinta, luces hacia dorado.
	vec3 virado = mix(sombra, luz, smoothstep(0.1, 0.85, l));
	c = mix(c, c * virado * 1.35, 0.32);
	// Un poco más de saturación, como pigmento.
	float gris = brillo(c);
	c = mix(vec3(gris), c, 1.18);

	// Grano de papel (0.5 es neutro) y viñeta suave.
	float grano = texture(papel, uv * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0) * 2.2).r;
	c *= 1.0 + (grano - 0.5) * 0.35;
	vec2 centro = uv - 0.5;
	c *= 1.0 - dot(centro, centro) * 0.55;

	c = mix(c, tinta_color.rgb, borde * 0.6);
	COLOR = vec4(mix(original, c, fuerza), 1.0);
}
