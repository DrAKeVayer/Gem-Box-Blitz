extends CanvasLayer

const SCENES = {
	"MAIN_MENU": "res://Scene/MainMenu.tscn",
	"MODE_SELECTOR": "res://Scene/ModeSelector.tscn",
	"GAME_MODE_1": "res://Scene/GameMode1.tscn",
	"GAME_MODE_2": "res://Scene/GameMode2.tscn",
	"TEST_MODE": "res://Scene/TestMode.tscn",
	"GENERIC_INFO_BOX": "res://Scene/InfoBox.tscn"
}

var active_scenes: Dictionary = {}

func _ready() -> void:
	pass
	
func change_scene(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("Scene key '", scene_key, "' not found")
		return
	var path = SCENES[scene_key]
	get_tree().change_scene_to_file(path)

func create_scene(scene_key: String) -> Node:
	if not SCENES.has(scene_key):
		push_error("Scene key '", scene_key, "' not found")
		return
	if active_scenes.has(scene_key):
		var existing = active_scenes[scene_key]
		if is_instance_valid(existing):
			existing.move_to_front()
			return existing
	var packed_scene = load(SCENES[scene_key]) as PackedScene
	if packed_scene == null:
		push_error("Could not load ", scene_key)
	var instance = packed_scene.instantiate()
	add_child(instance)
	
	active_scenes[scene_key] = instance
	return instance
	
func close_scene(scene_key: String) -> void:
	if active_scenes.has(scene_key):
		var node_to_close = active_scenes[scene_key]
		if is_instance_valid(node_to_close):
			node_to_close.queue_free()
		active_scenes.erase(scene_key)

func close_all_scene() -> void:
	for key in active_scenes:
		var node_to_close = active_scenes[key]
		if is_instance_valid(node_to_close):
			node_to_close.queue_free()
		active_scenes.erase(key)

func reload_current() -> void:
	get_tree().reload_current_scene()
