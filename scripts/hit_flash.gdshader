shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;
uniform float strength = 0.0;
uniform vec3 tint : source_color = vec3(1.0);
void fragment() {
	ALBEDO = tint;
	ALPHA = strength;
}
