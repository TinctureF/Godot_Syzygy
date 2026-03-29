@tool
extends CharacterBody3D

@export_group("移动与钝感")
@export var max_speed: float = 30.0
@export var acceleration: float = 3.0
@export var friction: float = 2.0

@export_group("生命值")
@export var max_hp: float = 20.0
var current_hp: float = 20.0
var current_hand: Array = []

@export_group("护盾")
@export var max_shield: float = 30.0
var current_shield: float = 0.0
var shield_active_hp: float = 5.0  # 血量低于此值时激活护盾
var has_shield: bool = false
var dying: bool = false  # 死亡状态，锁死护盾激活

@export_group("飞行边界 (屏幕百分比)")
@export var margin_x: float = 0.05 # 左右留白 5%
@export var margin_y: float = 0.08 # 上下留白 8%

@export_group("尾焰动态")
@export var flame_base_scale: Vector3 = Vector3(1, 1, 1) # 初始大小
@export var flame_max_boost: float = 1.5               # 向前飞时的最大倍率
@export var flame_min_brake: float = 0.6               # 后退时的最小倍率
@export var flame_lerp_speed: float = 8.0              # 缩放变化的平滑度

@onready var engine_flames: Node3D = $starship/EngineFlames
@onready var ship_visual: Node3D = $starship

func _ready():
	current_hp = max_hp
	current_shield = 0.0  # 护盾初始为0
	has_shield = false
	dying = false  # 重置死亡状态
	add_to_group("player")
	# 同步初始值到 DataVault
	DataVault.player_hp = current_hp
	DataVault.player_max_hp = max_hp
	DataVault.player_shield = current_shield
	DataVault.player_max_shield = max_shield

func get_faction() -> String:
	return "player"

func add_card_to_hand(card_data) -> bool:
	if card_data:
		current_hand.append(card_data)
		return true
	return false

## 增加护盾
func add_shield(amount: float):
	current_shield = clamp(current_shield + amount, 0, max_shield)
	has_shield = current_shield > 0
	# 同步到 DataVault
	DataVault.player_shield = current_shield
	DataVault.player_max_shield = max_shield
	SignalBus.player_shield_changed.emit(current_shield, max_shield)
	print("[Player] 护盾增加 %.1f, 当前: %.1f / %.1f" % [amount, current_shield, max_shield])

## 护盾加满
func fill_shield():
	current_shield = max_shield
	has_shield = true
	# 同步到 DataVault
	DataVault.player_shield = current_shield
	DataVault.player_max_shield = max_shield
	SignalBus.player_shield_changed.emit(current_shield, max_shield)
	print("[Player] 护盾已加满!")

func take_damage(amount: float):
	# 如果已死亡，忽略后续伤害
	if dying:
		return

	SignalBus.player_hit.emit(amount)

	# 护盾先扣
	if has_shield and current_shield > 0:
		current_shield -= amount
		# 同步到 DataVault
		DataVault.player_shield = current_shield
		SignalBus.player_shield_changed.emit(current_shield, max_shield)
		if current_shield <= 0:
			current_shield = 0
			DataVault.player_shield = 0
			has_shield = false
			print("[Player] 护盾破碎！")
		print("玩家护盾受伤: %.1f, 剩余护盾: %.1f" % [amount, current_shield])
		return

	# 扣血前先检查是否会导致死亡
	if current_hp - amount <= 0:
		# 即将死亡，不再激活护盾，直接结束
		dying = true
		current_hp = 0
		DataVault.player_hp = 0
		print("[Player] 血量耗尽，发送 game_over 信号")
		SignalBus.game_over.emit(false)
		return

	# 正常扣血
	current_hp -= amount
	# 同步到 DataVault
	DataVault.player_hp = current_hp
	DataVault.player_max_hp = max_hp
	SignalBus.player_hp_changed.emit(current_hp, max_hp)
	print("玩家血量受伤: %.1f, 剩余血量: %.1f" % [amount, current_hp])

	# 检查是否激活护盾（确保血量大于0且未死亡时才激活）
	if not has_shield and not dying and current_hp > 0 and current_hp <= shield_active_hp:
		_activate_shield()

func _activate_shield():
	has_shield = true
	current_shield = max_shield
	# 同步到 DataVault
	DataVault.player_shield = current_shield
	DataVault.player_max_shield = max_shield
	SignalBus.player_shield_changed.emit(current_shield, max_shield)
	print("[Player] 护盾激活！")

