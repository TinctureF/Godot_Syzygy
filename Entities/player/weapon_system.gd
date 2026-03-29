extends Node3D

# 导出子弹预制体，记得把 PlayerBullet.tscn 拖进来
@export var bullet_scene: PackedScene

# 基础数值设定
var base_fire_rate: float = 10.0  # 每秒10发
var current_fire_rate: float = 10.0
var fire_timer: float = 0.0

# Point buff参数
var damage_multiplier: float = 1.0
var bullet_scale: float = 1.0
var triple_shot: bool = false
var point_buff_timer: float = 0.0
var point_buff_type: int = 0

func _ready():
	# 连接buff更新信号
	SignalBus.buff_updated.connect(_on_buff_updated)

func _process(delta: float):
	# 1. 累加时间（这里会自动响应我们以后做的时空减速）
	fire_timer += delta

	# 2. 计算当前的射击间隔
	var fire_interval = 1.0 / current_fire_rate

	# 3. 自动触发判定
	if fire_timer >= fire_interval:
		shoot()
		fire_timer = 0.0 # 归零重置计时器

	# 4. Point buff倒计时
	if point_buff_timer > 0:
		point_buff_timer -= delta
		if point_buff_timer <= 0:
			_reset_point_buff()

func shoot():
	# 计算伤害
	var damage = 1.0 * damage_multiplier

	# 三排射击
	if triple_shot:
		_spawn_bullet_with_offset(Vector3(0, -0.3, 0), damage)
		_spawn_bullet_with_offset(Vector3(0, 0, 0), damage)
		_spawn_bullet_with_offset(Vector3(0, 0.3, 0), damage)
	else:
		_spawn_bullet_with_offset(Vector3(0, 0, 0), damage)

func _spawn_bullet_with_offset(offset: Vector3, damage: float):
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)

	# 核心逻辑：设置初始位置时，强制将 Z 设为 0
	var spawn_pos = $Muzzle.global_position + offset
	spawn_pos.z = 0
	bullet.global_position = spawn_pos

	# 同时确保旋转对齐，让子弹沿 X 轴飞行
	bullet.global_transform.basis = $Muzzle.global_transform.basis

	# 设置子弹属性
	bullet.damage = damage

	# 应用bullet_scale
	if bullet_scale != 1.0:
		if bullet.has_node("MeshInstance3D"):
			var mesh = bullet.get_node("MeshInstance3D")
			mesh.scale *= bullet_scale
		if bullet.has_node("CollisionShape3D"):
			var collision = bullet.get_node("CollisionShape3D")
			collision.scale *= bullet_scale

# 以后用于接收卡牌 Buff 的函数
func apply_speed_buff(multiplier: float):
	current_fire_rate = base_fire_rate * multiplier

## 响应Buff更新
func _on_buff_updated(buff: Dictionary) -> void:
	if buff.has("multiplier"):
		damage_multiplier = buff.multiplier

## 应用Point buff效果
func apply_point_buff(buff_type: int):
	if buff_type == 1:
		# 单张Point: 子弹变大，伤害翻倍，持续10秒
		point_buff_type = 1
		point_buff_timer = 10.0
		bullet_scale = 2.0
		damage_multiplier = 2.0
		print("[WeaponSystem] Point单张buff: bullet_scale=%.1f, damage_multiplier=%.1f, 持续10秒" % [bullet_scale, damage_multiplier])
	elif buff_type == 2:
		# Point顺子/刻子: 子弹变大，伤害翻倍，三排射击，持续15秒
		point_buff_type = 2
		point_buff_timer = 15.0
		bullet_scale = 2.0
		damage_multiplier = 2.0
		triple_shot = true
		print("[WeaponSystem] Point顺子/刻子buff: bullet_scale=%.1f, damage_multiplier=%.1f, triple_shot=true, 持续15秒" % [bullet_scale, damage_multiplier])

## 重置Point buff
func _reset_point_buff():
	point_buff_type = 0
	bullet_scale = 1.0
	triple_shot = false
	print("[WeaponSystem] Point buff结束, bullet_scale=%.1f, triple_shot=%s" % [bullet_scale, triple_shot])

## 获取当前DPS
func get_current_dps() -> float:
	return current_fire_rate * damage_multiplier
