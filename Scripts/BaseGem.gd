extends Control
class_name Gem

var grid_pos: Vector2i = Vector2i.ZERO
var val: int = 1
var is_selected: bool = false
var deleted: bool = false
@onready var sprite: Sprite2D = $MainSprite
@onready var text = $Number
@onready var highlight = $SelectedSprite
@onready var explosion = $Explode
@onready var gem_area: Area2D = $GemArea
@onready var col_shape: CollisionShape2D = $GemArea/CollisionShape2D

func setup(p_grid_pos: Vector2i, p_val: int, target_cell_size: Vector2) -> void:
	val = p_val
	is_selected = false
	grid_pos = p_grid_pos
	
	size = target_cell_size
	custom_minimum_size = target_cell_size
	pivot_offset = target_cell_size / 2.0

	if sprite and sprite.texture:
		var tex_size = sprite.texture.get_size()
		sprite.scale = target_cell_size / tex_size
		sprite.position = Vector2.ZERO
		sprite.centered = true
		sprite.visible = true                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
	
	if text:
		text.text = str(val)
		text.size = target_cell_size
		text.position = - (target_cell_size)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if highlight:
		var tex_size = sprite.texture.get_size()
		highlight.scale = target_cell_size / tex_size
		highlight.position = - (target_cell_size / 2)
		highlight.centered = true
		highlight.visible = false
	
	if explosion:
		explosion.emitting = false
		explosion.position = - (target_cell_size / 2)
		
	if col_shape and col_shape.shape is RectangleShape2D:
		col_shape.shape.size = target_cell_size
		col_shape.position = - (target_cell_size / 2)
	
func set_selected(setter: bool) -> void:
	is_selected = setter
	sprite.visible = !setter
	highlight.visible = setter
	
func get_val() -> int:
	return val
	
func animate_spawn(delay: float = 0.0, duration: float = 0.25) -> Tween:
	scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE, duration)
	return tween
	
func animate_pulse(delay: float = 0.0, duration: float = 0.4, max_scale: float = 1.2) -> void:
	var tween = create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	
	tween.tween_property(self, "scale", Vector2.ONE * max_scale, duration * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, duration * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
func explode() -> void:
	if deleted:
		return

	deleted = true
	text.visible = false
	highlight.visible = false

	if explosion:
		explosion.emitting = true

	var hollow_material := sprite.material as ShaderMaterial

	if hollow_material:
		var tween := create_tween()
		
		tween.tween_property(hollow_material, "shader_parameter/hole_progress", 1.0, 0.25)\
			.from(0.0)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)

		tween.tween_callback(func():
			sprite.visible = false
		)
	else:
		sprite.visible = false
