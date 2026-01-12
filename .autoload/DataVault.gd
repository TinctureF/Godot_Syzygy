# DataVault.gd
# 数据黑匣子 - 只记录不计算
extends Node

## 核心数据
var energy: float = 100.0  # 当前能量值
var dps_snapshot: float = 0.0  # DPS快照
var remaining_cards: int = 144  # 剩余牌数

## 战斗统计
var total_damage_dealt: float = 0.0
var enemies_killed: int = 0
var cards_collected: int = 0
var cards_wasted: int = 0

## 时间记录
var game_time: float = 0.0
var battle_time: float = 0.0

func _ready():
	# 连接到SignalBus进行自动记录
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.card_collected.connect(_on_card_collected)

## 记录能量变化
func record_energy(delta: float) -> void:
	energy += delta
	energy = clampf(energy, 0.0, 100.0)

## 获取数据快照
func get_snapshot() -> Dictionary:
	return {
		"energy": energy,
		"dps": dps_snapshot,
		"remaining_cards": remaining_cards,
		"enemies_killed": enemies_killed,
		"cards_collected": cards_collected,
		"game_time": game_time
	}

## 重置数据
func reset() -> void:
	energy = 100.0
	dps_snapshot = 0.0
	remaining_cards = 144
	total_damage_dealt = 0.0
	enemies_killed = 0
	cards_collected = 0
	cards_wasted = 0
	game_time = 0.0
	battle_time = 0.0

func _on_enemy_died(enemy_data: Dictionary) -> void:
	enemies_killed += 1
	if enemy_data.has("damage"):
		total_damage_dealt += enemy_data.damage

func _on_card_collected(card: Resource) -> void:
	cards_collected += 1
	remaining_cards -= 1
