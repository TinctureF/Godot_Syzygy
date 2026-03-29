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
	
	print("=== THINKING ===")
	
	# 初始化牌库
	DeckLibrary.initialize_deck()
	DataVault.reset()
	
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
	
	print("=== START ===")
	
	# 启动敌人生成器
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner and spawner.has_method("start_spawning"):
		spawner.start_spawning()

## 进入结算状态
func _enter_result_state(victory: bool) -> void:
	current_state = GameState.RESULT
	SignalBus.stage_changed.emit("RESULT")
	
	print("=== PASS ===")
	print("TO BE CONTINUE: ", victory)
	
	# 停止敌人生成
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner and spawner.has_method("stop_spawning"):
		spawner.stop_spawning()
	
	# 显示结算数据
	if has_node("/root/DataVault"):
		var data = get_node("/root/DataVault").get_snapshot()
		print("Enemies_Killed: ", data.enemies_killed)
		print("Cards_Collected: ", data.cards_collected)
		print("Remaining_Cards: ", data.remaining_cards)

## 游戏结束
func _on_game_over(victory: bool) -> void:
	print("[StageCoordinator] 收到 game_over 信号, victory:", victory)

	# 立即锁死数据，阻止回血Buff继续执行
	DataVault.lock_data()

	_enter_result_state(victory)

	# 立即暂停游戏，防止回血等逻辑继续执行
	get_tree().paused = true

	# 延迟一小段时间后切换到 gameover 场景
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/gameover.tscn")

## 监控牌库是否耗尽
func _process(_delta):
	if current_state == GameState.BATTLE:
		if DataVault.remaining_cards <= 0:
			SignalBus.game_over.emit(false)

## 重新开始
func restart() -> void:
	_enter_init_state()
