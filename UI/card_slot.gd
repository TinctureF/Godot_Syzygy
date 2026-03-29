# CardSlot.gd
extends PanelContainer

signal slot_pressed(index: int)

# --- 核心修复：在这里声明变量 ---

@onready var suit_label = %SuitLabel 
@onready var card_art = %CardArt
@onready var highlight_panel = $HighlightPanel
# ----------------------------

var current_card: CardObject = null
var slot_index: int = 0
var last_click_time: float = 0.0
var double_click_threshold: float = 0.3

func _ready():
	self.modulate.a = 0.0
	# 确保能接收鼠标事件
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# 处理点击事件
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_empty():
				# 检测双击
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_click_time < double_click_threshold:
					# 双击：快速发牌（连续发3张）
					slot_pressed.emit(slot_index)
					await get_tree().create_timer(0.1).timeout
					slot_pressed.emit(slot_index)
					await get_tree().create_timer(0.1).timeout
					slot_pressed.emit(slot_index)
				else:
					# 单击：普通发牌
					slot_pressed.emit(slot_index)
				last_click_time = current_time

func is_empty() -> bool:
	return current_card == null

func set_card_data(data: CardObject):
	current_card = data 
	
	if data == null:
		self.modulate.a = 0.0
		return

	# --- 🚨 开启数据雷达：看控制台！ ---
	# print("【终端调试】准备装载卡牌：", data.resource_path)
	# print("【终端调试】卡牌图片数据：", data.card_texture)
	# --------------------------------

	# 如果这里报错说找不到 %CardArt，检查你上一轮的操作！
	if card_art:
		# 🔴 核心：强制把图片数据赋过去
		card_art.texture = data.card_texture
		# push_warning("【终端调试】card_art.texture 已赋值为：", card_art.texture)

	# 其他逻辑保持不变...
	self.modulate.a = 1.0
	
	if data == null:
		self.modulate.a = 0.0
		suit_label.text = ""
		card_art.texture = null
		return
	
	# --- 战术读数核心逻辑 ---
	var suit_char = "?" # 默认值，如果没对上就会显示 ?
	
	# 这里必须确保 CardObject.gd 里的 Enum 名字和这里一模一样
	match data.suit:
		0: suit_char = "P" # Point (假设 0 是第一个)
		1: suit_char = "L" # Line  (假设 1 是第二个)
		2: suit_char = "A" # Plane (假设 2 是第三个)
	
	# 如果上面的 Enum 对不上，我们尝试用代码里的常量名匹配
	if data.suit == CardObject.Suit.POINT: suit_char = "P"
	elif data.suit == CardObject.Suit.LINE: suit_char = "L"
	elif data.suit == CardObject.Suit.PLANE: suit_char = "A"

	# 拼接字母 + 数字 (强行转 String)
	var final_text = suit_char + str(data.value)
	suit_label.text = final_text
	
	# 🔴 调试雷达：如果还是没编号，看控制台输出了什么
	# print("【终端数据】花色枚举值:", data.suit, " | 数字值:", data.value, " | 最终文本:", final_text)

	# --- 后续视觉处理 ---
	card_art.texture = data.card_texture
	self.modulate.a = 1.0
	
	# 根据花色变色（让 UI 活起来）
	match suit_char:
		"P": self.modulate = Color(1, 0.5, 0.5) # 红色系
		"L": self.modulate = Color(0.5, 1, 0.5) # 绿色系
		"A": self.modulate = Color(0.5, 0.8, 1) # 蓝色系
	
	# 这里的动效可以稍微改强一点，表示“装填”
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# card_slot.gd 内部

# --- 【核心修复：添加这个缺失的函数】 ---
func set_highlight(is_on: bool) -> void:
	# 确保高亮面板节点存在，防止再次报错
	if highlight_panel == null:
		return
	
	# 简单的开关显示
	highlight_panel.visible = is_on
	
	# 如果想让效果更“战术”，加个简单的呼吸效果
	if is_on:
		var tween = create_tween().set_loops()
		# 透明度在 0.4 到 1.0 之间循环，模拟呼吸灯
		tween.tween_property(highlight_panel, "modulate:a", 0.4, 0.6)
		tween.tween_property(highlight_panel, "modulate:a", 1.0, 0.6)
	else:
		# 关闭时停止所有动画，重置透明度
		var tween = create_tween()
		highlight_panel.modulate.a = 1.0
