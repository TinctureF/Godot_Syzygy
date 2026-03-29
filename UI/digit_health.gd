extends HBoxContainer

# 颜色常量定义: 符合深铅灰色与自发光设定
const COLOR_ACTIVE = Color(1.0, 1.0, 1.0, 1.0)   # 青色高亮
const COLOR_SHIELD = Color(1.0, 1.0, 1.0, 1.0)  # 蓝色护盾
const COLOR_INACTIVE = Color(0.2, 0.2, 0.2, 0.5) # 暗灰半透明网点感
# 定义回血闪烁的颜色（明亮的荧光绿）
const COLOR_HEAL_FLASH = Color(0.0, 1.0, 0.3, 1.0)
# Line suit回血常量
const HEAL_SINGLE_LINE = 5.0   # 单张Line回血量
const HEAL_COMBO_LINE = 30.0   # Line顺子/刻子回血量

@onready var digit_labels = get_children() # 获取那10个Label数字
@onready var shield_bar = $"../PlayerStatus/ShieldBar"
@onready var shield_mesh_3d: MeshInstance3D = $"../../Player/Starship/ShieldMesh"

var current_max_hp: float = 100.0
# 记录上一次的血量阶梯，用于对比差异
var last_threshold: int = 0

func _ready():
	# 初始连接: 监听玩家受伤信号
	SignalBus.player_hit.connect(_on_player_hit)
	# 监听护盾变化信号
	SignalBus.player_shield_changed.connect(_on_shield_changed)
	# 监听血量变化信号
	SignalBus.player_hp_changed.connect(_on_hp_changed)
	# 监听手牌评估结果(用于Line suit回血)
	SignalBus.hand_evaluated.connect(_on_hand_evaluated)
	# 初始化护盾条样式
	_setup_shield_bar_style()
	# 初始显示满血(100)
	_update_display(current_max_hp)
	# 初始护盾状态(开局为0，隐藏)
	_update_shield_display(0, 30)
	# 同步护盾显示：已在上面初始化，信号连接后会自动更新
	
func _setup_shield_bar_style():
	if shield_bar:
		# 设置最小高度
		shield_bar.custom_minimum_size = Vector2(0, 20)

		# 创建背景样式(深灰色边框)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # 深灰背景
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 1.0, 1.0, 1.0)  # 蓝色边框
		style.set_corner_radius_all(4)
		shield_bar.add_theme_stylebox_override("background", style)

		# 创建填充样式(蓝色)
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(1.0, 1.0, 1.0, 0.9)  # 蓝色填充
		fill_style.set_corner_radius_all(2)
		shield_bar.add_theme_stylebox_override("fill", fill_style)

func _on_player_hit(_damage_amount):
	# 每次受伤时更新UI (使用已保存的最大血量)
	_update_display(current_max_hp)

func _on_hp_changed(current_hp: float, max_hp: float):
	current_max_hp = max_hp

	# 计算新的亮起边界
	var new_threshold = int(ceil(current_hp / 10.0))

	# 执行显示更新（包含闪烁逻辑）
	_update_display_with_fx(new_threshold)

	# 更新历史记录
	last_threshold = new_threshold

func _on_shield_changed(current_shield: float, max_shield: float):
	# 护盾变化时也更新显示
	_update_shield_display(current_shield, max_shield)
	_update_shield_membrane(current_shield, max_shield)

## 手牌评估回调 - 处理Line/Point suit buff效果
func _on_hand_evaluated(result: Dictionary):
	if not result.has("combo"):
		return

	var cards_used = result.get("cards_used", [])
	if cards_used.is_empty():
		return

	# 检查花色
	var all_line = true
	var all_point = true
	for card in cards_used:
		if card is CardObject:
			if card.suit != CardObject.Suit.LINE:
				all_line = false
			if card.suit != CardObject.Suit.POINT:
				all_point = false

	# 判断是顺子还是刻子
	var is_triplet = _check_is_triplet(cards_used)
	var is_sequence = _check_is_sequence(cards_used)

	# 处理LINE suit回血
	if all_line and (is_triplet or is_sequence):
		_apply_line_heal(HEAL_COMBO_LINE)
		print("[DigitHealth] Line顺子/刻子! 回血 %.1f" % HEAL_COMBO_LINE)
		return

	# 处理POINT suit buff
	if all_point and (is_triplet or is_sequence):
		_apply_point_combo_buff()
		print("[DigitHealth] Point顺子/刻子! 子弹变大，伤害翻倍，三排射击，15秒")
		return

## 检测是否是刻子
func _check_is_triplet(cards: Array) -> bool:
	if cards.size() != 3:
		return false
	var values = []
	for card in cards:
		if card is CardObject:
			values.append(card.value)
	return values[0] == values[1] and values[1] == values[2]

## 检测是否是顺子
func _check_is_sequence(cards: Array) -> bool:
	if cards.size() != 3:
		return false
	var values = []
	for card in cards:
		if card is CardObject:
			values.append(card.value)
	values.sort()
	return values[1] == values[0] + 1 and values[2] == values[1] + 1

