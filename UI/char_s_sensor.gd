# CharSensorController.gd
extends TextureButton # 如果你用的是TextureButton

# 获取下方各层级的“引用”，方便控制它们
@onready var visual_container = $Visual_Container
@onready var char_label = $"../MainChar_Label"
@onready var glow_sprite = $Visual_Container/Glow_Sprite
@onready var options_drawer = $Options_Drawer

func _ready():
	# 1. 初始视觉设定：让文字看起来像未激活的灰度档案 
	char_label.modulate = Color(0.4, 0.4, 0.4) # 深铅灰色
	glow_sprite.modulate.a = 0 # 辉光初始不可见
	
	# 2. 初始菜单设定：隐藏并缩放到0 
	options_drawer.modulate.a = 0
	options_drawer.scale.y = 0
	options_drawer.hide()

	# 3. 链接鼠标进入和离开的信号
	mouse_entered.connect(_on_interaction_start)
	mouse_exited.connect(_on_interaction_end)

func _on_interaction_start():
	# 唤醒式动效：当鼠标进入反应区域 
	options_drawer.show()
	var tween = create_tween().set_parallel(true)
	
	# 文字瞬间过载，变为亮白色产生辉光 
	tween.tween_property(char_label, "modulate", Color(2.5, 2.5, 2.5), 0.1)
	tween.tween_property(glow_sprite, "modulate.a", 0.8, 0.2)
	
	# 选项菜单滑出（Scale Y从0到1） 
	tween.tween_property(options_drawer, "modulate:a", 1.0, 0.2)
	tween.tween_property(options_drawer, "scale:y", 1.0, 0.3).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _on_interaction_end():
	# 冷却动效：鼠标离开 
	var tween = create_tween().set_parallel(true)
	tween.tween_property(char_label, "modulate", Color(0.4, 0.4, 0.4), 0.3)
	tween.tween_property(glow_sprite, "modulate.a", 0.0, 0.3)
	
	# 菜单收回 
	tween.tween_property(options_drawer, "modulate:a", 0.0, 0.2)
	tween.tween_property(options_drawer, "scale:y", 0.0, 0.2)
