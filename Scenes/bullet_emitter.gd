# 粒子子弹执行层
extends GPUParticles3D

@export var damage: float = 1.0
@export var bullet_speed: float = 50.0

func _physics_process(delta):
	# 每一帧，我们代表“整个弹流”进行一次前向探测
	var space_state = get_world_3d().direct_space_state
	
	# 模拟探测：从当前发射点向前方投射射线
	# 探测距离 = 速度 * 帧时间 (delta)
	var cast_dist = bullet_speed * delta
	var target_pos = global_position + (-global_transform.basis.z * cast_dist)
	
	var query = PhysicsRayQueryParameters3D.create(global_position, target_pos)
	query.collision_mask = 2 # 仅探测第 2 层（敌机层） [cite: 893]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		_on_bullet_hit(result)

func _on_bullet_hit(result):
	# 命中判定
	var collider = result.collider
	if collider.has_method("take_damage"):
		collider.take_damage(damage)
		
