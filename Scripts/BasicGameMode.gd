extends Node2D

@onready var grid = $NormalGrid
@export var selection_mode: SelectionManager.MODE

var target_score: int = 10
var total_score: int = 0
var level: int = 1
var level_target: Array[int] = [10, 100, 105, 110, 115, 120, 125, 135, 150, 175]
const LEVEL_OVERFLOW: int = 185
var ace_target: int = 190
const ACE_OVERFLOW: int = 198
var cleared: int = 0
var is_level_complete: bool = false
var is_level_aced: bool = false
var combo_stage: int = 0

@export var max_time: float = 90.0
@export var initial_time: float = 90.0
var base_max_time: float = 90.0
var level_timer: Timer

var combo_timeout: float = 4.0
var combo_streak: int = 0
var combo_timer: float = 0.0
var current_blitz_tier: String = ""
var is_combo_active: bool = false
var is_game_paused: bool = false 

var is_warning_active: bool = false

const MATCH_CONFIGS: Dictionary = {
	3: {"text": "GOOD!", "sfx": "voice_good", "score": 2},
	4: {"text": "AWESOME!", "score": 5, "sfx": "voice_awesome"},
	5: {"text": "SPECTACULAR!", "sfx": "voice_specta"},
	6: {"text": "UNBELIEVABLE!", "sfx": "voice_unbelieve"}
}

const BLITZ_CONFIGS: Dictionary = {
	3: {"tier": "2", "text": "GREAT BLITZ", "time": 0.5},
	6: {"tier": "3", "text": "AWESOME BLITZ", "time": 0.75},
	10: {"tier": "4", "text": "SUPER BLITZ", "time": 1.0},
	15: {"tier": "5", "text": "HYPER BLITZ", "time": 1.25}
}

func _get_blitz_data(streak: int) -> Dictionary:
	if streak in BLITZ_CONFIGS:
		return BLITZ_CONFIGS[streak]
	if streak > 15 and streak % 5 == 0:
		return {"tier": "6", "text": "UNBELIEVABLE BLITZ", "time": 1.5}
	return {}

func _get_combo_tier(streak: int, sfx_index: int) -> Dictionary:
	if streak >= 20: return {"bonus": 5, "sfx": "blitzed6"}
	elif streak >= 15: return {"bonus": 5, "sfx": "blitzed5"}
	elif streak >= 10: return {"bonus": 3, "sfx": "blitzed4"}
	elif streak >= 6: return {"bonus": 2, "sfx": "blitzed3"}
	elif streak >= 3: return {"bonus": 1, "sfx": "blitzed2"}
	return {"bonus": 0, "sfx": "matched%d" % sfx_index}

func _ready() -> void:
	base_max_time = max_time
	
	EventBus.pause_game.connect(_on_pause_game)
	EventBus.level_up_time_landed.connect(_on_level_up_time_landed)
	EventBus.level_up_sequence_finished.connect(_on_level_up_sequence_finished)
	
	grid.score_changed.connect(func(score): EventBus.total_score_updated.emit(score))
	grid.score_finished.connect(process_match)
	grid.set_mode(selection_mode)
	
	EventBus.pause_game.emit(true)
	AudioManager.play_bgm("blitz")
	
	total_score = 0
	_setup_timer()
	
	EventBus.timer_setup.emit(initial_time, max_time)
	EventBus.level_target_setup.emit(level_target[level])
	EventBus.level_updated.emit(level)
	EventBus.combo_reset.emit()
	EventBus.level_state_changed.emit(0)
	
	var voice_ready: AudioStreamPlayer = AudioManager.play_sfx("voice_get_ready")
	if voice_ready:
		await voice_ready.finished
		
	AudioManager.play_sfx("voice_go")
	EventBus.popup_text_requested.emit("GO!", false)
	
	EventBus.pause_game.emit(false)
	start_game_timer()

func _setup_timer() -> void:
	level_timer = Timer.new()
	level_timer.one_shot = true
	level_timer.wait_time = initial_time
	level_timer.timeout.connect(_on_timer_timeout)
	add_child(level_timer)
	
func _process(_delta: float) -> void:
	if is_game_paused:
		return
		
	if level_timer and not level_timer.is_stopped():
		var time_left: float = level_timer.time_left
		EventBus.timer_updated.emit(time_left)
		
		if is_combo_active:
			combo_timer -= _delta
			EventBus.combo_updated.emit(combo_streak, 0, "", combo_timer)
			if combo_timer <= 0.0:
				_reset_combo()
		
		if time_left <= 10.0 and not is_warning_active and time_left > 0.0:
			is_warning_active = true
			EventBus.warning_state_changed.emit(true)
		elif time_left > 10.0 and is_warning_active:
			is_warning_active = false
			EventBus.warning_state_changed.emit(false)

func _unhandled_input(event: InputEvent) -> void:
	if is_game_paused or not (is_level_complete or is_level_aced) or grid.is_shifting:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE):
		_level_up()

func _on_pause_game(is_paused: bool) -> void:
	is_game_paused = is_paused
	if level_timer:
		level_timer.paused = is_paused

func start_game_timer() -> void:
	level_timer.wait_time = initial_time
	level_timer.start()
	EventBus.timer_setup.emit(initial_time, max_time)
	
