extends Button
class_name RoundButton

@onready var sprite: Sprite2D = $Sprite
@onready var color_state: Sprite2D = $ColorState
@onready var click_shape: CollisionShape2D = $ClickArea/ClickShape
var change_scene_key: String = ""
var create_front_scene_key: String = ""
var scene_key_to_close: Array[String] = []
var current_base_color: B_Color = B_Color.RED

enum B_Color {
	RED, RED_PRESSED,
	BLUE, BLUE_PRESSED,
	GREEN, GREEN_PRESSED,
	GRAY
}
enum B_Icon {
	BACK
}

var b_color_load = {
	B_Color.RED: preload("res://Assets/Images/RoundButtonRed.png"),
	B_Color.RED_PRESSED: preload("res://Assets/Images/RoundButtonRedPressed.png"),
	B_Color.BLUE: preload("res://Assets/Images/RoundButtonBlue.png"),
	B_Color.BLUE_PRESSED: preload("res://Assets/Images/RoundButtonBluePressed.png"),
	B_Color.GREEN: preload("res://Assets/Images/RoundButtonGreen.png"),
	B_Color.GREEN_PRESSED: preload("res://Assets/Images/RoundButtonGreenPressed.png"),
	B_Color.GRAY: preload("res://Assets/Images/RoundButtonGray.png")
}

var b_icon_load = {
	B_Icon.BACK: preload("res://Assets/Icons/BackArrow.png")
}

var pressed_color_map = {
	B_Color.RED: B_Color.RED_PRESSED,
	B_Color.BLUE: B_Color.BLUE_PRESSED,
	B_Color.GREEN: B_Color.GREEN_PRESSED
}

class Config:
	var target_change_scene: String = ""
	var target_front_scene: String = ""
	var target_close_scenes: Array[String] = []
	var b_color: B_Color = B_Color.RED
	var b_pos: Vector2i = Vector2i(0, 0)
	var b_scale: float = 1.0
	var b_icon: B_Icon = B_Icon.BACK

func _ready() -> void:
	flat = true
	pressed.connect(_on_pressed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	if sprite:
		sprite.z_index = 1
	
func _has_point(point: Vector2) -> bool:
	if not click_shape:
		click_shape = get_node_or_null("ClickArea/ClickShape")
		
	if click_shape and click_shape.shape is CircleShape2D:
		var circle := click_shape.shape as CircleShape2D
		return point.distance_to(click_shape.position) <= circle.radius
		
	if color_state and color_state.texture:
		var radius: float = color_state.texture.get_size().x / 2.0
		return point.distance_to(Vector2(radius, radius)) <= radius
		
	return Rect2(Vector2.ZERO, size).has_point(point)

func create_button(cfg: Config) -> void:
	if not sprite:
		sprite = $Sprite
	if not color_state:
		color_state = $ColorState
	if not click_shape:
		click_shape = $ClickArea/ClickShape
		
	if not cfg.target_change_scene.is_empty():
		change_scene_key = cfg.target_change_scene
	if not cfg.target_front_scene.is_empty():
		create_front_scene_key = cfg.target_front_scene
	if not cfg.target_close_scenes.is_empty():
		scene_key_to_close = cfg.target_close_scenes
	current_base_color = cfg.b_color
	_set_color_state(current_base_color)
	
	if cfg.b_icon in b_icon_load:
		sprite.texture = b_icon_load[cfg.b_icon]
		
	_adjust_layout()

	position = cfg.b_pos
	scale = Vector2(cfg.b_scale, cfg.b_scale)
	pivot_offset = Vector2.ZERO
	
func _adjust_layout() -> void:
	if color_state and color_state.texture:
		var base_size: Vector2 = color_state.texture.get_size()
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		custom_minimum_size = base_size
		size = base_size
		
		color_state.centered = true
		color_state.offset = Vector2.ZERO
		color_state.position = base_size / 2.0
		
		if sprite and sprite.texture:
			var icon_size: Vector2 = sprite.texture.get_size()
			if icon_size.x > 0 and icon_size.y > 0:
				var padding_ratio: float = 0.6
				var scale_val: float = min(base_size.x / icon_size.x, base_size.y / icon_size.y) * padding_ratio
				sprite.scale = Vector2(scale_val, scale_val)
				
				sprite.centered = true
				sprite.offset = Vector2.ZERO
				sprite.position = base_size / 2.0
				
				sprite.z_index = 1
		
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
