shader_type spatial;
render_mode cull_disabled;

// Copa de palmera. UV.x va de la base (0) a la punta (1) de cada hoja y UV.y
// distingue cada hoja para que no se muevan todas a la vez.

varying vec3 normal_mundo;

void vertex() {
	vec3 raiz = MODEL_MATRIX[3].xyz;
	float fase = raiz.x * 0.71 + raiz.z * 0.53;
	float u = UV.x;
	float hoja = UV.y * 6.2831;
	// Toda la copa se mece con el viento; las puntas se van más lejos que la base.
	float viento = sin(TIME * 1.1 + fase) * 0.6 + sin(TIME * 1.9 + fase * 1.3) * 0.4;
	VERTEX.xz += vec2(0.07, 0.045) * viento * u;
	// Cada hoja sube y baja a su ritmo, y la punta tiembla.
	VERTEX.y += sin(TIME * 2.4 + hoja + fase) * 0.07 * u * u;
	VERTEX.y += sin(TIME * 7.0 + hoja * 3.0 + u * 6.0) * 0.012 * u;
	normal_mundo = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.85;
	// Las hojas se iluminan igual por las dos caras.
	vec3 n = normalize((VIEW_MATRIX * vec4(normal_mundo, 0.0)).xyz);
	NORMAL = FRONT_FACING ? n : -n;
}