func add_timer_time(bonus_time: float) -> void:
	if not level_timer: return
		
	var old_time: float = level_timer.time_left if not level_timer.is_stopped() else 0.0
	var new_time: float = clampf(old_time + bonus_time, 0.0, 600.0)
	
	if new_time > max_time:
		max_time = new_time
	
	level_timer.wait_time = max_time
	level_timer.start(new_time)
	EventBus.timer_bonus_added.emit(bonus_time, new_time, max_time)
	
	if new_time > 10.0 and is_warning_active:
		is_warning_active = false
		EventBus.warning_state_changed.emit(false)

func _on_timer_timeout() -> void:
	if is_warning_active:
		is_warning_active = false
		EventBus.warning_state_changed.emit(false)
		
	if is_level_complete:
		_level_up()
		return
		
	EventBus.timer_updated.emit(0.0)
	EventBus.pause_game.emit(true)
	AudioManager.play_sfx("voice_timeup")
	EventBus.popup_text_requested.emit("TIME UP!", false)
	EventBus.game_over.emit()
		
func check_blitz_streak(streak: int) -> void:
	var data: Dictionary = _get_blitz_data(streak)
	if data.is_empty(): 
		return
	var old_tier: String = current_blitz_tier
	current_blitz_tier = data.tier
	
	add_timer_time(data.time)
	EventBus.blitz_triggered.emit(old_tier, data.tier, data.text, data.time)

func _process_match_reward(matched_gems: int) -> int:
	if matched_gems < 2: return 0
		
	if matched_gems >= 5:
		add_timer_time(0.5 * matched_gems)
	else:
		var base_time: float = 0.5 * matched_gems
		var min_time: float = 0.25 * matched_gems
		var penalty: float = 0.03 * (level - 1) * (5 - matched_gems)
		add_timer_time(maxf(min_time, base_time - penalty))
		
	var bonus_score: int = 0
	var config: Dictionary = MATCH_CONFIGS.get(mini(matched_gems, 6), {})
	if not config.is_empty():
		bonus_score += (10 * (matched_gems - 4)) if matched_gems >= 5 else config.get("score", 0)
		EventBus.match_rewarded.emit(matched_gems, config.text, config.sfx)

	is_combo_active = true
	combo_timer = combo_timeout
	combo_streak += 1
	check_blitz_streak(combo_streak)
	
	var sfx_index: int = clampi(matched_gems - 1, 1, 6)
	var combo_data: Dictionary = _get_combo_tier(combo_streak, sfx_index)
	bonus_score += combo_data.bonus
	
	EventBus.combo_updated.emit(combo_streak, combo_data.bonus, combo_data.sfx, combo_timeout)
	return bonus_score

func _reset_combo() -> void:
	is_combo_active = false
	combo_timer = 0.0
	combo_streak = 0
	current_blitz_tier = ""
	EventBus.combo_reset.emit()

func _process_level() -> void:
	cleared = grid.get_cell_cleared()
	EventBus.level_progress_updated.emit(cleared)
	
	if cleared >= ace_target:
		if not is_level_aced:
			is_level_aced = true
			is_level_complete = true
			EventBus.level_state_changed.emit(2) # ACE
	elif cleared >= level_target[level]:
		if not is_level_complete:
			is_level_complete = true
			EventBus.level_state_changed.emit(1) # COMPLETE

func process_match(score: int, gems: Array[Vector2i]) -> void:
	if score == target_score:
		var valid_gem: int = 0
		for g in gems:
			if grid.get_gem(g) != null:
				grid.remove_gem(g)
				valid_gem += 1
				
		total_score += level * (target_score + _process_match_reward(valid_gem))
		EventBus.score_updated.emit(total_score)
		_process_level()

func _level_up() -> void:
	EventBus.pause_game.emit(true)
	level += 1
	var was_aced: bool = is_level_aced
	is_level_aced = false
	is_level_complete = false
	
	if was_aced: AudioManager.play_sfx("level_aced")
	else: AudioManager.play_sfx("level_complete")
	
	EventBus.level_up_sequence_started.emit(level - 1, was_aced)

func _on_level_up_time_landed(bonus_time: float) -> void:
	add_timer_time(bonus_time)
	if level_timer and not level_timer.is_stopped():
		var current_left: float = level_timer.time_left
		max_time = clampf(current_left, base_max_time, max_time)
		level_timer.wait_time = max_time
		EventBus.timer_setup.emit(current_left, max_time)

func _on_level_up_sequence_finished() -> void:
	EventBus.level_state_changed.emit(0)
	if level >= 10:
		level_target.append(LEVEL_OVERFLOW)
		ace_target = ACE_OVERFLOW
	EventBus.level_target_setup.emit(level_target[level])
	
	var target_dir: StaticGrid.Direction
	match (level - 2) % 4:
		0: target_dir = StaticGrid.Direction.DOWN
		1: target_dir = StaticGrid.Direction.LEFT
		2: target_dir = StaticGrid.Direction.UP
		3: target_dir = StaticGrid.Direction.RIGHT
	
	await grid.shift_and_refill(target_dir)
	EventBus.level_updated.emit(level)
	await get_tree().create_timer(0.75).timeout
	
	EventBus.popup_text_requested.emit("GO!", false)
	AudioManager.play_sfx("voice_go")
	EventBus.pause_game.emit(false)
