extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

var SFX = {
	"click": {"stream": preload("res://Assets/Audio/SFX/Click1.wav"), "volume_db": 0.0},
	"extra_time": {"stream": preload("res://Assets/Audio/SFX/ExtraTime.wav"), "volume_db": 1.0},
	"item_sold": {"stream": preload("res://Assets/Audio/SFX/ItemSold.wav"), "volume_db": 0.0},
	"matched1": {"stream": preload("res://Assets/Audio/SFX/Matched1.wav"), "volume_db": -2.0},
	"matched2": {"stream": preload("res://Assets/Audio/SFX/Matched2.wav"), "volume_db": -2.0},
	"matched3": {"stream": preload("res://Assets/Audio/SFX/Matched3.wav"), "volume_db": -2.0},
	"matched4": {"stream": preload("res://Assets/Audio/SFX/Matched4.wav"), "volume_db": -2.0},
	"matched5": {"stream": preload("res://Assets/Audio/SFX/Matched5.wav"), "volume_db": -2.0},
	"matched6": {"stream": preload("res://Assets/Audio/SFX/Matched6.wav"), "volume_db": -2.0},
	"blitzed2": {"stream": preload("res://Assets/Audio/SFX/MatchBlitz2.wav"), "volume_db": -2.0},
	"blitzed3": {"stream": preload("res://Assets/Audio/SFX/MatchBlitz3.wav"), "volume_db": -2.0},
	"blitzed4": {"stream": preload("res://Assets/Audio/SFX/MatchBlitz4.wav"), "volume_db": -2.0},
	"blitzed5": {"stream": preload("res://Assets/Audio/SFX/MatchBlitz5.wav"), "volume_db": -2.0},
	"blitzed6": {"stream": preload("res://Assets/Audio/SFX/MatchBlitz6.wav"), "volume_db": -2.0},
	"blitz_jingle2": {"stream": preload("res://Assets/Audio/SFX/Blitz2Jingle.wav"), "volume_db": -13.0},
	"blitz_jingle3": {"stream": preload("res://Assets/Audio/SFX/Blitz3Jingle.wav"), "volume_db": -12.5},
	"blitz_jingle4": {"stream": preload("res://Assets/Audio/SFX/Blitz4Jingle.wav"), "volume_db": -12.0},
	"blitz_jingle5": {"stream": preload("res://Assets/Audio/SFX/Blitz5Jingle.wav"), "volume_db": -11.5},
	"blitz_jingle6": {"stream": preload("res://Assets/Audio/SFX/Blitz6Jingle.wav"), "volume_db": -11.0},
	"time_warning": {"stream": preload("res://Assets/Audio/SFX/TimeWarning.wav"), "volume_db": 0.0},
	"level_complete": {"stream": preload("res://Assets/Audio/SFX/LevelComplete.wav"), "volume_db": -5.0},
	"bonus_1": {"stream": preload("res://Assets/Audio/SFX/Bonus_1.wav"), "volume_db": 0.0},
	"level_aced": {"stream": preload("res://Assets/Audio/SFX/LevelAced.wav"), "volume_db": -2.0},
	"voice_30s": {"stream": preload("res://Assets/Audio/SFX/Voice30Seconds.wav"), "volume_db": 0.0},
	"voice_awesome": {"stream": preload("res://Assets/Audio/SFX/VoiceAwesome.wav"), "volume_db": -8.0},
	"voice_get_ready": {"stream": preload("res://Assets/Audio/SFX/VoiceGetReady.wav"), "volume_db": -7.0},
	"voice_go": {"stream": preload("res://Assets/Audio/SFX/VoiceGo.wav"), "volume_db": -6.0},
	"voice_good": {"stream": preload("res://Assets/Audio/SFX/VoiceGood.wav"), "volume_db": -8.0},
	"voice_specta": {"stream": preload("res://Assets/Audio/SFX/VoiceSpectacular.wav"), "volume_db": -7.0},
	"voice_timeup": {"stream": preload("res://Assets/Audio/SFX/VoiceTimeUp.wav"), "volume_db": 0.0},
	"voice_unbelieve": {"stream": preload("res://Assets/Audio/SFX/VoiceUnbelievable.wav"), "volume_db": -6.0},
	"voice_blitz1": {"stream": preload("res://Assets/Audio/SFX/VoiceBlitzCombo.wav"), "volume_db": -6.0},
	"voice_blitz2": {"stream": preload("res://Assets/Audio/SFX/VoiceBlitzGreat.wav"), "volume_db": -6.0},
	"voice_blitz3": {"stream": preload("res://Assets/Audio/SFX/VoiceBlitzAwesome.wav"), "volume_db": -6.0},
	"voice_blitz4": {"stream": preload("res://Assets/Audio/SFX/VoiceBlitzSuper.wav"), "volume_db": -6.0},
	"voice_blitz5": {"stream": preload("res://Assets/Audio/SFX/VoiceBlitzHyper.wav"), "volume_db": -6.0},
	"voice_blitz6": {"stream": preload("res://Assets/Audio/SFX/VoiceBlitzUnbelie.wav"), "volume_db": -6.0},
	"voice_level_complete": {"stream": preload("res://Assets/Audio/SFX/VoiceLevelComplete.wav"), "volume_db": -4.0}
}

var BGM = {
	"blitz": {"stream": preload("res://Assets/Audio/BGM/Blitz.ogg"), "volume_db": -6.0},
	"main_menu": {"stream": preload("res://Assets/Audio/BGM/MainMenu.ogg"), "volume_db": -5.0}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.bus = "Music"
	add_child(music_player)
	EventBus.match_rewarded.connect(func(_gems, _text, sfx): play_sfx(sfx))
	EventBus.combo_updated.connect(func(_streak, _bonus, sfx, _timeout): play_sfx(sfx))
	EventBus.blitz_triggered.connect(func(old_tier, tier, _text, _time):
		play_sfx("voice_blitz" + tier)
		play_sfx("blitz_jingle" + tier)
	)

func is_music_playing(key: String) -> bool:
	if not BGM.has(key):
		return false
	return music_player.playing and music_player.stream == BGM[key]["stream"]

func play_bgm(key: String, fade_duration: float = 0.0, volume_offset_db: float = 0.0) -> void:
	if not BGM.has(key):
		push_warning("No BGM key '" + key + "' found")
		return
	if is_music_playing(key):
		return
		
	var target_db: float = BGM[key]["volume_db"] + volume_offset_db
	_play_music(BGM[key]["stream"], target_db, fade_duration)
	
func _play_music(stream: AudioStream, target_db: float = 0.0, fade_duration: float = 0.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return
		
	if fade_duration <= 0.0:
		music_player.stream = stream
		music_player.volume_db = target_db
		music_player.play()
	else:
		var tween: Tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration / 2.0)
		tween.tween_callback(func():
			music_player.stream = stream
			music_player.play()
		)
		tween.tween_property(music_player, "volume_db", target_db, fade_duration / 2.0)

func stop_music() -> void:
	music_player.stop()

func play_sfx(key: String, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> AudioStreamPlayer:
	if key == "":
		return null
	if not SFX.has(key):
		push_warning("No SFX key '" + key + "' found")
		return null
		
	var sfx_data = SFX[key]
	var target_db: float = sfx_data["volume_db"] + volume_offset_db
	return _play_sfx(sfx_data["stream"], target_db, pitch_scale)
	
func _play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not stream:
		return null
		
	var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.bus = "SFX"
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch_scale
	
	add_child(sfx_player)
	sfx_player.play()
	
	sfx_player.finished.connect(sfx_player.queue_free)
	return sfx_player
