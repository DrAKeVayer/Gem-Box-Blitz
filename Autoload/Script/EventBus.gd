extends Node

signal pause_game(is_paused: bool)
signal game_over()

signal total_score_updated(total: int)
signal score_updated(score: int)
signal level_updated(level: int)
signal level_target_setup(target: int)
signal level_progress_updated(cleared: int)
signal level_state_changed(state_type: int)

signal timer_setup(initial: float, max_time: float)
signal timer_updated(current: float)
signal timer_bonus_added(bonus: float, target_time: float, new_max: float)
signal warning_state_changed(is_warning: bool)

signal blitz_triggered(old_tier: String, tier: String, text: String, bonus_time: float)
signal match_rewarded(matched_gems: int, popup_text: String, sfx_name: String)
signal combo_updated(streak: int, bonus: int, sfx_name: String, timeout: float)
signal combo_reset()

signal popup_text_requested(text: String, is_compliment: bool)
signal level_up_sequence_started(level: int, is_aced: bool)
signal level_up_time_landed(bonus_time: float)
signal level_up_sequence_finished()
