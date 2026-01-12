# Projectile.gd
# 投射物基类 - 最小子弹逻辑
extends Area2D

## 基础属性
var speed: float = 400.0
var damage: float = 1.0
var direction: Vector2 = Vector2.RIGHT
var faction: String = "player"  # "player" 或 "enemy"

## 生命周期
var lifetime: float = 5.0
var current_lifetime: float = 0.0

func _ready():
	# 连接碰撞检测
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float):
	# 向前飞行
	position += direction * speed * delta
	
	# 生命周期检测
	current_lifetime += delta
	if current_lifetime >= lifetime:
		_on_lifetime_expired()

## 碰撞处理
func _on_area_entered(area: Area2D):
	if area.has_method("get_faction"):
		var target_faction = area.get_faction()
		if target_faction != faction:
			_hit_target(area)

func _on_body_entered(body: Node2D):
	# 碰到物体时的处理
	if body.has_method("get_faction"):
		var target_faction = body.get_faction()
		if target_faction != faction:
			_hit_target(body)

## 命中目标
func _hit_target(target: Node):
	# 发送信号
	if faction == "player" and target.has_method("take_damage"):
		SignalBus.bullet_hit_enemy.emit(self, target)
		target.take_damage(damage)
	
	# 销毁子弹
	_destroy()

## 生命周期到期
func _on_lifetime_expired():
	_destroy()

## 销毁子弹
func _destroy():
	# 通知对象池回收
	if get_parent().has_method("recycle_bullet"):
		get_parent().recycle_bullet(self)
	else:
		queue_free()

## 获取阵营
func get_faction() -> String:
	return faction
