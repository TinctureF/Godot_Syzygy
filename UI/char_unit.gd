# CharUnit.gd
extends Control

# 直接获取内部的 Label，不需要路径偏移
@onready var label = $"../../Char_S_Container/MainChar_Label"

@export var target_menu: VBoxContainer
@export var group_siblings: Array[Control]

var close_timer: SceneTreeTimer = null

func _ready():
	# 核心修复：确保 CharUnit 本身就能接收鼠标信号
	# 设置 Mouse Filter 为 Stop，确保它能拦截鼠标
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 连接自身的信号
	mouse_entered.connect(_on_self_mouse_entered)
	mouse_exited.connect(_on_self_mouse_exited)

	# 初始化颜色（调暗）
	label.modulate = Color(0.4, 0.4, 0.4)

	$Char_Sensor.mouse_entered.connect(_on_mouse_entered)
	$Char_Sensor.mouse_exited.connect(_on_mouse_exited)

	print("--- 调试开始 ---")
	print("全局单例对象: ", SignalBus)
	if SignalBus.has_signal("menu_opened"):
		print("成功：找到了 menu_opened 信号")
	else:
		print("警告：SignalBus 身上没有这个信号！其包含的方法列表为: ", SignalBus.get_method_list())
	# 【核心】监听全局信号：如果开的不是我的菜单，我立刻闭嘴
	SignalBus.menu_opened.connect(func(opened_menu):
		if opened_menu != target_menu:
			_force_close()
	)

	# 菜单也要感应鼠标，防止在操作菜单时消失
	if target_menu:
		target_menu.mouse_entered.connect(_stop_close_timer)
		target_menu.mouse_exited.connect(_on_mouse_exited)

func _on_self_mouse_entered():
	# 视觉反馈：瞬间过载亮起
	# 使用 2.0 以上的数值可以产生 Glow 辉光感
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(2.5, 2.5, 2.5), 0.1)

func _on_self_mouse_exited():
	# 视觉反馈：冷却回暗
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(0.4, 0.4, 0.4), 0.2)

func _on_mouse_entered():
	_stop_close_timer()
	# 【核心】通知全局：我要开菜单了，请清理现场
	SignalBus.menu_opened.emit(target_menu)
	_animate_menu(true)
	_set_group_highlight(true)

func _on_mouse_exited():
	_stop_close_timer()
	close_timer = get_tree().create_timer(5.0) # 5秒缓冲
	close_timer.timeout.connect(_force_close)

func _force_close():
	_stop_close_timer()
	_animate_menu(false)
	_set_group_highlight(false)

func _stop_close_timer():
	if close_timer:
		# 这里的 disconnect 是为了防止计时器到期后仍然触发关闭
		if close_timer.timeout.is_connected(_force_close):
			close_timer.timeout.disconnect(_force_close)
		close_timer = null

func _set_group_highlight(active: bool):
	_set_label_color(active)
	for sibling in group_siblings:
		if sibling.has_method("_set_label_color"):
			sibling._set_label_color(active)

func _set_label_color(active: bool):
	var color = Color(2.5, 2.5, 2.5) if active else Color(0.4, 0.4, 0.4)
	create_tween().tween_property($"../../Char_S_Container/MainChar_Label", "modulate", color, 0.1)

func _animate_menu(show: bool):
	if not target_menu: return
	
	# 强行停止旧动画，防止排版乱跳
	var t = create_tween().set_parallel(true)
	if show:
		target_menu.show()
		t.tween_property(target_menu, "modulate:a", 1.0, 0.2)
		t.tween_property(target_menu, "scale:y", 1.0, 0.3).set_trans(Tween.TRANS_QUINT)
	else:
		t.tween_property(target_menu, "modulate:a", 0.0, 0.2)
		t.tween_property(target_menu, "scale:y", 0.0, 0.2)
		t.set_parallel(false)
		t.tween_callback(target_menu.hide)
