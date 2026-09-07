shader_type canvas_item;

uniform vec4 current_gradient_a : source_color = vec4(0.9, 0.9, 0.9, 1.0);
uniform vec4 current_gradient_b : source_color = vec4(0.65, 0.65, 0.65, 1.0);
uniform vec4 target_gradient_a : source_color = vec4(0.0, 0.4, 1.0, 1.0);
uniform vec4 target_gradient_b : source_color = vec4(0.0, 1.0, 0.5, 1.0);

uniform float scroll_offset = 0.0;
uniform float gradient_scale : hint_range(0.5, 10.0) = 1.5;

uniform vec4 crest_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 current_pos = vec2(-0.25, 0.5);
uniform vec2 move_direction = vec2(1.0, 0.0);
uniform float wave_crest_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float wave_angle : hint_range(0.1, 1.5) = 0.6;
uniform float wave_frequency : hint_range(5.0, 100.0) = 35.0;
uniform float wave_speed : hint_range(0.0, 20.0) = 8.0;
uniform float wave_width : hint_range(0.005, 0.2) = 0.05;

void fragment() {
    vec4 base_tex = texture(TEXTURE, UV);

    if (base_tex.a <= 0.001) {
        COLOR = base_tex;
    } else {
        float grad_cycle = sin((UV.y * gradient_scale - scroll_offset) * 6.2831853) * 0.5 + 0.5;
        vec3 grad_curr = mix(current_gradient_a.rgb, current_gradient_b.rgb, grad_cycle);
        vec3 grad_target = mix(target_gradient_a.rgb, target_gradient_b.rgb, grad_cycle);

        vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
        float aspect = tex_size.x / tex_size.y;
        vec2 corrected_uv = vec2(UV.x * aspect, UV.y);
        vec2 corrected_pos = vec2(current_pos.x * aspect, current_pos.y);
        vec2 delta = corrected_uv - corrected_pos;

        vec2 forward = normalize(vec2(move_direction.x * aspect, move_direction.y));
        vec2 right = vec2(-forward.y, forward.x);

        float dist_along = dot(delta, forward);
        float dist_cross = abs(dot(delta, right));

        float wake_front = -dist_cross / tan(wave_angle);

        float wave_transition = smoothstep(wake_front - wave_width, wake_front + 0.001, dist_along);
        wave_transition = 1.0 - wave_transition;

        float dist_to_edge = abs(dist_along - wake_front);
        float edge_mask = smoothstep(wave_width, 0.0, dist_to_edge) * wave_crest_intensity;
        if (dist_along > 0.0) {
            edge_mask = 0.0;
        }
        float crest_val = (sin(dist_to_edge * wave_frequency - TIME * wave_speed) * 0.5 + 0.5) * edge_mask;

        vec3 active_tint = mix(grad_curr, grad_target, wave_transition);
        vec3 final_color = base_tex.rgb * active_tint;
        final_color = mix(final_color, crest_color.rgb * base_tex.rgb, crest_val);

        COLOR = vec4(final_color, base_tex.a);
    }
}