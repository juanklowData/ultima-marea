shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.09, 0.08, 0.16, 0.8);
uniform float relampago = 0.0;

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

void vertex() {
	altura = VERTEX.y;
}

void fragment() {
	float subida = clamp((altura + 6.0) / 12.0, 0.0, 1.0);
	vec2 q = vec2(UV.x * 180.0 + TIME * 0.8, altura * 0.5 - TIME * 1.8);
	float n = ruido(q) * 0.6 + ruido(q * 2.3 + 7.0) * 0.4;
	ALBEDO = mix(color.rgb * (0.7 + 0.6 * n), vec3(0.8, 0.85, 1.0), relampago * 0.7);
	ALPHA = color.a * (1.0 - subida * 0.9) * (0.45 + 0.55 * n);
}
