# WeaponSystem.gd
# 武器系统 - 负责射击逻辑
extends Node2D

## 引用
@onready var bullet_pool = get_node("/root/BulletPool")

## 射击参数
var base_fire_rate: float = 5.0  # 每秒5发
var fire_rate_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var bullet_speed: float = 400.0

var fire_cooldown: float = 0.0

func _ready():
	# 连接buff更新信号
	SignalBus.buff_updated.connect(_on_buff_updated)

func _process(delta: float):
	# 冷却计时
	if fire_cooldown > 0:
		fire_cooldown -= delta

## 尝试射击
func try_fire() -> bool:
	if fire_cooldown <= 0:
		_fire_bullet()
		fire_cooldown = 1.0 / (base_fire_rate * fire_rate_multiplier)
		return true
	return false

## 发射子弹
func _fire_bullet() -> void:
	if not bullet_pool:
		return
	
	var bullet_pos = global_position + Vector2(20, 0)  # 向右偏移
	var direction = Vector2.RIGHT
	var damage = 1.0 * damage_multiplier
	
	bullet_pool.spawn_bullet(bullet_pos, direction, "player", damage, bullet_speed)

## 响应Buff更新
func _on_buff_updated(buff: Dictionary) -> void:
	if buff.has("multiplier"):
		damage_multiplier = buff.multiplier
	if buff.has("fire_rate"):
		fire_rate_multiplier = buff.fire_rate
	if buff.has("bullet_speed"):
		bullet_speed = buff.bullet_speed

## 获取当前DPS
func get_current_dps() -> float:
	return base_fire_rate * fire_rate_multiplier * damage_multiplier
