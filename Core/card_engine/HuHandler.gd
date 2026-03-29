# HuHandler.gd
# 胡牌处理器 - 管理胡牌状态和决策
extends Node

## 胡牌等级
enum HuLevel { NONE, DAWN, ASCEND, ANNIHILATION }

var current_hu_level: HuLevel = HuLevel.NONE
var registry_sets: int = 0  # 已打出的面子数
var can_hu: bool = false  # 是否可以胡牌
var hu_pending: bool = false  # 胡牌待确认状态

## 胡牌配置
const MIN_SETS_FOR_HU: int = 3  # 最少3组可胡

## 信号
signal hu_triggered(level: HuLevel, sets: int)
signal hu_state_changed(can_hu: bool, sets: int)

func _ready():
	SignalBus.hand_changed.connect(_on_hand_changed)

## 手牌变化时检查是否可以胡牌
func _on_hand_changed(hand: Array) -> void:
	_check_hu_state(hand)

## 检查胡牌状态
func _check_hu_state(hand: Array) -> void:
	# 计算当前手牌中的成组数
	var sets_in_hand = _count_sets_in_hand(hand)
	var total_sets = registry_sets + sets_in_hand

	can_hu = total_sets >= MIN_SETS_FOR_HU
	hu_state_changed.emit(can_hu, total_sets)

## 计算手牌中的成组数
func _count_sets_in_hand(hand: Array) -> int:
	if hand.size() < 3:
		return 0

	var evaluator = get_node_or_null("/root/HandEvaluator")
	if not evaluator:
		return 0

	var sequences = evaluator._find_sequences(hand)
	var triplets = evaluator._find_triplets(hand)

	return sequences.size() + triplets.size()

## 打出顺子/刻子时调用
func register_combo(sets_count: int) -> void:
	registry_sets += sets_count
	print("[HuHandler] 注册面子，当前累计: ", registry_sets)
	_check_hu_state([])

## 请求胡牌
func request_hu() -> bool:
	if not can_hu:
		return false

	hu_pending = true
	hu_triggered.emit(current_hu_level, registry_sets)
	return true

## 确认胡牌
func confirm_hu() -> void:
	if not hu_pending:
		return

	# 根据累计面子数确定胡牌等级
	if registry_sets >= 5:
		current_hu_level = HuLevel.ANNIHILATION
	elif registry_sets >= 4:
		current_hu_level = HuLevel.ASCEND
	else:
		current_hu_level = HuLevel.DAWN

	# 应用效果
	_apply_hu_effect()

	# 重置
	hu_pending = false

## 拒绝胡牌（继续积累）
func decline_hu() -> void:
	hu_pending = false
	print("[HuHandler] 拒绝胡牌，继续积累")

## 应用胡牌效果
func _apply_hu_effect() -> void:
	var buff_assembler = get_node_or_null("/root/BuffAssembler")
	if not buff_assembler:
		return

	match current_hu_level:
		HuLevel.DAWN:
			print("[HuHandler] 胡牌！破晓（3组）")
			buff_assembler.on_hu(registry_sets)
		HuLevel.ASCEND:
			print("[HuHandler] 胡牌！凌霄（4组）")
			buff_assembler.on_hu(registry_sets)
		HuLevel.ANNIHILATION:
			print("[HuHandler] 胡牌！湮灭（5组）")
			buff_assembler.on_hu(registry_sets)

	# 重置累计
	registry_sets = 0
	can_hu = false
	hu_state_changed.emit(false, 0)

## 获取当前胡牌信息
func get_hu_info() -> Dictionary:
	return {
		"level": current_hu_level,
		"level_name": HuLevel.keys()[current_hu_level],
		"registry_sets": registry_sets,
		"can_hu": can_hu,
		"pending": hu_pending
	}

## 重置
func reset() -> void:
	current_hu_level = HuLevel.NONE
	registry_sets = 0
	can_hu = false
	hu_pending = false
