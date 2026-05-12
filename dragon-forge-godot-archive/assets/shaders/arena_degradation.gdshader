shader_type spatial;

uniform float corruption_level : hint_range(0.0, 1.0) = 0.0;
uniform vec3 circuit_color : source_color = vec3(0.1, 0.1, 0.2);
uniform vec3 leak_color : source_color = vec3(1.0, 0.0, 1.0);

void fragment() {
	vec2 grid_uv = floor(UV * 50.0) / 50.0;
	float noise = fract(sin(dot(grid_uv, vec2(12.9898, 78.233))) * 43758.5453);
	if (noise < corruption_level) {
		discard;
	}
	float edge = smoothstep(corruption_level, corruption_level + 0.04, noise);
	ALBEDO = mix(leak_color, circuit_color, edge);
	EMISSION = leak_color * (1.0 - edge) * corruption_level;
}
