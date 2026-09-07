extends Node2D
class_name StaticGrid

const GemScene = preload("res://Scene/BaseGem.tscn")

@export var columns: int = 20
@export var rows: int = 10
@export var cell_size: Vector2 = Vector2(80, 80)
@export var spacing: Vector2 = Vector2(8, 8)

@onready var selection: SelectionManager = $Selection
signal score_changed(score: int)
signal score_finished(score: int, gems: Array[Vector2i])
const weight: Array[int] = [7, 7, 6, 6, 5, 4, 4, 4, 3]
var total_weight: int
var grid: Array = []
enum Direction { UP, DOWN, LEFT, RIGHT }

var is_shifting: bool = false

func _ready() -> void:
	selection.selection_changed.connect(process_selected_gem)
	selection.selection_finished.connect(process_finished_gem)
	selection._setup_selection()
	total_weight = 0
	for w in weight:
		total_weight += w
	
func init_grid() -> void:
	grid.clear()
	for x in range(columns):
		grid.append([])
		for y in range(rows):
			grid[x].append(null)
			
	for y in range(rows):
		for x in range(columns):
			var gem = spawn_gem(Vector2i(x, y))
			var delay = (x + y) * 0.02
			gem.animate_spawn(delay)
			
func gen_value() -> int:
	var res: int = randi_range(0, total_weight - 1)
	for i in range(weight.size()):
		if res < weight[i]:
			return i + 1
		res -= weight[i]
	return 1
	
func init_all_1() -> void:
	grid.clear()
	for x in range(columns):
		grid.append([])
		for y in range(rows):
			grid[x].append(null)
			
	for y in range(rows):
		for x in range(columns):
			var gem = spawn_all_1(Vector2i(x, y))
			var delay = (x + y) * 0.02
			gem.animate_spawn(delay)
			
func gen_all_1() -> int:
	return 1
	
func spawn_all_1(cell: Vector2i) -> Gem:
	var gem = GemScene.instantiate()
	var val = gen_all_1()
	
	add_child(gem)
	gem.position = grid_to_world(cell)
	gem.setup(cell, val, cell_size)
	grid[cell.x][cell.y] = gem
	return gem
	
func spawn_gem(cell: Vector2i) -> Gem:
	var gem = GemScene.instantiate()
	var val = gen_value()
	
	add_child(gem)
	gem.position = grid_to_world(cell)
	gem.setup(cell, val, cell_size)
	grid[cell.x][cell.y] = gem
	return gem
	
func shift_and_refill(dir: Direction) -> void:
	if is_shifting:
		return
	is_shifting = true

	var max_pulse_delay: float = 0.0
	for x in range(columns):
		for y in range(rows):
			var gem = grid[x][y]
			if gem != null:
				var delay = _get_wave_delay(Vector2i(x, y), dir)
				gem.animate_pulse(delay, 0.15, 1.2)
				if delay > max_pulse_delay:
					max_pulse_delay = delay
	await get_tree().create_timer(max_pulse_delay + 0.15).timeout
	var moved_gems: Array = []
	match dir:
		Direction.UP:
			for x in range(columns):
				var target_y = 0
				for y in range(rows):
					if grid[x][y] != null:
						if y != target_y:
							grid[x][target_y] = grid[x][y]
							grid[x][y] = null
							grid[x][target_y].grid_pos = Vector2i(x, target_y)
							moved_gems.append(grid[x][target_y])
						target_y += 1
		Direction.DOWN:
			for x in range(columns):
				var target_y = rows - 1
				for y in range(rows - 1, -1, -1):
					if grid[x][y] != null:
						if y != target_y:
							grid[x][target_y] = grid[x][y]
							grid[x][y] = null
							grid[x][target_y].grid_pos = Vector2i(x, target_y)
							moved_gems.append(grid[x][target_y])
						target_y -= 1
		Direction.LEFT:
			for y in range(rows):
				var target_x = 0
				for x in range(columns):
					if grid[x][y] != null:
						if x != target_x:
							grid[target_x][y] = grid[x][y]
							grid[x][y] = null
							grid[target_x][y].grid_pos = Vector2i(target_x, y)
							moved_gems.append(grid[target_x][y])
						target_x += 1
		Direction.RIGHT:
			for y in range(rows):
				var target_x = columns - 1
				for x in range(columns - 1, -1, -1):
					if grid[x][y] != null:
						if x != target_x:
							grid[target_x][y] = grid[x][y]
							grid[x][y] = null
							grid[target_x][y].grid_pos = Vector2i(target_x, y)
							moved_gems.append(grid[target_x][y])
						target_x -= 1

	var move_duration: float = 0.3
	if moved_gems.size() > 0:
		var move_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		for gem in moved_gems:
			var target_pos = grid_to_world(gem.grid_pos)
			move_tween.tween_property(gem, "position", target_pos, move_duration)
		await move_tween.finished
	else:
		await get_tree().create_timer(0.05).timeout
	await refill_empty_cells(dir)
	
	is_shifting = false

