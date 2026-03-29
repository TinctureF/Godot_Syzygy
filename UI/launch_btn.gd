# LaunchButton.gd
extends Button

# 在检查器里选择你的 main.tscn 文件
@export_file("*.tscn") var target_scene: String = "res://Scenes/Main.tscn"

func _ready():
	# 确保按钮能点
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# 连接内置的按下信号
	pressed.connect(_on_launch_pressed)

func _on_launch_pressed():
	print(">>> [CMD] 强制切换场景至: ", target_scene)
	
	# 使用最直接的切换方式
	# 如果你的 main.tscn 在根目录，且拼写无误，它会立刻跳转
	var result = get_tree().change_scene_to_file(target_scene)
	
	# 万一失败了（比如文件路径错了），会在控制台报错
	if result != OK:
		print(">>> [ERROR] 场景切换失败！错误代码: ", result)
		print("请检查检查器（Inspector）里的 target_scene 路径是否正确。")
