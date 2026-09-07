extends Button
class_name LongButton

@onready var content: RichTextLabel = $Content
@onready var color_state: NinePatchRect = $ColorState

var change_scene_key: String = ""
var create_front_scene_key: String = ""
var scene_key_to_close: Array[String] = []
var current_base_color: B_Color = B_Color.PURPLE

enum B_Color {
	RED, RED_PRESSED,
	PURPLE, PURPLE_PRESSED,
	GREEN, GREEN_PRESSED,
	YELLOW, YELLOW_PRESSED,
	GRAY
}

enum B_Size {
	LARGE,
	MEDIUM,
	SMALL,
	TINY
}

const SIZE_PRESETS = {
	B_Size.LARGE: {
		"scale": 1.0,
		"font_size": 120,
		"outline_size": 20
	},
	B_Size.MEDIUM: {
		"scale": 0.75,
		"font_size": 110,
		"outline_size": 18
	},
	B_Size.SMALL: {
		"scale": 0.5,
		"font_size": 90,
		"outline_size": 15
	},
	B_Size.TINY: {
		"scale": 0.35,
		"font_size": 70,
		"outline_size": 2
	}
}

var b_color_load = {
	B_Color.RED: preload("res://Assets/Images/LongButtonRed.png"),
	B_Color.RED_PRESSED: preload("res://Assets/Images/LongButtonRedPressed.png"),
	B_Color.PURPLE: preload("res://Assets/Images/LongButtonPurple.png"),
	B_Color.PURPLE_PRESSED: preload("res://Assets/Images/LongButtonPurplePressed.png"),
	B_Color.GREEN: preload("res://Assets/Images/LongButtonGreen.png"),
	B_Color.GREEN_PRESSED: preload("res://Assets/Images/LongButtonGreenPressed.png"),
	B_Color.YELLOW: preload("res://Assets/Images/LongButtonYellow.png"),
	B_Color.YELLOW_PRESSED: preload("res://Assets/Images/LongButtonYellowPressed.png"),
	B_Color.GRAY: preload("res://Assets/Images/LongButtonGray.png")
}

var pressed_color_map = {
	B_Color.RED: B_Color.RED_PRESSED,
	B_Color.PURPLE: B_Color.PURPLE_PRESSED,
	B_Color.GREEN: B_Color.GREEN_PRESSED,
	B_Color.YELLOW: B_Color.YELLOW_PRESSED
}

class Config:
	var target_change_scene: String = ""
	var target_front_scene: String = ""
	var target_close_scenes: Array[String] = []
	var b_text: String = "Missing."
	var b_color: B_Color = B_Color.PURPLE
	var b_pos: Vector2i = Vector2i(0, 0)
	var b_length: int = 500
	var b_size: B_Size = B_Size.LARGE
	var f_color: Color = Color.WHITE
	var outl_color: Color = Color.BLACK

func _ready() -> void:
	content.bbcode_enabled = true
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	pressed.connect(_on_pressed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func create_button(cfg: Config) -> void:
	if not content:
		content = $Content
	if not color_state:
		color_state = $ColorState
		
	var f_color_hex = cfg.f_color.to_html(false)
	var outl_color_hex = cfg.outl_color.to_html(false)
	
	var preset = SIZE_PRESETS[cfg.b_size]
	var scale_val: float = preset["scale"]
	var f_size: int = preset["font_size"]
	var outl_size: int = preset["outline_size"]
	
	content.text = "[center][font_size=%d][color=#%s][outline_color=#%s][outline_size=%d]%s[/outline_size][/outline_color][/color][/font_size][/center]" % [
		f_size, f_color_hex, outl_color_hex, outl_size, cfg.b_text
	]
	
	if not cfg.target_change_scene.is_empty():
		change_scene_key = cfg.target_change_scene
	if not cfg.target_front_scene.is_empty():
		create_front_scene_key = cfg.target_front_scene
	if not cfg.target_close_scenes.is_empty():
		scene_key_to_close = cfg.target_close_scenes
		
	current_base_color = cfg.b_color
	_set_color_state(cfg.b_color)
	
	position = cfg.b_pos
	scale = Vector2(scale_val, scale_val)
	custom_minimum_size = Vector2(cfg.b_length, 298)
	pivot_offset = Vector2(cfg.b_length, 298) * 0.5
		
func _set_color_state(state: B_Color) -> void:
	color_state.texture = b_color_load[state]
	
func _on_button_down() -> void:
	if pressed_color_map.has(current_base_color):
		_set_color_state(pressed_color_map[current_base_color])

func _on_button_up() -> void:
	_set_color_state(current_base_color)
	
func _on_pressed():
	AudioManager.play_sfx("click")
	for key in scene_key_to_close:
		if not key.is_empty():
			SceneManager.close_scene(key)
	if not create_front_scene_key.is_empty():
		SceneManager.create_scene(create_front_scene_key)
	if not change_scene_key.is_empty():
		SceneManager.change_scene(change_scene_key)
