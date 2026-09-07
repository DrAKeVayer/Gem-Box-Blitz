extends Control

func _ready() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.modulate.a = 0.0
	add_child(vbox)
	
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.pivot_offset = vbox.size / 2
	vbox.add_theme_constant_override("separation", 20)
	
	var mode_1_btn: LongButton = GlobalAssets.create_long_button()
	var cfg1 = LongButton.Config.new()
	cfg1.target_change_scene = "GAME_MODE_1"
	cfg1.b_text = "Rectangle"
	cfg1.b_length = 700
	mode_1_btn.create_button(cfg1)
	vbox.add_child(mode_1_btn)
	
	var mode_2_btn: LongButton = GlobalAssets.create_long_button()
	var cfg2 = LongButton.Config.new()
	cfg2.target_change_scene = "GAME_MODE_2"
	cfg2.b_text = "Path"
	cfg2.b_length = 700
	mode_2_btn.create_button(cfg2)
	vbox.add_child(mode_2_btn)
	
	var mode_3_btn: LongButton = GlobalAssets.create_long_button()
	var cfg3 = LongButton.Config.new()
	cfg3.target_change_scene = "TEST_MODE"
	cfg3.b_text = "Test Mode"
	cfg3.b_length = 700
	mode_3_btn.create_button(cfg3)
	vbox.add_child(mode_3_btn)
	
	await get_tree().process_frame
	
	vbox.scale = Vector2(0.5, 0.5)
	
	var real_width: float = vbox.size.x * vbox.scale.x
	vbox.position = Vector2((1920.0 - real_width) / 2.0, 600)
	
	var return_btn: RoundButton = GlobalAssets.create_round_button()
	var cfg4 = RoundButton.Config.new()
	cfg4.target_change_scene = "MAIN_MENU"
	cfg4.b_scale = 0.25
	cfg4.b_icon = RoundButton.B_Icon.BACK

	var base_texture: Texture2D = return_btn.b_color_load[cfg4.b_color]
	var button_height_scaled: float = base_texture.get_size().y * cfg4.b_scale

	var viewport_height: float = get_viewport_rect().size.y
	var margin_x: float = 30.0
	var margin_y: float = 30.0

	cfg4.b_pos = Vector2i(int(margin_x), int(viewport_height - button_height_scaled - margin_y))

	return_btn.create_button(cfg4)
	add_child(return_btn)
	vbox.modulate.a = 1.0
