shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float speed : hint_range(0.0, 2.0) = 0.3;
uniform float strength : hint_range(0.0, 0.05) = 0.02;
uniform vec2 direction = vec2(0.0, 1.0); // vertical shimmer
uniform vec2 noise_scroll_dir = vec2(1.0, 0.0);

void fragment() {
    vec2 uv = UV;

    // Scroll the noise texture
    vec2 noise_uv = fract(uv * 2.0 + noise_scroll_dir * TIME * speed);
    float n = texture(noise_texture, noise_uv).r;

    // Apply distortion
    vec2 offset = (n - 0.5) * direction * strength;

    // Sample the sprite texture with offset
    COLOR = texture(TEXTURE, uv + offset);
}
