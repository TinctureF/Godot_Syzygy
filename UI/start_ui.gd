extends Control # 必须有这一行，否则报错 get_tree()

@onready var logo_group = $LogoGroup # 确保路径正确

func _ready():
	# 1. 监听窗口大小变化
	get_tree().root.size_changed.connect(_on_window_resize)
	# 2. 初始运行一次对齐
	_on_window_resize()

func _on_window_resize():
	if not logo_group: return
	
	# 获取当前视口的实际大小
	var screen_size = get_viewport_rect().size
	
	# 手动计算中心点：(屏幕宽度/2 - UI宽度/2)
	# 确保 LogoGroup 的 Pivot Offset 设为中心，或者这里减去一半的 size
	logo_group.global_position = screen_size / 2 - logo_group.size / 2
	
	print(">>> [UI] 战术重绘完成，当前分辨率: ", screen_size)
