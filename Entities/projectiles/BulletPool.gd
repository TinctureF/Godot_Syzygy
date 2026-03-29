extends Area3D

@export var bullet_scene: PackedScene
@export var speed: float = 30.0 # 子弹飞行速度
@export var damage: float = 2.0 # 基础伤害值
@export var lifespan: float = 3.0 # 存活时间，防止飞出世界后占用内存

func get_damage() -> float:
	return damage

func _ready():
	area_entered.connect(_on_area_entered)

var _timer: float = 0.0

func _physics_process(delta: float):
	# 核心修改：将 -global_transform.basis.z 改为 global_transform.basis.x [cite: 1214]
	# 假设你的飞机向右开火，使用 basis.x；如果向左，则使用 -basis.x
	var direction = global_transform.basis.x 
	var velocity = direction * speed * delta 
	# 无论逻辑如何计算，物理执行前强制将 Z 轴归零
	global_position.z = 0
	global_translate(velocity)
	
	# 强制锁定 Z 轴（深度），防止子弹产生“斜向出鞘”的错觉 [cite: 1, 1164]
	global_position.z = 0
	# 自动销毁逻辑
	_timer += delta
	if _timer >= lifespan:
		_recycle()

func _recycle():
	# 如果使用了对象池，这里应该是通知 Manager 回收 [cite: 1089]
	# DEMO 阶段可以直接删除
	queue_free()

# 碰撞逻辑已经在敌机端实现，但子弹击中后也需要消失
func _on_area_entered(_area: Area3D):
	# 击中任何东西（通常是敌机）后，子弹消失
	_recycle()

## 生成子弹
func spawn_bullet(pos: Vector2, direction: Vector2, _faction: String, _damage: float, _speed: float, bullet_scale: float = 1.0):
	if not bullet_scene:
		return

	var bullet = bullet_scene.instantiate()
	bullet.position = Vector3(pos.x, pos.y, 0)
	bullet.damage = _damage
	bullet.speed = _speed

	# 设置子弹大小 (MeshInstance3D用于3D子弹)
	if bullet_scale != 1.0:
		print("[BulletPool] 应用bullet_scale: ", bullet_scale)
		if bullet.has_node("MeshInstance3D"):
			var mesh = bullet.get_node("MeshInstance3D")
			mesh.scale *= bullet_scale
			print("[BulletPool] MeshInstance3D scale: ", mesh.scale)
		# 同时缩放碰撞体
		if bullet.has_node("CollisionShape3D"):
			var collision = bullet.get_node("CollisionShape3D")
			collision.scale *= bullet_scale

	# 设置方向（通过旋转）
	if direction != Vector2.RIGHT:
		var angle = direction.angle()
		bullet.rotation.z = angle

	add_child(bullet)