## 回血方法
func heal(amount: float):
	if dying or DataVault.game_over_locked:  # 双重保护：死亡状态或数据锁死时不能回血
		return
	current_hp = clamp(current_hp + amount, 0, max_hp)
	# 同步到 DataVault
	DataVault.player_hp = current_hp
	DataVault.player_max_hp = max_hp
	SignalBus.player_hp_changed.emit(current_hp, max_hp)
	print("[Player] 回血 %.1f, 当前血量: %.1f / %.1f" % [amount, current_hp, max_hp])

func _physics_process(delta):
	if Engine.is_editor_hint(): return

	# 1. 获取输入并计算带钝感的速度
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_vel = Vector3(input_dir.x, -input_dir.y, 0) * max_speed
	
	if target_vel.length() > 0:
		velocity = velocity.lerp(target_vel, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector3.ZERO, friction * delta)

	# 2. 执行移动
	move_and_slide()
	
	# 3. 核心：强制限制在屏幕内 [逻辑严密]
	_apply_screen_limits()


func _apply_screen_limits():
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	
	# 1. 获取屏幕坐标 (Vector2: x, y)
	var screen_pos = camera.unproject_position(global_position)
	var screen_rect = get_viewport().get_visible_rect().size
	
	# 2. 计算 3D 空间中的深度 (物体到相机平面的距离) 
	# 我们直接计算 global_position 到相机平面的投影距离
	var origin = camera.global_transform.origin
	var direction = -camera.global_transform.basis.z # 相机面对的方向
	var distance_to_cam = (global_position - origin).dot(direction)

	# 3. 定义限制范围
	var min_x = screen_rect.x * margin_x
	var max_x = screen_rect.x * (1.0 - margin_x)
	var min_y = screen_rect.y * margin_y
	var max_y = screen_rect.y * (1.0 - margin_y)
	
	# 4. 限制坐标
	var clamped_x = clamp(screen_pos.x, min_x, max_x)
	var clamped_y = clamp(screen_pos.y, min_y, max_y)
	
	# 5. 如果发生越界，重新计算 3D 坐标
	if screen_pos.x != clamped_x or screen_pos.y != clamped_y:
		# 使用 project_position 将屏幕像素和深度转回 3D 坐标 
		var target_3d_pos = camera.project_position(Vector2(clamped_x, clamped_y), distance_to_cam)
		
		# 越界反馈：清空对应轴向速度，增强“钝感”撞墙效果 [cite: 1172]
		if not is_equal_approx(screen_pos.x, clamped_x): 
			velocity.x = 0
		if not is_equal_approx(screen_pos.y, clamped_y): 
			velocity.y = 0
		
		global_position = target_3d_pos

func _process(delta):
	# 1. 基础抖动逻辑
	_handle_flame_jitter()
	
	if Engine.is_editor_hint(): return
	
	# 2. 侧倾动态：仅响应上下移动 (Y轴)
	var vertical_input = Input.get_axis("move_up", "move_down")
	ship_visual.rotation.z = lerp(ship_visual.rotation.z, -vertical_input * 0.6, delta * 5.0)
	
	# 3. 核心：尾焰缩放动态 [逻辑严密]
	# 需求：向前飞(X轴正向)尾焰变大，后退(X轴负向)变小
	_handle_flame_scaling(delta)

func _handle_flame_scaling(delta):
	if not engine_flames: return
	
	# 获取 X 轴的输入状态 (-1 为后退，1 为前进)
	var forward_input = Input.get_axis("move_left", "move_right")
	
	var target_scale_factor: float = 1.0
	
	if forward_input > 0:
		# 向前飞：推进器全开
		target_scale_factor = flame_max_boost
	elif forward_input < 0:
		# 后退：推进器减弱
		target_scale_factor = flame_min_brake
	else:
		# 静止或仅上下飞：恢复基础大小
		target_scale_factor = 1.0
		
	# 平滑插值：防止缩放瞬间跳变，产生一种能量涌动的过渡感
	var target_scale = flame_base_scale * target_scale_factor
	engine_flames.scale = engine_flames.scale.lerp(target_scale, delta * flame_lerp_speed)

func _handle_flame_jitter():
	if engine_flames:
		# 维持你之前的抖动逻辑，确保尾焰始终有活性
		var t = Time.get_ticks_msec() * 0.2
		engine_flames.position.x = sin(t) * 0.03
		engine_flames.position.y = cos(t * 1.1) * 0.03
