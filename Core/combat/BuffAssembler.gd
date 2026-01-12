# BuffAssembler.gd
# Buff组装器 - 简化版
extends Node

## 当前Buff状态
var current_buff: Dictionary = {
	"multiplier": 1.0,
	"fire_rate": 1.0,
	"has_combo": false,
	"combo_type": ""
}

func _ready():
	# 连接手牌变化信号
	SignalBus.hand_changed.connect(_on_hand_changed)

## 手牌变化时重新计算Buff
func _on_hand_changed(hand: Array) -> void:
	# 获取评估器
	var evaluator = get_node_or_null("/root/HandEvaluator")
	if not evaluator:
		evaluator = preload("res://Scripts/HandEvaluator.gd").new()
		add_child(evaluator)
	
	# 评估手牌
	current_buff = evaluator.evaluate_hand(hand)
	
	# 发送Buff更新信号
	SignalBus.buff_updated.emit(current_buff)
	
	print("Buff更新: 倍率=", current_buff.multiplier, " 类型=", current_buff.combo_type)

## 获取当前Buff
func get_current_buff() -> Dictionary:
	return current_buff

## 重置Buff
func reset() -> void:
	current_buff = {
		"multiplier": 1.0,
		"fire_rate": 1.0,
		"has_combo": false,
		"combo_type": ""
	}
	SignalBus.buff_updated.emit(current_buff)
