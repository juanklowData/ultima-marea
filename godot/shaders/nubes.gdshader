shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec2 zona_centro = vec2(0.0);
uniform float zona_radio = 80.0;
uniform float relampago = 0.0;
uniform vec4 color_nube : source_color = vec4(0.06, 0.06, 0.1, 1.0);
uniform vec4 color_luz : source_color = vec4(0.78, 0.82, 1.0, 1.0);

varying vec3 pos_mundo;

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
	float valor = 0.0;
	float peso = 0.5;
	for (int i = 0; i < 5; i++) {
		valor += peso * ruido(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		peso *= 0.5;
	}
	return valor;
}

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 rel = pos_mundo.xz - zona_centro;
	float d = length(rel);
	float fuera = smoothstep(zona_radio + 1.0, zona_radio + 9.0, d);
	if (fuera <= 0.001) {
		discard;
	}
	float angulo = TIME * 0.04 + d * 0.004;
	mat2 giro = mat2(vec2(cos(angulo), -sin(angulo)), vec2(sin(angulo), cos(angulo)));
	vec2 q = giro * rel * 0.07 + vec2(TIME * 0.06, -TIME * 0.04);
	float nube = fbm(q);
	float detalle = fbm(q * 2.6 - vec2(TIME * 0.15, TIME * 0.1));
	float densidad = smoothstep(0.3, 0.75, nube * 0.75 + detalle * 0.4);
	vec3 color = mix(color_nube.rgb * 0.5, color_nube.rgb * 2.2, detalle * detalle);
	color = mix(color, color_luz.rgb, relampago * detalle * detalle * 0.8);
	ALBEDO = color;
	ALPHA = fuera * clamp(0.3 + densidad * 0.45, 0.0, 0.72);
}
