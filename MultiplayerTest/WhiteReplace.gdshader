shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // replace white with this color
uniform float threshold = 0.95; // how close to white a pixel must be

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Check if pixel is near white
    if (tex_color.r > threshold && tex_color.g > threshold && tex_color.b > threshold) {
        COLOR = vec4(target_color.rgb, tex_color.a * target_color.a);
    } else {
        COLOR = tex_color;
    }
}
