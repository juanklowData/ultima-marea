shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

// Raya de viento: UV.x a lo largo (cola en 0, cabeza en 1), UV.y a lo ancho. COLOR.a = opacidad.
void fragment() {
	float largo = smoothstep(0.0, 0.7, UV.x) * smoothstep(1.0, 0.85, UV.x);
	float ancho = 1.0 - abs(UV.y * 2.0 - 1.0);
	ALBEDO = vec3(0.92, 0.97, 1.0);
	ALPHA = COLOR.a * largo * ancho * 0.85;
}
