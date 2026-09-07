extends Control

@onready var background: Sprite2D = $Background
@onready var red_border: CanvasItem = $RedBorder
@onready var total_text: RichTextLabel = $InfoHUD/Total
@onready var score_text: RichTextLabel = $InfoHUD/Score
@onready var level_text: RichTextLabel = $InfoHUD/Level
@onready var timer_bar: TextureProgressBar = $TimerBar
@onready var timer_particle: GPUParticles2D = $TimerBar/TimerParticle
@onready var timer_box = $TimerBar/TimerBox
@onready var combo_bar: TextureProgressBar = $ComboBar
@onready var combo_count: RichTextLabel = $ComboBar/ComboCount
@onready var combo_particle: GPUParticles2D = $ComboBar/ComboParticle
@onready var level_bar: TextureProgressBar = $LevelBar
@onready var combo_bar_back: TextureProgressBar = $ComboBackground
@onready var background_mat = background.material as ShaderMaterial
@onready var flame_mat = combo_bar_back.material as ShaderMaterial

const DEFAULT_COLOR_A: Color = Color(0.9, 0.9, 0.9, 1.0)
const DEFAULT_COLOR_B: Color = Color(0.65, 0.65, 0.65, 1.0)

var bg_col_a: Color = DEFAULT_COLOR_A
var bg_col_b: Color = DEFAULT_COLOR_B
var flame_col_a: Color = DEFAULT_COLOR_A
var flame_col_b: Color = DEFAULT_COLOR_B

var default_scroll_speed: float = 0.8
var bg_scroll_speed: float = 0.8
var flame_scroll_speed: float = 0.8

var bg_accumulated_offset: float = 0.0
var flame_accumulated_offset: float = 0.0

var bg_wave_tween: Tween
var flame_burst_tween: Tween

var _combo_tween: Tween
var level_target: int = 100
var warning_tween: Tween
var wave_tween: Tween

static var BAR_EFFECT_CONFIGS: Dictionary = {
	1: {
		"color": Color(1.0, 0.9, 0.0, 1.0),
		"texture": preload("res://Assets/Images/GoldParticle.png")
	},
	2: {
		"color": Color(0.9, 0.2, 1.0, 1.0),
		"texture": preload("res://Assets/Images/PurpleParticle.png")
	}
}

var max_time: float = 60.0
var default_tween_duration: float = 1.0
var display_time: float = 0.0
var timer_tween: Tween
var is_intro_playing: bool = true
const BASE_SCALE: Vector2 = Vector2(0.15, 0.15)

const BLITZ_GRADIENTS = {
	"2": {
		"top": Color("#A6FF73"),
		"bottom": Color("#1FB852")
	},
	"3": {
		"top": Color("#66F2FF"),
		"bottom": Color("#1580E0")
	},
	"4": {
		"top": Color("#FFEB4D"),
		"bottom": Color("#FA8514")
	},
	"5": {
		"top": Color("#FF7333"),
		"bottom": Color("#E01A2E")
	},
	"6": {
		"top": Color("#EB66FF"),
		"bottom": Color("#6B0DA6")
	}
}

const CHEVRON_COLORS = {
	"2": Color("#1FB852"),
	"3": Color("#1580E0"),
	"4": Color("#FA8514"),
	"5": Color("#E01A2E"),
	"6": Color("#6B0DA6")
}

const COMBO_BAR_CONFIG = {
	"2": {
		"color": Color("#1FB852"),
		"amount": 12,
		"initial_velocity": 20.0
	},
	"3": {
		"color": Color("#1580E0"),
		"amount": 16,
		"initial_velocity": 28.0
	},
	"4": {
		"color": Color("#FA8514"),
		"amount": 20,
		"initial_velocity": 36.0
	},
	"5": {
		"color": Color("#E01A2E"),
		"amount": 26,
		"initial_velocity": 45.0
	},
	"6": {
		"color": Color("#6B0DA6"),
		"amount": 32,
		"initial_velocity": 55.0
	}
}

const WAVE_GRADIENT: Dictionary = {
	"4": {
		"color_a": Color(1.0, 0.9, 0.0, 1.0),
		"color_b": Color(1.0, 0.55, 0.1, 1.0)
	},
	"6": {
		"color_a": Color(0.9, 0.2, 1.0, 1.0),
		"color_b": Color(1.0, 0.35, 0.75, 1.0)
	},
	"2": {
		"color_a": Color("22d55fff"),
		"color_b": Color(0.2, 1.0, 0.8, 1.0)
	},
	"3": {
		"color_a": Color("3d9afaff"),
		"color_b": Color(0.3, 0.85, 1.0, 1.0)
	},
	"5": {
		"color_a": Color("fb4448ff"),
		"color_b": Color(1.0, 0.45, 0.2, 1.0)
	}
}

