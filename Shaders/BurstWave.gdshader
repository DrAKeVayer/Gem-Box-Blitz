shader_type canvas_item;

uniform vec4 current_gradient_a : source_color = vec4(0.9, 0.9, 0.9, 1.0);
uniform vec4 current_gradient_b : source_color = vec4(0.65, 0.65, 0.65, 1.0);
uniform vec4 target_gradient_a : source_color = vec4(0.0, 0.4, 1.0, 1.0);
uniform vec4 target_gradient_b : source_color = vec4(0.0, 1.0, 0.5, 1.0);

uniform float scroll_offset = 0.0;
uniform float gradient_scale : hint_range(0.5, 10.0) = 1.5;

uniform float color_mix_factor : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 base_tex = texture(TEXTURE, UV);

    if (base_tex.a <= 0.001) {
        COLOR = base_tex;
    } else {
        float grad_cycle = sin((-UV.y * gradient_scale - scroll_offset) * 6.2831853) * 0.5 + 0.5;
        vec3 grad_curr = mix(current_gradient_a.rgb, current_gradient_b.rgb, grad_cycle);
        vec3 grad_target = mix(target_gradient_a.rgb, target_gradient_b.rgb, grad_cycle);

        vec3 active_tint = mix(grad_curr, grad_target, color_mix_factor);

        COLOR = vec4(base_tex.rgb * active_tint, base_tex.a);
    }
}