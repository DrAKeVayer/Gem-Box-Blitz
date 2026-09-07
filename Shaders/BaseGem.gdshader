shader_type canvas_item;

uniform sampler2D hole_mask : filter_linear, source_color;
uniform float hole_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 gem = texture(TEXTURE, UV);

    if (hole_progress > 0.001) {
        vec2 mask_uv = (UV - vec2(0.5)) / hole_progress + vec2(0.5);

        float mask_alpha = 0.0;
        if (mask_uv.x >= 0.0 && mask_uv.x <= 1.0 && mask_uv.y >= 0.0 && mask_uv.y <= 1.0) {
            mask_alpha = texture(hole_mask, mask_uv).a;
        }

        gem.a *= (1.0 - mask_alpha);
    }

    COLOR = gem;
}