@export var font_size: int = 70
@export var outline_size: int = 10
@export var outline_color: Color = Color.BLACK
@export var enter_duration: float = 0.35
@export var stay_duration: float = 0.9
@export var exit_duration: float = 0.25
@export var trail_interval: float = 0.018

const POOL_SIZE: int = 40
var _ghost_pool: Array[RichTextLabel] = []
var _pool_index: int = 0
var _trail_timer: float = 0.0
var _is_trailing: bool = false
var blitz_label: RichTextLabel
var _blitz_tween: Tween
var _is_game_paused: bool = false

func _ready() -> void:
	if red_border: red_border.modulate.a = 0.0
	reset_bar_effects()
	stop_combo_bar_effect()
	_init_materials()
	
	update_total(0)
	update_score(0)
	update_level(1)
	update_combo_count(0)
	timer_bar.step = 0.0
	timer_box.scale = Vector2(0.15, 0.15)
	
	_setup_return_button()
	play_timer_box_intro()
	set_up_combo_bar()
	update_combo_visuals()
	_setup_blitz_labels()
	
	EventBus.pause_game.connect(func(paused): _is_game_paused = paused)
	EventBus.total_score_updated.connect(update_total)
	EventBus.score_updated.connect(update_score)
	EventBus.level_updated.connect(update_level)
	EventBus.level_target_setup.connect(set_up_level_bar)
	EventBus.level_progress_updated.connect(update_level_bar)
	EventBus.level_state_changed.connect(play_timer_bar_effect)
	
	EventBus.timer_setup.connect(set_up_timer_bar)
	EventBus.timer_updated.connect(update_timer)
	EventBus.timer_bonus_added.connect(func(bonus, tgt, n_max): animate_time_bonus(bonus, tgt, n_max, 0.6))
	EventBus.warning_state_changed.connect(_on_warning_state_changed)
	
	EventBus.match_rewarded.connect(func(_gems, text, _sfx): play_popup_text_animation(text, true))
	EventBus.combo_updated.connect(_on_combo_updated) #combo time left update
	EventBus.combo_reset.connect(_on_combo_reset) #combo lost
	EventBus.blitz_triggered.connect(_on_blitz_triggered) #blitz info every match
	EventBus.popup_text_requested.connect(play_popup_text_animation)
	EventBus.level_up_sequence_started.connect(play_level_up_sequence)

func _init_materials() -> void:
	if background_mat:
		background_mat.set_shader_parameter("current_gradient_a", bg_col_a)
		background_mat.set_shader_parameter("current_gradient_b", bg_col_b)
		background_mat.set_shader_parameter("target_gradient_a", bg_col_a)
		background_mat.set_shader_parameter("target_gradient_b", bg_col_b)
		background_mat.set_shader_parameter("wave_crest_intensity", 0.0)

	if flame_mat:
		flame_mat.set_shader_parameter("current_gradient_a", flame_col_a)
		flame_mat.set_shader_parameter("current_gradient_b", flame_col_b)
		flame_mat.set_shader_parameter("target_gradient_a", flame_col_a)
		flame_mat.set_shader_parameter("target_gradient_b", flame_col_b)
		flame_mat.set_shader_parameter("color_mix_factor", 0.0)

func _setup_return_button() -> void:
	var return_btn = GlobalAssets.create_round_button()
	var cfg3 = RoundButton.Config.new()
	cfg3.target_change_scene = "MAIN_MENU"
	cfg3.b_scale = 0.25
	cfg3.b_icon = RoundButton.B_Icon.BACK
	var base_texture = return_btn.b_color_load[cfg3.b_color]
	var margin_x: float = 30.0
	var margin_y: float = 30.0
	var pos_top_right = Vector2i(int(get_viewport_rect().size.x - (base_texture.get_size().x * cfg3.b_scale) - margin_x), int(margin_y))
	cfg3.b_pos = pos_top_right
	return_btn.create_button(cfg3)
	add_child(return_btn)

