extends Node2D

@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var sprite: Sprite2D = $Sprite2D

func set_time(seconds_float: float) -> void:
	var total_seconds: int = ceil(maxf(seconds_float, 0.0))
	var minutes: int = int(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	
	var time_str: String = "%02d:%02d" % [minutes, seconds]
	
	rich_text_label.text = "[center]%s[/center]" % time_str

func get_box_height() -> float:
	return sprite.texture.get_size().y * sprite.scale.y
