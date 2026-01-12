# CombatResolver.gd
# 战斗裁判 - MVP：简单的伤害处理
extends Node

func _ready():
	# 连接战斗信号
	SignalBus.bullet_hit_enemy.connect(_on_bullet_hit_enemy)

## 子弹命中敌人
func _on_bullet_hit_enemy(bullet: Node, enemy: Node) -> void:
	# MVP：简化处理，伤害在Projectile中已经处理
	# 这里只做记录和特效（暂时不做）
	pass

## 玩家子弹对消敌方子弹（MVP暂不实现）
func check_bullet_collision(player_bullet: Node, enemy_bullet: Node) -> void:
	pass