## 应用Line回血
func _apply_line_heal(amount: float):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("heal"):
		player.heal(amount)
		# 触发回血视觉反馈
		_trigger_heal_vfx()

## 回血视觉特效
func _trigger_heal_vfx():
	for label in digit_labels:
		var tween = create_tween()
		tween.tween_property(label, "modulate", Color(0.5, 1.0, 0.5, 1.0), 0.1)
		tween.tween_property(label, "modulate", COLOR_ACTIVE, 0.2)

## 应用Point顺子/刻子buff
func _apply_point_combo_buff():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("WeaponSystem"):
		var weapon = player.get_node("WeaponSystem")
		if weapon.has_method("apply_point_buff"):
			weapon.apply_point_buff(2)  # 2 = Point顺子/刻子

func _update_display(current_hp: float):
	# 计算应该亮起几个数字 (每10点血亮一个)
	# 例如: 100-91 亮10个, 90-81 亮9个, ... 10-1 亮1个, 0 全灭
	var threshold = int(ceil(current_hp / 10.0))
	for i in range(digit_labels.size()):
		var label = digit_labels[i]
		# 数字0在index 0, 数字1在index 1, ...
		var digit_value = i  # 0到9

		if digit_value < threshold:
			# 应该亮起
			label.modulate = COLOR_ACTIVE
			label.remove_theme_constant_override("shadow_offset_x")
		else:
			# 应该熄灭
			_trigger_extinguish_vfx(label)

func _update_display_with_fx(new_threshold: int):
	for i in range(digit_labels.size()):
		var label = digit_labels[i]
		var digit_value = i  # 0-9 对应从左到右

		# 判定逻辑：如果该数字之前是灭的 (>= last_threshold)
		# 现在变亮了 (< new_threshold)，则触发回血闪烁
		if digit_value < new_threshold:
			if digit_value >= last_threshold and last_threshold != 0:
				# 触发绿色闪烁效果
				_trigger_heal_vfx_single(label)
			else:
				# 已经是亮着的，保持常亮
				label.modulate = COLOR_ACTIVE
		else:
			# 保持熄灭状态
			label.modulate = COLOR_INACTIVE

func _update_shield_display(current_shield: float, max_shield: float):
	if shield_bar:
		# 1. 动态同步最大值（如果你的护盾上限会变，这很重要）
		shield_bar.max_value = max_shield
		
		# 2. 核心修正：直接将当前数值赋给进度条的 value
		# Godot 的 ProgressBar 会根据 value/max_value 的比例自动绘制填充长度
		shield_bar.value = current_shield
		
		# 3. 显隐逻辑优化：
		# 虽然你想让它随数值增加，但当护盾彻底为 0 时，通常还是建议隐藏
		# 或者你可以让它永远可见，但背景是全黑的。
		shield_bar.visible = current_shield > 0
		
	print("[DigitHealth] Shield Update: %f / %f" % [current_shield, max_shield])
	
func _update_shield_membrane(current_shield: float, max_shield: float):
	if shield_mesh_3d:
		var mat = shield_mesh_3d.get_active_material(0) as ShaderMaterial
		if mat:
			# 通过 shader 的 shield_color alpha 通道控制透明度
			if current_shield <= 0:
				# 完全透明
				mat.set_shader_parameter("shield_color", Color(0.3, 0.67, 1.0, 0.0))
				shield_mesh_3d.visible = false
			else:
				var shield_ratio = current_shield / max_shield
				mat.set_shader_parameter("intensity", shield_ratio * 2.0)
				# 恢复可见
				mat.set_shader_parameter("shield_color", Color(0.3, 0.67, 1.0, 1.0))
				shield_mesh_3d.visible = true

				# 低能量时增加脉动频率
				if shield_ratio < 0.3:
					mat.set_shader_parameter("pulse_speed", 4.0) # 紧急闪烁
				else:
					mat.set_shader_parameter("pulse_speed", 1.0)
				
func _trigger_extinguish_vfx(label: Label):
	# 熄灭时的动效: 先闪烁, 再变暗
	var tween = create_tween()
	# 模拟旧显示器的色散闪烁
	tween.tween_property(label, "modulate", Color.WHITE, 0.05)
	tween.tween_property(label, "modulate", COLOR_INACTIVE, 0.1)
	# 注意: 不再修改label.position.y以避免位置偏移
	
func _trigger_heal_vfx_single(label: Label):
	var tween = create_tween()
	# 1. 瞬间变为荧光绿
	label.modulate = COLOR_HEAL_FLASH
	
	# 2. 产生“数字化”的跳动闪烁
	tween.tween_property(label, "modulate", Color.WHITE, 0.05)
	tween.tween_property(label, "modulate", COLOR_HEAL_FLASH, 0.05)
	
	# 3. 最终恢复为标准青色
	tween.tween_property(label, "modulate", COLOR_ACTIVE, 0.2)
