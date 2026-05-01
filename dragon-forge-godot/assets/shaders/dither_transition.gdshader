shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float transition_level : hint_range(0.0, 1.0) = 0.0;
uniform float packet_loss_flicker : hint_range(0.0, 1.0) = 0.0;
uniform vec4 schematic_tint : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform vec4 void_color : source_color = vec4(0.02, 0.04, 0.05, 1.0);

float bayer8(vec2 pixel) {
	int x = int(mod(pixel.x, 8.0));
	int y = int(mod(pixel.y, 8.0));
	int index = x + y * 8;
	float values[64] = float[](
		0.0, 48.0, 12.0, 60.0, 3.0, 51.0, 15.0, 63.0,
		32.0, 16.0, 44.0, 28.0, 35.0, 19.0, 47.0, 31.0,
		8.0, 56.0, 4.0, 52.0, 11.0, 59.0, 7.0, 55.0,
		40.0, 24.0, 36.0, 20.0, 43.0, 27.0, 39.0, 23.0,
		2.0, 50.0, 14.0, 62.0, 1.0, 49.0, 13.0, 61.0,
		34.0, 18.0, 46.0, 30.0, 33.0, 17.0, 45.0, 29.0,
		10.0, 58.0, 6.0, 54.0, 9.0, 57.0, 5.0, 53.0,
		42.0, 26.0, 38.0, 22.0, 41.0, 25.0, 37.0, 21.0
	);
	return values[index] / 63.0;
}

void fragment() {
	vec4 base = texture(screen_texture, SCREEN_UV);
	vec2 pixel = floor(FRAGCOORD.xy);
	float threshold = bayer8(pixel);
	float random_flicker = step(0.82, fract(sin(dot(pixel + TIME, vec2(12.9898, 78.233))) * 43758.5453));
	float level = clamp(transition_level + random_flicker * packet_loss_flicker * 0.28, 0.0, 1.0);

	float reveal = step(threshold, level);
	float scanline = 0.86 + sin(SCREEN_UV.y * 480.0 + TIME * 16.0) * 0.08;
	vec4 schematic = mix(void_color, schematic_tint * scanline, 0.72);
	COLOR = mix(base, schematic, reveal);
}
