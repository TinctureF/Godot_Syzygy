# LootDropper.gd
# 掉落管理器 - 敌人死亡→抽牌→生成掉落卡牌
extends Node

## 引用
@onready var deck_library = get_node("/root/DeckLibrary")
@export var loot_card_scene: PackedScene

func _ready():
	# 连接敌人死亡信号
	SignalBus.enemy_died.connect(_on_enemy_died)
	
	# 加载掉落卡牌场景
	if not loot_card_scene:
		loot_card_scene = preload("res://Entities/card/LootCard.tscn")

## 敌人死亡时掉落卡牌
func _on_enemy_died(enemy_data: Dictionary) -> void:
	var drop_position = enemy_data.position
	var drop_count = enemy_data.get("card_drop_count", 1)
	
	# 生成掉落卡牌
	for i in range(drop_count):
		_spawn_loot_card(drop_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)))

## 生成一张掉落卡牌
func _spawn_loot_card(pos: Vector2) -> void:
	if not deck_library:
		print("错误：找不到DeckLibrary")
		return
	
	# 从牌库抽一张牌
	var card = deck_library.draw_card()
	if not card:
		print("牌库已空，无法生成掉落")
		return
	
	# 实例化掉落卡牌
	if not loot_card_scene:
		print("错误：找不到LootCard场景")
		return
	
	var loot_card = loot_card_scene.instantiate()
	loot_card.card_data = card
	loot_card.position = pos
	
	# 添加到场景
	get_tree().root.add_child(loot_card)
