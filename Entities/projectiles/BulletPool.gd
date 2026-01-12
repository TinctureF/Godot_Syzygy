# BulletPool.gd
# 子弹对象池 - 简单复用机制
extends Node

## 预设场景
@export var bullet_scene: PackedScene

## 对象池
var active_bullets: Array[Node] = []
var inactive_bullets: Array[Node] = []

const MAX_POOL_SIZE = 200

func _ready():
	# 预先创建一些子弹
	for i in range(20):
		var bullet = _create_bullet()
		inactive_bullets.append(bullet)

## 生成子弹
func spawn_bullet(pos: Vector2, dir: Vector2, faction: String, damage: float = 1.0, speed: float = 400.0) -> Node:
	var bullet: Node
	
	if inactive_bullets.size() > 0:
		bullet = inactive_bullets.pop_back()
	else:
		bullet = _create_bullet()
	
	# 重置子弹属性
	bullet.position = pos
	bullet.direction = dir.normalized()
	bullet.faction = faction
	bullet.damage = damage
	bullet.speed = speed
	bullet.visible = true
	bullet.set_physics_process(true)
	
	active_bullets.append(bullet)
	return bullet

## 回收子弹
func recycle_bullet(bullet: Node) -> void:
	if bullet not in active_bullets:
		return
	
	active_bullets.erase(bullet)
	bullet.visible = false
	bullet.set_physics_process(false)
	
	if inactive_bullets.size() < MAX_POOL_SIZE:
		inactive_bullets.append(bullet)
	else:
		bullet.queue_free()

## 创建新子弹
func _create_bullet() -> Node:
	var bullet
	if bullet_scene:
		bullet = bullet_scene.instantiate()
	else:
		# 使用内置的简单子弹
		bullet = preload("res://Entities/Projectile.tscn").instantiate()
	
	add_child(bullet)
	bullet.visible = false
	bullet.set_physics_process(false)
	return bullet

## 清理所有子弹
func clear_all_bullets() -> void:
	for bullet in active_bullets:
		recycle_bullet(bullet)
