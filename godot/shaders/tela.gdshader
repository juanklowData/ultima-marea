shader_type spatial;
render_mode cull_disabled;

uniform sampler2D dibujo : source_color, filter_linear_mipmap;
// 0 = vela (se hincha y riza por el centro); 1 = bandera (ondea desde el asta, en UV.x = 1).
uniform float ondear = 0.0;

void vertex() {
	vec3 origen = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float fase = origen.x * 0.9 + origen.z * 0.6;
	float t = TIME;
	float centro = sin(UV.x * PI) * sin(UV.y * PI);
	float vela = centro * (0.05 * sin(t * 1.7 + fase) + 0.025)
		+ centro * 0.018 * sin(t * 4.3 + UV.x * 6.0 + UV.y * 3.0 + fase);
	float libre = 1.0 - UV.x;
	float bandera = libre * (0.07 * sin(t * 7.5 - libre * 7.0 + fase) + 0.025 * sin(t * 12.0 - libre * 11.0 + UV.y * 3.0));
	VERTEX.z -= mix(vela, bandera, ondear);
}

void fragment() {
	vec4 color = texture(dibujo, UV);
	ALBEDO = color.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
