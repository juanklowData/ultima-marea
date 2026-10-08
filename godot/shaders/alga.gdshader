shader_type spatial;
render_mode cull_disabled;

// UV.x: 0 en el pie de la cinta, 1 en la punta. UV.y distingue cada cinta.
varying vec3 normal_mundo;

void vertex() {
	vec3 raiz = MODEL_MATRIX[3].xyz;
	float fase = raiz.x * 0.9 + raiz.z * 0.6 + UV.y * 6.2831;
	float u = UV.x;
	VERTEX.x += sin(TIME * 1.3 + fase + u * 2.5) * 0.12 * u;
	VERTEX.z += cos(TIME * 1.0 + fase * 1.3 + u * 2.0) * 0.08 * u;
	normal_mundo = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.9;
	vec3 n = normalize((VIEW_MATRIX * vec4(normal_mundo, 0.0)).xyz);
	NORMAL = FRONT_FACING ? n : -n;
}
