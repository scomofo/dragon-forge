shader_type canvas_item;

uniform float corruption_level : hint_range(0.0, 1.0) = 0.0;
uniform vec4 source_code_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	float stripe = step(2.0 - corruption_level * 2.0, mod(UV.y * 100.0, 2.0));
	float flicker = step(0.55, fract(sin(dot(UV * TIME, vec2(12.9898, 78.233))) * 43758.5453));
	float corruption = clamp(corruption_level * (0.55 + flicker * 0.45), 0.0, 1.0);
	COLOR = mix(base_color, source_code_color, stripe * corruption);
}
