extends Control

func _ready() -> void:
	AudioManager.play_bgm("main_menu")
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.modulate.a = 0.0
	add_child(vbox)
	
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.pivot_offset = vbox.size / 2
	vbox.add_theme_constant_override("separation", 20)
	
	var mode_1_btn: LongButton = GlobalAssets.create_long_button()
	var cfg1 = LongButton.Config.new()
	cfg1.target_change_scene = "MODE_SELECTOR"
	cfg1.b_text = "Start"
	cfg1.b_length = 800
	mode_1_btn.create_button(cfg1)
	vbox.add_child(mode_1_btn)
	
	var info_btn: LongButton = GlobalAssets.create_long_button()
	var cfg2 = LongButton.Config.new()
	cfg2.target_front_scene = "GENERIC_INFO_BOX"
	cfg2.b_text = "Info"
	cfg2.b_length = 700
	info_btn.create_button(cfg2)
	vbox.add_child(info_btn)
	info_btn.pressed.connect(_on_open_info_pressed)
	
	await get_tree().process_frame
	
	vbox.scale = Vector2(0.5, 0.5)
	
	var real_width: float = vbox.size.x * vbox.scale.x
	vbox.position = Vector2((1920.0 - real_width) / 2.0, 550)
	vbox.modulate.a = 1.0
	
func _on_open_info_pressed() -> void:
	EventBus.pause_game.emit(true)
	
	var box_cfg = InfoBox.Config.new()
	box_cfg.title_text = "Disclaimer"
	box_cfg.body_text = "Proof of concept product, all assets belong to their rightful owner. Original game idea: Fruit Box by GameSaien"
	box_cfg.box_size = Vector2(750, 450)
	
	var close_btn_cfg = LongButton.Config.new()
	close_btn_cfg.b_text = "OK"
	close_btn_cfg.b_color = LongButton.B_Color.PURPLE
	close_btn_cfg.b_size = LongButton.B_Size.SMALL
	close_btn_cfg.b_length = 320
	box_cfg.custom_buttons_cfg.clear()
	box_cfg.custom_buttons_cfg.append(close_btn_cfg)
	
	var info_box_node = GlobalAssets.show_info_box(box_cfg)
	
	info_box_node.tree_exited.connect(func():
		EventBus.pause_game.emit(false)
	)
