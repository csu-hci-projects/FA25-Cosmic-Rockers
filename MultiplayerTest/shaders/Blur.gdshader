shader_type canvas_item;
render_mode blend_mix;

uniform float blur_radius = 4.0;
uniform int steps = 4;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE;

	for (int i = 0; i < steps; i ++) {
		float value = blur_radius / float(steps) * float(i + 1);
		col += texture(TEXTURE, UV + vec2(0.0, -value) * ps);
		col += texture(TEXTURE, UV + vec2(0.0, value) * ps);
		col += texture(TEXTURE, UV + vec2(-value, 0.0) * ps);
		col += texture(TEXTURE, UV + vec2(value, 0.0) * ps);
	}
	col /= float(steps * 4) + 1.0;

	COLOR = col;
}