shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0, 0.25, 0.05, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.8;
uniform float motion : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float radius = length(p);
	float ring = smoothstep(0.61, 0.75, radius) * (1.0 - smoothstep(0.82, 0.98, radius));
	float circuit = pow(max(0.0, sin(atan(p.y, p.x) * 12.0 + TIME * motion)), 12.0);
	float core = (1.0 - smoothstep(0.0, 0.72, radius)) * 0.16;
	ALBEDO = tint.rgb * 1.8;
	ALPHA = (ring * (0.48 + 0.52 * circuit) + core) * strength * tint.a;
}
