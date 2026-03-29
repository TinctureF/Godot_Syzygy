extends Area3D

# --- 属性设置 ---
@export var max_hp: float = 5.0      # 蜂群无人机血量
@export var explosion_scene: PackedScene = preload("res://Entities/enemy/EnemyExplosionVFX.tscn")

# --- 移动相关属性 ---
@export var speed: float = 5.0      # 向左飞行的速度
@export var wave_amplitude: float = 2.0  # 纵向摆动的幅度
@export var wave_frequency: float = 1.5  # 纵向摆动的频率

var _random_offset: float = 0.0     # 随机偏移，让每只飞得不一样
var _time: float = 0.0
var current_hp: float
var original_speed: float = 5.0

# --- 编队相关属性 ---
var is_leader: bool = false
var formation_id: int = 0
var is_formation_broken: bool = false
var drift_direction: Vector2 = Vector2.ZERO

# 引用 Mesh 以便做受击反馈（可选）
@onready var mesh = $MeshInstance3D
@onready var core_1 = $CollisionShape3D1

func _ready():
	# 随机化初始相位，防止六只敌机排成一条完美的直线，增加病毒的有机感
	_random_offset = randf() * PI * 2
	current_hp = max_hp
	original_speed = speed
	# 确保敌机在正确的组里，方便玩家子弹识别
	add_to_group("enemy")
	add_to_group("formation_member")
	# 连接信号：当有东西撞到我时
	area_entered.connect(_on_area_entered)
	# 连接信号：撞到玩家（body_entered用于检测CharacterBody3D）
	body_entered.connect(_on_body_entered)

func set_leader(leader: bool, fid: int):
	is_leader = leader
	formation_id = fid
	if leader:
		add_to_group("formation_leader")

func set_move_speed(new_speed: float):
	speed = new_speed
	original_speed = new_speed

func on_leader_died():
	if is_formation_broken:
		return
	is_formation_broken = true
	# 减速50%
	speed = original_speed * 0.5
	# 随机漂移方向
	drift_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func _physics_process(delta: float):
	if not core_1: return

	_time += delta
	var t = Time.get_ticks_msec() / 1000.0 * 2.0

	# 1. 核心视觉同步逻辑 (保持你原有的逻辑)
	var p1_pos = Vector3(sin(t * 0.7) * 0.3, cos(t * 1.2) * 0.3, 0)
	core_1.position = p1_pos

	# 2. 整体位移逻辑：从右往左飞 (X轴负方向)
	global_position.x -= speed * delta

	# 3. 随机轨道：添加一点纵向的正弦波蠕动
	global_position.y += sin(_time * wave_frequency + _random_offset) * wave_amplitude * delta

	# 4. 编队崩溃后的漂移
	if is_formation_broken:
		global_position.x += drift_direction.x * speed * 0.3 * delta
		global_position.y += drift_direction.y * speed * 0.3 * delta

	# 5. 强制锁定 Z 轴深度
	global_position.z = 0

	# 6. 屏幕外自动销毁（防止飞出屏幕后还在跑，浪费资源）
	if global_position.x < -20: # 假设相机中心在0，左侧边界约为-20
		queue_free()

func _on_area_entered(area: Area3D):
	# 检查撞到的是不是玩家子弹
	if area.is_in_group("player_bullet"):
		# 假设子弹脚本里有一个 damage 变量
		var damage = 2.0  # 默认伤害2
		if area.has_method("get_damage"):
			damage = area.get_damage()

		take_damage(damage)

		# 子弹击中后应该消失（由子弹自己控制或这里调用）
		if area.has_method("destroy"):
			area.destroy()
		elif area.has_method("_recycle"):
			area._recycle()

func _on_body_entered(body: Node3D):
	# 撞到玩家
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(5)
		die()

func take_damage(amount: float):
	current_hp -= amount
	print("敌机受伤: %.1f, 剩余血量: %.1f" % [amount, current_hp])
	if current_hp <= 0:
		die()

func die():
	# 如果是组长死亡，通知其他组员编队崩溃
	if is_leader:
		_notify_formation_broken()

	# 发出敌机死亡信号，触发卡牌掉落
	SignalBus.enemy_died.emit({
		"world_position": global_position,  # 传递 3D 世界坐标
		"card_drop_count": 1
	})

	# 触发抽牌到卡槽
	SignalBus.enemy_killed_for_card.emit()

	if explosion_scene:
		var effect = explosion_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = global_position

	queue_free()

func _notify_formation_broken():
	# 通知同一编队的所有组员
	var enemies = get_tree().get_nodes_in_group("formation_member")
	for enemy in enemies:
		if enemy != self and enemy.formation_id == formation_id:
			enemy.on_leader_died()
