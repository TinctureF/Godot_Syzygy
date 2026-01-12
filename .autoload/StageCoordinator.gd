# StageCoordinator.gd
# 关卡协调器 - MVP：让游戏开始和结束
extends Node

## 游戏状态
enum GameState {
	INIT,
	BATTLE,
	RESULT
}

var current_state: GameState = GameState.INIT

func _ready():
	# 连接游戏结束信号
	SignalBus.game_over.connect(_on_game_over)
	
	# 开始初始化
	_enter_init_state()

## 进入初始化状态
func _enter_init_state() -> void:
	current_state = GameState.INIT
	SignalBus.stage_changed.emit("INIT")
	
	print("=== 游戏初始化 ===")
	
	# 初始化牌库
	if has_node("/root/DeckLibrary"):
		get_node("/root/DeckLibrary").init_deck()
	
	# 重置数据
	if has_node("/root/DataVault"):
		get_node("/root/DataVault").reset()
	
	# 等待一帧后进入战斗
	await get_tree().process_frame
	_enter_battle_state()

## 进入战斗状态
func _enter_battle_state() -> void:
	current_state = GameState.BATTLE
	SignalBus.stage_changed.emit("BATTLE")
	
	print("=== 战斗开始 ===")
	
	# 启动敌人生成器
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner and spawner.has_method("start_spawning"):
		spawner.start_spawning()

## 进入结算状态
func _enter_result_state(victory: bool) -> void:
	current_state = GameState.RESULT
	SignalBus.stage_changed.emit("RESULT")
	
	print("=== 游戏结束 ===")
	print("胜利: ", victory)
	
	# 停止敌人生成
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner and spawner.has_method("stop_spawning"):
		spawner.stop_spawning()
	
	# 显示结算数据
	if has_node("/root/DataVault"):
		var data = get_node("/root/DataVault").get_snapshot()
		print("击杀数: ", data.enemies_killed)
		print("收集卡牌: ", data.cards_collected)
		print("剩余牌数: ", data.remaining_cards)

## 游戏结束
func _on_game_over(victory: bool) -> void:
	_enter_result_state(victory)

## 重新开始
func restart() -> void:
	_enter_init_state()