func _setup_blitz_labels() -> void:
	blitz_label = _create_gradient_text_node()
	blitz_label.visible = false
	add_child(blitz_label)
	for i in range(POOL_SIZE):
		var ghost: RichTextLabel = _create_gradient_text_node()
		ghost.visible = false
		ghost.show_behind_parent = true
		add_child(ghost)
		_ghost_pool.append(ghost)

func _process(delta: float) -> void:
	if _is_trailing and blitz_label:
		_trail_timer += delta
		if _trail_timer >= trail_interval:
			_trail_timer = 0.0
			_spawn_ghost(blitz_label.position)

	if background_mat:
		bg_accumulated_offset += bg_scroll_speed * delta
		bg_accumulated_offset = fmod(bg_accumulated_offset, 1.0)
		background_mat.set_shader_parameter("scroll_offset", bg_accumulated_offset)
	if flame_mat:
		flame_accumulated_offset += flame_scroll_speed * delta
		flame_accumulated_offset = fmod(flame_accumulated_offset, 1.0)
		flame_mat.set_shader_parameter("scroll_offset", flame_accumulated_offset)

func _on_combo_updated(_streak: int, bonus: int, _sfx: String, timeout: float) -> void:
	combo_bar.value = timeout
	combo_bar_back.value = timeout
	if bonus > 0: update_combo_count(bonus)

func _on_combo_reset() -> void:
	combo_bar.value = 0.0
	combo_bar_back.value = 0.0
	update_combo_count(0)
	stop_combo_bar_effect()
	reset_all_gradients_to_default(0.6)

func _on_blitz_triggered(old_tier: String, tier: String, text: String, _time: float) -> void:
	play_blitz_text(text, tier)
	play_timer_bar_chevron(tier)
	play_combo_bar_effect(tier)

	if tier != old_tier:
		play_horizontal_wake_transition(tier, 1.3)
		play_burst_transition(tier, 10.0, 0.8)
	else:
		play_burst_transition(tier, 8.0, 0.5)

func _on_warning_state_changed(is_active: bool) -> void:
	if is_active:
		_loop_warning_sequence()
	else:
		if warning_tween and warning_tween.is_valid():
			warning_tween.kill()
		if red_border:
			var exit_tween = create_tween()
			exit_tween.tween_property(red_border, "modulate:a", 0.0, 0.2)

func _loop_warning_sequence() -> void:
	if _is_game_paused: return
	
	AudioManager.play_sfx("time_warning")
	if red_border:
		if warning_tween and warning_tween.is_valid(): warning_tween.kill()
		warning_tween = create_tween()
		red_border.modulate.a = 1.0
		warning_tween.tween_property(red_border, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.0, false).timeout
	# Sẽ tự dừng nếu Base Game gọi _on_warning_state_changed(false)

