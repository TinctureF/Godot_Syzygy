# DataVault.gd - 存储 DEMO 核心数值
extends Node

# --- 玩家基础属性 ---
var player_hp: float = 100.0
var player_energy: float = 100.0
var max_energy: float = 100.0

# --- 卡牌计数器 ---
var total_cards_in_deck: int = 108 # DEMO 精简版牌数
var cards_consumed: int = 0         # 已消耗或流失的牌
var registry_sets: int = 0          # 已打出的面子组数（用于判定胡牌）

# --- 战力统计 ---
var current_win_level: int = 0      # 当前胡牌等级
var dps_multiplier: float = 1.0     # 最终战力倍率

# --- 功能函数：修改数据并通知全局 ---
func take_damage(amount: float):
	player_hp = clamp(player_hp - amount, 0, 100)
	SignalBus.player_damaged.emit(player_hp) # 通知 UI 更新

func use_energy(amount: float) -> bool:
	if player_energy >= amount:
		player_energy -= amount
		# 这里可以添加一个能量改变的信号
		return true
	return false

func add_registry_set():
	registry_sets += 1
	# 检查是否达成胡牌条件的工作交给 WinConditionChecker
