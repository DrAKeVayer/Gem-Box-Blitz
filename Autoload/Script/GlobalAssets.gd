extends Node

const LONG_BUTTON = preload("res://Scene/LongButton.tscn")
const ROUND_BUTTON = preload("res://Scene/RoundButton.tscn")
const INFO_BOX = preload("res://Scene/InfoBox.tscn")

func create_long_button() -> LongButton:
	return LONG_BUTTON.instantiate()
	
func create_round_button() -> RoundButton:
	return ROUND_BUTTON.instantiate()

func show_info_box(cfg: InfoBox.Config = null) -> InfoBox:
	var box = INFO_BOX.instantiate() as InfoBox
	if cfg == null:
		cfg = InfoBox.Config.new()
	get_tree().root.add_child(box)
	box.create_info_box(cfg)
	
	return box
