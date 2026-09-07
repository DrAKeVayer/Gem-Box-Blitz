extends Node2D
class_name SelectionManager

signal selection_changed(new_cells: Array[Vector2i], old_cells: Array[Vector2i])
signal selection_finished(cells: Array[Vector2i])

enum MODE {RECTANGLE, PATH}
@export var current_mode: MODE = MODE.RECTANGLE

@export var rect_fill_color: Color = Color(0.2, 0.6, 1.0, 0.25)
@export var rect_border_color: Color = Color(0.2, 0.6, 1.0, 0.9)
@export var path_line_color: Color = Color(1.0, 0.8, 0.2, 0.9)
@export var path_line_width: float = 4.0

var is_selecting: bool = false
var is_input_enabled: bool = true
var drag_cur_pos: Vector2 = Vector2.ZERO
var drag_start_pos: Vector2 = Vector2.ZERO

var select_area: Area2D
var select_collision: CollisionShape2D
var select_shape: RectangleShape2D

var selected_cells: Array[Vector2i] = []

func _setup_selection() -> void:
	select_area = Area2D.new()
	select_collision = CollisionShape2D.new()
	select_shape = RectangleShape2D.new()
	
	select_collision.shape = select_shape
	select_area.add_child(select_collision)
	add_child(select_area)
	
	select_area.collision_layer = 0
	select_area.collision_mask = 2
	select_area.monitoring = false
	EventBus.pause_game.connect(set_paused)
	
func set_paused(enabled: bool) -> void:
	is_input_enabled = !enabled
	set_process_unhandled_input(!enabled)
	
	if enabled and is_selecting:
		cancel_selection()

func cancel_selection() -> void:
	if not is_selecting:
		return
	is_selecting = false
	if select_area:
		select_area.monitoring = false
		
	selected_cells.clear()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not is_input_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_selection()
		else:
			_end_selection()
	elif event is InputEventMouseMotion and is_selecting:
		_update_selection()
		
func _start_selection() -> void:
	is_selecting = true
	drag_start_pos = to_local(get_global_mouse_position())
	drag_cur_pos = drag_start_pos
	selected_cells.clear()
	
	if current_mode == MODE.RECTANGLE:
		select_area.monitoring = true
		_sync_select_box()
		_query_overlapping_gems()
	elif current_mode == MODE.PATH:
		_check_hovered_gem_for_path()
		
	queue_redraw()

func _update_selection() -> void:
	drag_cur_pos = to_local(get_global_mouse_position())
	
	if current_mode == MODE.RECTANGLE:
		_sync_select_box()
		_query_overlapping_gems()
	elif current_mode == MODE.PATH:
		_check_hovered_gem_for_path()
		
	queue_redraw()

func _end_selection() -> void:
	if not is_selecting:
		return
	is_selecting = false
	select_area.monitoring = false
	queue_redraw()
	
	if selected_cells.size() > 0:
		selection_finished.emit(selected_cells)
	selected_cells = []
	
func _sync_select_box() -> void:
	var top_left = Vector2(minf(drag_start_pos.x, drag_cur_pos.x), minf(drag_start_pos.y, drag_cur_pos.y))
	var bottom_right = Vector2(maxf(drag_start_pos.x, drag_cur_pos.x), maxf(drag_start_pos.y, drag_cur_pos.y))
	var box_size = (bottom_right - top_left).abs()
	
	select_area.position = top_left + box_size / 2.0
	select_shape.size = box_size
	
func _query_overlapping_gems() -> void:
	var areas = select_area.get_overlapping_areas()
	var new_cells: Array[Vector2i] = []
	
	for a in areas:
		var gem = a.get_parent() as Gem
		if gem and not new_cells.has(gem.grid_pos):
			new_cells.append(gem.grid_pos)
			
	if new_cells != selected_cells:
		selection_changed.emit(new_cells, selected_cells)
		selected_cells = new_cells
	
func _check_hovered_gem_for_path() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collision_mask = 2
	
	var results = space_state.intersect_point(query)
	if results.is_empty():
		return
		
	var gem = results[0].collider.get_parent() as Gem
	if not gem:
		return
		
	var cur_cell: Vector2i = gem.grid_pos
	if selected_cells.is_empty():
		selected_cells.append(cur_cell)
		selection_changed.emit(selected_cells, [])
		return
		
	if selected_cells.size() >= 2 and cur_cell == selected_cells[selected_cells.size() - 2]:
		var old = selected_cells.duplicate()
		selected_cells.pop_back()
		selection_changed.emit(selected_cells, old)
		return
		
	var last_cell: Vector2i = selected_cells.back()
	if cur_cell != last_cell and not selected_cells.has(cur_cell):
		if cur_cell.x == last_cell.x or cur_cell.y == last_cell.y:
			var segment = _get_line_cells(last_cell, cur_cell)
			
			if not _is_segment_clear(segment, cur_cell):
				return
				
			var pending = selected_cells.duplicate()
			pending.append_array(segment)
			
			if _count_corners(pending) > 1:
				return
				
			var old = selected_cells.duplicate()
			selected_cells.append_array(segment)
			selection_changed.emit(selected_cells, old)

func _get_line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var step = Vector2i(
		clampi(to.x - from.x, -1, 1),
		clampi(to.y - from.y, -1, 1)
	)
	var cur = from + step
	while cur != to + step:
		cells.append(cur)
		cur += step
	return cells

func _is_segment_clear(segment: Array[Vector2i], target_cell: Vector2i) -> bool:
	for cell in segment:
		if selected_cells.has(cell):
			return false
			
		if cell != target_cell:
			if _is_cell_blocked(cell):
				return false
	return true

func _is_cell_blocked(cell: Vector2i) -> bool:
	var parent_grid = get_parent() as StaticGrid
	if not parent_grid:
		return false

	return parent_grid.has_gem_at(cell)
			
func _count_corners(path: Array[Vector2i]) -> int:
	if path.size() < 3:
		return 0
	var corners: int = 0
	var last_direct: Vector2i = path[1] - path[0]
	for i in range (2, path.size()):
		var cur_direct: Vector2i = path[i] - path[i - 1]
		if cur_direct != last_direct:
			corners += 1
		last_direct = cur_direct
	return corners
	
func _draw() -> void:
	if not is_selecting:
		return
	match current_mode:
		MODE.RECTANGLE:
			var top_left = Vector2(minf(drag_start_pos.x, drag_cur_pos.x), minf(drag_start_pos.y, drag_cur_pos.y))
			var size = (drag_cur_pos - drag_start_pos).abs()
			var rect = Rect2(top_left, size)
			
			draw_rect(rect, rect_fill_color, true)
			draw_rect(rect, rect_border_color, false, 2.0)
		MODE.PATH:
			if selected_cells.size() > 1:
				var parent_grid = get_parent() as StaticGrid
				var points: PackedVector2Array = []
				for cell in selected_cells:
					points.append(parent_grid.grid_to_world(cell) - (parent_grid.cell_size / 2))
				draw_polyline(points, path_line_color, path_line_width, true)
				for cell in selected_cells:
					draw_circle(parent_grid.grid_to_world(cell) - (parent_grid.cell_size / 2), 6.0, path_line_color)
