extends Control
class_name InfoBox

class Config:
	var title_text: String = "INFORMATION"
	var body_text: String = "Template Content"
	var scene_key_name: String = ""
	var box_size: Vector2 = Vector2(800, 500)
	var title_font_size: int = 40
	var title_outline_size: int = 8
	var body_font_size: int = 28
	var body_outline_size: int = 4
	var custom_buttons_cfg: Array[LongButton.Config] = []
	var patch_margin_left: int = 75
	var patch_margin_top: int = 75
	var patch_margin_right: int = 75
	var patch_margin_bottom: int = 75

	var region_rect: Rect2 = Rect2(0, 0, 1275, 676)
	
func _ready() -> void:
	pass
	
func _add_scaled_button_to_container(container: Container, btn_cfg: LongButton.Config) -> LongButton:
	var btn: LongButton = GlobalAssets.create_long_button()
	btn.create_button(btn_cfg)
	
	var scale_val: float = LongButton.SIZE_PRESETS[btn_cfg.b_size]["scale"]
	var unscaled_size = Vector2(btn_cfg.b_length, 298.0)
	var scaled_size = unscaled_size * scale_val
	
	var slot = Control.new()
	slot.custom_minimum_size = scaled_size
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	btn.anchor_left = 0.0
	btn.anchor_top = 0.0
	btn.anchor_right = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = 0.0
	btn.offset_top = 0.0
	btn.offset_right = unscaled_size.x
	btn.offset_bottom = unscaled_size.y
	
	btn.pivot_offset = Vector2.ZERO
	btn.position = Vector2.ZERO
	btn.scale = Vector2(scale_val, scale_val)
	
	slot.add_child(btn)
	container.add_child(slot)
	
	return btn

func create_info_box(cfg: Config) -> void:
	if not cfg:
		cfg = Config.new()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var nine_patch_rect = get_node_or_null("NinePatchRect") as NinePatchRect
	if not nine_patch_rect:
		nine_patch_rect = NinePatchRect.new()
		nine_patch_rect.name = "NinePatchRect"
		add_child(nine_patch_rect)

	nine_patch_rect.texture = preload("res://Assets/Images/TimerBox.png")
	nine_patch_rect.patch_margin_left = cfg.patch_margin_left
	nine_patch_rect.patch_margin_top = cfg.patch_margin_top
	nine_patch_rect.patch_margin_right = cfg.patch_margin_right
	nine_patch_rect.patch_margin_bottom = cfg.patch_margin_bottom
	nine_patch_rect.region_rect = cfg.region_rect

	for child in nine_patch_rect.get_children():
		child.queue_free()

	nine_patch_rect.custom_minimum_size = cfg.box_size
	nine_patch_rect.size = cfg.box_size
	nine_patch_rect.pivot_offset = cfg.box_size / 2.0
	
	nine_patch_rect.anchor_left = 0.5
	nine_patch_rect.anchor_top = 0.5
	nine_patch_rect.anchor_right = 0.5
	nine_patch_rect.anchor_bottom = 0.5
	
	nine_patch_rect.offset_left = -cfg.box_size.x / 2.0
	nine_patch_rect.offset_top = -cfg.box_size.y / 2.0
	nine_patch_rect.offset_right = cfg.box_size.x / 2.0
	nine_patch_rect.offset_bottom = cfg.box_size.y / 2.0

	var margin_container = MarginContainer.new()
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 40)
	margin_container.add_theme_constant_override("margin_right", 40)
	margin_container.add_theme_constant_override("margin_top", 30)
	margin_container.add_theme_constant_override("margin_bottom", 30)
	nine_patch_rect.add_child(margin_container)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 15)
	margin_container.add_child(main_vbox)
	
	var title_label = RichTextLabel.new()
	title_label.bbcode_enabled = true
	title_label.fit_content = true
	title_label.scroll_active = false
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "[center][font_size=%d][outline_size=%d][outline_color=#000000][b]%s[/b][/outline_color][/outline_size][/font_size][/center]" % [
		cfg.title_font_size, cfg.title_outline_size, cfg.title_text
	]
	main_vbox.add_child(title_label)

	var body_label = RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.fit_content = true
	body_label.scroll_active = false
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.text = "[center][font_size=%d][outline_size=%d][outline_color=#000000][b]%s[/b][/outline_color][/outline_size][/font_size][/center]" % [
		cfg.body_font_size, cfg.body_outline_size, cfg.body_text
	]
	main_vbox.add_child(body_label)

	var button_container = GridContainer.new()
	var btn_count = max(1, cfg.custom_buttons_cfg.size())
	button_container.columns = min(2, btn_count)
	button_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button_container.size_flags_vertical = Control.SIZE_SHRINK_END
	button_container.add_theme_constant_override("h_separation", 20)
	button_container.add_theme_constant_override("v_separation", 15)
	main_vbox.add_child(button_container)

	if cfg.custom_buttons_cfg.is_empty():
		var default_btn_cfg = LongButton.Config.new()
		default_btn_cfg.b_text = "OK"
		default_btn_cfg.b_color = LongButton.B_Color.PURPLE
		default_btn_cfg.b_size = LongButton.B_Size.SMALL
		default_btn_cfg.b_length = 350
		
		var ok_btn = _add_scaled_button_to_container(button_container, default_btn_cfg)
		ok_btn.pressed.connect(queue_free)
	else:
		for btn_cfg in cfg.custom_buttons_cfg:
			var btn = _add_scaled_button_to_container(button_container, btn_cfg)
			if btn_cfg.target_close_scenes.is_empty():
				btn.pressed.connect(queue_free)
