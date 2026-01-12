# BaseEnemy.gd
# 基础敌人 - 一个会死的靶子
extends CharacterBody2D

## 基础属性
@export var max_hp: float = 25.0
@export var move_speed: float = 120.0
@export var contact_damage: float = 6.0
@export var card_drop_count: int = 1

var current_hp: float = 25.0
var faction: String = "enemy"

## 移动模式
enum MovePattern {
	STRAIGHT_LEFT,  # 直线向左
	SINE_WAVE,      # 正弦波
	STATIONARY      # 静止
}
@export var move_pattern: MovePattern = MovePattern.STRAIGHT_LEFT

var time_alive: float = 0.0

func _ready():
	current_hp = max_hp
	# 设置碰撞层
	collision_layer = 4  # 敌人层
	collision_mask = 2   # 玩家子弹层

func _physics_process(delta: float):
	time_alive += delta
	
	# 根据移动模式移动
	match move_pattern:
		MovePattern.STRAIGHT_LEFT:
			velocity = Vector2.LEFT * move_speed
		MovePattern.SINE_WAVE:
			velocity = Vector2.LEFT * move_speed
			velocity.y = sin(time_alive * 3.0) * 50.0
		MovePattern.STATIONARY:
			velocity = Vector2.ZERO
	
	move_and_slide()
	
	# 飞出屏幕则销毁
	if position.x < -100 or position.x > get_viewport_rect().size.x + 100:
		queue_free()

## 受到伤害
func take_damage(damage: float) -> void:
	current_hp -= damage
	
	# 简单闪烁效果
	_flash_white()
	
	if current_hp <= 0:
		_die()

## 死亡处理
func _die() -> void:
	# 发送死亡信号
	var enemy_data = {
		"position": position,
		"card_drop_count": card_drop_count,
		"damage": max_hp
	}
	SignalBus.enemy_died.emit(enemy_data)
	
	queue_free()

## 闪白效果
func _flash_white() -> void:
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(2, 2, 2, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1, 1)

## 获取阵营
func get_faction() -> String:
	return faction

## 碰撞玩家处理
func _on_body_entered(body: Node2D):
	if body.has_method("take_damage") and body.has_method("get_faction"):
		if body.get_faction() == "player":
			body.take_damage(contact_damage)
			_die()
