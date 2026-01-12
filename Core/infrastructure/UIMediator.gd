# UIMediator.gd
# UI中介器 - 处理卡牌收集和手牌显示（MVP简化版）
extends Node

## 引用
var player: Node = null

func _ready():
	# 连接信号
	SignalBus.card_collected.connect(_on_card_collected)
	SignalBus.hand_changed.connect(_on_hand_changed)
	
	# 等待场景加载后获取玩家引用
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

## 收到卡牌收集信号
func _on_card_collected(card: CardObject) -> void:
	print("UI: 收集到卡牌 ", card.get_display_name())
	# MVP: 不做动画，直接更新手牌显示
	_update_hand_display()

## 手牌变化
func _on_hand_changed(hand: Array) -> void:
	print("UI: 手牌变化，当前 ", hand.size(), " 张")
	_update_hand_display()

## 更新手牌显示（MVP：只打印到控制台）
func _update_hand_display() -> void:
	if not player or not player.has_method("add_card_to_hand"):
		return
	
	var hand = player.current_hand
	var display_text = "手牌["
	for card in hand:
		display_text += card.get_display_name() + " "
	display_text += "]"
	
	print(display_text)
	
	# 检查是否有可打出的牌组
	_check_playable_combo(hand)

## 检查可打出的牌组
func _check_playable_combo(hand: Array) -> void:
	# 获取评估器
	var evaluator = get_node_or_null("/root/HandEvaluator")
	if not evaluator:
		evaluator = preload("res://Scripts/HandEvaluator.gd").new()
		add_child(evaluator)
	
	var combo = evaluator.get_playable_combo(hand)
	if combo.size() > 0:
		print(">>> 可打出组合: ", combo[0].get_display_name(), " ", combo[1].get_display_name(), " ", combo[2].get_display_name())
