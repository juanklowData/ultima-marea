shader_type spatial;
render_mode cull_back;

uniform float tiempo = 0.0;
uniform float destello = 0.0;
uniform float fase = 0.0;
uniform vec4 color_lomo : source_color = vec4(0.42, 0.09, 0.17, 1.0);
uniform vec4 color_manchas : source_color = vec4(0.22, 0.04, 0.10, 1.0);
uniform vec4 color_vientre : source_color = vec4(0.78, 0.45, 0.44, 1.0);

varying vec3 local;

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
	local = VERTEX;
	// Respiración y pliegues que recorren el manto.
	float pliegue = sin(VERTEX.y * 7.0 - tiempo * 1.6 + fase) * 0.035 + sin(atan(VERTEX.x, VERTEX.z) * 5.0 + tiempo * 0.7) * 0.02;
	float respira = 1.0 + 0.045 * sin(tiempo * 1.25 + fase);
	VERTEX += NORMAL * pliegue;
	VERTEX.xz *= respira;
}

void fragment() {
	float manchas = ruido(local.xz * 4.0 + vec2(local.y * 3.0, 0.0)) * 0.65 + ruido(local.xy * 9.0) * 0.35;
	vec3 color = mix(color_lomo.rgb, color_manchas.rgb, smoothstep(0.5, 0.7, manchas));
	float abajo = smoothstep(0.1, -0.5, local.y);
	color = mix(color, color_vientre.rgb, abajo * 0.7);
	// Venas claras finas.
	float vena = 1.0 - smoothstep(0.0, 0.04, abs(ruido(local.xy * 5.0 + local.zy * 3.0) - 0.5));
	color = mix(color, color_lomo.rgb * 1.8, vena * 0.25);
	ALBEDO = color;
	ROUGHNESS = 0.26;
	SPECULAR = 0.7;
	RIM = 0.4;
	RIM_TINT = 0.5;
	EMISSION = vec3(1.0, 0.35, 0.25) * destello * 0.8;
}
