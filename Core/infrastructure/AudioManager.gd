# AudioManager.gd
extends Node

# 预加载音乐资源（请确保路径正确）
var bgm_mianscreen = preload("res://Assets/audio/bgm/MainSite_BGM.wav")
var bgm_startscreen = preload("res://Assets/audio/bgm/syzygy.wav")
var bgm_intro = preload("res://Assets/audio/bgm/syzygy.wav")  # 使用现有的开场音乐

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready():
	# 初始化播放器
	add_child(music_player)
	music_player.bus = &"Music" # Godot 4 推荐对名称使用 StringName (&"")
	play_bgm(bgm_intro)

# 播放背景音乐并实现平滑切换
func play_bgm(stream: AudioStream, fade_duration: float = 2.0):
	if music_player.stream == stream:
		return
		
	# 修复：Godot 4 的 Tween 创建方式已更改 
	var tween = create_tween()
	# 先淡出音量
	tween.tween_property(music_player, "volume_db", -80.0, fade_duration / 2.0)
	# 切换音频流
	tween.tween_callback(func(): _change_stream(stream))
	# 再淡入音量
	tween.tween_property(music_player, "volume_db", 0.0, fade_duration / 2.0)

func _change_stream(stream: AudioStream):
	music_player.stream = stream
	music_player.play()

# 特效：当时控开启时调用，让音乐变闷
#func set_warp_effect(is_warping: bool):
	#var effect_index = AudioServer.get_bus_effect_index("Music", 0) # 假设第一个特效是低通滤波
	#AudioServer.set_bus_effect_enabled("Music", effect_index, is_warping)
