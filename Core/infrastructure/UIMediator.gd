# UIMediator.gd
# UI中介器 - 管理所有游戏UI
extends Node

## UI节点引用
var hand_container: HBoxContainer
var energy_bar: ProgressBar
var hp_bar: ProgressBar
var hu_indicator: Label
var combo_indicator: Label
var stage_label: Label
var debug_label: Label

## 玩家引用
var player: Node = null
var data_vault: Node = null

## 预制体
var card_slot_scene: PackedScene

func _ready():
	# 等待场景加载
	await get_tree().process_frame
	_setup_references()
	_connect_signals()

## 设置引用
func _setup_references() -> void:
	player = get_tree().get_first_node_in_group("player")
	data_vault = get_node_or_null("/root/DataVault")

	# 尝试获取UI节点
	var canvas = get_tree().get_first_node_in_group("ui_canvas")
	if canvas:
		energy_bar = canvas.get_node_or_null("EnergyBar")
		hp_bar = canvas.get_node_or_null("HPBar")
		hu_indicator = canvas.get_node_or_null("HuIndicator")
		combo_indicator = canvas.get_node_or_null("ComboIndicator")
		stage_label = canvas.get_node_or_null("StageLabel")
		debug_label = canvas.get_node_or_null("DebugPanel/Label")
		hand_container = canvas.get_node_or_null("HandContainer")

## 连接信号
func _connect_signals() -> void:
	SignalBus.card_collected.connect(_on_card_collected)
	SignalBus.hand_changed.connect(_on_hand_changed)
	SignalBus.buff_updated.connect(_on_buff_updated)
	SignalBus.stage_changed.connect(_on_stage_changed)
	SignalBus.player_hit.connect(_on_player_hit)
	SignalBus.game_over.connect(_on_game_over)

func _process(delta: float):
	# 更新能量条
	if player and energy_bar:
		energy_bar.value = player.get_energy()
		if energy_bar.max_value == 0:
			energy_bar.max_value = 100

	# 更新HP条
	if player and hp_bar:
		hp_bar.value = player.current_hp
		if hp_bar.max_value == 0:
			hp_bar.max_value = player.max_hp

	# 更新Debug信息
	if data_vault and debug_label:
		var remaining = data_vault.remaining_cards
		debug_label.text = "剩余牌: %d\n击杀: %d" % [remaining, data_vault.enemies_killed]

## 卡牌收集
func _on_card_collected(card: CardObject) -> void:
	_update_hand_display()

## 手牌变化
func _on_hand_changed(hand: Array) -> void:
	_update_hand_display()
	_check_combos(hand)

## Buff更新
func _on_buff_updated(buff: Dictionary) -> void:
	if combo_indicator:
		if buff.has_combo:
			combo_indicator.text = buff.get("name", "") + " Ready!"
			combo_indicator.modulate = Color.GREEN
		else:
			combo_indicator.text = ""
			combo_indicator.modulate = Color.WHITE

## 阶段变化
func _on_stage_changed(stage: String) -> void:
	if stage_label:
		stage_label.text = stage
	print("UI: 阶段变化 - ", stage)

## 玩家受伤
func _on_player_hit(damage: float) -> void:
	# 受伤闪红效果可以在这里处理UI反馈
	pass

## 游戏结束
func _on_game_over(victory: bool) -> void:
	if hu_indicator:
		hu_indicator.text = "胜利!" if victory else "失败!"
		hu_indicator.modulate = Color.GREEN if victory else Color.RED

## 更新手牌显示
func _update_hand_display() -> void:
	if not player:
		return

	var hand = player.current_hand

	# 简单打印
	var display = "手牌: "
	for card in hand:
		display += card.get_display_name() + " "
	print("[UI] ", display)

## 检查可打出组合
func _check_combos(hand: Array) -> void:
	if hand.size() < 3:
		return

	var evaluator = get_node_or_null("/root/HandEvaluator")
	if not evaluator:
		return

	var combo = evaluator.get_playable_combo(hand)
	if combo.size() > 0:
		print("[UI] 可打出: ", combo[0].get_display_name(), "-",
			  combo[1].get_display_name(), "-", combo[2].get_display_name())

		# 通知HuHandler
		var hu_handler = get_node_or_null("/root/HuHandler")
		if hu_handler:
			hu_handler.register_combo(1)
