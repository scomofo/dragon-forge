shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float collapse : hint_range(0.0, 1.0) = 0.0;
uniform float collapse_factor : hint_range(0.0, 1.0) = 0.0;
uniform vec4 screen_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	float amount = max(collapse, collapse_factor);
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);
	vec4 tex = texture(screen_texture, uv);

	float vertical_window = 1.0 - step(0.5 - amount * 0.5, abs(centered.y));
	float horizontal_window = 1.0 - step(0.5 - pow(amount, 4.0) * 0.5, abs(centered.x));
	float beam = vertical_window * horizontal_window;
	float white_point = smoothstep(0.025, 0.0, length(centered)) * amount;
	float scan = 0.88 + sin(uv.y * 720.0) * 0.06;

	vec4 collapsed = mix(tex * scan, screen_color, amount * 0.8);
	COLOR = mix(vec4(0.0, 0.0, 0.0, 1.0), collapsed, beam);
	COLOR = mix(COLOR, screen_color, white_point);
}
