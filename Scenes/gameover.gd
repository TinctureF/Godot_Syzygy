extends Node3D

# 引用 UI 节点
@onready var title_label = $CanvasLayer/VBoxContainer/"CONNECTION LOST"
@onready var score_label = $CanvasLayer/VBoxContainer/LabelScoreSummary
@onready var restart_btn = $CanvasLayer/VBoxContainer/ButtonLayout/RestartButton
@onready var quit_btn = $CanvasLayer/VBoxContainer/ButtonLayout/QuitButton

func _ready():
	# 1. 游戏结束时通常需要暂停世界逻辑，但允许 UI 运行
	get_tree().paused = true

	# 允许 UI 在暂停时响应输入
	$CanvasLayer.process_mode = Node.PROCESS_MODE_INHERIT

	# 2. 从 DataVault 获取战报数据（基于你的程序架构文档）
	#_populate_stats()

	# 3. 播放出现动画
	$AnimationPlayer.play("fade_in")

	# 4. 连接按钮信号
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

#func _populate_stats():
	## 从单例 DataVault 获取数据
	#var sets = DataVault.registry_sets
	#var win_lv = DataVault.current_win_level
	#var kills = DataVault.total_kills
	#
	#var lv_name = ["无", "破晓", "凌霄", "湮灭", "归虚"][win_lv]
	#
	## 格式化显示：使用等宽字体效果更好
	#score_label.text = """
	#[ 系统同步状态 ]
	#最高胡牌等级: %s
	#完成面子总数: %d
	#敌机歼灭总数: %d
	#------------------
	#数据链路已烧毁...
	#""" % [lv_name, sets, kills]

func _on_restart_pressed():
	get_tree().paused = false
	# 跳转开始界面
	get_tree().change_scene_to_file("res://Scenes/Start Screen.tscn")

func _on_quit_pressed():
	# 退出游戏
	get_tree().quit()
