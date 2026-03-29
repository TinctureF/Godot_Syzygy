# SwarmDrone.gd
# 蜂群无人机 - 编队飞行AI
extends CharacterBody2D

## 基础属性（根据GDD）
@export var max_hp: float = 5.0
@export var move_speed: float = 200.0
@export var contact_damage: float = 5.0
@export var card_drop_count: int = 1
@export var size: Vector2 = Vector2(20, 20)  # 20x20 px

## 编队角色
enum Role { LEADER, MEMBER }
@export var role: Role = Role.MEMBER
@export var formation_offset: Vector2 = Vector2.ZERO

## 编队类型
enum FormationType { V_SHAPE, LINE, DIAMOND }
@export var formation: FormationType = FormationType.V_SHAPE

var current_hp: float = 5.0
var faction: String = "enemy"
var time_alive: float = 0.0
var leader: Node2D = null
var is_chaotic: bool = false  # 组长死后进入混乱状态

func _ready():
	current_hp = max_hp
	collision_layer = 4
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("swarm_drone")

func _physics_process(delta: float):
	time_alive += delta

	# 根据状态移动
	if is_chaotic:
		_chaotic_movement(delta)
	else:
		_formation_movement(delta)

	move_and_slide()

	# 飞出屏幕销毁
	if position.x < -100 or position.x > get_viewport_rect().size.x + 100:
		queue_free()

## 编队移动
func _formation_movement() -> void:
	if leader and is_instance_valid(leader):
		# 跟随组长
		var target_pos = leader.position + formation_offset
		velocity = (target_pos - position).normalized() * move_speed
	else:
		# 无组长则直线向左
		velocity = Vector2.LEFT * move_speed

## 混乱移动（组长死后）
func _chaotic_movement(delta: float) -> void:
	# 布朗运动 + 逃离
	var random_force = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized() * 50.0
	velocity = Vector2.LEFT * 100.0 + random_force  # 降速 + 混乱

## 受到伤害
func take_damage(damage: float) -> void:
	current_hp -= damage
	_flash_white()

	if current_hp <= 0:
		_on_death()

## 组长死亡时通知
func notify_leader_dead() -> void:
	if role == Role.LEADER:
		return
	# 进入混乱状态
	is_chaotic = true
	move_speed = 100.0
	print("[SwarmDrone] 组长阵亡，剩余成员进入混乱状态")

## 死亡处理
func _on_death() -> void:
	# 通知队友
	var members = get_tree().get_nodes_in_group("swarm_drone")
	for member in members:
		if member != self and member.role == Role.MEMBER:
			var offset = position - member.position
			if offset.length() < 50:
				member.notify_leader_dead()

	# 检查是否全歼（整组死亡）
	if role == Role.LEADER:
		var remaining = 0
		for m in members:
			if m != self and is_instance_valid(m):
				remaining += 1
		if remaining == 0:
			print("[SwarmDrone] 全歼整组！额外掉牌率+10%")
			card_drop_count += 1  # 额外掉牌

	var enemy_data = {
		"world_position": Vector3(position.x, position.y, 0),  # 2D → 3D 世界坐标
		"card_drop_count": card_drop_count,
		"damage": max_hp,
		"type": "swarm_drone"
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

func get_faction() -> String:
	return faction
