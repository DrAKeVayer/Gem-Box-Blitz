shader_type canvas_item;

uniform bool is_glowing = true;
uniform vec4 tint_color : source_color = vec4(1.0, 0.9, 0.0, 1.0);
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.2;
uniform float max_alpha : hint_range(0.0, 1.0) = 0.4;

uniform float chevron_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 chevron_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float chevron_alpha : hint_range(0.0, 1.0) = 0.6;
uniform float chevron_thickness : hint_range(0.01, 0.5) = 0.08; 
uniform float chevron_angle : hint_range(0.1, 2.0) = 0.5;

void fragment() {
	vec4 org_color = texture(TEXTURE, UV);
	
	if (org_color.a == 0.0) {
		COLOR = org_color;
	} else {
		vec3 base_rgb = org_color.rgb;
		if (is_glowing) {
			float wave = (sin(TIME * pulse_speed) + 1.0) * 0.5;
			float current_alpha = mix(min_alpha, max_alpha, wave);
			base_rgb = mix(base_rgb, tint_color.rgb, current_alpha);
		}

		if (chevron_progress > 0.0 && chevron_progress < 1.0) {
			float current_y = mix(1.2, -0.2, chevron_progress);
			
			float chevron_line_y = current_y + abs(UV.x - 0.5) * chevron_angle;
			float dist_to_chevron = abs(UV.y - chevron_line_y);

			float mask = 1.0 - smoothstep(0.0, chevron_thickness, dist_to_chevron);
			base_rgb = mix(base_rgb, chevron_color.rgb, mask * chevron_alpha * chevron_color.a);
		}

		COLOR = vec4(base_rgb, org_color.a);
	}
}