func refill_empty_cells(dir: Direction) -> void:
	var max_delay: float = -1.0
	var last_tween: Tween = null

	for y in range(rows):
		for x in range(columns):
			if grid[x][y] == null:
				var cell = Vector2i(x, y)
				var gem: Gem = spawn_gem(cell)
				var delay = _get_wave_delay(cell, dir)
				var tween = gem.animate_spawn(delay)
				
				if delay > max_delay:
					max_delay = delay
					last_tween = tween

	if last_tween and last_tween.is_valid():
		await last_tween.finished

func _get_wave_delay(cell: Vector2i, dir: Direction) -> float:
	var step_delay: float = 0.02
	match dir:
		Direction.UP:
			return cell.y * step_delay
		Direction.DOWN:
			return (rows - 1 - cell.y) * step_delay
		Direction.LEFT:
			return cell.x * step_delay
		Direction.RIGHT:
			return (columns - 1 - cell.x) * step_delay
	return 0.0

func grid_to_world(cell: Vector2i) -> Vector2:
	var stride = cell_size + spacing
	return Vector2(
		cell.x * stride.x + cell_size.x / 2.0,
		cell.y * stride.y + cell_size.y / 2.0
	)
	
func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows
	
func get_gem(cell: Vector2i) -> Gem:
	if is_valid_cell(cell):
		return grid[cell.x][cell.y]
	return null
	
func get_cell_count() -> int:
	var count: int = 0
	for col in grid:
		for gem in col:
			if gem != null:
				count += 1
	return count
	
func get_cell_cleared() -> int:
	return (columns * rows - get_cell_count())
		
func has_gem_at(cell: Vector2i) -> bool:
	return is_valid_cell(cell) and grid[cell.x][cell.y] != null
	
func remove_gem(cell: Vector2i) -> void:
	var g = get_gem(cell)
	if g:
		grid[cell.x][cell.y] = null
		destroy_gem(g)
		
func destroy_gem(g: Gem) -> void:
	g.explode()
	
func set_mode(mode: SelectionManager.MODE) -> void:
	selection.current_mode = mode
	
func pause_grid(enabled: bool) -> void:
	selection.set_input_enabled(enabled)
	
func process_selected_gem(new_gems: Array[Vector2i], old_gems: Array) -> void:
	var total_val: int = 0
	
	for g in old_gems:
		var cur_gem: Gem = get_gem(g)
		if cur_gem != null:
			cur_gem.set_selected(false)
	
	for g in new_gems:
		var cur_gem: Gem = get_gem(g)
		if cur_gem != null:
			total_val += cur_gem.get_val()
			cur_gem.set_selected(true)
		score_changed.emit(total_val)
	
func process_finished_gem(fin_gems: Array[Vector2i]) -> void:
	var total_val: int = 0
	
	for g in fin_gems:
		var cur_gem: Gem = get_gem(g)
		if cur_gem != null:
			total_val += cur_gem.get_val()
			cur_gem.set_selected(false)
	score_finished.emit(total_val, fin_gems)