func play_level_up_sequence(level_num: int, is_aced: bool, custom_stay_duration: float = 1.2) -> void:
	var seq_container = Control.new()
	seq_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seq_container.z_index = 10
	add_child(seq_container)
	
	var main_text = "LEVEL %d ACED!" % level_num if is_aced else "LEVEL %d COMPLETE!" % level_num
	var main_color: Color = BAR_EFFECT_CONFIGS[2 if is_aced else 1]["color"]
	var seconds_num: int = 90 if is_aced else 30
	var sub_text = "+%d Seconds" % seconds_num
	
	var create_label = func(t: String, f_s: int, f_c: Color, o_s: int) -> RichTextLabel:
		var lbl = RichTextLabel.new()
		lbl.bbcode_enabled = true; lbl.fit_content = true; lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("normal_font_size", f_s)
		lbl.add_theme_color_override("default_color", f_c)
		lbl.add_theme_constant_override("outline_size", o_s)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.text = "[center]" + t + "[/center]"
		return lbl

	var main_label = create_label.call(main_text, 120, main_color, 18)
	var sub_label = create_label.call(sub_text, 85, Color.WHITE, 14)
	seq_container.add_child(main_label); seq_container.add_child(sub_label)
	
	await get_tree().process_frame
	if not is_instance_valid(seq_container): return
		
	var spacing: float = 10.0
	var total_w = maxf(main_label.size.x, sub_label.size.x)
	var total_h = main_label.size.y + sub_label.size.y + spacing
	
	main_label.position = Vector2((total_w - main_label.size.x) / 2.0, 0)
	sub_label.position = Vector2((total_w - sub_label.size.x) / 2.0, main_label.size.y + spacing)
	seq_container.size = Vector2(total_w, total_h)
	seq_container.pivot_offset = seq_container.size / 2.0
	seq_container.global_position = (get_viewport_rect().size / 2.0) - seq_container.pivot_offset
	seq_container.scale = Vector2.ZERO
	
	var appear_tween = create_tween()
	appear_tween.tween_property(seq_container, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await appear_tween.finished
		
	await get_tree().create_timer(custom_stay_duration).timeout

	if is_instance_valid(sub_label):
		var current_sub_global = sub_label.global_position
		sub_label.get_parent().remove_child(sub_label)
		add_child(sub_label)
		sub_label.global_position = current_sub_global
		
		var fly_target = timer_bar.global_position + (timer_bar.size / 2.0) - (sub_label.size / 2.0)
		var fly_tween = create_tween().set_parallel(true)
		fly_tween.tween_property(sub_label, "global_position", fly_target, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fly_tween.tween_property(sub_label, "scale", Vector2(0.2, 0.2), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fly_tween.tween_property(sub_label, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await fly_tween.finished
		sub_label.queue_free()
		AudioManager.play_sfx("extra_time")
		
		# Thông báo Base Game cộng giờ
		EventBus.level_up_time_landed.emit(float(seconds_num))

	var disappear_tween = create_tween().set_parallel(true)
	disappear_tween.tween_property(seq_container, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	disappear_tween.tween_property(seq_container, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await disappear_tween.finished
	seq_container.queue_free()
	
	# Thông báo Base Game kết thúc toàn bộ chuỗi anim
	EventBus.level_up_sequence_finished.emit()

func play_horizontal_wake_transition(tier: String, duration: float = 1.3) -> void:
	if not background_mat or not WAVE_GRADIENT.has(tier):
		return

	var preset: Dictionary = WAVE_GRADIENT[tier]
	var new_color_a: Color = preset["color_a"]
	var new_color_b: Color = preset["color_b"]

	if bg_wave_tween and bg_wave_tween.is_valid():
		bg_wave_tween.kill()

	background_mat.set_shader_parameter("current_gradient_a", bg_col_a)
	background_mat.set_shader_parameter("current_gradient_b", bg_col_b)
	background_mat.set_shader_parameter("target_gradient_a", new_color_a)
	background_mat.set_shader_parameter("target_gradient_b", new_color_b)
	background_mat.set_shader_parameter("move_direction", Vector2.RIGHT)

	var start_pos: Vector2 = Vector2(-0.25, 0.1)
	var end_pos: Vector2 = Vector2(1.5, 0.1)

	background_mat.set_shader_parameter("current_pos", start_pos)
	background_mat.set_shader_parameter("wave_crest_intensity", 1.0)

	bg_wave_tween = create_tween()
	bg_wave_tween.tween_method(
		func(pos: Vector2): background_mat.set_shader_parameter("current_pos", pos),
		start_pos, end_pos, duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	bg_wave_tween.parallel().tween_method(
		func(val: float): background_mat.set_shader_parameter("wave_crest_intensity", val),
		1.0, 0.0, duration
	)

	bg_wave_tween.tween_callback(func():
		bg_col_a = new_color_a
		bg_col_b = new_color_b
		background_mat.set_shader_parameter("current_gradient_a", bg_col_a)
		background_mat.set_shader_parameter("current_gradient_b", bg_col_b)
		background_mat.set_shader_parameter("wave_crest_intensity", 0.0)
	)
	
func play_burst_transition(tier: String, burst_speed: float = 1.2, duration: float = 0.5) -> void:
	if not flame_mat or not WAVE_GRADIENT.has(tier):
		return

	var preset: Dictionary = WAVE_GRADIENT[tier]
	var target_col_a: Color = preset["color_a"]
	var target_col_b: Color = preset["color_b"]

	if flame_burst_tween and flame_burst_tween.is_valid():
		flame_burst_tween.kill()

	flame_mat.set_shader_parameter("current_gradient_a", flame_col_a)
	flame_mat.set_shader_parameter("current_gradient_b", flame_col_b)
	flame_mat.set_shader_parameter("target_gradient_a", target_col_a)
	flame_mat.set_shader_parameter("target_gradient_b", target_col_b)
	flame_mat.set_shader_parameter("color_mix_factor", 0.0)

	flame_burst_tween = create_tween()
	var half_time: float = duration * 0.7

	flame_burst_tween.tween_property(self, "flame_scroll_speed", burst_speed, half_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	flame_burst_tween.parallel().tween_method(
		func(val: float): flame_mat.set_shader_parameter("color_mix_factor", val),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	flame_burst_tween.tween_property(self, "flame_scroll_speed", default_scroll_speed, half_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	flame_burst_tween.tween_callback(func():
		flame_col_a = target_col_a
		flame_col_b = target_col_b
		flame_mat.set_shader_parameter("current_gradient_a", flame_col_a)
		flame_mat.set_shader_parameter("current_gradient_b", flame_col_b)
		flame_mat.set_shader_parameter("color_mix_factor", 0.0)
	)
	
func reset_all_gradients_to_default(duration: float = 0.6) -> void:
	if bg_wave_tween and bg_wave_tween.is_valid():
		bg_wave_tween.kill()
	if flame_burst_tween and flame_burst_tween.is_valid():
		flame_burst_tween.kill()

	if flame_mat:
		flame_mat.set_shader_parameter("current_gradient_a", flame_col_a)
		flame_mat.set_shader_parameter("current_gradient_b", flame_col_b)
		flame_mat.set_shader_parameter("target_gradient_a", DEFAULT_COLOR_A)
		flame_mat.set_shader_parameter("target_gradient_b", DEFAULT_COLOR_B)
		flame_mat.set_shader_parameter("color_mix_factor", 0.0)

		var f_tween = create_tween()
		f_tween.tween_method(
			func(val: float): flame_mat.set_shader_parameter("color_mix_factor", val),
			0.0, 1.0, duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		f_tween.tween_callback(func():
			flame_col_a = DEFAULT_COLOR_A
			flame_col_b = DEFAULT_COLOR_B
			flame_mat.set_shader_parameter("current_gradient_a", flame_col_a)
			flame_mat.set_shader_parameter("current_gradient_b", flame_col_b)
			flame_mat.set_shader_parameter("color_mix_factor", 0.0)
			flame_scroll_speed = default_scroll_speed
		)

	if background_mat:
		background_mat.set_shader_parameter("current_gradient_a", bg_col_a)
		background_mat.set_shader_parameter("current_gradient_b", bg_col_b)
		background_mat.set_shader_parameter("target_gradient_a", DEFAULT_COLOR_A)
		background_mat.set_shader_parameter("target_gradient_b", DEFAULT_COLOR_B)
		background_mat.set_shader_parameter("current_pos", Vector2(2.2, 0.5))
		background_mat.set_shader_parameter("wave_crest_intensity", 0.0)

		bg_col_a = DEFAULT_COLOR_A
		bg_col_b = DEFAULT_COLOR_B
		background_mat.set_shader_parameter("current_gradient_a", bg_col_a)
		background_mat.set_shader_parameter("current_gradient_b", bg_col_b)
		bg_scroll_speed = default_scroll_speed

func play_blitz_text(text: String, blitz_level: String = "2") -> void:
	if not BLITZ_GRADIENTS.has(blitz_level):
		push_warning("Không tìm thấy blitz_level: '%s', dùng '2' làm mặc định" % blitz_level)
		blitz_level = "2"
		
	var top_color: Color = BLITZ_GRADIENTS[blitz_level].top
	var bot_color: Color = BLITZ_GRADIENTS[blitz_level].bottom

	if _blitz_tween and _blitz_tween.is_valid():
		_blitz_tween.kill()
	_is_trailing = false
	
	_update_text_and_gradient(blitz_label, text, top_color, bot_color)
	for ghost in _ghost_pool:
		_update_text_and_gradient(ghost, text, top_color, bot_color)
		ghost.visible = false

	await get_tree().process_frame
	_start_fly_sequence()
	
func _update_text_and_gradient(rtl: RichTextLabel, text: String, top_col: Color, bot_col: Color) -> void:
	rtl.text = text
	
	var tex_rect: TextureRect = rtl.get_child(0) as TextureRect
	if tex_rect and tex_rect.texture is GradientTexture2D:
		var grad_tex: GradientTexture2D = tex_rect.texture as GradientTexture2D
		grad_tex.gradient.colors = PackedColorArray([top_col, bot_col])
		
func _create_gradient_text_node() -> RichTextLabel:
	var rtl: RichTextLabel = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_constant_override("outline_size", outline_size)
	rtl.add_theme_color_override("font_outline_color", outline_color)
	
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color.WHITE])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	
	var grad_tex: GradientTexture2D = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.5, 0.0) # Đỉnh
	grad_tex.fill_to = Vector2(0.5, 1.0)   # Chân
	
	var tex_rect: TextureRect = TextureRect.new()
	tex_rect.texture = grad_tex
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	rtl.add_child(tex_rect)
	return rtl
	
func set_up_timer_bar(initial_time: float, new_max_time: float) -> void:
	max_time = new_max_time
	timer_bar.min_value = 0.0
	timer_bar.max_value = max_time
	timer_bar.value = initial_time
	display_time = initial_time
	_update_timer_visuals(timer_bar.value)

func play_timer_bar_effect(state_type: int) -> void:
	if state_type == 0 or not BAR_EFFECT_CONFIGS.has(state_type):
		reset_bar_effects()
		return
	var config = BAR_EFFECT_CONFIGS[state_type]
	_set_timer_bar_glow(true, config["color"], config["texture"])

func reset_bar_effects() -> void:
	_set_timer_bar_glow(false)

func _set_timer_bar_glow(enabled: bool, tint_color: Color = Color.WHITE, particle_tex: Texture2D = null) -> void:
	if timer_particle:
		timer_particle.emitting = enabled
		if particle_tex: timer_particle.texture = particle_tex
	if timer_bar and timer_bar.material is ShaderMaterial:
		var timer_mat = timer_bar.material as ShaderMaterial
		timer_mat.set_shader_parameter("is_glowing", enabled)
		if enabled: timer_mat.set_shader_parameter("tint_color", tint_color)

func play_popup_text_animation(text_content: String, is_compliment: bool = false, popup_font_size: int = 150, popup_font_color: Color = Color.WHITE, popup_outline_size: int = 20, popup_outline_color: Color = Color.BLACK, center_pos: Vector2 = Vector2.ZERO) -> void:
	# (Toàn bộ logic hàm play_popup_text_animation của bạn được giữ nguyên ở đây)
	# ... (Viết lại code gốc play_popup_text_animation của bạn)
	var popup_label: RichTextLabel = RichTextLabel.new()
	popup_label.bbcode_enabled = true
	popup_label.fit_content = true
	popup_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	popup_label.scroll_active = false
	popup_label.z_index = 1
	popup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	popup_label.add_theme_font_size_override("normal_font_size", popup_font_size)
	popup_label.add_theme_color_override("default_color", popup_font_color)
	popup_label.add_theme_constant_override("outline_size", popup_outline_size)
	popup_label.add_theme_color_override("font_outline_color", popup_outline_color)
	
	popup_label.text = "[center]" + text_content + "[/center]"
	add_child(popup_label)
	
	if center_pos == Vector2.ZERO: center_pos = get_viewport_rect().size / 2.0
	popup_label.reset_size()
	popup_label.pivot_offset = popup_label.size / 2.0
	popup_label.global_position = center_pos - popup_label.pivot_offset
	popup_label.scale = Vector2.ZERO
	popup_label.modulate.a = 1.0

	var tween: Tween = create_tween()
	if not is_compliment:
		tween.tween_property(popup_label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.5)
		tween.tween_property(popup_label, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(popup_label, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		popup_label.modulate.a = 0.6
		font_size = 100
		outline_size = 15
		tween.tween_property(popup_label, "scale", Vector2(1.15, 1.15), 0.4).set_ease(Tween.EASE_OUT)
		tween.tween_property(popup_label, "scale", Vector2(1.35, 1.35), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(popup_label, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(popup_label.queue_free)

func play_timer_bar_chevron(target_color: String, duration: float = 0.6) -> void:
	_set_chevron_level_color(target_color)
	_play_chevron_sweep(duration)
	
func _play_chevron_sweep(duration: float = 0.6) -> void:
	var chevron_mat = timer_bar.material as ShaderMaterial
	if not chevron_mat:
		return

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	chevron_mat.set_shader_parameter("chevron_progress", 0.0)
	tween.tween_property(chevron_mat, "shader_parameter/chevron_progress", 1.0, duration)
	
	tween.tween_callback(func(): chevron_mat.set_shader_parameter("chevron_progress", 0.0))
	
func _set_chevron_level_color(target_color: String) -> void:
	var chevron_mat = timer_bar.material as ShaderMaterial
	if not chevron_mat:
		return
	
	var color: Color = CHEVRON_COLORS.get(target_color, Color.WHITE)
	chevron_mat.set_shader_parameter("chevron_color", color)

func _update_timer_visuals(current_time: float) -> void:
	timer_box.set_time(current_time)
	if is_intro_playing:
		return
	timer_box.position.x = timer_bar.size.x / 2.0
	timer_box.position.y = _calculate_box_y()
	
func _calculate_box_y() -> float:
	var bar_height: float = timer_bar.size.y
	var scaled_box_height: float = timer_box.get_box_height() * BASE_SCALE.y
	var half_height: float = scaled_box_height / 2.0

	var padding: float = 0.0 

	var top_y: float = half_height + padding
	var bottom_y: float = bar_height - half_height - padding

	var ratio: float = clampf(timer_bar.ratio, 0.0, 1.0)
	return lerpf(bottom_y, top_y, ratio)
	
func _set_tween_max_time(val: float) -> void:
	max_time = val
	timer_bar.max_value = val
	
func _set_tween_time(val: float) -> void:
	display_time = val
	timer_bar.value = clamp(val, 0.0, max_time)
	_update_timer_visuals(val)

func animate_time_bonus(bonus_time: float, target_time: float, new_max_time: float = -1.0, duration: float = -1.0) -> void:
	var tween_time: float = default_tween_duration if duration < 0.0 else duration
	var target_max: float = new_max_time if (new_max_time > 0.0 and new_max_time != max_time) else max_time
	
	if bonus_time >= 3.0:
		if timer_tween and timer_tween.is_valid():
			timer_tween.kill()
			
		timer_tween = create_tween().set_parallel(true)
		timer_tween.set_trans(Tween.TRANS_QUAD)
		timer_tween.set_ease(Tween.EASE_OUT)
		
		if target_max != max_time:
			timer_tween.tween_method(_set_tween_max_time, max_time, target_max, tween_time)
		
		timer_tween.tween_method(_set_tween_time, display_time, target_time, tween_time)
	else:
		if target_max != max_time:
			_set_tween_max_time(target_max)
		_set_tween_time(target_time)
		
func play_timer_box_intro() -> void:
	is_intro_playing = true
	
	await get_tree().process_frame

	timer_box.scale = BASE_SCALE
	timer_box.position.x = timer_bar.size.x / 2.0
	timer_box.position.y = _calculate_box_y()
	
	var target_local_pos: Vector2 = timer_box.position
	var target_global_pos: Vector2 = timer_box.global_position

	var screen_center: Vector2 = get_viewport_rect().size / 2.0
	timer_box.global_position = screen_center
	timer_box.scale = Vector2(0.001, 0.001)

	var tween: Tween = create_tween()

	tween.tween_property(timer_box, "scale", Vector2(0.45, 0.45), 0.7)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(timer_box, "global_position", screen_center, 0.7)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_interval(0.5)

	tween.tween_property(timer_box, "global_position", target_global_pos, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(timer_box, "scale", BASE_SCALE, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(func():
		is_intro_playing = false
		timer_box.position = target_local_pos
		_update_timer_visuals(timer_bar.value)
	)
	
func _spawn_ghost(pos: Vector2) -> void:
	var ghost: RichTextLabel = _ghost_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	
	ghost.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ghost.size = blitz_label.size
	ghost.scale = blitz_label.scale
	ghost.z_index = 1
	
	var tex_rect: TextureRect = ghost.get_child(0) as TextureRect
	if tex_rect:
		tex_rect.size = ghost.size
		tex_rect.visible = true
	
	ghost.position = pos
	
	ghost.modulate.a = 0.4
	ghost.visible = true
	
	var t: Tween = create_tween()
	t.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.tween_property(ghost, "modulate:a", 0.0, 0.35)
	t.tween_callback(func(): ghost.visible = false)
	
func _start_fly_sequence() -> void:
	blitz_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	blitz_label.reset_size()
	var text_size: Vector2 = blitz_label.size
	
	var screen_width: float = get_viewport_rect().size.x
	
	var parent_offset_x: float = global_position.x
	var target_center_x: float = ((screen_width - text_size.x) / 2.0) - parent_offset_x
	
	var custom_y: float = 70.0
	
	var start_pos: Vector2 = Vector2(-text_size.x - 40, custom_y)
	var center_pos: Vector2 = Vector2(target_center_x, custom_y)
	var end_pos: Vector2 = Vector2(screen_width + 40 - parent_offset_x, custom_y)
	
	blitz_label.position = start_pos
	blitz_label.modulate.a = 1.0
	blitz_label.visible = true
	
	_blitz_tween = create_tween()
	
	_blitz_tween.tween_callback(func(): _is_trailing = true)
	_blitz_tween.tween_property(blitz_label, "position", center_pos, enter_duration)\
		.set_trans(Tween.TRANS_LINEAR)
		
	_blitz_tween.tween_callback(func(): _is_trailing = false)
	_blitz_tween.tween_interval(stay_duration)
	
	_blitz_tween.tween_callback(func(): _is_trailing = true)
	_blitz_tween.tween_property(blitz_label, "position", end_pos, exit_duration)\
		.set_trans(Tween.TRANS_LINEAR)
		
	_blitz_tween.tween_callback(func(): 
		_is_trailing = false
		blitz_label.visible = false
	)
	
func set_up_combo_bar() -> void:
	var combo_time: float = 4.0
	combo_bar.max_value = combo_time
	combo_bar.min_value = 0.0
	combo_bar.value = 0.0
	combo_bar_back.max_value = combo_time
	combo_bar_back.min_value = 0.0
	combo_bar_back.value = 0.0
	
func play_combo_bar_effect(level: String, spread_degrees: float = 15.0) -> void:
	if not COMBO_BAR_CONFIG.has(level):
		stop_combo_bar_effect()
		return

	var config: Dictionary = COMBO_BAR_CONFIG[level]
	var current_color: Color = config["color"]

	if combo_bar and combo_bar.material is ShaderMaterial:
		var combo_bar_mat = combo_bar.material as ShaderMaterial
		combo_bar_mat.set_shader_parameter("is_glowing", true)
		combo_bar_mat.set_shader_parameter("tint_color", current_color)

	if combo_particle:
		var p_mat = combo_particle.process_material as ParticleProcessMaterial
		if p_mat:
			combo_particle.amount = config["amount"]
			combo_particle.restart()

			p_mat.color = current_color

			var velocity: float = config["initial_velocity"]
			p_mat.initial_velocity_min = velocity * 0.8
			p_mat.initial_velocity_max = velocity * 1.2
			p_mat.direction = Vector3(0.0, -1.0, 0.0)
			p_mat.spread = spread_degrees
			p_mat.scale_max = 0.35
			p_mat.scale_min = 0.2

			combo_particle.emitting = true
			
func update_combo_visuals() -> void:
	combo_count.set_anchors_preset(Control.PRESET_TOP_LEFT)
	combo_count.pivot_offset = combo_count.size / 2.0
			
func stop_combo_bar_effect() -> void:
	if combo_bar and combo_bar.material is ShaderMaterial:
		var combo_bar_mat = combo_bar.material as ShaderMaterial
		combo_bar_mat.set_shader_parameter("is_glowing", false)

	if combo_particle:
		combo_particle.emitting = false
			
func update_total(score: int) -> void: total_text.text = "Total: " + str(score)
func update_level(level: int) -> void: level_text.text = "Level: " + str(level)
func update_score(score: int) -> void: score_text.text = "Score: " + str(score)
func update_timer(current_time: float) -> void:
	if timer_tween and timer_tween.is_valid():
		return
	
	display_time = current_time
	timer_bar.value = clamp(current_time, 0.0, max_time)
	_update_timer_visuals(current_time)
func set_up_level_bar(target: int = 200) -> void:
	level_target = target; level_bar.max_value = level_target; level_bar.value = 0
func update_level_bar(cleared: int) -> void: level_bar.value = cleared

func update_combo_count(combo: int) -> void:
	if combo <= 0:
		if combo_count.text != "":
			if _combo_tween and _combo_tween.is_valid(): _combo_tween.kill()
			combo_count.pivot_offset = combo_count.size / 2.0
			_combo_tween = create_tween()
			_combo_tween.tween_property(combo_count, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			_combo_tween.tween_callback(func(): combo_count.text = "")
		return
	combo_count.text = "+" + str(combo)
	combo_count.pivot_offset = combo_count.size / 2.0
	if _combo_tween and _combo_tween.is_valid(): _combo_tween.kill()
	combo_count.scale = Vector2.ONE
	_combo_tween = create_tween()
	_combo_tween.tween_property(combo_count, "scale", Vector2(1.25, 1.25), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_combo_tween.tween_property(combo_count, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
