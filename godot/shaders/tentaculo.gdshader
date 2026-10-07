shader_type spatial;
render_mode cull_back;

// El tentáculo es un cilindro de alto 1 que aquí se dobla en una curva suave.
// El eje local +Y sale de la raíz y la curva se dobla hacia +Z (afuera del cuerpo).
uniform float tiempo = 0.0;
uniform float largo = 6.0;
uniform float grosor = 0.45;
// Ángulo inicial desde la vertical hacia fuera.
uniform float inclinacion = 0.5;
// Curvatura repartida a lo largo y curvatura extra que se concentra en la punta (radianes).
uniform float curva = 2.0;
uniform float curva_punta = 0.0;
uniform float onda = 1.0;
uniform float fase = 0.0;
uniform float vaiven = 0.3;
uniform float destello = 0.0;
uniform vec4 color_lomo : source_color = vec4(0.42, 0.09, 0.17, 1.0);
uniform vec4 color_manchas : source_color = vec4(0.22, 0.04, 0.10, 1.0);
uniform vec4 color_vientre : source_color = vec4(0.88, 0.58, 0.55, 1.0);

varying float tramo;
varying vec2 seccion;
varying float radio_local;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// La onda nace en la raíz y viaja hacia la punta, creciendo con el largo.
float curvatura(float u) {
	float ondulacion = onda * (sin(u * 7.0 - tiempo * 1.7 + fase) * 0.7 + sin(u * 13.0 - tiempo * 2.9 + fase * 1.9) * 0.3) * (0.25 + u);
	return curva + curva_punta * 3.0 * u * u + ondulacion;
}

// Curvatura hacia los costados: el brazo serpentea fuera de su plano.
float curvatura_lateral(float u) {
	return vaiven * (sin(u * 5.0 - tiempo * 1.1 + fase * 2.3) * 0.8 + sin(u * 9.0 + tiempo * 0.7 + fase) * 0.4) * (0.3 + u) * 2.2;
}

float radio_en(float s) {
	float r = grosor * mix(1.0, 0.1, pow(s, 0.8));
	return r * sqrt(clamp((1.0 - s) / 0.03, 0.0, 1.0));
}

void vertex() {
	float s = clamp(VERTEX.y + 0.5, 0.0, 1.0);
	vec2 c = normalize(VERTEX.xz + vec2(0.00001));

	float angulo = inclinacion;
	float desvio = 0.0;
	vec2 punto = vec2(0.0);
	float lateral = 0.0;
	float paso = s / 18.0;
	for (int i = 0; i < 18; i++) {
		float u = (float(i) + 0.5) * paso;
		float k = curvatura(u);
		float medio = angulo + k * paso * 0.5;
		float medio_lado = desvio + curvatura_lateral(u) * paso * 0.5;
		punto += vec2(cos(medio), sin(medio)) * paso * cos(medio_lado);
		lateral += sin(medio_lado) * paso;
		angulo += k * paso;
		desvio += curvatura_lateral(u) * paso;
	}
	punto *= largo;
	lateral *= largo;

	vec3 n1 = vec3(1.0, 0.0, 0.0);
	vec3 n2 = vec3(0.0, -sin(angulo), cos(angulo));
	float r = radio_en(s);
	VERTEX = vec3(lateral, punto.x, punto.y) + r * (c.x * n1 + c.y * n2);
	NORMAL = normalize(c.x * n1 + c.y * n2);
	tramo = s;
	seccion = c;
	radio_local = r;
}

void fragment() {
	float a = atan(seccion.y, seccion.x);
	float vientre = smoothstep(0.15, 0.6, seccion.y);

	float manchas = ruido(vec2(tramo * largo * 1.6 + seccion.x * 1.3, seccion.y * 1.4 + seccion.x * 0.7));
	vec3 color = mix(color_lomo.rgb, color_manchas.rgb, smoothstep(0.55, 0.72, manchas));
	color = mix(color, color_lomo.rgb * 1.5, smoothstep(-0.3, 0.2, seccion.y) * (1.0 - vientre) * 0.35);
	color = mix(color, color_vientre.rgb, vientre * 0.85);

	// Dos filas de ventosas en la cara interior.
	float celdas = 28.0;
	float largo_celda = largo / celdas;
	float ventosa = 0.0;
	float hueco = 0.0;
	for (int fila = 0; fila < 2; fila++) {
		float lado = fila == 0 ? -0.42 : 0.42;
		float f = fract(tramo * celdas + float(fila) * 0.5);
		vec2 q = vec2((f - 0.5) * largo_celda, (a - 1.5708 - lado) * radio_local);
		float tam = min(radio_local * 0.36, largo_celda * 0.42);
		float dd = length(q) / max(tam, 0.0001);
		ventosa = max(ventosa, 1.0 - smoothstep(0.7, 1.0, dd));
		hueco = max(hueco, 1.0 - smoothstep(0.25, 0.5, dd));
	}
	ventosa *= vientre;
	hueco *= vientre;
	color = mix(color, vec3(0.96, 0.78, 0.74), ventosa * 0.8);
	color = mix(color, vec3(0.45, 0.16, 0.2), hueco * 0.7);

	ALBEDO = color;
	ROUGHNESS = mix(0.22, 0.4, vientre);
	SPECULAR = 0.7;
	RIM = 0.35;
	RIM_TINT = 0.5;
	EMISSION = vec3(1.0, 0.35, 0.25) * destello * 0.8;
}
