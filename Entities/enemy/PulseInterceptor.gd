# PulseInterceptor.gd
# 脉冲拦截机 - Z字蛇行 + 弹幕 + 护盾机制
extends CharacterBody2D

## 基础属性（根据GDD）
@export var max_hp: float = 25.0
@export var move_speed: float = 120.0
@export var contact_damage: float = 5.0
@export var card_drop_count: int = 1
@export var size: Vector2 = Vector2(40, 36)  # 40x36 px

var current_hp: float = 25.0
var faction: String = "enemy"
var time_alive: float = 0.0

## 弹幕参数
var bullet_speed: float = 250.0
var bullet_damage: float = 6.0
var fire_pattern: int = 0  # 0: 3连扇形
var fire_interval: float = 2.0
var fire_timer: float = 0.0

## 护盾机制
var has_shield: bool = false
var shield_health: float = 5.0
var shield_active_hp: float = 10.0  # 血量低于此值时激活护盾

## 加速状态
var is_boosted: bool = false

func _ready():
	current_hp = max_hp
	collision_layer = 4
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("pulse_interceptor")

func _physics_process(delta: float):
	time_alive += delta

	# Z字蛇行移动
	_sine_wave_movement(delta)

	# 发射弹幕
	_update_fire(delta)

	move_and_slide()

	# 飞出屏幕销毁
	if position.x < -100 or position.x > get_viewport_rect().size.x + 100:
		queue_free()

## Z字蛇行移动
func _sine_wave_movement(delta: float) -> void:
	var base_velocity = Vector2.LEFT * move_speed
	var wave = sin(time_alive * 3.0) * 50.0
	velocity = base_velocity + Vector2(0, wave)

	# 护盾激活后加速
	if is_boosted:
		velocity *= 1.5  # 180/120 = 1.5

## 弹幕发射
func _update_fire(delta: float) -> void:
	fire_timer += delta
	if fire_timer >= fire_interval:
		fire_timer = 0.0
		_fire_burst()

## 3连扇形脉冲弹
func _fire_burst() -> void:
	var bullet_pool = get_node_or_null("/root/BulletPool")
	if not bullet_pool:
		return

	# 发射3发，角度分布：-25°, 0°, +25°
	var angles = [-25.0, 0.0, 25.0]
	for angle_deg in angles:
		var direction = Vector2.LEFT.rotated(deg_to_rad(angle_deg))
		bullet_pool.spawn_bullet(
			global_position,
			direction,
			"enemy",
			bullet_damage,
			bullet_speed
		)

## 受到伤害
func take_damage(damage: float) -> void:
	# 护盾先扣
	if has_shield and shield_health > 0:
		shield_health -= damage
		if shield_health <= 0:
			has_shield = false
			is_boosted = false
			move_speed = 120.0  # 恢复速度
			print("[PulseInterceptor] 护盾破碎")
		_flash_blue()
		return

	current_hp -= damage

	# 检查是否激活护盾
	if not has_shield and current_hp <= shield_active_hp:
		_activate_shield()

	_flash_white()

	if current_hp <= 0:
		_on_death()

## 激活护盾
func _activate_shield() -> void:
	has_shield = true
	shield_health = 5.0
	is_boosted = true
	move_speed = 180.0  # 提速
	print("[PulseInterceptor] 护盾激活！速度提升")

## 死亡处理
func _on_death() -> void:
	var enemy_data = {
		"world_position": Vector3(position.x, position.y, 0),  # 2D → 3D 世界坐标
		"card_drop_count": card_drop_count,
		"damage": max_hp,
		"type": "pulse_interceptor"
	}
	SignalBus.enemy_died.emit(enemy_data)
	queue_free()

func _flash_white() -> void:
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(2, 2, 2, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1, 1)

func _flash_blue() -> void:
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(0.5, 0.5, 2, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1, 1)

func get_faction() -> String:
	return faction
